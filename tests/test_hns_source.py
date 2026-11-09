import re
import unittest
from pathlib import Path


SCRIPTING_DIR = Path(__file__).parents[1] / "src" / "scripting"
SOURCE_PATH = SCRIPTING_DIR / "hns.sma"
ROOT_SOURCE = SOURCE_PATH.read_text(encoding="utf-8")
INTERNAL_SOURCE_PATHS = sorted((SCRIPTING_DIR / "hns").glob("*.inc"))
EXPECTED_INTERNAL_MODULES = {
  "countdown.inc",
  "definitions.inc",
  "equipment.inc",
  "fall_damage.inc",
  "flashbang.inc",
  "map_rules.inc",
  "player_state.inc",
  "round.inc",
  "team_flow.inc",
  "ui.inc",
}
SOURCE = "\n".join(
  [ROOT_SOURCE]
  + [path.read_text(encoding="utf-8") for path in INTERNAL_SOURCE_PATHS]
)
CONFIG_PATH = Path(__file__).parents[1] / "src" / "configs" / "hns.cfg"
CONFIG = CONFIG_PATH.read_text(encoding="cp1251")
LANG_PATH = Path(__file__).parents[1] / "src" / "data" / "lang" / "hns.txt"
LANG = LANG_PATH.read_text(encoding="utf-8")


def function_body(name: str) -> str:
  match = re.search(rf"\b{name}\s*\([^)]*\)\s*\{{", SOURCE)
  if not match:
    raise AssertionError(f"Function {name} was not found")

  opening_brace = SOURCE.index("{", match.start())
  depth = 0

  for index in range(opening_brace, len(SOURCE)):
    if SOURCE[index] == "{":
      depth += 1
    elif SOURCE[index] == "}":
      depth -= 1
      if depth == 0:
        return SOURCE[opening_brace + 1:index]

  raise AssertionError(f"Function {name} has no closing brace")


