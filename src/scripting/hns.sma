// Добавить какой-то знак, что флешка просрала
// Anti Frag
// Стандартные модельки
// Кастомные звуки на победу
// Сообщения о командах в чате
// проверить g_bAlive когда /afk пишет
// Проверить g_aCountdownSound что играет и g_aIsAfkTeam
// Проверить антифлеш кт во время отсчёта

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <fun>
#include <cstrike>
#include <dhudmessage>

#define PLUGIN "Hide N Seek: Ultimate"
#define VERSION "1.0"
#define AUTHOR "foxmits"

#define CHAT_PREFIX "^4[^1HNS by foxmits^4]^1"

#define AUTOHEAL_TASKID 2604171756
#define REVIVE_TASKID 2604172001

new bool:g_bStart = false;

new bool:g_bAlive[33];
new bool:g_bConnected[33];

new g_SyncHud;

new g_iFlasher;
new g_iFlasherTeam;

new bool:g_aCountdownSound[33] = true;
new g_aIsAfkTeam[33] = 0;

new g_iTimer = 0;

new g_RegisterSpawn;
new const g_DefaultEntities[][] = {
	"func_vip_safetyzone",
	"func_escapezone",
	"hostage_entity",
	"monster_scientist",
	"func_bomb_target",
	"info_bomb_target",
	"armoury_entity"
};

new g_TimerEntity;

enum _:g_eCVARS {
	CVAR_TIMER,
	CVAR_TIMER_IMMORTAL,
	CVAR_TIMER_IMMORTAL_DELAY,

	CVAR_TIMER_ANTIFLASH_CT,

	CVAR_CD_SOUND,

	CVAR_CT_TIMER_FADE_SCREEN,
	CVAR_CT_TIMER_FADE_SCREEN_R,
	CVAR_CT_TIMER_FADE_SCREEN_G,
	CVAR_CT_TIMER_FADE_SCREEN_B,
	CVAR_CT_TIMER_FADE_SCREEN_ALPHA,

	CVAR_REMOVE_BREAKABLES,
	CVAR_REMOVE_DOORS,

	CVAR_HEGRENADE_MODE,

	CVAR_FLASHBANG_MODE,
	CVAR_FLASHBANG_COUNT,

	CVAR_FLASHBANG_FAILURE_CHANCE,

	CVAR_SMOKEGRENADE_MODE,

	CVAR_FLASH_FLASHER,
	CVAR_FLASH_TEAMMATE,

	CVAR_AUTOHEAL,
	CVAR_AUTOHEAL_MODE,
	CVAR_AUTOHEAL_MAX_HP,
	CVAR_AUTOHEAL_DELAY,

	CVAR_FALLDOWN_SHOW_DMG,
	CVAR_FALLDOWN_PLAY_SOUND,

	CVAR_FALLDOWN_FADESCREEN,
	CVAR_FALLDOWN_FADESCREEN_R,
	CVAR_FALLDOWN_FADESCREEN_G,
	CVAR_FALLDOWN_FADESCREEN_B,
	CVAR_FALLDOWN_FADESCREEN_ALPHA,

	CVAR_AUTOJOIN,
	CVAR_AUTOJOIN_IMMUNITY,
	CVAR_AUTOJOIN_IMMUNITY_FLAG,

	CVAR_CHANGE_TEAM,
	CVAR_CHANGE_TEAM_IMMUNITY,
	CVAR_CHANGE_TEAM_IMMUNITY_FLAG,

	CVAR_AFK_CONTROL,
	CVAR_AFK_CONTROL_TIMER_REVIVE,

	CVAR_TR_FAKE_KNIFE_MODE
};

