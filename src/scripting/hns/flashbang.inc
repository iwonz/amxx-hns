#if defined _hns_flashbang_included
	#endinput
#endif
#define _hns_flashbang_included

new const FLASHBANG_MODEL[] = "models/w_flashbang.mdl";

new g_iFlasher;
new CsTeams:g_iFlasherTeam;
new bool:g_bFlashFailed;
new bool:g_bFlashbangEntity[MAX_TRACKED_ENTITIES];

fnResetFlashbangRoundState() {
	g_iFlasher = 0;
	g_iFlasherTeam = CS_TEAM_UNASSIGNED;
	g_bFlashFailed = false;
}

public fwdSetModel(ent, const szModel[]) {
	if(ent > 0 && ent < sizeof g_bFlashbangEntity)
		g_bFlashbangEntity[ent] = equal(szModel, FLASHBANG_MODEL) != 0;

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
		g_iFlasherTeam = cs_get_user_team(iOwner);
	} else {
		g_iFlasher = 0;
		g_iFlasherTeam = CS_TEAM_UNASSIGNED;
	}

	g_bFlashFailed = g_iCvarFlashbangFailureChance > 0 && random_num(1, 100) <= g_iCvarFlashbangFailureChance;

	if(g_bFlashFailed && is_user_connected(iOwner))
		fnNotifyFlashbangFailure(iOwner);
}

fnNotifyFlashbangFailure(id) {
	switch(g_iCvarFlashbangFailureNotify) {
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

public msgScreenFade(msgId, msgDest, msgEnt) {
	if(!fnIsFlashScreenFade() || !g_iFlasherTeam || !is_user_alive(msgEnt))
		return PLUGIN_CONTINUE;

	if(g_bFlashFailed)
		return PLUGIN_HANDLED;

	if(g_iTimer && g_iCvarTimerAntiflashCt == 1 && cs_get_user_team(msgEnt) == CS_TEAM_CT)
		return PLUGIN_HANDLED;

	if(g_iFlasher == msgEnt && g_iCvarFlashFlasher == 0)
		return PLUGIN_HANDLED;

	if(g_iFlasherTeam == cs_get_user_team(msgEnt) && g_iCvarFlashTeammate == 0)
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
