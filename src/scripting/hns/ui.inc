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
	client_print_color(id, id, "%L %L", id, "HNS_CHAT_PREFIX", id, szKey);
}

stock ClearDHUDMessages(id, iClear = 8)
	for(new iDHUD = 0; iDHUD < iClear; iDHUD++)
		show_dhudmessage(id, "");
