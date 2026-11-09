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

new const FLASHBANG_MODEL[] = "models/w_flashbang.mdl";
new g_szHidersWinSound[MAX_SOUND_PATH_LENGTH + 1] = "radio/terwin.wav";
new g_szSeekersWinSound[MAX_SOUND_PATH_LENGTH + 1] = "radio/ctwin.wav";

new bool:g_bStart = false;
new bool:g_bCountdownActive = false;

new g_iFlasher;
new g_iFlasherTeam;
new bool:g_bFlashFailed;
new bool:g_bFlashbangEntity[MAX_TRACKED_ENTITIES];

new g_iTimer = 0;

new g_TimerEntity;

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

public fnSayAfk(id) {
	if(get_pcvar_num(g_aCvar[CVAR_AFK_CONTROL]) == 0) {
		ChatColorKey(id, "HNS_FEATURE_DISABLED");
		return PLUGIN_HANDLED;
	}

	new iUserTeam = get_user_team(id);

	if(iUserTeam == 3) {
		ChatColorKey(id, "HNS_ALREADY_SPECTATOR");
		ChatColorKey(id, "HNS_RETURN_TO_GAME_HINT");
		return PLUGIN_HANDLED;
	}

	if(is_user_alive(id))
		fnUserSilentKill(id);

	cs_set_user_team(id, 3);

	ChatColorKey(id, "HNS_MOVED_TO_SPECTATOR");
	ChatColorKey(id, "HNS_RETURN_TO_GAME_HINT");

	g_aIsAfkTeam[id] = iUserTeam;

	return PLUGIN_HANDLED;
}

public fnSayPlay(id) {
	if(get_pcvar_num(g_aCvar[CVAR_AFK_CONTROL]) == 0) {
		ChatColorKey(id, "HNS_FEATURE_DISABLED");
		return PLUGIN_HANDLED;
	}

	if(get_user_team(id) != 3 || !fnIsPlayableTeam(g_aIsAfkTeam[id])) {
		ChatColorKey(id, "HNS_CANNOT_RETURN_TO_GAME");
		return PLUGIN_HANDLED;
	}

	cs_set_user_team(id, g_aIsAfkTeam[id]);

	if(get_pcvar_num(g_aCvar[CVAR_AFK_CONTROL_TIMER_REVIVE]) == 1 && g_iTimer) {
		remove_task(TASK_AFK_REVIVE + id);
		set_task(0.2, "fnAfkControlRevive", TASK_AFK_REVIVE + id);
	}

	ChatColorKey(id, "HNS_RETURNED_TO_GAME");

	g_aIsAfkTeam[id] = 0;

	return PLUGIN_HANDLED;
}

bool:fnIsPlayableTeam(iTeam) {
	return iTeam == 1 || iTeam == 2;
}

public fnAfkControlRevive(iTaskID) {
	new id = iTaskID - TASK_AFK_REVIVE;

	if(
		g_bConnected[id] &&
		g_bStart &&
		g_iTimer > 0 &&
		!is_user_alive(id) &&
		fnIsPlayableTeam(get_user_team(id))
	)
		ExecuteHamB(Ham_CS_RoundRespawn, id);
}

public fnToggleCountdownSound(id) {
	if(get_pcvar_num(g_aCvar[CVAR_CD_SOUND]) == 0) {
		ChatColorKey(id, "HNS_COUNTDOWN_SOUND_SERVER_DISABLED");
		return PLUGIN_HANDLED;
	}

	if(g_aCountdownSound[id])
		ChatColorKey(id, "HNS_COUNTDOWN_SOUND_DISABLED");
	else
		ChatColorKey(id, "HNS_COUNTDOWN_SOUND_ENABLED");

	g_aCountdownSound[id] = !g_aCountdownSound[id];

	return PLUGIN_HANDLED;
}

public fnDeath() {
	// new iKiller = read_data(1);
	new iVictim = read_data(2);

	if(
		get_pcvar_num(g_aCvar[CVAR_TIMER_IMMORTAL]) == 1 &&
		g_bStart &&
		g_iTimer > 0
	) {
		new Float:fReviveDelay;
		fReviveDelay = get_pcvar_float(g_aCvar[CVAR_TIMER_IMMORTAL_DELAY]);

		new iReviveTaskID = TASK_REVIVE + iVictim;

		if(task_exists(iReviveTaskID))
			remove_task(iReviveTaskID);

		set_task(fReviveDelay, "fnRevive", iReviveTaskID);
	}
}

