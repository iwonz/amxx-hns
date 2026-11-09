#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <fun>
#include <cstrike>
#include <dhudmessage>

#define PLUGIN "Hide N Seek: Ultimate"
#define VERSION "1.0"
#define AUTHOR "foxmits"

#include "hns/definitions.inc"
#include "hns/player_state.inc"
#include "hns/ui.inc"
#include "hns/map_rules.inc"
#include "hns/fall_damage.inc"
#include "hns/equipment.inc"

new const FLASHBANG_MODEL[] = "models/w_flashbang.mdl";

new g_iFlasher;
new g_iFlasherTeam;
new bool:g_bFlashFailed;
new bool:g_bFlashbangEntity[MAX_TRACKED_ENTITIES];

#include "hns/countdown.inc"
#include "hns/team_flow.inc"
#include "hns/round.inc"

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_dictionary("hns.txt");

	// CVARS
	g_aCvar[CVAR_TIMER] = register_cvar("hns_timer", "10");
	g_aCvar[CVAR_TIMER_IMMORTAL] = register_cvar("hns_timer_immortal", "1");
	g_aCvar[CVAR_TIMER_IMMORTAL_DELAY] = register_cvar("hns_timer_immortal_delay", "3.0");

	g_aCvar[CVAR_TIMER_ANTIFLASH_CT] = register_cvar("hns_timer_antiflash_ct", "1");

	g_aCvar[CVAR_CD_SOUND] = register_cvar("hns_cd_sound", "1");
	g_aCvar[CVAR_WIN_SOUND_MODE] = register_cvar("hns_win_sound_mode", "3");
	g_aCvar[CVAR_WIN_SOUND_HIDERS] = register_cvar("hns_win_sound_hiders", g_szHidersWinSound);
	g_aCvar[CVAR_WIN_SOUND_SEEKERS] = register_cvar("hns_win_sound_seekers", g_szSeekersWinSound);

	g_aCvar[CVAR_CT_TIMER_FADE_SCREEN] = register_cvar("hns_ct_timer_fade_screen", "1");
	g_aCvar[CVAR_CT_TIMER_FADE_SCREEN_R] = register_cvar("hns_ct_timer_fade_screen_r", "0");
	g_aCvar[CVAR_CT_TIMER_FADE_SCREEN_G] = register_cvar("hns_ct_timer_fade_screen_g", "0");
	g_aCvar[CVAR_CT_TIMER_FADE_SCREEN_B] = register_cvar("hns_ct_timer_fade_screen_b", "0");
	g_aCvar[CVAR_CT_TIMER_FADE_SCREEN_ALPHA] = register_cvar("hns_ct_timer_fade_screen_alpha", "150");

	g_aCvar[CVAR_HEGRENADE_MODE] = register_cvar("hns_hegrenade_mode", "0");

	g_aCvar[CVAR_FLASHBANG_MODE] = register_cvar("hns_flashbang_mode", "1");
	g_aCvar[CVAR_FLASHBANG_COUNT] = register_cvar("hns_flashbang_count", "2");

	g_aCvar[CVAR_FLASHBANG_FAILURE_CHANCE] = register_cvar("hns_flashbang_failure_chance", "0");
	g_aCvar[CVAR_FLASHBANG_FAILURE_NOTIFY] = register_cvar("hns_flashbang_failure_notify", "1");

	g_aCvar[CVAR_SMOKEGRENADE_MODE] = register_cvar("hns_smokegrenade_mode", "1");

	g_aCvar[CVAR_FLASH_FLASHER] = register_cvar("hns_flash_flasher", "0");
	g_aCvar[CVAR_FLASH_TEAMMATE] = register_cvar("hns_flash_teammate", "0");

	g_aCvar[CVAR_AUTOHEAL] = register_cvar("hns_autoheal", "1");
	g_aCvar[CVAR_AUTOHEAL_MODE] = register_cvar("hns_autoheal_mode", "3");
	g_aCvar[CVAR_AUTOHEAL_MAX_HP] = register_cvar("hns_autoheal_max_hp", "60");
	g_aCvar[CVAR_AUTOHEAL_DELAY] = register_cvar("hns_autoheal_delay", "1.5");

	g_aCvar[CVAR_FALLDOWN_SHOW_DMG] = register_cvar("hns_falldown_show_dmg", "1");
	g_aCvar[CVAR_FALLDOWN_PLAY_SOUND] = register_cvar("hns_falldown_play_sound", "1");

	g_aCvar[CVAR_FALLDOWN_FADESCREEN] = register_cvar("hns_falldown_fadescreen", "1");
	g_aCvar[CVAR_FALLDOWN_FADESCREEN_R] = register_cvar("hns_falldown_fadescreen_r", "255");
	g_aCvar[CVAR_FALLDOWN_FADESCREEN_G] = register_cvar("hns_falldown_fadescreen_g", "0");
	g_aCvar[CVAR_FALLDOWN_FADESCREEN_B] = register_cvar("hns_falldown_fadescreen_b", "0");
	g_aCvar[CVAR_FALLDOWN_FADESCREEN_ALPHA] = register_cvar("hns_falldown_fadescreen_alpha", "80");

	g_aCvar[CVAR_AUTOJOIN] = register_cvar("hns_autojoin", "1");
	g_aCvar[CVAR_AUTOJOIN_IMMUNITY] = register_cvar("hns_autojoin_immunity", "1");
	g_aCvar[CVAR_AUTOJOIN_IMMUNITY_FLAG] = register_cvar("hns_autojoin_immunity_flag", "t");

	g_aCvar[CVAR_CHANGE_TEAM] = register_cvar("hns_change_team", "0");
	g_aCvar[CVAR_CHANGE_TEAM_IMMUNITY] = register_cvar("hns_change_team_immunity", "1");
	g_aCvar[CVAR_CHANGE_TEAM_IMMUNITY_FLAG] = register_cvar("hns_change_team_immunity_flag", "t");

	g_aCvar[CVAR_AFK_CONTROL] = register_cvar("hns_afk_control", "1");
	g_aCvar[CVAR_AFK_CONTROL_TIMER_REVIVE] = register_cvar("hns_afk_timer_revive", "1");

	g_aCvar[CVAR_TR_FAKE_KNIFE_MODE] = register_cvar("hns_tr_fake_knife_mode", "1");

	// EVENTS
	register_event("HLTV", "fnRoundBeforeFreezeTime", "a", "1=0", "2=0");
	register_logevent("fnRoundAfterFreezeTime", 2, "0=World triggered", "1=Round_Start");
	register_logevent("fnRoundEnd", 2, "0=World triggered", "1=Round_Draw", "1=Round_End");

	register_event("DeathMsg", "fnDeath", "a");

	register_event("CurWeapon", "fnTakeKnife", "be", "1=1", "2=29");

	RegisterHam(Ham_Spawn, "player", "fnPlayerSpawnAfter", 1);
	RegisterHam(Ham_TakeDamage, "player", "fnTakeDamage");

	// MESSAGES
	register_message(get_user_msgid("SendAudio"), "msgBlockWINSendAudio");
	register_message(get_user_msgid("TextMsg"), "msgBlockWINSendText");

	register_message(get_user_msgid("StatusIcon"), "msgStatusIcon");

	register_message(get_user_msgid("ScreenFade"), "msgScreenFade");

	register_message(get_user_msgid("ShowMenu"), "msgShowMenu");
	register_message(get_user_msgid("VGUIMenu"), "msgVguiMenu");

	g_TimerEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));

	// FORWARDS
	register_forward(FM_Think, "fwdThink");
	register_forward(FM_SetModel, "fwdSetModel");
	register_forward(FM_CmdStart, "fwdCmdStart");
	register_forward(FM_EmitSound, "fwdEmitSound");

	unregister_forward(FM_Spawn, g_RegisterSpawn);

	// CLIENT CMD
	register_clcmd("say /cd", "fnToggleCountdownSound");
	register_clcmd("say_team /cd", "fnToggleCountdownSound");

	register_clcmd("say /afk", "fnSayAfk");
	register_clcmd("say_team /afk", "fnSayAfk");

	register_clcmd("say /spec", "fnSayAfk");
	register_clcmd("say_team /spec", "fnSayAfk");

	register_clcmd("say /play", "fnSayPlay");
	register_clcmd("say_team /play", "fnSayPlay");

	register_clcmd("say /back", "fnSayPlay");
	register_clcmd("say_team /back", "fnSayPlay");

	register_clcmd("chooseteam", "fnChooseTeam");
	register_clcmd("jointeam", "fnJoinTeam");

	g_SyncHud = CreateHudSyncObj();
}

