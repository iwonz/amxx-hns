#if defined _hns_ui_included
	#endinput
#endif
#define _hns_ui_included

new g_SyncHud;

fnMakeScreenFade(id, r = 0, g = 0, b = 0, alpha = 100, fade = 0) {
	message_begin(MSG_ONE, get_user_msgid("ScreenFade"), _, id);
	write_short(2048 * fade); // 2048 = 0.5 сек.
	write_short(2048 * fade);
	write_short(0x0000);
	write_byte(r);
	write_byte(g);
	write_byte(b);
	write_byte(alpha);
	message_end();
}

stock ChatColorKey(id, const szKey[]) {
	new szMessage[190];
	formatex(szMessage, charsmax(szMessage), "%L %L", id, "HNS_CHAT_PREFIX", id, szKey);

	replace_all(szMessage, charsmax(szMessage), "!n", "^1");
	replace_all(szMessage, charsmax(szMessage), "!t", "^3");
	replace_all(szMessage, charsmax(szMessage), "!g", "^4");

	SendChatColor(id, szMessage);
}

stock SendChatColor(const id, const szMessage[]) {
	static iPlayersCount, aPlayers[32], iMessageId;

	if(!iMessageId)
		iMessageId = get_user_msgid("SayText");

	if(id) {
		aPlayers[0] = id;
		iPlayersCount = 1;
	} else
		get_players(aPlayers, iPlayersCount, "ch");

	for(new i = 0; i < iPlayersCount; i++) {
		message_begin(MSG_ONE, iMessageId, .player = aPlayers[i]);
		write_byte(aPlayers[i]);
		write_string(szMessage);
		message_end();
	}
}

stock ClearDHUDMessages(id, iClear = 8)
	for(new iDHUD = 0; iDHUD < iClear; iDHUD++)
		show_dhudmessage(id, "");
