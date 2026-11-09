#if defined _hns_fall_damage_included
	#endinput
#endif
#define _hns_fall_damage_included

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
