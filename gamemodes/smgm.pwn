/*==============================================================================

	SanMarino RolePlay

		Big thanks to WopsS for the initial concept and developing!
		Also thanks to Nestor for the idea long ago with some very productive discussions!
		Big thanks to Brko for great mapping and helping me find a creativty!

==============================================================================*/

#include <a_samp>

/*==============================================================================

	Library Predefinitions

==============================================================================*/

#undef MAX_PLAYERS
#define MAX_PLAYERS	(1000)

/*==============================================================================
	Guaranteed first call
	OnGameModeInit_Setup is called before ANYTHING else, the purpose of this is
	to prepare various internal and external systems that may need to be ready
	for other modules to use their functionality. This function isn't hooked.
	OnScriptInit (from YSI) is then called through modules which is used to
	prepare dependencies such as databases, folders and register debuggers.
	OnGameModeInit is then finally called throughout modules and starts inside
	the "Server/Init.pwn" module (very important) so itemtypes and other object
	types can be defined. This callback is used throughout other scripts as a
	means for declaring entities with relevant data.
==============================================================================*/

public OnGameModeInit()
{
	print("\n[OnGameModeInit] Initialising 'Main'...");

	OnGameModeInit_Setup();

	#if defined main_OnGameModeInit
		return main_OnGameModeInit();
	#else
		return 1;
	#endif
}
#if defined _ALS_OnGameModeInit
	#undef OnGameModeInit
#else
	#define _ALS_OnGameModeInit
#endif
 
#define OnGameModeInit main_OnGameModeInit
#if defined main_OnGameModeInit
	forward main_OnGameModeInit();
#endif

/*==============================================================================

	Libraries and respective links to their release pages

==============================================================================*/
#include <a_mysql>															// By BlueG, R39-3:					https://github.com/pBlueG/SA-MP-MySQL
#include <sscanf2>																// By Y_Less, 2.8.2:					http://forum.sa-mp.com/showthread.php?t=570927
#include <crashdetect>														// By Zeex	, f4d84e2b1c:			http://forum.sa-mp.com/showthread.php?t=262796
#include <YSI\y_timers>													// By Y_Less, f4d85a8:			http://forum.sa-mp.com/showthread.php?t=570884
#include <YSI\y_commands>											// By Y_Less, f4d85a8:			http://forum.sa-mp.com/showthread.php?t=570884
#include <YSI\y_master>													// By Y_Less, f4d85a8:			http://forum.sa-mp.com/showthread.php?t=570884
#include <strlib>																	// By Slice, 48c183f0ad:			https://github.com/oscar-broman/strlib
#include <streamer>															// By Incognito, 2.7.6:				http://forum.sa-mp.com/showthread.php?t=102865
#include <easyDialog>														// By Emmet,04/04/2015:  	http://forum.sa-mp.com/showthread.php?t=475838
#include <libRegEx>															// By FF-Koala,f4a455a665:	http://forum.sa-mp.com/showthread.php?t=526725
//#include <EVF>																	// By Emmet_	:							http://forum.sa-mp.com/showthread.php?t=486060
//#include <modelsizes>													// By Y_Less:								http://forum.sa-mp.com/showthread.php?t=570965
/*==============================================================================

	Definitions

==============================================================================*/

#define SCM SendClientMessage

// MySQL
forward WhenAccountCheck(playerid, password[]);

new gTemp[256];

// Login
new gRegistred[MAX_PLAYERS];
new gLogged[MAX_PLAYERS];
new RegistrationStep[MAX_PLAYERS];

forward Update(playerid, type);

// Money
#define ResetMoneyBar ResetPlayerMoney
#define UpdateMoneyBar GivePlayerMoney

enum pInfo
{
	pPassword[128], pLevel, pAdmin, pHelper, pCash, pAccount, pEmail, pRegistred, pTutorial, pSex, pAge, pPhoneNumber, pPremiumAccount, pBanned, pWarns, 
	pLeader, pMember, pRank, pSkin, pSpawnLoc,pRPname,pInterior, pIP,pMapper, pLastLogin[100]
};

