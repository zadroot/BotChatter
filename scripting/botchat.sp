#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_NAME             "DoD:S Bot Chatter"
#define PLUGIN_AUTHOR           "Root"
#define PLUGIN_DESCRIPTION      "Simple bot chatter for DoD:S"
#define PLUGIN_VERSION          "1.0"
#define PLUGIN_CONTACT          "http://www.dodsplugins.com/"

#define CHAT_MESSAGE_MAX_LENGTH 256
#define EVENT_NAME_MAX_LENGTH   32
#define DOD_MAXPLAYERS          33

new Handle:botcomm_version = INVALID_HANDLE,
	Handle:botcomm_enable = INVALID_HANDLE,
	Handle:ChatMessages = INVALID_HANDLE,
	Float:last_message[DOD_MAXPLAYERS] = {0.0, ...},
	Float:current_time = 0.0;

public Plugin:myinfo =
{
	name			= PLUGIN_NAME,
	author			= PLUGIN_AUTHOR,
	description		= PLUGIN_DESCRIPTION,
	version			= PLUGIN_VERSION,
	url				= PLUGIN_CONTACT
};

public OnPluginStart()
{
	LoadTranslations("common.phrases");

	botcomm_version = CreateConVar("dod_botcomm_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED);
	botcomm_enable  = CreateConVar("sm_botcomm_enable",   "1", "Enable or disable botchatter", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);

	HookEvents();
	HookConVarChange(botcomm_enable, OnEnableChange);

	RegAdminCmd("chatter_refresh", Command_RefreshConfig, ADMFLAG_GENERIC);
}

public OnMapStart()
{
	LoadChatMessages();
	SetConVarString(botcomm_version, PLUGIN_VERSION);

	for(new i = 0; i <= MaxClients; i++) last_message[i] = 0.0;
}

/* public OnGameFrame()
{
	static Float:last_say = 0.0;

	current_time = GetGameTime();

	if((last_say - 0.1) < current_time)
		return; // do not work too fast

	last_say = current_time;
} */

public OnEnableChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(strcmp(oldValue, newValue) != 0)
	{
		if(strcmp(newValue, "0") == 0) UnhookEvents();
		else HookEvents();
	}
}

public OnClientPostAdminCheck(client)
{
	if(!GetConVarBool(botcomm_enable))
		return;

	new _:Teamchat/*, Float:type_time*/;
	decl String:message[CHAT_MESSAGE_MAX_LENGTH], String:client_name[MAX_NAME_LENGTH], Float:type_time/*, String:bot_name[MAX_NAME_LENGTH]*/;

	if(IsValidClient(client)) GetClientName(client, client_name, sizeof(client_name));

	if(IsValidBot(client))
	{
		if(FindEvent("player_connected", message, sizeof(message), type_time, Teamchat, client))
		{
			/*if(message[0] == '#')
			{
				GetClientName(client, client_name, sizeof(client_name));
				Format(message, sizeof(message), "%T", message[1], LANG_SERVER, client_name);
			}*/
			BotSay(client, "player_connected", message, type_time, bool:Teamchat);
		}
	}
	else if(strlen(client_name) > 0)
	{
		for(new bot = 1; bot <= MaxClients; bot++)
		{
			if(IsValidBot(bot) && BotRandomSay())
			{
				if(FindEvent("other_player_connected", message, sizeof(message), type_time, Teamchat, bot))
				{
					/*if(message[0] == '#')
					{
						GetClientName(bot, bot_name, sizeof(bot_name));
						Format(message, sizeof(message), "%T", message[1], LANG_SERVER, bot_name);
					}*/
					BotSay(bot, "other_player_connected", message, type_time, bool:Teamchat);
				}
			}
		}
	}
}

