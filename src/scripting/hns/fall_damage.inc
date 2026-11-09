#if defined _hns_fall_damage_included
	#endinput
#endif
#define _hns_fall_damage_included

new g_iFallHealthBefore[MAX_PLAYERS + 1];
new bool:g_bFallDamagePending[MAX_PLAYERS + 1];

fnResetFallDamageState(id) {
	g_iFallHealthBefore[id] = 0;
	g_bFallDamagePending[id] = false;
}

public fnTakeDamagePre(iVictim, iInflictor, iAttacker, Float:fDamage, bitsDamageType) {
	if(!(bitsDamageType & DMG_FALL))
		return HAM_IGNORED;

	if(!is_user_alive(iVictim))
		return HAM_IGNORED;

	g_iFallHealthBefore[iVictim] = get_user_health(iVictim);
	g_bFallDamagePending[iVictim] = true;

	return HAM_IGNORED;
}

public fnTakeDamagePost(iVictim, iInflictor, iAttacker, Float:fDamage, bitsDamageType) {
	if(!(bitsDamageType & DMG_FALL) || !g_bFallDamagePending[iVictim])
		return HAM_IGNORED;

	new iHealthBefore = g_iFallHealthBefore[iVictim];
	g_iFallHealthBefore[iVictim] = 0;
	g_bFallDamagePending[iVictim] = false;

	if(!g_bConnected[iVictim] || !is_user_alive(iVictim))
		return HAM_IGNORED;

	new iDamage = iHealthBefore - get_user_health(iVictim);

	if(iDamage <= 0)
		return HAM_IGNORED;

	fnApplyFallDamageEffects(iVictim, iDamage);
	return HAM_IGNORED;
}

fnApplyFallDamageEffects(iVictim, iDamage) {
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

	if(g_iCvarAutoheal == 0)
		return;

	if(g_iCvarAutohealMode != 3 && g_iCvarAutohealMode != _:cs_get_user_team(iVictim))
		return;

	new iAutohealTaskId = TASK_AUTOHEAL + iVictim;

	if(task_exists(iAutohealTaskId))
		remove_task(iAutohealTaskId);

	new aArgs[1];
	aArgs[0] = iDamage;

	set_task(g_fCvarAutohealDelay, "fnAutoHeal", iAutohealTaskId, aArgs, 1);
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
