#if defined _hns_team_flow_included
	#endinput
#endif
#define _hns_team_flow_included

public fnSayAfk(id) {
	if(g_iCvarAfkControl == 0) {
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
	if(g_iCvarAfkControl == 0) {
		ChatColorKey(id, "HNS_FEATURE_DISABLED");
		return PLUGIN_HANDLED;
	}

	if(get_user_team(id) != 3 || !fnIsPlayableTeam(g_aIsAfkTeam[id])) {
		ChatColorKey(id, "HNS_CANNOT_RETURN_TO_GAME");
		return PLUGIN_HANDLED;
	}

	cs_set_user_team(id, g_aIsAfkTeam[id]);

	if(g_iCvarAfkTimerRevive == 1 && g_iTimer) {
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
	new iImmunityFlag = read_flags(g_szCvarAutojoinImmunityFlag);

	return (
		g_iCvarAutojoin == 1 &&
		!get_user_team(id) &&
		!task_exists(TASK_FORCE_JOIN + id) &&
		(g_iCvarAutojoinImmunity == 0 || !(get_user_flags(id) & iImmunityFlag))
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

	if(g_iCvarChangeTeam == 1)
		return PLUGIN_CONTINUE;

	if(g_iCvarChangeTeamImmunity == 1) {
		new iImmunityFlag = read_flags(g_szCvarChangeTeamImmunityFlag);

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