new g_aCvar[g_eCVARS];

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);

	// CVARS
	g_aCvar[CVAR_TIMER] = register_cvar("hns_timer", "10");
	g_aCvar[CVAR_TIMER_IMMORTAL] = register_cvar("hns_timer_immortal", "1");
	g_aCvar[CVAR_TIMER_IMMORTAL_DELAY] = register_cvar("hns_timer_immortal_delay", "3.0");

	g_aCvar[CVAR_TIMER_ANTIFLASH_CT] = register_cvar("hns_timer_antiflash_ct", "1");

	g_aCvar[CVAR_CD_SOUND] = register_cvar("hns_cd_sound", "1");

	g_aCvar[CVAR_CT_TIMER_FADE_SCREEN] = register_cvar("hns_ct_timer_fade_screen", "1");
	g_aCvar[CVAR_CT_TIMER_FADE_SCREEN_R] = register_cvar("hns_ct_timer_fade_screen_r", "0");
	g_aCvar[CVAR_CT_TIMER_FADE_SCREEN_G] = register_cvar("hns_ct_timer_fade_screen_g", "0");
	g_aCvar[CVAR_CT_TIMER_FADE_SCREEN_B] = register_cvar("hns_ct_timer_fade_screen_b", "0");
	g_aCvar[CVAR_CT_TIMER_FADE_SCREEN_ALPHA] = register_cvar("hns_ct_timer_fade_screen_alpha", "150");

	g_aCvar[CVAR_HEGRENADE_MODE] = register_cvar("hns_hegrenade_mode", "0");

	g_aCvar[CVAR_FLASHBANG_MODE] = register_cvar("hns_flashbang_mode", "1");
	g_aCvar[CVAR_FLASHBANG_COUNT] = register_cvar("hns_flashbang_count", "2");

	g_aCvar[CVAR_FLASHBANG_FAILURE_CHANCE] = register_cvar("hns_flashbang_failure_chance", "0");

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
	register_message(get_user_msgid("SendAudio"), "msgSendAudio");

	register_message(get_user_msgid("ShowMenu"), "msgShowMenu");
	register_message(get_user_msgid("VGUIMenu"), "msgVguiMenu");

	g_TimerEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));

	// FORWARDS
	register_forward(FM_Think, "fwdThink");
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

public client_connect(id) {
	g_bConnected[id] = true;
	g_aIsAfkTeam[id] = 0;
}

public client_disconnect(id) {
	g_bConnected[id] = false;
	g_bAlive[id] = false;
	g_aIsAfkTeam[id] = 0;
}

public fnSayAfk(id) {
	if(get_pcvar_num(g_aCvar[CVAR_AFK_CONTROL]) == 0) {
		ChatColor(id, "%s Функция ^3отключена на сервере!", CHAT_PREFIX);
		return PLUGIN_HANDLED;
	}

	new iUserTeam = get_user_team(id);

	if(iUserTeam == 3) {
		ChatColor(id, "%s Вы уже находитесь в наблюдателях!", CHAT_PREFIX);
		ChatColor(id, "%s Чтобы ^4вернуться в игру^1, напишите ^4/play ^1или ^4/back ^1в чате.", CHAT_PREFIX);
		return PLUGIN_HANDLED;
	}

	if(g_bAlive[id])
		fnUserSilentKill(id);

	cs_set_user_team(id, 3);

	ChatColor(id, "%s Вы успешно ^3перемещены в наблюдатели^1!", CHAT_PREFIX);
	ChatColor(id, "%s Чтобы ^4вернуться в игру^1, напишите ^4/play ^1или ^4/back ^1в чате.", CHAT_PREFIX);

	g_aIsAfkTeam[id] = iUserTeam;

	return PLUGIN_HANDLED;
}

public fnSayPlay(id) {
	if(get_pcvar_num(g_aCvar[CVAR_AFK_CONTROL]) == 0) {
		ChatColor(id, "%s Функция ^3отключена на сервере!", CHAT_PREFIX);
		return PLUGIN_HANDLED;
	}

	// code ...
	cs_set_user_team(id, g_aIsAfkTeam[id]);

	if(get_pcvar_num(g_aCvar[CVAR_AFK_CONTROL_TIMER_REVIVE]) == 1 && g_iTimer)
		set_task(0.2, "fnAfkControlRevive", id);

	ChatColor(id, "%s Вы успешно ^4вернулись в игру^1!", CHAT_PREFIX);

	g_aIsAfkTeam[id] = 0;

	return PLUGIN_HANDLED;
}

public fnAfkControlRevive(id)
	ExecuteHamB(Ham_CS_RoundRespawn, id);

public fnToggleCountdownSound(id) {
	if(get_pcvar_num(g_aCvar[CVAR_CD_SOUND]) == 0) {
		ChatColor(id, "%s Звук отсчёта до начала раунда ^3отключен ^1на сервере!", CHAT_PREFIX);
		return PLUGIN_HANDLED;
	}

	if(g_aCountdownSound[id])
		ChatColor(id, "%s Вы ^3выключили ^1звук отсчёта до начала раунда!", CHAT_PREFIX);
	else
		ChatColor(id, "%s Вы ^4включили ^1звук отсчёта до начала раунда!", CHAT_PREFIX);

	g_aCountdownSound[id] = !g_aCountdownSound[id];

	return PLUGIN_HANDLED;
}

