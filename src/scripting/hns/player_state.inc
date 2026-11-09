#if defined _hns_player_state_included
	#endinput
#endif
#define _hns_player_state_included

new bool:g_bConnected[MAX_PLAYERS + 1];
new bool:g_aCountdownSound[MAX_PLAYERS + 1];
new CsTeams:g_aIsAfkTeam[MAX_PLAYERS + 1] = CS_TEAM_UNASSIGNED;
