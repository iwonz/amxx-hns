import re
import unittest
from pathlib import Path


SOURCE_PATH = Path(__file__).parents[1] / "src" / "scripting" / "hns.sma"
SOURCE = SOURCE_PATH.read_text(encoding="utf-8")


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


if __name__ == "__main__":
  unittest.main()
