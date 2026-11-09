#if defined _hns_equipment_included
	#endinput
#endif
#define _hns_equipment_included

public fnTakeKnife(id) {
	if(get_pcvar_num(g_aCvar[CVAR_TR_FAKE_KNIFE_MODE]) == 2 && get_user_team(id) == 1) {
		set_pev(id, pev_viewmodel2, "");
		set_pev(id, pev_weaponmodel2, "");
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
