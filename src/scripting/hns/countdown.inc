#if defined _hns_countdown_included
	#endinput
#endif
#define _hns_countdown_included

new bool:g_bStart = false;
new bool:g_bCountdownActive = false;
new g_iTimer = 0;
new g_TimerEntity;

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