public fnDeath() {
	// new iKiller = read_data(1);
	new iVictim = read_data(2);

	g_bAlive[iVictim] = false;

	if(
		get_pcvar_num(g_aCvar[CVAR_TIMER_IMMORTAL]) == 1 &&
		g_iTimer
	) {
		new Float:fReviveDelay;
		fReviveDelay = get_pcvar_float(g_aCvar[CVAR_TIMER_IMMORTAL_DELAY]);

		new iReviveTaskID = REVIVE_TASKID + iVictim;

		if(task_exists(iReviveTaskID))
			remove_task(iReviveTaskID);

		set_task(fReviveDelay, "fnRevive", iReviveTaskID);
	}
}

public fnRevive(iTaskID) {
	new iUserID = iTaskID - REVIVE_TASKID;
	new iUserTeam = get_user_team(iUserID);

	if(
		!g_bAlive[iUserID] &&
		(iUserTeam == 1 || iUserTeam == 2)
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
		!task_exists(id) &&
		(get_pcvar_num(g_aCvar[CVAR_AUTOJOIN_IMMUNITY]) == 0 || !(get_user_flags(id) & iImmunityFlag))
	);
}

fnForceTeamJoinTask(id, menu_msgid) {
	static param_menu_msgid[2];
	param_menu_msgid[0] = menu_msgid;
	set_task(0.1, "fnForceTeamJoin", id, param_menu_msgid, sizeof param_menu_msgid);
}

public fnForceTeamJoin(menu_msgid[], id) {
	if(get_user_team(id))
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
	new aPlayers[32], iPlayersCount, i;
	get_players(aPlayers, iPlayersCount, "ch");

	for(i = 0; i < iPlayersCount; i++) {
		if(task_exists(AUTOHEAL_TASKID + i))
			remove_task(AUTOHEAL_TASKID + i);

		if(task_exists(REVIVE_TASKID + i))
			remove_task(REVIVE_TASKID + i);
	}

	if(!g_bStart)
		return 0;

	switch(fnTRAlive()) {
		// Terrorist(s) alive, e.g hiders win
		case true: {
			ClearDHUDMessages(0);
			set_dhudmessage(255, 0, 0, -1.0, -0.65, 0, 0.0, 5.0, 0.1, 1.0);
			show_dhudmessage(0, "Прячущиеся победили!");
		}

		// No terrorist(s) alive, e.g seekers win
		case false: {
			set_task(0.1, "fnSwapTeams");

			ClearDHUDMessages(0);
			set_dhudmessage(0, 0, 255, -1.0, -0.65, 0, 0.0, 5.0, 0.1, 1.0);
			show_dhudmessage(0, "Ищущие победили!");
		}
	}

	g_bStart = false;
	return 0;
}