public plugin_cfg() {
	new szConfigDir[128];
	get_localinfo("amxx_configsdir", szConfigDir, charsmax(szConfigDir));
	server_cmd("exec ^"%s/hns.cfg^"", szConfigDir);
}

public client_connect(id) {
	g_bConnected[id] = true;
	g_aCountdownSound[id] = true;
	g_aIsAfkTeam[id] = 0;
}

public client_disconnect(id) {
	fnRemovePlayerTasks(id);

	g_bConnected[id] = false;
	g_aCountdownSound[id] = false;
	g_aIsAfkTeam[id] = 0;
}

fnRemoveRoundTasks(id) {
	remove_task(TASK_AUTOHEAL + id);
	remove_task(TASK_REVIVE + id);
	remove_task(TASK_AFK_REVIVE + id);
	remove_task(TASK_GIVE_WEAPONS + id);
}

fnRemovePlayerTasks(id) {
	fnRemoveRoundTasks(id);
	remove_task(TASK_FORCE_JOIN + id);
}

public fwdSetModel(ent, const szModel[]) {
	if(ent > 0 && ent < sizeof g_bFlashbangEntity)
		g_bFlashbangEntity[ent] = equal(szModel, FLASHBANG_MODEL) != 0;

	return FMRES_IGNORED;
}