public OnClientDisconnect_Post(client)
{
	if(!GetConVarBool(botcomm_enable))
		return;

	new _:Teamchat/*, Float:type_time*/;
	decl String:message[CHAT_MESSAGE_MAX_LENGTH], Float:type_time/*, String:client_name[MAX_NAME_LENGTH], String:bot_name[MAX_NAME_LENGTH]*/;

	/*if (IsValidClient(client)) GetClientName(client, client_name, sizeof(client_name));*/

	for(new bot = 1; bot <= MaxClients; bot++)
	{
		if(IsValidBot(bot) && BotRandomSay())
		{
			if(FindEvent("other_player_disconnected", message, sizeof(message), type_time, Teamchat, bot))
			{
				/*if(message[0] == '#')
				{
					GetClientName(bot, bot_name, sizeof(bot_name));
					Format(message, sizeof(message), "%T", message[1], LANG_SERVER, bot_name);
				}*/
				BotSay(bot, "other_player_disconnected", message, type_time, bool:Teamchat);
			}
		}
	}
}

public Event_Player_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new bot = GetClientOfUserId(GetEventInt(event, "userid"));

	new _:Teamchat/*, Float:type_time*/;
	decl String:message[CHAT_MESSAGE_MAX_LENGTH], Float:type_time/*, String:bot_name[MAX_NAME_LENGTH]*/;

	if(IsValidBot(bot) && BotRandomSay())
	{
		if(FindEvent("player_spawn", message, sizeof(message), type_time, Teamchat, bot))
		{
			/*if(message[0] == '#')
			{
				GetClientName(bot, bot_name, sizeof(bot_name));
				Format(message, sizeof(message), "%T", message[1], LANG_SERVER, bot_name);
			}*/
			BotSay(bot, "player_spawn", message, type_time, bool:Teamchat);

			/*new rnd = GetRandomInt(0, 3);
			switch (rnd)
			{
				case 0: FakeClientCommand(bot, "voice_displace");
				case 1: FakeClientCommand(bot, "voice_movewithtank");
				case 2: FakeClientCommand(bot, "voice_coverflanks");
				case 3: FakeClientCommand(bot, "voice_attack");
			}*/
		}
	}
}

public Event_Player_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));

	new _:Teamchat/*, Float:type_time*/;
	decl String:message[CHAT_MESSAGE_MAX_LENGTH], Float:type_time/*, String:attacker_name[MAX_NAME_LENGTH], String:victim_name[MAX_NAME_LENGTH]*/;

	if(IsValidBot(attacker) && BotRandomSay())
	{
		if(FindEvent("player_kill", message, sizeof(message), type_time, Teamchat, attacker))
		{
			/*if(message[0] == '#')
			{
				GetClientName(attacker, attacker_name, sizeof(attacker_name));
				Format(message, sizeof(message), "%T", message[1], LANG_SERVER, attacker_name);
			}*/
			BotSay(attacker, "player_kill", message, type_time, bool:Teamchat);
			//FakeClientCommand(attacker, "voice_niceshot");
		}
	}
	if(IsValidBot(victim) && BotRandomSay())
	{
		if(FindEvent("player_death", message, sizeof(message), type_time, Teamchat, victim))
		{
			/*if(message[0] == '#')
			{
				GetClientName(victim, victim_name, sizeof(victim_name));
				Format(message, sizeof(message), "%T", message[1], LANG_SERVER, victim_name);
			}*/
			BotSay(victim, "player_death", message, type_time, bool:Teamchat);
		}
	}
}

public Event_Achievement_Earned(Handle:event, const String:name[], bool:dontBroadcast)
{
	//new client = GetClientOfUserId(GetEventInt(event, "player"));

	new _:Teamchat/*, Float:type_time*/;
	decl String:message[CHAT_MESSAGE_MAX_LENGTH], Float:type_time/*, String:client_name[MAX_NAME_LENGTH], String:bot_name[MAX_NAME_LENGTH]*/;

	/*if (IsValidClient(client)) GetClientName(client, client_name, sizeof(client_name));*/

	for(new bot = 1; bot <= MaxClients; bot++)
	{
		if(IsValidBot(bot) && BotRandomSay())
		{
			if(FindEvent("achievement_earned", message, sizeof(message), type_time, Teamchat, bot))
			{
				/*if(message[0] == '#')
				{
					GetClientName(bot, bot_name, sizeof(bot_name));
					Format(message, sizeof(message), "%T", message[1], LANG_SERVER, bot_name);
				}*/
				BotSay(bot, "achievement_earned", message, type_time, bool:Teamchat);
			}
		}
	}
}