new PlayerInfo[MAX_PLAYERS][pInfo];
new Cash[MAX_PLAYERS];


// Tutorial
new TutorialTime[MAX_PLAYERS];

// Admin & Helpers & Reports
#define ADMIN_SPEC_TYPE_NONE 0
#define ADMIN_SPEC_TYPE_PLAYER 1
#define ADMIN_SPEC_TYPE_VEHICLE 2

new ReportTime[MAX_PLAYERS];
new SpectateType[MAX_PLAYERS];
new SpectatedID[MAX_PLAYERS];

forward AdminsBroadCast(color, string[]);
forward HelpersBroadCast(color, string[]);

// Faction
forward SetPlayerFactionColor(playerid);
forward FactionsBroadCast(faction, color, string[]);
forward RadioBroadCast(faction, color, string[]);

forward ShowStats(playerid, targetid);
forward KickPublic(playerid);
forward ProxDetector(Float:radi, playerid, string[],col1,col2,col3,col4,col5);


/*==============================================================================

	Global values

==============================================================================*/



/*==============================================================================

	Gamemode Scripts

==============================================================================*/

//Main Scripts
#include "SM/Core/Config.pwn"
#include "SM/Utility/Colors.pwn"

//MySQL
#include "SM/Core/Mysql/Connect.pwn"
#include "SM/Core/Mysql/LoadAccount.pwn"

//Utility Scripts
#include "SM/Utility/Scripts.pwn"
#include "SM/Utility/Check.pwn"
#include "SM/Utility/Regex.pwn"
#include "SM/Utility/Format.pwn"
#include "SM/Utility/Organisation.pwn"
	
//UI
#include "SM/Core/UI/GlobalUI.pwn"
#include "SM/Core/UI/Logo.pwn"

//Dialogs
#include "SM/Core/Dialogs/Main.pwn"
#include "SM/Core/Dialogs/Register.pwn"
#include "SM/Core/Dialogs/Login.pwn"
#include "SM/Core/Dialogs/House.pwn"
#include "SM/Core/Dialogs/Mapping.pwn"
#include "SM/Core/Dialogs/Commands.pwn"

//Timers
#include "SM/Core/Timers/Global.pwn"
#include "SM/Core/Timers/Player.pwn"

//Systems
#include "SM/Core/System/Fade.pwn"
#include "SM/Core/System/Login.pwn"
#include "SM/Core/System/Register.pwn"
#include "SM/Core/System/CharCreator.pwn"
#include "SM/Core/System/Spawn.pwn"
#include "SM/Core/System/EnterExit.pwn"
#include "SM/Core/System/COS.pwn"
#include "SM/Core/System/Tune.pwn"
#include "SM/Core/System/House.pwn"
#include "SM/Core/System/Objects.pwn"
//#include "SM/Core/System/Event.pwn" --need to finish (done around 10%)
//#include "SM/Core/System/AntiCheat.pwn" --need to finish (done around 0%)

//Commands
#include "SM/Core/Commands/Organisation/Main.pwn"
#include "SM/Core/Commands/Player.pwn"
#include "SM/Core/Commands/Admin.pwn"
#include "SM/Core/Commands/Main.pwn"
#include "SM/Core/Commands/House.pwn"

#if defined GMDEBUG
#include "SM/Core/Commands/Test.pwn"	
#endif

main()
{
	print("\n\n/*==============================================================================\n\n");
	print("	SanMarino RolePlay by m0k1 | DEV VERSION");
	print("\n\n==============================================================================*/\n\n");
}

OnGameModeInit_Setup()
{
	print("\n[OnGameModeInit_Setup] Setting up...");
	Streamer_ToggleErrorCallback(true);
	SetWorldTime(1);
}

public OnGameModeInit()
{
	return 1;
}

public OnGameModeExit()
{
	return 1;
}

