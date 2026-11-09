#if defined _hns_round_included
	#endinput
#endif
#define _hns_round_included

new g_szHidersWinSound[MAX_SOUND_PATH_LENGTH + 1] = "radio/terwin.wav";
new g_szSeekersWinSound[MAX_SOUND_PATH_LENGTH + 1] = "radio/ctwin.wav";

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

bool:fnTRAlive() {
	new aPlayers[32], iPlayersCount, i;
	get_players(aPlayers, iPlayersCount, "ch");

	for(i = 0; i < iPlayersCount; i++)
		if(is_user_alive(aPlayers[i]) && get_user_team(aPlayers[i]) == 1)
			return true;

	return false;
}