public Event_Point_Captured(Handle:event, const String:name[], bool:dontBroadcast)
{
	new bot, _:Teamchat;
	decl String:cappers[256], String:message[CHAT_MESSAGE_MAX_LENGTH], Float:type_time/*, String:bot_name[MAX_NAME_LENGTH]*/;

	GetEventString(event, "cappers", cappers, sizeof(cappers));

	for(new i = 0 ; i < strlen(cappers); i++)
	{
		bot = cappers[i];
		if(IsValidBot(bot) && BotRandomSay())
		{
			if(FindEvent("dod_point_captured", message, sizeof(message), type_time, Teamchat, bot))
			{
				/*if(message[0] == '#')
				{
					GetClientName(bot, bot_name, sizeof(bot_name));
					Format(message, sizeof(message), "%T", message[1], LANG_SERVER, bot_name);
				}*/
				BotSay(bot, "dod_point_captured", message, type_time, bool:Teamchat);
				//FakeClientCommand(bot, "");
			}
		}
	}
}

public Event_Capture_Blocked(Handle:event, const String:name[], bool:dontBroadcast)
{
	new bot = GetEventInt(event, "blocker");

	new _:Teamchat/*, Float:type_time*/;
	decl String:message[CHAT_MESSAGE_MAX_LENGTH], Float:type_time/*, String:client_name[MAX_NAME_LENGTH], String:bot_name[MAX_NAME_LENGTH]*/;

	if(IsValidBot(bot) && BotRandomSay())
	{
		if(FindEvent("dod_capture_blocked", message, sizeof(message), type_time, Teamchat, bot))
		{
			/*if(message[0] == '#')
			{
				GetClientName(bot, bot_name, sizeof(bot_name));
				Format(message, sizeof(message), "%T", message[1], LANG_SERVER, bot_name);
			}*/
			BotSay(bot, "dod_capture_blocked", message, type_time, bool:Teamchat);
		}
	}
}

public Event_Time_Added(Handle:event, const String:name[], bool:dontBroadcast)
{
	new _:Teamchat/*, Float:type_time*/;
	decl String:message[CHAT_MESSAGE_MAX_LENGTH], Float:type_time/*, String:bot_name[MAX_NAME_LENGTH]*/;

	for(new bot = 1; bot <= MaxClients; bot++)
	{
		if(IsValidBot(bot) && BotRandomSay())
		{
			if(FindEvent("dod_timer_time_added", message, sizeof(message), type_time, Teamchat, bot))
			{
				/*if(message[0] == '#')
				{
					GetClientName(bot, bot_name, sizeof(bot_name));
					Format(message, sizeof(message), "%T", message[1], LANG_SERVER, bot_name);
				}*/
				BotSay(bot, "dod_timer_time_added", message, type_time, bool:Teamchat);
				//FakeClientCommand(bot, "voice_moveupmg");
			}
		}
	}
}

public Event_Bomb_Exploded(Handle:event, const String:name[], bool:dontBroadcast)
{
	//new client = GetClientOfUserId(GetEventInt(event, "userid"));

	new _:Teamchat/*, Float:type_time*/;
	decl String:message[CHAT_MESSAGE_MAX_LENGTH], Float:type_time/*, String:client_name[MAX_NAME_LENGTH], String:bot_name[MAX_NAME_LENGTH]*/;

	/*if (IsValidClient(client)) GetClientName(client, client_name, sizeof(client_name));*/

	for(new bot = 1; bot <= MaxClients; bot++)
	{
		if(IsValidBot(bot) && BotRandomSay())
		{
			if(FindEvent("dod_bomb_exploded", message, sizeof(message), type_time, Teamchat, bot))
			{
				/*if(message[0] == '#')
				{
					GetClientName(bot, bot_name, sizeof(bot_name));
					Format(message, sizeof(message), "%T", message[1], LANG_SERVER, bot_name);
				}*/
				BotSay(bot, "dod_bomb_exploded", message, type_time, bool:Teamchat);
				//FakeClientCommand(bot, "voice_areaclear");
				//FakeClientCommand(bot, "voice_wegothim");
			}
		}
	}
}