public fnSwapTeams() {
	new aPlayers[32], iPlayersCount, i;
	get_players(aPlayers, iPlayersCount, "ch");

	for(i = 0; i < iPlayersCount; i++) {
		if(!g_bConnected[aPlayers[i]])
			continue;

		new iUserTeam = get_user_team(aPlayers[i]);

		switch(iUserTeam) {
			case 1: {
				if(g_aIsAfkTeam[aPlayers[i]] != 0)
					g_aIsAfkTeam[aPlayers[i]] = 2;

				cs_set_user_team(aPlayers[i], 2);
			}
			case 2: {
				if(g_aIsAfkTeam[aPlayers[i]] != 0)
					g_aIsAfkTeam[aPlayers[i]] = 1;

				cs_set_user_team(aPlayers[i], 1);
			}
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

	fnGetPlayers(iTR, iCT);

	if(iTR && iCT)
		g_bStart = true;

	g_iFlasher = g_iFlasherTeam = 0;
}

public fnRoundAfterFreezeTime() {
	if(g_bStart) {
		g_iTimer = get_pcvar_num(g_aCvar[CVAR_TIMER]);
		set_pev(g_TimerEntity, pev_nextthink, get_gametime());
	}
}

public fwdThink(ent)
	if(ent == g_TimerEntity)
		fnTimer(ent);

public fnTimer(ent) {
	new aPlayers[32], iPlayersCount, i;
	get_players(aPlayers, iPlayersCount, "ch");

	if(g_iTimer) {
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
				show_dhudmessage(aPlayers[i], "Игра начнётся через %s", WordForm(g_iTimer, "секунду", "секунды", "секунд"));
			}
		}

		g_iTimer--;
		set_pev(ent, pev_nextthink, get_gametime() + 1.0);
	} else {
		for(i = 0; i < iPlayersCount; i++) {
			ClearDHUDMessages(aPlayers[i]);
			set_dhudmessage(random_num(0, 255), random_num(0, 255), random_num(0, 255), -1.0, -0.65, 0, 0.0, 5.0, 0.1, 1.0);
			show_dhudmessage(aPlayers[i], "Понеслась!!!");

			if(get_user_team(aPlayers[i]) == 2) {
				set_pev(aPlayers[i], pev_flags, pev(aPlayers[i], pev_flags) & ~FL_FROZEN);
				fnMakeScreenFade(aPlayers[i], 0, 0, 0, 255, 0);
			}
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
			ShowSyncHudMsg(iVictim, g_SyncHud, "Урон: %d", iDamage);
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
				new iAutohealTaskId = AUTOHEAL_TASKID + iVictim;
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
	new iUserId = iTaskId - AUTOHEAL_TASKID;

	if(g_bAlive[iUserId]) {
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
		g_bAlive[id] = true;

		set_task(0.1, "taskGiveWeapons", id);
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
	if(!g_bAlive[id])
		return 1;

	static weapon;
	weapon = get_user_weapon(id);

	if(weapon != CSW_KNIFE)
		return 1;

	static button;
	button = get_uc(handle, UC_Buttons);

	new iCvarFakeMode = get_pcvar_num(g_aCvar[CVAR_TR_FAKE_KNIFE_MODE]);

	switch(get_user_team(id)) {
		case 1: {
			if(iCvarFakeMode == 1 || iCvarFakeMode == 2) {
				if(button & IN_ATTACK)
					button &= ~IN_ATTACK; // Block

				if(button & IN_ATTACK2)
					button &= ~IN_ATTACK2; // Block

				set_uc(handle, UC_Buttons, button);
				return 4;
			}
		}
	}

	return 1;
}

public taskGiveWeapons(id) {
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

fnMakeScreenFade(id, r = 0, g = 0, b = 0, alpha = 100, fade = 0) {
	message_begin(MSG_ONE, get_user_msgid("ScreenFade"), _, id);
	write_short(2048 * fade); // 2048 = 0.5 сек.
	write_short(2048 * fade);
	write_short(0x0000);
	write_byte(r);
	write_byte(g);
	write_byte(b);
	write_byte(alpha);
	message_end();
}

public plugin_precache() {
	g_aCvar[CVAR_REMOVE_BREAKABLES] = register_cvar("hns_remove_breakables", "1");
	g_aCvar[CVAR_REMOVE_DOORS] = register_cvar("hns_remove_doors", "1");

	g_RegisterSpawn = register_forward(FM_Spawn, "fwdEntitySpawn");

	for(new i = 1; i <= 10; i++) {
		new szPrecacheCountdown[32];
		formatex(szPrecacheCountdown, 31, "hns/countdown/%d.wav", i);

		precache_sound(szPrecacheCountdown);
	}

	precache_sound("hns/falldown/1.wav");
}

public fwdEntitySpawn(ent) {
	if(!pev_valid(ent))
		return 1;

	new szClass[33];

	pev(ent, pev_classname, szClass, 32);

	for(new i; i < sizeof g_DefaultEntities; i++) {
		if(equal(szClass, g_DefaultEntities[i])) {
			engfunc(EngFunc_RemoveEntity, ent);
			return 4;
		}
	}

	if(get_pcvar_num(g_aCvar[CVAR_REMOVE_DOORS])) {
		if(equal(szClass, "func_door") || equal(szClass, "func_door_rotating")) {
			engfunc(EngFunc_RemoveEntity, ent);
			return 4;
		}
	}

	if(get_pcvar_num(g_aCvar[CVAR_REMOVE_BREAKABLES]) && equal(szClass, "func_breakable")) {
		engfunc(EngFunc_RemoveEntity, ent);
		return 4;
	}

	return 1;
}

public msgStatusIcon(msgid, msgdest, id) {
	static szMsg[8];
	get_msg_arg_string(2, szMsg, 7);

	if(equal(szMsg, "buyzone") && get_msg_arg_int(1)) {
		set_pdata_int(id, 235, get_pdata_int(id, 235) & ~(1<<0));
		return 1;
	}

	return 0;
}

public msgScreenFade(msgId, msgDest, msgEnt) {
	if(!g_iFlasherTeam || !g_bAlive[msgEnt])
		return PLUGIN_CONTINUE;

	if(g_iTimer && get_pcvar_num(g_aCvar[CVAR_TIMER_ANTIFLASH_CT]) == 1 && get_user_team(msgEnt) == 2)
		return PLUGIN_HANDLED;

	if(g_iFlasher == msgEnt && get_pcvar_num(g_aCvar[CVAR_FLASH_FLASHER]) == 0)
		return PLUGIN_HANDLED;

	if(g_iFlasherTeam == get_user_team(msgEnt) && get_pcvar_num(g_aCvar[CVAR_FLASH_TEAMMATE]) == 0)
		return PLUGIN_HANDLED;

	new iFlashBangFailureChance = get_pcvar_num(g_aCvar[CVAR_FLASHBANG_FAILURE_CHANCE]);

	if(iFlashBangFailureChance > 0) {
		if(random_num(1, 100) <= iFlashBangFailureChance) {
			return PLUGIN_HANDLED;
		}
	}

	return PLUGIN_CONTINUE;
}

public msgSendAudio(msgId, msgDest, msgEnt) {
	static id, text[19];
	get_msg_arg_string(2, text, charsmax(text));

	if(text[7] == 'F' && text[11] == 'I' && text[13] == 'H') {
		g_iFlasher = (id = get_msg_arg_int(1));
		g_iFlasherTeam = get_user_team(id);
	}
}

public fnChooseTeam(id) {
	if(get_user_team(id) == 3) {
		if(!g_aIsAfkTeam[id])
			return 0;
		else {
			ChatColor(id, "%s Чтобы ^4вернуться в игру^1, напишите ^4/play ^1или ^4/back ^1в чате!", CHAT_PREFIX);
			return 1;
		}
	}

	if(get_pcvar_num(g_aCvar[CVAR_CHANGE_TEAM]) == 1) {
		if(get_pcvar_num(g_aCvar[CVAR_CHANGE_TEAM_IMMUNITY]) == 1) {
			new szImmunityFlag[2];
			get_pcvar_string(g_aCvar[CVAR_CHANGE_TEAM_IMMUNITY_FLAG], szImmunityFlag, 1);
			new iImmunityFlag = read_flags(szImmunityFlag);

			if(get_user_flags(id) & iImmunityFlag)
				return 0;
		}
	}

	return 1;
}

public fnJoinTeam(id) {
	if(get_user_team(id) == 3) {
		if(!g_aIsAfkTeam[id])
			return 0;
		else {
			ChatColor(id, "%s Чтобы ^4вернуться в игру^1, напишите ^4/play ^1или ^4/back ^1в чате!", CHAT_PREFIX);
			return 1;
		}
	}

	if(get_pcvar_num(g_aCvar[CVAR_CHANGE_TEAM]) == 1) {
		if(get_pcvar_num(g_aCvar[CVAR_CHANGE_TEAM_IMMUNITY]) == 1) {
			new szImmunityFlag[2];
			get_pcvar_string(g_aCvar[CVAR_CHANGE_TEAM_IMMUNITY_FLAG], szImmunityFlag, 1);
			new iImmunityFlag = read_flags(szImmunityFlag);

			if(get_user_flags(id) & iImmunityFlag)
				return 0;
		}
	}

	return 1;
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
		if(g_bAlive[aPlayers[i]] && get_user_team(aPlayers[i]) == 1)
			return true;

	return false;
}

stock ChatColor(const id, const szMessage[], any:...) {
    static pnum, players[32], szMsg[190], IdMsg;
    vformat(szMsg, charsmax(szMsg), szMessage, 3);

    if(!IdMsg)
        IdMsg = get_user_msgid("SayText");

    if(id) {
        players[0] = id;
        pnum = 1;
    }
    else
        get_players(players, pnum, "ch");

    for(new i; i < pnum; i++) {
        message_begin(MSG_ONE, IdMsg, .player = players[i]);
        write_byte(players[i]);
        write_string(szMsg);
        message_end();
    }
}

stock WordForm(iNum, szForm1[], szForm2[], szForm3[]) {
    new szResult[128];

    iNum = abs(iNum) % 100;
    new iNum_x = iNum % 10;

    if(iNum > 10 && iNum < 20)
        formatex(szResult, 127, "%d %s", iNum, szForm3);
    else if(iNum_x > 1 && iNum_x < 5)
        formatex(szResult, 127, "%d %s", iNum, szForm2);
    else if(iNum_x == 1)
        formatex(szResult, 127, "%d %s", iNum, szForm1);
    else
        formatex(szResult, 127, "%d %s", iNum, szForm3);

    return szResult;
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

stock ClearDHUDMessages(id, iClear = 8)
	for(new iDHUD = 0; iDHUD < iClear; iDHUD++)
		show_dhudmessage(id, "");