public OnPlayerConnect(playerid)
{
	gRegistred[playerid] = 0; 
	gLogged[playerid] = 0;
	RegistrationStep[playerid] = 0;
	TutorialTime[playerid] = 0;
	ReportTime[playerid] = 0; 
	SpectatedID[playerid] = 0;
	PlayerInfo[playerid][pRegistred] = 0;
	PlayerInfo[playerid][pRPname] = 0;
	PlayerInfo[playerid][pTutorial] = 0;
	PlayerInfo[playerid][pSex] = 0;
	return 1;
}


public OnPlayerDeath(playerid, killerid, reason)
{
	return 1;
}

public OnVehicleSpawn(vehicleid)
{
	return 1;
}

public OnVehicleDeath(vehicleid, killerid)
{
	return 1;
}

public OnPlayerText(playerid, text[])
{
	new pName[MAX_PLAYER_NAME];
	new string[256];
 	GetPlayerName(playerid, pName, sizeof(pName));

	format(string, sizeof(string), "%s kaze: %s", pName, text);
	ProxDetector(20.0, playerid, string, COLOR_FADE1, COLOR_FADE2, COLOR_FADE3, COLOR_FADE4, COLOR_FADE5);
	return 0;
}


public KickPublic(playerid)
{
	Kick(playerid);
}

public ProxDetector(Float:radi, playerid, string[], col1, col2, col3, col4, col5)
{
	if(IsPlayerConnected(playerid))
	{
		new Float:posx, Float:posy, Float:posz;
		new Float:oldposx, Float:oldposy, Float:oldposz;
		new Float:gTempposx, Float:gTempposy, Float:gTempposz;
		GetPlayerPos(playerid, oldposx, oldposy, oldposz);
		for(new i = 0; i < MAX_PLAYERS; i++)
		{
			if(IsPlayerConnected(i))
			{
				if(GetPlayerVirtualWorld(i) == GetPlayerVirtualWorld(playerid))
				{
						GetPlayerPos(i, posx, posy, posz);
						gTempposx = (oldposx -posx);
						gTempposy = (oldposy -posy);
						gTempposz = (oldposz -posz);
						if (((gTempposx < radi/16) && (gTempposx > -radi/16)) && ((gTempposy < radi/16) && (gTempposy > -radi/16)) && ((gTempposz < radi/16) && (gTempposz > -radi/16)))
						{
							SendClientMessage(i, col1, string);
						}
						else if (((gTempposx < radi/8) && (gTempposx > -radi/8)) && ((gTempposy < radi/8) && (gTempposy > -radi/8)) && ((gTempposz < radi/8) && (gTempposz > -radi/8)))
						{
							SendClientMessage(i, col2, string);
						}
						else if (((gTempposx < radi/4) && (gTempposx > -radi/4)) && ((gTempposy < radi/4) && (gTempposy > -radi/4)) && ((gTempposz < radi/4) && (gTempposz > -radi/4)))
						{
							SendClientMessage(i, col3, string);
						}
						else if (((gTempposx < radi/2) && (gTempposx > -radi/2)) && ((gTempposy < radi/2) && (gTempposy > -radi/2)) && ((gTempposz < radi/2) && (gTempposz > -radi/2)))
						{
							SendClientMessage(i, col4, string);
						}
						else if (((gTempposx < radi) && (gTempposx > -radi)) && ((gTempposy < radi) && (gTempposy > -radi)) && ((gTempposz < radi) && (gTempposz > -radi)))
						{
							SendClientMessage(i, col5, string);
						}
				}
				else
				{
					SendClientMessage(i, col1, string);
				}
			}
		}
	}
	return 0;
}

public AdminsBroadCast(color, string[])
{
	for(new i = 0; i < MAX_PLAYERS; i++)
	{
		if(IsPlayerConnected(i))
		{
			if(PlayerInfo[i][pAdmin] >= 1)
			{
				SendClientMessage(i, color, string);
			}
		}
	}
	return 1;
}

public HelpersBroadCast(color, string[])
{
	for(new i = 0; i < MAX_PLAYERS; i++)
	{
		if(IsPlayerConnected(i))
		{
			if(PlayerInfo[i][pHelper] >= 1)
			{
				SendClientMessage(i, color, string);
			}
		}
	}
	return 1;
}