public Event_Kill_Planter(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "victimid"));

	new _:Teamchat/*, Float:type_time*/;
	decl String:message[CHAT_MESSAGE_MAX_LENGTH], Float:type_time/*, String:bot_name[MAX_NAME_LENGTH]*/;

	for(new bot = 1; bot <= MaxClients; bot++)
	{
		if(IsValidBot(bot) && BotRandomSay())
		{
			if(GetClientTeam(bot) != GetClientTeam(client))
			{
				if(FindEvent("dod_kill_planter_enemy", message, sizeof(message), type_time, Teamchat, bot))
				{
					/*if(message[0] == '#')
					{
						GetClientName(bot, bot_name, sizeof(bot_name));
						Format(message, sizeof(message), "%T", message[1], LANG_SERVER, bot_name);
					}*/
					BotSay(bot, "dod_kill_planter_enemy", message, type_time, bool:Teamchat);
					//FakeClientCommand(bot, "voice_hold");
				}
			}
		}
	}
}

public Event_Kill_Defuser(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "victimid"));

	new _:Teamchat/*, Float:type_time*/;
	decl String:message[CHAT_MESSAGE_MAX_LENGTH], Float:type_time/*, String:bot_name[MAX_NAME_LENGTH]*/;

	for(new bot = 1; bot <= MaxClients; bot++)
	{
		if(IsValidBot(bot) && BotRandomSay())
		{
			if(GetClientTeam(bot) != GetClientTeam(client))
			{
				if(FindEvent("dod_kill_defuser_enemy", message, sizeof(message), type_time, Teamchat, bot))
				{
					/*if(message[0] == '#')
					{
						GetClientName(bot, bot_name, sizeof(bot_name));
						Format(message, sizeof(message), "%T", message[1], LANG_SERVER, bot_name);
					}*/
					BotSay(bot, "dod_kill_defuser_enemy", message, type_time, bool:Teamchat);
					//FakeClientCommand(bot, "voice_coverflanks");
				}
			}
		}
	}
}

public Event_Bomb_Planted(Handle:event, const String:name[], bool:dontBroadcast)
{
	new win_team = GetEventInt(event, "team");

	new _:Teamchat/*, Float:type_time*/;
	decl String:message[CHAT_MESSAGE_MAX_LENGTH], Float:type_time/*, String:bot_name[MAX_NAME_LENGTH]*/;

	for(new bot = 1; bot <= MaxClients; bot++)
	{
		if(IsValidBot(bot) && BotRandomSay())
		{
			if(GetClientTeam(bot) == win_team)
			{
				if(FindEvent("dod_bomb_planted_friend", message, sizeof(message), type_time, Teamchat, bot))
				{
					/*if(message[0] == '#')
					{
						GetClientName(bot, bot_name, sizeof(bot_name));
						Format(message, sizeof(message), "%T", message[1], LANG_SERVER, bot_name);
					}*/
					BotSay(bot, "dod_bomb_planted_friend", message, type_time, bool:Teamchat);
					//FakeClientCommand(bot, "voice_hold");
				}
			}
			else
			{
				if(FindEvent("dod_bomb_planted_enemy", message, sizeof(message), type_time, Teamchat, bot))
				{
					/*if(message[0] == '#')
					{
						GetClientName(bot, bot_name, sizeof(bot_name));
						Format(message, sizeof(message), "%T", message[1], LANG_SERVER, bot_name);
					}*/
					BotSay(bot, "dod_bomb_planted_enemy", message, type_time, bool:Teamchat);
					//FakeClientCommand(bot, "voice_cover");
				}
			}
		}
	}
}

public Event_Bomb_Defused(Handle:event, const String:name[], bool:dontBroadcast)
{
	new bomb_team = GetEventInt(event, "team");

	new _:Teamchat/*, Float:type_time*/;
	decl String:message[CHAT_MESSAGE_MAX_LENGTH], Float:type_time/*, String:bot_name[MAX_NAME_LENGTH]*/;

	for(new bot = 1; bot <= MaxClients; bot++)
	{
		if(IsValidBot(bot) && BotRandomSay())
		{
			if(GetClientTeam(bot) == bomb_team)
			{
				if(FindEvent("dod_bomb_defused_friend", message, sizeof(message), type_time, Teamchat, bot))
				{
					/*if(message[0] == '#')
					{
						GetClientName(bot, bot_name, sizeof(bot_name));
						Format(message, sizeof(message), "%T", message[1], LANG_SERVER, bot_name);
					}*/
					BotSay(bot, "dod_bomb_defused_friend", message, type_time, bool:Teamchat);
					//FakeClientCommand(bot, "voice_thanks");
				}
			}
			else
			{
				if(FindEvent("dod_bomb_defused_enemy", message, sizeof(message), type_time, Teamchat, bot))
				{
					/*if(message[0] == '#')
					{
						GetClientName(bot, bot_name, sizeof(bot_name));
						Format(message, sizeof(message), "%T", message[1], LANG_SERVER, bot_name);
					}*/
					BotSay(bot, "dod_bomb_defused_enemy", message, type_time, bool:Teamchat);
					//FakeClientCommand(bot, "voice_displace");
				}
			}
		}
	}
}