public fnRevive(iTaskID) {
	new iUserID = iTaskID - TASK_REVIVE;
	new iUserTeam = get_user_team(iUserID);

	if(
		g_bConnected[iUserID] &&
		g_bStart &&
		g_iTimer > 0 &&
		!is_user_alive(iUserID) &&
		fnIsPlayableTeam(iUserTeam)
	) {
		ExecuteHamB(Ham_CS_RoundRespawn, iUserID);
	}
}

public msgBlockWINSendText(msg_id, msg_dest, msg_entity) {
	static message[3];
	get_msg_arg_string(2, message, sizeof message - 1);

	switch(message[1]) {
		// -- #CTs_Win ; #Terrorists_Win ; #Round_Draw
		case 'C', 'T':
			return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}


public msgBlockWINSendAudio(msg_id, msg_dest, msg_entity) {
	static message[10];
	get_msg_arg_string(2, message, sizeof message - 1);

	switch(message[7]) {
		// -- %!MRAD_terwin ; %!MRAD_ctwin ; %!MRAD_rounddraw
		case 'c', 't':
			return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

// AUTOJOIN

public msgShowMenu(msgid, dest, id) {
	if(!fnBeAutojoin(id))
		return PLUGIN_CONTINUE;

	static team_select[] = "#Team_Select";
	static menu_text_code[sizeof team_select];
	get_msg_arg_string(4, menu_text_code, sizeof menu_text_code - 1);

	if(!equal(menu_text_code, team_select))
		return PLUGIN_CONTINUE;

	fnForceTeamJoinTask(id, msgid);

	return PLUGIN_HANDLED;
}

public msgVguiMenu(msgid, dest, id) {
	if(get_msg_arg_int(1) != 2 || !fnBeAutojoin(id))
		return PLUGIN_CONTINUE;

	fnForceTeamJoinTask(id, msgid);

	return PLUGIN_HANDLED;
}

bool:fnBeAutojoin(id) {
	new szImmunityFlag[2];
	get_pcvar_string(g_aCvar[CVAR_AUTOJOIN_IMMUNITY_FLAG], szImmunityFlag, 1);

	new iImmunityFlag = read_flags(szImmunityFlag);

	return (
		get_pcvar_num(g_aCvar[CVAR_AUTOJOIN]) == 1 &&
		!get_user_team(id) &&
		!task_exists(TASK_FORCE_JOIN + id) &&
		(get_pcvar_num(g_aCvar[CVAR_AUTOJOIN_IMMUNITY]) == 0 || !(get_user_flags(id) & iImmunityFlag))
	);
}

fnForceTeamJoinTask(id, menu_msgid) {
	static param_menu_msgid[2];
	param_menu_msgid[0] = menu_msgid;
	remove_task(TASK_FORCE_JOIN + id);
	set_task(0.1, "fnForceTeamJoin", TASK_FORCE_JOIN + id, param_menu_msgid, sizeof param_menu_msgid);
}

public fnForceTeamJoin(menu_msgid[], iTaskID) {
	new id = iTaskID - TASK_FORCE_JOIN;

	if(!g_bConnected[id] || get_user_team(id))
		return;

	fnJinTeam(id, menu_msgid[0], "5", "5");
}

stock fnJinTeam(id, menu_msgid, /* const */ team[] = "5", /* const */ class[] = "0") {
	static jointeam[] = "jointeam";

	if(class[0] == '0') {
		engclient_cmd(id, jointeam, team);
		return;
	}

	static msg_block, joinclass[] = "joinclass";
	msg_block = get_msg_block(menu_msgid);
	set_msg_block(menu_msgid, BLOCK_SET);
	engclient_cmd(id, jointeam, team);
	engclient_cmd(id, joinclass, class);
	set_msg_block(menu_msgid, msg_block);
}

// END OF AUTOJOIN

// END OF ROUND

public fnRoundEnd() {
	fnStopCountdown();

	for(new i = 1; i <= 32; i++)
		fnRemoveRoundTasks(i);

	if(!g_bStart)
		return 0;

	switch(fnTRAlive()) {
		// Terrorist(s) alive, e.g hiders win
		case true: {
			fnPlayWinSound(1);
			fnShowRoundWinMessage("HNS_HIDERS_WIN", 255, 0, 0);
		}

		// No terrorist(s) alive, e.g seekers win
		case false: {
			set_task(0.1, "fnSwapTeams");
			fnPlayWinSound(2);
			fnShowRoundWinMessage("HNS_SEEKERS_WIN", 0, 0, 255);
		}
	}

	g_bStart = false;
	return 0;
}

fnShowRoundWinMessage(const szKey[], iRed, iGreen, iBlue) {
	new aPlayers[32], iPlayersCount;
	get_players(aPlayers, iPlayersCount, "ch");

	for(new i = 0; i < iPlayersCount; i++) {
		ClearDHUDMessages(aPlayers[i]);
		set_dhudmessage(iRed, iGreen, iBlue, -1.0, -0.65, 0, 0.0, 5.0, 0.1, 1.0);
		show_dhudmessage(aPlayers[i], "%L", aPlayers[i], szKey);
	}
}

fnPlayWinSound(iWinner) {
	new iSoundMode = clamp(get_pcvar_num(g_aCvar[CVAR_WIN_SOUND_MODE]), 0, 3);

	if(iSoundMode != 3 && iSoundMode != iWinner)
		return;

	new szSound[MAX_SOUND_PATH_LENGTH + 1];

	switch(iWinner) {
		case 1: copy(szSound, charsmax(szSound), g_szHidersWinSound);
		case 2: copy(szSound, charsmax(szSound), g_szSeekersWinSound);
	}

	if(szSound[0])
		client_cmd(0, "spk %s", szSound);
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

public fnSwapTeams() {
	new aPlayers[32], iPlayersCount, i;
	get_players(aPlayers, iPlayersCount, "ch");

	for(i = 0; i < iPlayersCount; i++) {
		if(!g_bConnected[aPlayers[i]])
			continue;

		new iUserTeam = get_user_team(aPlayers[i]);

		switch(g_aIsAfkTeam[aPlayers[i]]) {
			case 1: g_aIsAfkTeam[aPlayers[i]] = 2;
			case 2: g_aIsAfkTeam[aPlayers[i]] = 1;
		}

		switch(iUserTeam) {
			case 1: cs_set_user_team(aPlayers[i], 2);
			case 2: cs_set_user_team(aPlayers[i], 1);
		}
	}
}

// END OF END OF ROUND

public fnTakeKnife(id) {
	if(get_pcvar_num(g_aCvar[CVAR_TR_FAKE_KNIFE_MODE]) == 2 && get_user_team(id) == 1) {
		set_pev(id, pev_viewmodel2, "");
		set_pev(id, pev_weaponmodel2, "");
	}
}

public fnRoundBeforeFreezeTime() {
	new iTR, iCT;

	fnStopCountdown();
	fnGetPlayers(iTR, iCT);

	g_bStart = iTR > 0 && iCT > 0;

	g_iFlasher = g_iFlasherTeam = 0;
	g_bFlashFailed = false;
}

public fnRoundAfterFreezeTime() {
	if(g_bStart) {
		g_iTimer = clamp(get_pcvar_num(g_aCvar[CVAR_TIMER]), 1, 10);
		g_bCountdownActive = true;
		set_pev(g_TimerEntity, pev_nextthink, get_gametime());
	}
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

public fnTimer(ent) {
	new aPlayers[32], iPlayersCount, i;
	get_players(aPlayers, iPlayersCount, "ch");

	if(g_iTimer > 0) {
		for(i = 0; i < iPlayersCount; i++) {
			if(g_bConnected[aPlayers[i]] && !is_user_bot(aPlayers[i]) && !is_user_hltv(aPlayers[i])) {
				if(get_user_team(aPlayers[i]) == 2) {
					set_pev(aPlayers[i], pev_flags, pev(aPlayers[i], pev_flags) | FL_FROZEN);

					if(get_pcvar_num(g_aCvar[CVAR_CT_TIMER_FADE_SCREEN]) == 1) {
						fnMakeScreenFade(
							aPlayers[i],
							get_pcvar_num(g_aCvar[CVAR_CT_TIMER_FADE_SCREEN_R]),
							get_pcvar_num(g_aCvar[CVAR_CT_TIMER_FADE_SCREEN_G]),
							get_pcvar_num(g_aCvar[CVAR_CT_TIMER_FADE_SCREEN_B]),
							get_pcvar_num(g_aCvar[CVAR_CT_TIMER_FADE_SCREEN_ALPHA]),
							2
						);
					}
				}

				if(get_pcvar_num(g_aCvar[CVAR_CD_SOUND]) == 1 && g_aCountdownSound[aPlayers[i]])
					client_cmd(aPlayers[i], "spk hns/countdown/%d.wav", g_iTimer);

				ClearDHUDMessages(aPlayers[i]);
				set_dhudmessage(255, 0, 0, -1.0, -0.65, 0, 0.0, 1.0, 0.1, 1.0);
				show_dhudmessage(aPlayers[i], "%L", aPlayers[i], "HNS_COUNTDOWN", g_iTimer);
			}
		}

		g_iTimer--;
		set_pev(ent, pev_nextthink, get_gametime() + 1.0);
	} else
		fnEndCountdown(true);
}

fnStopCountdown() {
	if(!g_bCountdownActive) {
		set_pev(g_TimerEntity, pev_nextthink, 0.0);
		return;
	}

	fnEndCountdown(false);
}

fnEndCountdown(bool:bShowStartMessage) {
	g_iTimer = 0;
	g_bCountdownActive = false;
	set_pev(g_TimerEntity, pev_nextthink, 0.0);

	new aPlayers[32], iPlayersCount;
	get_players(aPlayers, iPlayersCount, "ch");

	for(new i = 0; i < iPlayersCount; i++) {
		ClearDHUDMessages(aPlayers[i]);

		if(bShowStartMessage) {
			set_dhudmessage(random_num(0, 255), random_num(0, 255), random_num(0, 255), -1.0, -0.65, 0, 0.0, 5.0, 0.1, 1.0);
			show_dhudmessage(aPlayers[i], "%L", aPlayers[i], "HNS_ROUND_START");
		}

		if(get_user_team(aPlayers[i]) == 2) {
			set_pev(aPlayers[i], pev_flags, pev(aPlayers[i], pev_flags) & ~FL_FROZEN);
			fnMakeScreenFade(aPlayers[i], 0, 0, 0, 255, 0);
		}
	}
}

public fnTakeDamage(iVictim, iInflictor, iAttacker, float:fDamage, bitsDamageType) {
	if(!(bitsDamageType & DMG_FALL))
		return HAM_IGNORED;

	new iVictimHealth = get_user_health(iVictim);
	ExecuteHam(Ham_TakeDamage, iVictim, iInflictor, iAttacker, fDamage, bitsDamageType);

	new iDamage = iVictimHealth - get_user_health(iVictim);

	if(iDamage <= iVictimHealth) {
		if(get_pcvar_num(g_aCvar[CVAR_FALLDOWN_PLAY_SOUND]) == 1)
			client_cmd(iVictim, "spk hns/falldown/1.wav");

		if(get_pcvar_num(g_aCvar[CVAR_FALLDOWN_SHOW_DMG]) == 1) {
			set_hudmessage(255, 0, 0, 0.05, 0.9, 0, 0.1, 3.0, 0.01, 0.01, -1);
			ShowSyncHudMsg(iVictim, g_SyncHud, "%L", iVictim, "HNS_FALL_DAMAGE", iDamage);
		}

		if(get_pcvar_num(g_aCvar[CVAR_FALLDOWN_FADESCREEN]) == 1)
			fnMakeScreenFade(
				iVictim,
				get_pcvar_num(g_aCvar[CVAR_FALLDOWN_FADESCREEN_R]),
				get_pcvar_num(g_aCvar[CVAR_FALLDOWN_FADESCREEN_G]),
				get_pcvar_num(g_aCvar[CVAR_FALLDOWN_FADESCREEN_B]),
				get_pcvar_num(g_aCvar[CVAR_FALLDOWN_FADESCREEN_ALPHA]),
				1
			);

		if(get_pcvar_num(g_aCvar[CVAR_AUTOHEAL]) == 1) {
			new iAutohealMode = get_pcvar_num(g_aCvar[CVAR_AUTOHEAL_MODE]);

			if(iAutohealMode == 3 || iAutohealMode == get_user_team(iVictim)) {
				new iAutohealTaskId = TASK_AUTOHEAL + iVictim;
				new Float:fAutoHealDelay;

				fAutoHealDelay = get_pcvar_float(g_aCvar[CVAR_AUTOHEAL_DELAY])

				if(task_exists(iAutohealTaskId))
					remove_task(iAutohealTaskId);

				new aArgs[1];
				aArgs[0] = iDamage;

				set_task(fAutoHealDelay, "fnAutoHeal", iAutohealTaskId, aArgs, 1);
			}
		}
	}

	return HAM_SUPERCEDE;
}

public fnAutoHeal(aArgs[], iTaskId) {
	new iUserId = iTaskId - TASK_AUTOHEAL;

	if(g_bConnected[iUserId] && is_user_alive(iUserId)) {
		new iMaxAutohealHP = get_pcvar_num(g_aCvar[CVAR_AUTOHEAL_MAX_HP]);
		new iDamage = aArgs[0];

		new iCurrentUserHP = get_user_health(iUserId);

		if(iDamage < iMaxAutohealHP)
			set_user_health(iUserId, iCurrentUserHP + iDamage);
		else
			set_user_health(iUserId, iCurrentUserHP + iMaxAutohealHP);
	}
}

public fnPlayerSpawnAfter(id) {
	if(is_user_alive(id)) {
		remove_task(TASK_GIVE_WEAPONS + id);
		set_task(0.1, "taskGiveWeapons", TASK_GIVE_WEAPONS + id);
	}
}

public fwdEmitSound(id, channel, const szSound[]) {
	new iCvarFakeMode = get_pcvar_num(g_aCvar[CVAR_TR_FAKE_KNIFE_MODE]);

	if(
		(iCvarFakeMode == 1 || iCvarFakeMode == 2) &&
		get_user_team(id) == 1 &&
		equal(szSound, "weapons/knife_deploy1.wav")
	)
		return 4;

	return 1;
}
public fwdCmdStart(id, handle) {
	if(!is_user_alive(id))
		return FMRES_IGNORED;

	if(get_user_weapon(id) != CSW_KNIFE)
		return FMRES_IGNORED;

	new iCvarFakeMode = get_pcvar_num(g_aCvar[CVAR_TR_FAKE_KNIFE_MODE]);

	if(get_user_team(id) != 1 || (iCvarFakeMode != 1 && iCvarFakeMode != 2))
		return FMRES_IGNORED;

	new iButtons = get_uc(handle, UC_Buttons);
	new iBlockedButtons = IN_ATTACK | IN_ATTACK2;

	if(!(iButtons & iBlockedButtons))
		return FMRES_IGNORED;

	set_uc(handle, UC_Buttons, iButtons & ~iBlockedButtons);
	return FMRES_HANDLED;
}

public taskGiveWeapons(iTaskID) {
	new id = iTaskID - TASK_GIVE_WEAPONS;

	if(!g_bConnected[id] || !is_user_alive(id))
		return;

	new cvarHegrenadeMode = get_pcvar_num(g_aCvar[CVAR_HEGRENADE_MODE]);

	new cvarFlashbangMode = get_pcvar_num(g_aCvar[CVAR_FLASHBANG_MODE]);
	new cvarFlashbangCount = get_pcvar_num(g_aCvar[CVAR_FLASHBANG_COUNT]);

	if(cvarFlashbangCount > 2) { cvarFlashbangCount = 2; }

	new cvarSmokegrenadeMode = get_pcvar_num(g_aCvar[CVAR_SMOKEGRENADE_MODE]);

	strip_user_weapons(id);

	give_item(id, "weapon_knife");

	new iUserTeam = get_user_team(id);

	if(cvarHegrenadeMode == iUserTeam || cvarHegrenadeMode == 3)
		give_item(id, "weapon_hegrenade");

	if(cvarFlashbangMode == iUserTeam || cvarFlashbangMode == 3)
		for(new i = 1; i <= cvarFlashbangCount; i++)
			give_item(id, "weapon_flashbang");

	if(cvarSmokegrenadeMode == iUserTeam || cvarSmokegrenadeMode == 3)
		give_item(id, "weapon_smokegrenade");
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

fnLoadWinSoundConfig() {
	new szConfigDir[128], szConfigPath[160];
	get_localinfo("amxx_configsdir", szConfigDir, charsmax(szConfigDir));
	formatex(szConfigPath, charsmax(szConfigPath), "%s/hns.cfg", szConfigDir);

	new iFile = fopen(szConfigPath, "rt");

	if(!iFile)
		return;

	new szLine[192], szKey[64], szValue[MAX_SOUND_PATH_LENGTH + 1];

	while(!feof(iFile)) {
		fgets(iFile, szLine, charsmax(szLine));
		trim(szLine);

		if(!szLine[0] || szLine[0] == ';' || (szLine[0] == '/' && szLine[1] == '/'))
			continue;

		szKey[0] = szValue[0] = 0;
		parse(szLine, szKey, charsmax(szKey), szValue, charsmax(szValue));

		if(equal(szKey, "hns_win_sound_hiders"))
			copy(g_szHidersWinSound, charsmax(g_szHidersWinSound), szValue);
		else if(equal(szKey, "hns_win_sound_seekers"))
			copy(g_szSeekersWinSound, charsmax(g_szSeekersWinSound), szValue);
	}

	fclose(iFile);
}

fnPrecacheWinSounds() {
	if(g_szHidersWinSound[0])
		precache_sound(g_szHidersWinSound);

	if(g_szSeekersWinSound[0] && !equal(g_szSeekersWinSound, g_szHidersWinSound))
		precache_sound(g_szSeekersWinSound);
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

public fnChooseTeam(id) {
	return fnHandleTeamChange(id);
}

public fnJoinTeam(id) {
	return fnHandleTeamChange(id);
}

fnHandleTeamChange(id) {
	if(get_user_team(id) == 3) {
		if(!g_aIsAfkTeam[id])
			return PLUGIN_CONTINUE;
		else {
			ChatColorKey(id, "HNS_RETURN_TO_GAME_HINT");
			return PLUGIN_HANDLED;
		}
	}

	if(get_pcvar_num(g_aCvar[CVAR_CHANGE_TEAM]) == 1)
		return PLUGIN_CONTINUE;

	if(get_pcvar_num(g_aCvar[CVAR_CHANGE_TEAM_IMMUNITY]) == 1) {
		new szImmunityFlag[2];
		get_pcvar_string(g_aCvar[CVAR_CHANGE_TEAM_IMMUNITY_FLAG], szImmunityFlag, 1);
		new iImmunityFlag = read_flags(szImmunityFlag);

		if(get_user_flags(id) & iImmunityFlag)
			return PLUGIN_CONTINUE;
	}

	return PLUGIN_HANDLED;
}

public fnGetPlayers(&tr, &ct) {
	new aPlayers[32], iPlayersCount, i;
	get_players(aPlayers, iPlayersCount, "ch");

	for(i = 0; i < iPlayersCount; i++) {
		if(!g_bConnected[aPlayers[i]])
			continue;

		switch(get_user_team(aPlayers[i])) {
			case 1: tr++;
			case 2: ct++;
		}
	}
}

bool:fnTRAlive() {
	new aPlayers[32], iPlayersCount, i;
	get_players(aPlayers, iPlayersCount, "ch");

	for(i = 0; i < iPlayersCount; i++)
		if(is_user_alive(aPlayers[i]) && get_user_team(aPlayers[i]) == 1)
			return true;

	return false;
}

stock fnUserSilentKill(id) {
	static msgid = 0;
	new msgblock;

	if(!msgid)
		msgid = get_user_msgid("DeathMsg");

	msgblock = get_msg_block(msgid);
	set_msg_block(msgid, BLOCK_ONCE);
	user_kill(id, 1);
	set_msg_block(msgid, msgblock);

	return 1;
}
