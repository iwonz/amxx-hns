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
		if(g_iCvarFalldownPlaySound == 1)
			client_cmd(iVictim, "spk hns/falldown/1.wav");

		if(g_iCvarFalldownShowDamage == 1) {
			set_hudmessage(255, 0, 0, 0.05, 0.9, 0, 0.1, 3.0, 0.01, 0.01, -1);
			ShowSyncHudMsg(iVictim, g_SyncHud, "%L", iVictim, "HNS_FALL_DAMAGE", iDamage);
		}

		if(g_iCvarFalldownFadeScreen == 1)
			fnMakeScreenFade(
				iVictim,
				g_iCvarFalldownFadeScreenRed,
				g_iCvarFalldownFadeScreenGreen,
				g_iCvarFalldownFadeScreenBlue,
				g_iCvarFalldownFadeScreenAlpha,
				1
			);

		if(g_iCvarAutoheal == 1) {
			if(g_iCvarAutohealMode == 3 || g_iCvarAutohealMode == _:cs_get_user_team(iVictim)) {
				new iAutohealTaskId = TASK_AUTOHEAL + iVictim;

				if(task_exists(iAutohealTaskId))
					remove_task(iAutohealTaskId);

				new aArgs[1];
				aArgs[0] = iDamage;

				set_task(g_fCvarAutohealDelay, "fnAutoHeal", iAutohealTaskId, aArgs, 1);
			}
		}
	}

	return HAM_SUPERCEDE;
}

public fnAutoHeal(aArgs[], iTaskId) {
	new iUserId = iTaskId - TASK_AUTOHEAL;

	if(g_bConnected[iUserId] && is_user_alive(iUserId)) {
		new iDamage = aArgs[0];

		new iCurrentUserHP = get_user_health(iUserId);

		if(iDamage < g_iCvarAutohealMaxHp)
			set_user_health(iUserId, iCurrentUserHP + iDamage);
		else
			set_user_health(iUserId, iCurrentUserHP + g_iCvarAutohealMaxHp);
	}
}