public Event_Round_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	new _:Teamchat/*, Float:type_time*/;
	decl String:message[CHAT_MESSAGE_MAX_LENGTH], Float:type_time/*, String:bot_name[MAX_NAME_LENGTH]*/;

	for(new bot = 1; bot <= MaxClients; bot++)
	{
		if(IsValidBot(bot) && BotRandomSay())
		{
			if(FindEvent("dod_round_start", message, sizeof(message), type_time, Teamchat, bot))
			{
				/*if(message[0] == '#')
				{
					GetClientName(bot, bot_name, sizeof(bot_name));
					Format(message, sizeof(message), "%T", message[1], LANG_SERVER, bot_name);
				}*/
				BotSay(bot, "dod_round_start", message, type_time, bool:Teamchat);
				//FakeClientCommand(bot, "voice_sticktogether");
			}
		}
	}
}

public Event_Round_Active(Handle:event, const String:name[], bool:dontBroadcast)
{
	new _:Teamchat/*, Float:type_time*/;
	decl String:message[CHAT_MESSAGE_MAX_LENGTH], Float:type_time/*, String:bot_name[MAX_NAME_LENGTH]*/;

	for(new bot = 1; bot <= MaxClients; bot++)
	{
		if(IsValidBot(bot) && BotRandomSay())
		{
			if(FindEvent(name, message, sizeof(message), type_time, Teamchat, bot))
			{
				/*if(message[0] == '#')
				{
					GetClientName(bot, bot_name, sizeof(bot_name));
					Format(message, sizeof(message), "%T", message[1], LANG_SERVER, bot_name);
				}*/
				BotSay(bot, name, message, type_time, bool:Teamchat);

				/*new rnd = GetRandomInt(0, 8);
				switch (rnd)
				{
					case 0: FakeClientCommand(bot, "voice_displace");
					case 1: FakeClientCommand(bot, "voice_attack");
					case 2: FakeClientCommand(bot, "voice_coverflanks");
					case 3: FakeClientCommand(bot, "voice_sticktogether");
					case 4: FakeClientCommand(bot, "voice_left");
					case 5: FakeClientCommand(bot, "voice_right");
					case 6: FakeClientCommand(bot, "voice_movewithtank");
					case 7: FakeClientCommand(bot, "voice_moveupmg");
					case 8: FakeClientCommand(bot, "voice_enemyahead");
				}*/
			}
		}
	}
}

public Event_Round_End(Handle:event, const String:name[], bool:dontBroadcast)
{
	new win_team = GetEventInt(event, "team");

	new _:Teamchat/*, Float:type_time*/;
	decl String:message[CHAT_MESSAGE_MAX_LENGTH], Float:type_time/*, String:bot_name[MAX_NAME_LENGTH]*/;

	for(new bot = 1; bot <= MaxClients; bot++)
	{
		if(IsValidBot(bot) && BotRandomSay())
		{
			if(GetClientTeam(bot) == win_team)
			{
				if(FindEvent("dod_round_win_friend", message, sizeof(message), type_time, Teamchat, bot))
				{
					/*if(message[0] == '#')
					{
						GetClientName(bot, bot_name, sizeof(bot_name));
						Format(message, sizeof(message), "%T", message[1], LANG_SERVER, bot_name);
					}*/
					BotSay(bot, "dod_round_win_friend", message, type_time, bool:Teamchat);
					//FakeClientCommand(bot, "voice_dropweapons");
				}
			}
			else
			{
				if(FindEvent("dod_round_win_enemy", message, sizeof(message), type_time, Teamchat, bot))
				{
					/*if(message[0] == '#')
					{
						GetClientName(bot, bot_name, sizeof(bot_name));
						Format(message, sizeof(message), "%T", message[1], LANG_SERVER, bot_name);
					}*/
					BotSay(bot, "dod_round_win_enemy", message, type_time, bool:Teamchat);
					//FakeClientCommand(bot, "voice_fallback");
				}
			}
		}
	}
}

