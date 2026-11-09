#if defined _hns_definitions_included
	#endinput
#endif
#define _hns_definitions_included

#define TASK_AUTOHEAL 1000
#define TASK_REVIVE 1100
#define TASK_AFK_REVIVE 1200
#define TASK_FORCE_JOIN 1300
#define TASK_GIVE_WEAPONS 1400
#define MAX_TRACKED_ENTITIES 2049
#define MAX_SOUND_PATH_LENGTH 63

new g_iCvarTimer;
new g_iCvarTimerImmortal;
new Float:g_fCvarTimerImmortalDelay;
new g_iCvarTimerAntiflashCt;

new g_iCvarCountdownSound;
new g_iCvarWinSoundMode;

new g_iCvarCtTimerFadeScreen;
new g_iCvarCtTimerFadeScreenRed;
new g_iCvarCtTimerFadeScreenGreen;
new g_iCvarCtTimerFadeScreenBlue;
new g_iCvarCtTimerFadeScreenAlpha;

new g_iCvarRemoveBreakables;
new g_iCvarRemoveDoors;

new g_iCvarHegrenadeMode;
new g_iCvarFlashbangMode;
new g_iCvarFlashbangCount;
new g_iCvarFlashbangFailureChance;
new g_iCvarFlashbangFailureNotify;
new g_iCvarSmokegrenadeMode;
new g_iCvarFlashFlasher;
new g_iCvarFlashTeammate;

new g_iCvarAutoheal;
new g_iCvarAutohealMode;
new g_iCvarAutohealMaxHp;
new Float:g_fCvarAutohealDelay;

new g_iCvarFalldownShowDamage;
new g_iCvarFalldownPlaySound;
new g_iCvarFalldownFadeScreen;
new g_iCvarFalldownFadeScreenRed;
new g_iCvarFalldownFadeScreenGreen;
new g_iCvarFalldownFadeScreenBlue;
new g_iCvarFalldownFadeScreenAlpha;

new g_iCvarAutojoin;
new g_iCvarAutojoinImmunity;
new g_szCvarAutojoinImmunityFlag[2];

new g_iCvarChangeTeam;
new g_iCvarChangeTeamImmunity;
new g_szCvarChangeTeamImmunityFlag[2];

new g_iCvarAfkControl;
new g_iCvarAfkTimerRevive;
new g_iCvarTrFakeKnifeMode;
