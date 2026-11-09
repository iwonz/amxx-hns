#if defined _hns_equipment_included
	#endinput
#endif
#define _hns_equipment_included

public fnTakeKnife(id) {
	if(g_iCvarTrFakeKnifeMode == 2 && cs_get_user_team(id) == CS_TEAM_T) {
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
	if(
		(g_iCvarTrFakeKnifeMode == 1 || g_iCvarTrFakeKnifeMode == 2) &&
		get_user_team(id) == _:CS_TEAM_T &&
		equal(szSound, "weapons/knife_deploy1.wav")
	)
		return FMRES_SUPERCEDE;

	return FMRES_IGNORED;
}
public fwdCmdStart(id, handle) {
	if(!is_user_alive(id))
		return FMRES_IGNORED;

	if(get_user_weapon(id) != CSW_KNIFE)
		return FMRES_IGNORED;

	if(cs_get_user_team(id) != CS_TEAM_T || (g_iCvarTrFakeKnifeMode != 1 && g_iCvarTrFakeKnifeMode != 2))
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

	strip_user_weapons(id);

	give_item(id, "weapon_knife");

	new iUserTeam = _:cs_get_user_team(id);

	if(g_iCvarHegrenadeMode == iUserTeam || g_iCvarHegrenadeMode == 3)
		give_item(id, "weapon_hegrenade");

	if(g_iCvarFlashbangMode == iUserTeam || g_iCvarFlashbangMode == 3)
		for(new i = 1; i <= g_iCvarFlashbangCount; i++)
			give_item(id, "weapon_flashbang");

	if(g_iCvarSmokegrenadeMode == iUserTeam || g_iCvarSmokegrenadeMode == 3)
		give_item(id, "weapon_smokegrenade");
}