public Event_Game_Over(Handle:event, const String:name[], bool:dontBroadcast)
{
	new _:Teamchat/*, Float:type_time*/;
	decl String:message[CHAT_MESSAGE_MAX_LENGTH], Float:type_time/*, String:bot_name[MAX_NAME_LENGTH]*/;

	for(new bot = 1; bot <= MaxClients; bot++)
	{
		if(IsValidBot(bot) && BotRandomSay())
		{
			if(FindEvent("dod_game_over", message, sizeof(message), type_time, Teamchat, bot))
			{
				/*if(message[0] == '#')
				{
					GetClientName(bot, bot_name, sizeof(bot_name));
					Format(message, sizeof(message), "%T", message[1], LANG_SERVER, bot_name);
				}*/
				BotSay(bot, "dod_game_over", message, type_time, bool:Teamchat);
				//FakeClientCommand(bot, "voice_ceasefire");
			}
		}
	}
}

public Action:Timer_BotSay(Handle:timer, Handle:data)
{
	ResetPack(data);
	new bot = ReadPackCell(data);

	if(!IsValidBot(bot))
		return Plugin_Handled;

	decl String:name[EVENT_NAME_MAX_LENGTH];
	ReadPackString(data, name, sizeof(name));

	decl String:message[CHAT_MESSAGE_MAX_LENGTH];
	ReadPackString(data, message, sizeof(message));

	new bool:Teamchat = (ReadPackCell(data) != 0);

	if (Teamchat)
		FakeClientCommand(bot, "say_team \"%s\"", message);
	else
		FakeClientCommand(bot, "say \"%s\"", message);

	return Plugin_Handled;
}

public Action:Command_RefreshConfig(client, args)
{
	LoadChatMessages();
	return Plugin_Handled;
}

bool:FindEvent(const String:name[], String:message[], _:length, &Float:type_time, &_:Teamchat, &bot)
{
	new bool:GotResults = false;

	decl String:curmap[32];
	GetCurrentMap(curmap, sizeof(curmap));

	SetRandomSeed(RoundFloat(GetEngineTime()));
	decl String:WordChance[4];
	new Float:SayChance = GetRandomFloat(0.0, 100.0);

	KvRewind(ChatMessages);
	if(KvJumpToKey(ChatMessages, name, false) && KvGotoFirstSubKey(ChatMessages))
	{
		decl String:strStrictMap[32];
		do
		{
			KvGetSectionName(ChatMessages, WordChance, sizeof(WordChance));
			if(StringToFloat(WordChance) >= SayChance)
			{
				KvGetString(ChatMessages, "message", message, length, NULL_STRING);
				type_time = KvGetFloat(ChatMessages, "typetime", 0.1);
				Teamchat = (KvGetNum(ChatMessages, "teamonly", 0) != 0 ? 1 : 0);

				KvGetString(ChatMessages, "mapstrict", strStrictMap, sizeof(strStrictMap), NULL_STRING);
				if(strlen(strStrictMap) > 0 && strcmp(curmap, strStrictMap, false ) != 0)
					continue;

				GotResults = true;

				if(GetRandomInt(0,1))
					break;
			}
		}
		while(KvGotoNextKey(ChatMessages));
	}

	return GotResults;
}

bool:BotRandomSay()
{
	SetRandomSeed(RoundFloat(GetEngineTime()));
	return(GetRandomFloat(0.0, 100.0) >= GetRandomFloat(62.5, 100.0));
}

bool:IsValidClient(client)
{
	return (client > 0 || client <= MaxClients && IsClientConnected(client) && IsClientInGame(client)) ? true : false;
}

