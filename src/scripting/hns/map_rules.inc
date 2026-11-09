#if defined _hns_map_rules_included
	#endinput
#endif
#define _hns_map_rules_included

new g_RegisterSpawn;
new const g_DefaultEntities[][] = {
	"func_vip_safetyzone",
	"func_escapezone",
	"hostage_entity",
	"monster_scientist",
	"func_bomb_target",
	"info_bomb_target",
	"armoury_entity"
};

public fwdEntitySpawn(ent) {
	if(!pev_valid(ent))
		return 1;

	new szClass[33];

	pev(ent, pev_classname, szClass, 32);

	for(new i; i < sizeof g_DefaultEntities; i++) {
		if(equal(szClass, g_DefaultEntities[i])) {
			engfunc(EngFunc_RemoveEntity, ent);
			return 4;
		}
	}

	if(get_pcvar_num(g_aCvar[CVAR_REMOVE_DOORS])) {
		if(equal(szClass, "func_door") || equal(szClass, "func_door_rotating")) {
			engfunc(EngFunc_RemoveEntity, ent);
			return 4;
		}
	}

	if(get_pcvar_num(g_aCvar[CVAR_REMOVE_BREAKABLES]) && equal(szClass, "func_breakable")) {
		engfunc(EngFunc_RemoveEntity, ent);
		return 4;
	}

	return 1;
}

public msgStatusIcon(msgid, msgdest, id) {
	static szMsg[8];
	get_msg_arg_string(2, szMsg, 7);

	if(equal(szMsg, "buyzone") && get_msg_arg_int(1)) {
		set_pdata_int(id, 235, get_pdata_int(id, 235) & ~(1<<0));
		return 1;
	}

	return 0;
}