class HnsSourceRegressionTests(unittest.TestCase):
  def test_internal_module_set_matches_the_composition_contract(self):
    self.assertEqual(
      EXPECTED_INTERNAL_MODULES,
      {path.name for path in INTERNAL_SOURCE_PATHS},
    )

  def test_every_internal_module_is_included_by_composition_root(self):
    for path in INTERNAL_SOURCE_PATHS:
      self.assertIn(f'#include "hns/{path.name}"', ROOT_SOURCE)

  def test_core_does_not_expose_a_public_plugin_api(self):
    for public_api_marker in (
      "public plugin_natives()",
      "register_library(",
      "register_native(",
      "CreateMultiForward(",
    ):
      self.assertNotIn(public_api_marker, SOURCE)

  def test_play_only_restores_afk_spectators_to_playable_team(self):
    body = function_body("fnSayPlay")
    guard = "if(get_user_team(id) != 3 || !fnIsPlayableTeam(g_aIsAfkTeam[id]))"
    team_change = "cs_set_user_team(id, g_aIsAfkTeam[id]);"

    self.assertIn("bool:fnIsPlayableTeam", SOURCE)
    self.assertIn(guard, body)
    self.assertLess(body.index(guard), body.index(team_change))

  def test_player_tasks_have_namespaces_and_lifecycle_cleanup(self):
    expected_task_bases = (
      "TASK_AUTOHEAL",
      "TASK_REVIVE",
      "TASK_AFK_REVIVE",
      "TASK_FORCE_JOIN",
      "TASK_GIVE_WEAPONS",
    )

    for task_base in expected_task_bases:
      self.assertRegex(SOURCE, rf"#define {task_base} \d+")

    self.assertNotIn("AUTOHEAL_TASKID", SOURCE)
    self.assertNotIn("REVIVE_TASKID", SOURCE)
    self.assertIn("fnRemovePlayerTasks(id);", function_body("client_disconnect"))
    self.assertIn("fnRemoveRoundTasks(i);", function_body("fnRoundEnd"))
    self.assertIn(
      'set_task(0.1, "taskGiveWeapons", TASK_GIVE_WEAPONS + id);',
      function_body("fnPlayerSpawnAfter"),
    )
    self.assertIn(
      'set_task(0.2, "fnAfkControlRevive", TASK_AFK_REVIVE + id);',
      function_body("fnSayPlay"),
    )

  def test_countdown_is_bounded_and_stopped_on_round_transitions(self):
    self.assertIn("new bool:g_bCountdownActive = false;", SOURCE)
    self.assertIn(
      "g_bStart = iTR > 0 && iCT > 0;",
      function_body("fnRoundBeforeFreezeTime"),
    )
    self.assertIn(
      "g_iTimer = clamp(get_pcvar_num(g_aCvar[CVAR_TIMER]), 1, 10);",
      function_body("fnRoundAfterFreezeTime"),
    )
    self.assertIn("fnStopCountdown();", function_body("fnRoundEnd"))
    self.assertIn("if(!g_bCountdownActive)", function_body("fnStopCountdown"))
    self.assertIn("fnEndCountdown(false);", function_body("fnStopCountdown"))
    self.assertIn("g_bStart &&", function_body("fnDeath"))
    self.assertIn("g_iTimer > 0", function_body("fnRevive"))
    self.assertIn("g_iTimer > 0", function_body("fnAfkControlRevive"))

  def test_flash_rules_are_scoped_to_the_detonating_flashbang(self):
    self.assertIn(
      'new const FLASHBANG_MODEL[] = "models/w_flashbang.mdl";',
      SOURCE,
    )
    self.assertNotIn(
      'register_message(get_user_msgid("SendAudio"), "msgSendAudio");',
      SOURCE,
    )
    self.assertNotRegex(SOURCE, r"public msgSendAudio\s*\(")
    self.assertIn('register_forward(FM_SetModel, "fwdSetModel");', SOURCE)
    self.assertIn("fnPrepareFlashbang(ent);", function_body("fwdThink"))

    fade_body = function_body("msgScreenFade")
    self.assertIn("if(!fnIsFlashScreenFade()", fade_body)
    self.assertIn("g_bFlashFailed", fade_body)
    self.assertNotIn("random_num", fade_body)
    self.assertIn("random_num", function_body("fnPrepareFlashbang"))
    self.assertIn(
      "fnResetFlashbangRoundState();",
      function_body("fnRoundBeforeFreezeTime"),
    )
    reset_body = function_body("fnResetFlashbangRoundState")
    self.assertIn("g_iFlasher = g_iFlasherTeam = 0;", reset_body)
    self.assertIn("g_bFlashFailed = false;", reset_body)

  def test_flash_failure_notification_mode_is_configurable_and_sent_once(self):
    self.assertIn("CVAR_FLASHBANG_FAILURE_NOTIFY", SOURCE)
    self.assertIn(
      'register_cvar("hns_flashbang_failure_notify", "1")',
      SOURCE,
    )
    self.assertIn('hns_flashbang_failure_notify "1"', CONFIG)
    self.assertIn('server_cmd("exec ^\"%s/hns.cfg^\"", szConfigDir);', SOURCE)

    prepare_body = function_body("fnPrepareFlashbang")
    self.assertIn(
      "if(g_bFlashFailed && is_user_connected(iOwner))",
      prepare_body,
    )
    self.assertIn("fnNotifyFlashbangFailure(iOwner);", prepare_body)

    notify_body = function_body("fnNotifyFlashbangFailure")
    self.assertIn("switch(iNotifyMode)", notify_body)
    self.assertIn("case 1:", notify_body)
    self.assertIn("case 2:", notify_body)
    self.assertIn("case 3:", notify_body)
    self.assertIn("ChatColor", notify_body)
    self.assertIn("show_dhudmessage", notify_body)
    self.assertIn('client_cmd(id, "spk buttons/button10.wav")', notify_body)
    self.assertNotIn(
      "fnNotifyFlashbangFailure",
      function_body("msgScreenFade"),
    )

  def test_antifrag_scaffolding_is_removed(self):
    for stale_text in (
      "Anti Frag",
      "Anti-Frag",
      "af_active",
      "af_type",
      "af_time",
      "HNS_AF_",
    ):
      self.assertNotIn(stale_text, SOURCE)
      self.assertNotIn(stale_text, CONFIG)
      self.assertNotIn(stale_text, LANG)

  def test_obsolete_player_model_todo_is_removed(self):
    self.assertNotIn("Стандартные модельки", SOURCE)

  def test_win_sounds_are_configured_precached_and_played_by_winner(self):
    for cvar_name in (
      "hns_win_sound_mode",
      "hns_win_sound_hiders",
      "hns_win_sound_seekers",
    ):
      self.assertIn(cvar_name, SOURCE)
      self.assertIn(cvar_name, CONFIG)

    precache_body = function_body("plugin_precache")
    self.assertIn("fnLoadWinSoundConfig();", precache_body)
    self.assertIn("fnPrecacheWinSounds();", precache_body)
    self.assertLess(
      precache_body.index("fnLoadWinSoundConfig();"),
      precache_body.index("fnPrecacheWinSounds();"),
    )

    win_precache_body = function_body("fnPrecacheWinSounds")
    self.assertIn("precache_sound(g_szHidersWinSound);", win_precache_body)
    self.assertIn("precache_sound(g_szSeekersWinSound);", win_precache_body)

    round_end_body = function_body("fnRoundEnd")
    self.assertIn("fnPlayWinSound(1);", round_end_body)
    self.assertIn("fnPlayWinSound(2);", round_end_body)

    play_body = function_body("fnPlayWinSound")
    self.assertIn("CVAR_WIN_SOUND_MODE", play_body)
    self.assertIn('client_cmd(0, "spk %s", szSound);', play_body)
    self.assertNotIn("Кастомные звуки на победу", SOURCE)

  def test_stale_countdown_command_notices_are_removed(self):
    for stale_text in (
      "Сообщения о командах в чате",
      "TODO: СДЕЛАТЬ",
      "cd_on",
      "cd_time",
      "/cdon",
      "/cdoff",
      "HNS_COUNTDOWN_ON",
      "HNS_COUNTDOWN_OFF",
    ):
      self.assertNotIn(stale_text, SOURCE)
      self.assertNotIn(stale_text, CONFIG)
      self.assertNotIn(stale_text, LANG)

  def test_countdown_sound_preference_is_initialized_per_connection(self):
    self.assertIn("new bool:g_aCountdownSound[33];", SOURCE)
    self.assertIn("g_aCountdownSound[id] = true;", function_body("client_connect"))
    self.assertIn("g_aCountdownSound[id] = false;", function_body("client_disconnect"))

  def test_afk_saved_team_follows_role_swaps(self):
    body = function_body("fnSwapTeams")
    saved_team_swap = "switch(g_aIsAfkTeam[aPlayers[i]])"
    active_team_swap = "switch(iUserTeam)"

    self.assertIn(saved_team_swap, body)
    self.assertIn("case 1: g_aIsAfkTeam[aPlayers[i]] = 2;", body)
    self.assertIn("case 2: g_aIsAfkTeam[aPlayers[i]] = 1;", body)
    self.assertLess(body.index(saved_team_swap), body.index(active_team_swap))
    self.assertNotIn("if(g_aIsAfkTeam[aPlayers[i]] != 0)", body)
    self.assertNotIn("Проверить g_aCountdownSound", SOURCE)

  def test_countdown_antiflash_only_blocks_flash_fades_for_seekers(self):
    body = function_body("msgScreenFade")
    flash_guard = "if(!fnIsFlashScreenFade()"
    countdown_guard = (
      "if(g_iTimer && get_pcvar_num(g_aCvar[CVAR_TIMER_ANTIFLASH_CT]) == 1 "
      "&& get_user_team(msgEnt) == 2)"
    )

    self.assertIn(flash_guard, body)
    self.assertIn(countdown_guard, body)
    self.assertLess(body.index(flash_guard), body.index(countdown_guard))
    self.assertNotIn("Проверить антифлеш кт", SOURCE)

  def test_all_player_facing_text_uses_complete_bilingual_dictionary(self):
    expected_keys = {
      "HNS_CHAT_PREFIX",
      "HNS_FEATURE_DISABLED",
      "HNS_ALREADY_SPECTATOR",
      "HNS_RETURN_TO_GAME_HINT",
      "HNS_MOVED_TO_SPECTATOR",
      "HNS_CANNOT_RETURN_TO_GAME",
      "HNS_RETURNED_TO_GAME",
      "HNS_COUNTDOWN_SOUND_SERVER_DISABLED",
      "HNS_COUNTDOWN_SOUND_DISABLED",
      "HNS_COUNTDOWN_SOUND_ENABLED",
      "HNS_FLASH_FAILED_CHAT",
      "HNS_FLASH_FAILED_HUD",
      "HNS_HIDERS_WIN",
      "HNS_SEEKERS_WIN",
      "HNS_COUNTDOWN",
      "HNS_ROUND_START",
      "HNS_FALL_DAMAGE",
    }
    keys_by_language = {"ru": set(), "en": set()}
    language = None

    for raw_line in LANG.splitlines():
      line = raw_line.strip()
      if line in ("[ru]", "[en]"):
        language = line[1:-1]
      elif language and line and not line.startswith(";"):
        keys_by_language[language].add(line.split("=", 1)[0].strip())

    self.assertEqual(expected_keys, keys_by_language["ru"])
    self.assertEqual(expected_keys, keys_by_language["en"])
    self.assertIn('register_dictionary("hns.txt");', SOURCE)
    self.assertNotIn("#define CHAT_PREFIX", SOURCE)
    self.assertNotIn("WordForm", SOURCE)
    self.assertIsNone(re.search(r'"[^"\n]*[А-Яа-яЁё][^"\n]*"', SOURCE))

    for key in expected_keys:
      self.assertIn(f'"{key}"', SOURCE)

  def test_alive_checks_use_engine_state_instead_of_cached_flags(self):
    self.assertNotIn("g_bAlive", SOURCE)
    self.assertIn("if(is_user_alive(id))", function_body("fnSayAfk"))
    self.assertIn("if(!is_user_alive(id))", function_body("fwdCmdStart"))
    self.assertIn("!is_user_alive(msgEnt)", function_body("msgScreenFade"))
    self.assertIn("is_user_alive(aPlayers[i])", function_body("fnTRAlive"))

  def test_cmdstart_preserves_game_callback_when_blocking_knife_attacks(self):
    body = function_body("fwdCmdStart")

    self.assertNotIn("return 4;", body)
    self.assertNotIn("FMRES_SUPERCEDE", body)
    self.assertIn("IN_ATTACK | IN_ATTACK2", body)
    self.assertIn("return FMRES_HANDLED;", body)
    self.assertIn("return FMRES_IGNORED;", body)

  def test_team_change_cvar_and_immunity_have_independent_semantics(self):
    self.assertIn("return fnHandleTeamChange(id);", function_body("fnChooseTeam"))
    self.assertIn("return fnHandleTeamChange(id);", function_body("fnJoinTeam"))

    body = function_body("fnHandleTeamChange")
    global_allow = "if(get_pcvar_num(g_aCvar[CVAR_CHANGE_TEAM]) == 1)"
    immunity_check = "if(get_pcvar_num(g_aCvar[CVAR_CHANGE_TEAM_IMMUNITY]) == 1)"

    self.assertIn(global_allow, body)
    self.assertIn(immunity_check, body)
    self.assertLess(body.index(global_allow), body.index(immunity_check))
    self.assertIn("return PLUGIN_CONTINUE;", body)
    self.assertIn("return PLUGIN_HANDLED;", body)

  def test_countdown_and_fall_fades_have_independent_config_keys(self):
    expected_values = {
      "hns_ct_timer_fade_screen_r": "0",
      "hns_ct_timer_fade_screen_g": "0",
      "hns_ct_timer_fade_screen_b": "0",
      "hns_ct_timer_fade_screen_alpha": "150",
      "hns_falldown_fadescreen_r": "255",
      "hns_falldown_fadescreen_g": "0",
      "hns_falldown_fadescreen_b": "0",
      "hns_falldown_fadescreen_alpha": "80",
    }

    configured_values = {}
    for raw_line in CONFIG.splitlines():
      match = re.fullmatch(r'(hns_(?:ct_timer|falldown)_fade_?screen_[a-z]+)\s+"([^"]+)"', raw_line.strip())
      if match:
        configured_values.setdefault(match.group(1), []).append(match.group(2))

    self.assertEqual(
      {name: [value] for name, value in expected_values.items()},
      configured_values,
    )


if __name__ == "__main__":
  unittest.main()