bool:IsValidBot(bot)
{
	return (IsValidClient(bot) && IsFakeClient(bot) && !IsClientObserver(bot)) ? true : false;
}

LoadChatMessages()
{
	decl String:file[PLATFORM_MAX_PATH]/* = ""*/;
	BuildPath(Path_SM, file, sizeof(file), "configs/botcomm.txt");

	if(!FileExists(file))
		SetFailState("Couldn't found file: %s", file);

	ChatMessages = CreateKeyValues("bot_chat");
	FileToKeyValues(ChatMessages, file);
}

BotSay(const bot, const String:name[], const String:message[], Float:type_time = 0.1, const bool:Teamchat = false)
{
	if(type_time < 0.1) type_time = 0.1; // prevent buggy timers

	type_time += ((last_message[bot] - current_time) > 0.0 ? (last_message[bot] - current_time) : 0.0);
	last_message[bot] = current_time + type_time;

	new Handle:data = CreateDataPack();
	CreateDataTimer(type_time, Timer_BotSay, data, TIMER_DATA_HNDL_CLOSE);
	WritePackCell(data, bot);
	WritePackString(data, name);
	WritePackString(data, message);
	WritePackCell(data, _:Teamchat);
}

HookEvents()
{
	HookEvent("player_spawn",         Event_Player_Spawn,       EventHookMode_Post);
	HookEvent("player_death",         Event_Player_Death,       EventHookMode_Post);

	HookEvent("achievement_earned",   Event_Achievement_Earned, EventHookMode_Post);

	HookEvent("dod_bomb_exploded",    Event_Bomb_Exploded,      EventHookMode_Post);
	HookEvent("dod_point_captured",   Event_Point_Captured,     EventHookMode_Post);
	HookEvent("dod_capture_blocked",  Event_Capture_Blocked,    EventHookMode_Post);

	HookEvent("dod_timer_time_added", Event_Time_Added,         EventHookMode_Post);

	HookEvent("dod_kill_planter",     Event_Kill_Planter,       EventHookMode_Post);
	HookEvent("dod_kill_defuser",     Event_Kill_Defuser,       EventHookMode_Post);

	HookEvent("dod_bomb_planted",     Event_Bomb_Planted,       EventHookMode_Post);
	HookEvent("dod_bomb_defused",     Event_Bomb_Defused,       EventHookMode_Post);

	HookEvent("dod_round_start",      Event_Round_Start,        EventHookMode_Post);
	HookEvent("dod_round_active",     Event_Round_Active,       EventHookMode_Post);
	HookEvent("dod_round_win",        Event_Round_End,          EventHookMode_Post);
	HookEvent("dod_game_over",        Event_Game_Over,          EventHookMode_Post);
}

UnhookEvents()
{
	UnhookEvent("player_spawn",         Event_Player_Spawn,       EventHookMode_Post);
	UnhookEvent("player_death",         Event_Player_Death,       EventHookMode_Post);

	UnhookEvent("achievement_earned",   Event_Achievement_Earned, EventHookMode_Post);

	UnhookEvent("dod_bomb_exploded",    Event_Bomb_Exploded,      EventHookMode_Post);
	UnhookEvent("dod_point_captured",   Event_Point_Captured,     EventHookMode_Post);
	UnhookEvent("dod_capture_blocked",  Event_Capture_Blocked,    EventHookMode_Post);

	UnhookEvent("dod_timer_time_added", Event_Time_Added,         EventHookMode_Post);

	UnhookEvent("dod_kill_planter",     Event_Kill_Planter,       EventHookMode_Post);
	UnhookEvent("dod_kill_defuser",     Event_Kill_Defuser,       EventHookMode_Post);

	UnhookEvent("dod_bomb_planted",     Event_Bomb_Planted,       EventHookMode_Post);
	UnhookEvent("dod_bomb_defused",     Event_Bomb_Defused,       EventHookMode_Post);

	UnhookEvent("dod_round_start",      Event_Round_Start,        EventHookMode_Post);
	UnhookEvent("dod_round_active",     Event_Round_Active,       EventHookMode_Post);
	UnhookEvent("dod_round_win",        Event_Round_End,          EventHookMode_Post);
	UnhookEvent("dod_game_over",        Event_Game_Over,          EventHookMode_Post);
}