public fwdThink(ent) {
	if(ent == g_TimerEntity) {
		if(!g_bStart) {
			fnStopCountdown();
			return FMRES_IGNORED;
		}

		fnTimer(ent);
		return FMRES_IGNORED;
	}

	if(fnIsFlashbangDetonating(ent))
		fnPrepareFlashbang(ent);

	return FMRES_IGNORED;
}

bool:fnIsFlashbangDetonating(ent) {
	if(
		ent <= 0 ||
		ent >= sizeof g_bFlashbangEntity ||
		!g_bFlashbangEntity[ent] ||
		!pev_valid(ent)
	)
		return false;

	new Float:fDamageTime;
	pev(ent, pev_dmgtime, fDamageTime);

	return fDamageTime <= get_gametime();
}

fnPrepareFlashbang(ent) {
	g_bFlashbangEntity[ent] = false;

	new iOwner = pev(ent, pev_owner);

	if(is_user_connected(iOwner)) {
		g_iFlasher = iOwner;
		g_iFlasherTeam = get_user_team(iOwner);
	} else {
		g_iFlasher = 0;
		g_iFlasherTeam = 0;
	}

	new iFailureChance = clamp(get_pcvar_num(g_aCvar[CVAR_FLASHBANG_FAILURE_CHANCE]), 0, 100);
	g_bFlashFailed = iFailureChance > 0 && random_num(1, 100) <= iFailureChance;

	if(g_bFlashFailed && is_user_connected(iOwner))
		fnNotifyFlashbangFailure(iOwner);
}

fnNotifyFlashbangFailure(id) {
	new iNotifyMode = clamp(get_pcvar_num(g_aCvar[CVAR_FLASHBANG_FAILURE_NOTIFY]), 0, 3);

	switch(iNotifyMode) {
		case 1:
			ChatColorKey(id, "HNS_FLASH_FAILED_CHAT");
		case 2: {
			set_dhudmessage(255, 80, 0, -1.0, 0.65, 0, 0.0, 2.0, 0.1, 0.2);
			show_dhudmessage(id, "%L", id, "HNS_FLASH_FAILED_HUD");
		}
		case 3:
			client_cmd(id, "spk buttons/button10.wav");
	}
}

public plugin_precache() {
	g_aCvar[CVAR_REMOVE_BREAKABLES] = register_cvar("hns_remove_breakables", "1");
	g_aCvar[CVAR_REMOVE_DOORS] = register_cvar("hns_remove_doors", "1");
	fnLoadWinSoundConfig();
	fnPrecacheWinSounds();

	g_RegisterSpawn = register_forward(FM_Spawn, "fwdEntitySpawn");

	for(new i = 1; i <= 10; i++) {
		new szPrecacheCountdown[32];
		formatex(szPrecacheCountdown, 31, "hns/countdown/%d.wav", i);

		precache_sound(szPrecacheCountdown);
	}

	precache_sound("hns/falldown/1.wav");
}

public msgScreenFade(msgId, msgDest, msgEnt) {
	if(!fnIsFlashScreenFade() || !g_iFlasherTeam || !is_user_alive(msgEnt))
		return PLUGIN_CONTINUE;

	if(g_bFlashFailed)
		return PLUGIN_HANDLED;

	if(g_iTimer && get_pcvar_num(g_aCvar[CVAR_TIMER_ANTIFLASH_CT]) == 1 && get_user_team(msgEnt) == 2)
		return PLUGIN_HANDLED;

	if(g_iFlasher == msgEnt && get_pcvar_num(g_aCvar[CVAR_FLASH_FLASHER]) == 0)
		return PLUGIN_HANDLED;

	if(g_iFlasherTeam == get_user_team(msgEnt) && get_pcvar_num(g_aCvar[CVAR_FLASH_TEAMMATE]) == 0)
		return PLUGIN_HANDLED;

	return PLUGIN_CONTINUE;
}

bool:fnIsFlashScreenFade() {
	return (
		get_msg_arg_int(4) == 255 &&
		get_msg_arg_int(5) == 255 &&
		get_msg_arg_int(6) == 255 &&
		get_msg_arg_int(7) > 0
	);
}
