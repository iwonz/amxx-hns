#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <fun>
#include <cstrike>

#include "hns/version.inc"

#define PLUGIN "Hide And Seek: Ultimate"
#define AUTHOR "foxmits"

#include "hns/definitions.inc"
#include "hns/player_state.inc"
#include "hns/ui.inc"
#include "hns/map_rules.inc"
#include "hns/fall_damage.inc"
#include "hns/equipment.inc"

#include "hns/countdown.inc"
#include "hns/flashbang.inc"
#include "hns/team_flow.inc"
#include "hns/round.inc"

public plugin_init() {
	register_plugin(PLUGIN, HNS_VERSION, AUTHOR);
	register_dictionary("hns.txt");

	// CVARS
	new pCvar;
	pCvar = create_cvar("hns_timer", "10", .description = "Countdown duration in seconds", .has_min = true, .min_val = 1.0, .has_max = true, .max_val = 10.0);
	bind_pcvar_num(pCvar, g_iCvarTimer);
	pCvar = create_cvar("hns_timer_immortal", "1", .description = "Respawn players during countdown", .has_min = true, .min_val = 0.0, .has_max = true, .max_val = 1.0);
	bind_pcvar_num(pCvar, g_iCvarTimerImmortal);
	pCvar = create_cvar("hns_timer_immortal_delay", "3.0", .description = "Countdown respawn delay", .has_min = true, .min_val = 0.0);
	bind_pcvar_float(pCvar, g_fCvarTimerImmortalDelay);

	pCvar = create_cvar("hns_timer_antiflash_ct", "1", .description = "Protect seekers from flash during countdown", .has_min = true, .min_val = 0.0, .has_max = true, .max_val = 1.0);
	bind_pcvar_num(pCvar, g_iCvarTimerAntiflashCt);

	pCvar = create_cvar("hns_cd_sound", "1", .description = "Enable countdown sounds", .has_min = true, .min_val = 0.0, .has_max = true, .max_val = 1.0);
	bind_pcvar_num(pCvar, g_iCvarCountdownSound);
	pCvar = create_cvar("hns_win_sound_mode", "3", .description = "Winning team sound mode", .has_min = true, .min_val = 0.0, .has_max = true, .max_val = 3.0);
	bind_pcvar_num(pCvar, g_iCvarWinSoundMode);
	create_cvar("hns_win_sound_hiders", g_szHidersWinSound, .description = "Hider win sound path loaded during precache");
	create_cvar("hns_win_sound_seekers", g_szSeekersWinSound, .description = "Seeker win sound path loaded during precache");

	pCvar = create_cvar("hns_ct_timer_fade_screen", "1", .description = "Fade seeker screens during countdown", .has_min = true, .min_val = 0.0, .has_max = true, .max_val = 1.0);
	bind_pcvar_num(pCvar, g_iCvarCtTimerFadeScreen);
	pCvar = create_cvar("hns_ct_timer_fade_screen_r", "0", .description = "Countdown fade red channel", .has_min = true, .min_val = 0.0, .has_max = true, .max_val = 255.0);
	bind_pcvar_num(pCvar, g_iCvarCtTimerFadeScreenRed);
	pCvar = create_cvar("hns_ct_timer_fade_screen_g", "0", .description = "Countdown fade green channel", .has_min = true, .min_val = 0.0, .has_max = true, .max_val = 255.0);
	bind_pcvar_num(pCvar, g_iCvarCtTimerFadeScreenGreen);
	pCvar = create_cvar("hns_ct_timer_fade_screen_b", "0", .description = "Countdown fade blue channel", .has_min = true, .min_val = 0.0, .has_max = true, .max_val = 255.0);
	bind_pcvar_num(pCvar, g_iCvarCtTimerFadeScreenBlue);
	pCvar = create_cvar("hns_ct_timer_fade_screen_alpha", "150", .description = "Countdown fade alpha channel", .has_min = true, .min_val = 0.0, .has_max = true, .max_val = 255.0);
	bind_pcvar_num(pCvar, g_iCvarCtTimerFadeScreenAlpha);

	pCvar = create_cvar("hns_hegrenade_mode", "0", .description = "HE grenade team mode", .has_min = true, .min_val = 0.0, .has_max = true, .max_val = 3.0);
	bind_pcvar_num(pCvar, g_iCvarHegrenadeMode);
	pCvar = create_cvar("hns_flashbang_mode", "1", .description = "Flashbang team mode", .has_min = true, .min_val = 0.0, .has_max = true, .max_val = 3.0);
	bind_pcvar_num(pCvar, g_iCvarFlashbangMode);
	pCvar = create_cvar("hns_flashbang_count", "2", .description = "Flashbang count per spawn", .has_min = true, .min_val = 0.0, .has_max = true, .max_val = 2.0);
	bind_pcvar_num(pCvar, g_iCvarFlashbangCount);
	pCvar = create_cvar("hns_flashbang_failure_chance", "0", .description = "Flashbang failure chance percent", .has_min = true, .min_val = 0.0, .has_max = true, .max_val = 100.0);
	bind_pcvar_num(pCvar, g_iCvarFlashbangFailureChance);
	pCvar = create_cvar("hns_flashbang_failure_notify", "1", .description = "Flashbang failure notification mode", .has_min = true, .min_val = 0.0, .has_max = true, .max_val = 3.0);
	bind_pcvar_num(pCvar, g_iCvarFlashbangFailureNotify);
	pCvar = create_cvar("hns_smokegrenade_mode", "1", .description = "Smoke grenade team mode", .has_min = true, .min_val = 0.0, .has_max = true, .max_val = 3.0);
	bind_pcvar_num(pCvar, g_iCvarSmokegrenadeMode);
	pCvar = create_cvar("hns_flash_flasher", "0", .description = "Allow self flash", .has_min = true, .min_val = 0.0, .has_max = true, .max_val = 1.0);
	bind_pcvar_num(pCvar, g_iCvarFlashFlasher);
	pCvar = create_cvar("hns_flash_teammate", "0", .description = "Allow teammate flash", .has_min = true, .min_val = 0.0, .has_max = true, .max_val = 1.0);
	bind_pcvar_num(pCvar, g_iCvarFlashTeammate);

	pCvar = create_cvar("hns_autoheal", "1", .description = "Enable delayed fall damage recovery", .has_min = true, .min_val = 0.0, .has_max = true, .max_val = 1.0);
	bind_pcvar_num(pCvar, g_iCvarAutoheal);
	pCvar = create_cvar("hns_autoheal_mode", "3", .description = "Fall damage recovery team mode", .has_min = true, .min_val = 0.0, .has_max = true, .max_val = 3.0);
	bind_pcvar_num(pCvar, g_iCvarAutohealMode);
	pCvar = create_cvar("hns_autoheal_max_hp", "60", .description = "Maximum health restored per fall", .has_min = true, .min_val = 0.0);
	bind_pcvar_num(pCvar, g_iCvarAutohealMaxHp);
	pCvar = create_cvar("hns_autoheal_delay", "1.5", .description = "Fall damage recovery delay", .has_min = true, .min_val = 0.0);
	bind_pcvar_float(pCvar, g_fCvarAutohealDelay);

	pCvar = create_cvar("hns_falldown_show_dmg", "1", .description = "Show received fall damage", .has_min = true, .min_val = 0.0, .has_max = true, .max_val = 1.0);
	bind_pcvar_num(pCvar, g_iCvarFalldownShowDamage);
	pCvar = create_cvar("hns_falldown_play_sound", "1", .description = "Play fall damage sound", .has_min = true, .min_val = 0.0, .has_max = true, .max_val = 1.0);
	bind_pcvar_num(pCvar, g_iCvarFalldownPlaySound);
	pCvar = create_cvar("hns_falldown_fadescreen", "1", .description = "Show fall damage screen fade", .has_min = true, .min_val = 0.0, .has_max = true, .max_val = 1.0);
	bind_pcvar_num(pCvar, g_iCvarFalldownFadeScreen);
	pCvar = create_cvar("hns_falldown_fadescreen_r", "255", .description = "Fall fade red channel", .has_min = true, .min_val = 0.0, .has_max = true, .max_val = 255.0);
	bind_pcvar_num(pCvar, g_iCvarFalldownFadeScreenRed);
	pCvar = create_cvar("hns_falldown_fadescreen_g", "0", .description = "Fall fade green channel", .has_min = true, .min_val = 0.0, .has_max = true, .max_val = 255.0);
	bind_pcvar_num(pCvar, g_iCvarFalldownFadeScreenGreen);
	pCvar = create_cvar("hns_falldown_fadescreen_b", "0", .description = "Fall fade blue channel", .has_min = true, .min_val = 0.0, .has_max = true, .max_val = 255.0);
	bind_pcvar_num(pCvar, g_iCvarFalldownFadeScreenBlue);
	pCvar = create_cvar("hns_falldown_fadescreen_alpha", "80", .description = "Fall fade alpha channel", .has_min = true, .min_val = 0.0, .has_max = true, .max_val = 255.0);
	bind_pcvar_num(pCvar, g_iCvarFalldownFadeScreenAlpha);

	pCvar = create_cvar("hns_autojoin", "1", .description = "Enable automatic team join", .has_min = true, .min_val = 0.0, .has_max = true, .max_val = 1.0);
	bind_pcvar_num(pCvar, g_iCvarAutojoin);
	pCvar = create_cvar("hns_autojoin_immunity", "1", .description = "Enable autojoin immunity", .has_min = true, .min_val = 0.0, .has_max = true, .max_val = 1.0);
	bind_pcvar_num(pCvar, g_iCvarAutojoinImmunity);
	pCvar = create_cvar("hns_autojoin_immunity_flag", "t", .description = "Autojoin immunity access flag");
	bind_pcvar_string(pCvar, g_szCvarAutojoinImmunityFlag, charsmax(g_szCvarAutojoinImmunityFlag));

	pCvar = create_cvar("hns_change_team", "0", .description = "Allow unrestricted team changes", .has_min = true, .min_val = 0.0, .has_max = true, .max_val = 1.0);
	bind_pcvar_num(pCvar, g_iCvarChangeTeam);
	pCvar = create_cvar("hns_change_team_immunity", "1", .description = "Enable team change immunity", .has_min = true, .min_val = 0.0, .has_max = true, .max_val = 1.0);
	bind_pcvar_num(pCvar, g_iCvarChangeTeamImmunity);
	pCvar = create_cvar("hns_change_team_immunity_flag", "t", .description = "Team change immunity access flag");
	bind_pcvar_string(pCvar, g_szCvarChangeTeamImmunityFlag, charsmax(g_szCvarChangeTeamImmunityFlag));

	pCvar = create_cvar("hns_afk_control", "1", .description = "Enable AFK spectator commands", .has_min = true, .min_val = 0.0, .has_max = true, .max_val = 1.0);
	bind_pcvar_num(pCvar, g_iCvarAfkControl);
	pCvar = create_cvar("hns_afk_timer_revive", "1", .description = "Respawn players returning during countdown", .has_min = true, .min_val = 0.0, .has_max = true, .max_val = 1.0);
	bind_pcvar_num(pCvar, g_iCvarAfkTimerRevive);
	pCvar = create_cvar("hns_tr_fake_knife_mode", "1", .description = "Hider fake knife mode", .has_min = true, .min_val = 0.0, .has_max = true, .max_val = 2.0);
	bind_pcvar_num(pCvar, g_iCvarTrFakeKnifeMode);

	// EVENTS
	register_event_ex("HLTV", "fnRoundBeforeFreezeTime", RegisterEvent_Global, "1=0", "2=0");
	register_logevent("fnRoundAfterFreezeTime", 2, "0=World triggered", "1=Round_Start");
	register_logevent("fnRoundEnd", 2, "0=World triggered", "1=Round_Draw", "1=Round_End");

	register_event_ex("DeathMsg", "fnDeath", RegisterEvent_Global);

	register_event_ex("CurWeapon", "fnTakeKnife", RegisterEvent_Single | RegisterEvent_OnlyAlive, "1=1", "2=29");

	RegisterHam(Ham_Spawn, "player", "fnPlayerSpawnAfter", 1);
	RegisterHam(Ham_TakeDamage, "player", "fnTakeDamagePre");
	RegisterHam(Ham_TakeDamage, "player", "fnTakeDamagePost", 1);

	// MESSAGES
	register_message(get_user_msgid("SendAudio"), "msgBlockWINSendAudio");
	register_message(get_user_msgid("TextMsg"), "msgBlockWINSendText");

	register_message(get_user_msgid("StatusIcon"), "msgStatusIcon");

	g_iScreenFadeMessageId = get_user_msgid("ScreenFade");
	register_message(g_iScreenFadeMessageId, "msgScreenFade");

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
	fnResetFallDamageState(id);
	g_bConnected[id] = true;
	g_aCountdownSound[id] = true;
	g_aIsAfkTeam[id] = CS_TEAM_UNASSIGNED;
}