public FactionsBroadCast(faction, color, string[])
{
	for(new i = 0; i < MAX_PLAYERS; i++)
	{
		if(IsPlayerConnected(i))
		{
			if(PlayerInfo[i][pMember] == faction || PlayerInfo[i][pLeader] == faction)
			{
				SendClientMessage(i, color, string);
			}
		}
	}
	return 1;
}

public RadioBroadCast(faction, color, string[])
{
	for(new i = 0; i < MAX_PLAYERS; i++)
	{
		if(IsPlayerConnected(i))
		{
			if(PlayerInfo[i][pMember] == faction || PlayerInfo[i][pLeader] == faction)
			{
				SendClientMessage(i, color, string);
			}
		}
	}
	return 1;
}

KickWithMessage(playerid, color, message[])
{
	SendClientMessage(playerid, color, message);
	SetTimerEx("KickPublic", 1000, 0, "d", playerid);
}

GivePlayerCash(playerid, money)
{
	Cash[playerid] += money;
	ResetMoneyBar(playerid);
	UpdateMoneyBar(playerid, Cash[playerid]);
	PlayerInfo[playerid][pCash] = Cash[playerid];
	Update(playerid, pCashu);

	return Cash[playerid];
}

SetPlayerCash(playerid, money)
{
	Cash[playerid] = money;
	ResetMoneyBar(playerid);
	UpdateMoneyBar(playerid, Cash[playerid]);
	PlayerInfo[playerid][pCash] = Cash[playerid];
	Update(playerid, pCashu);
	return Cash[playerid];
}

ResetPlayerCash(playerid)
{
	Cash[playerid] = 0;
	ResetMoneyBar(playerid);
	UpdateMoneyBar(playerid, Cash[playerid]);
	PlayerInfo[playerid][pCash] = Cash[playerid];
	Update(playerid, pCashx);

	return Cash[playerid];
}

GetPlayerCash(playerid)
{
	return Cash[playerid];
}

public ShowStats(playerid, targetid)
{
	if(IsPlayerConnected(targetid))
	{
		new pName[MAX_PLAYER_NAME];
		GetPlayerName(targetid, pName, sizeof(pName));
		new string[256];

		new level = PlayerInfo[targetid][pLevel];
		new sex[8];
		if(PlayerInfo[targetid][pSex] == 1)
		{
			sex = "Musko";
		}
		else if(PlayerInfo[targetid][pSex] == 2)
		{
			sex = "Zensko";
		}
		new age = PlayerInfo[targetid][pAge];
		new cash = GetPlayerCash(targetid);
		new account = PlayerInfo[targetid][pAccount];
		new phonenumber = PlayerInfo[targetid][pPhoneNumber];
		new premiumaccount[4];
		if(PlayerInfo[targetid][pPremiumAccount] == 1)
		{
			premiumaccount = "Da";
	 	}
	 	else
	 	{
	 		premiumaccount = "Ne";
		}
		SendClientMessage(playerid, COLOR_SERVER_GREEN,"_______________________________________");
		format(string, sizeof(string), "%s stats", pName);
		SendClientMessage(playerid, COLOR_WHITE, string);
		format(string, sizeof(string), "Level:[%d] Pol:[%s] Godine:[%d] Novac:[$%s] Banka:[$%s] Telefon:[%s]", level, sex, age, FormatNumber(cash), FormatNumber(account), PhoneFormat(phonenumber));
		SendClientMessage(playerid, COLOR_WHITE,string);
		format(string, sizeof(string), "VIP:[%s]", premiumaccount);
		SendClientMessage(playerid, COLOR_WHITE,string);
		format(string, sizeof(string), "Organizacija:[%s] Rank:[%s]", GetFactionName(PlayerInfo[targetid][pMember]), GetRankName(PlayerInfo[targetid][pMember],PlayerInfo[targetid][pRank]));
		SendClientMessage(playerid, COLOR_WHITE,string);
		SendClientMessage(playerid, COLOR_SERVER_GREEN,"_______________________________________");

	}
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	return 1;
}

public OnPlayerClickPlayer(playerid, clickedplayerid, source)
{
	return 1;
}