public client_disconnected(id, bool:drop, message[], maxlen) {
	fnRemovePlayerTasks(id);
	fnResetFallDamageState(id);

	g_bConnected[id] = false;
	g_aCountdownSound[id] = false;
	g_aIsAfkTeam[id] = CS_TEAM_UNASSIGNED;
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

public fwdThink(ent) {
	if(ent == g_TimerEntity) {
		if(!g_bStart) {
			fnStopCountdown();
			return FMRES_IGNORED;
		}

		fnTimer(ent);
		return FMRES_IGNORED;
	}

	if(ent <= 0 || ent >= sizeof g_bFlashbangEntity || !g_bFlashbangEntity[ent])
		return FMRES_IGNORED;

	if(fnIsFlashbangDetonating(ent))
		fnPrepareFlashbang(ent);

	return FMRES_IGNORED;
}
public plugin_precache() {
	new pCvar = create_cvar("hns_remove_breakables", "1", .description = "Remove breakable entities", .has_min = true, .min_val = 0.0, .has_max = true, .max_val = 1.0);
	bind_pcvar_num(pCvar, g_iCvarRemoveBreakables);
	pCvar = create_cvar("hns_remove_doors", "1", .description = "Remove door entities", .has_min = true, .min_val = 0.0, .has_max = true, .max_val = 1.0);
	bind_pcvar_num(pCvar, g_iCvarRemoveDoors);
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
