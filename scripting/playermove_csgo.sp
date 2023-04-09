#pragma semicolon 1
#pragma dynamic 8000
#pragma newdecls required

#include <sourcemod>
#include <cstrike>
#undef REQUIRE_PLUGIN
#include <playermove>

public Plugin myinfo =
{
    name = "Player Move - CS:GO",
    author = "Ilusion9",
    description = "Provides methods of moving players to a different team in CS:GO.",
    version = "1.0",
    url = "https://github.com/Ilusion9/"
};

#define PLUGIN_HAS_PLAYERMOVE_LIBRARY_LOADED        (1 << 0)

int g_PluginFlags;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_CSGO)
	{
		strcopy(error, err_max, "Expected CS:GO Engine");
		return APLRes_Failure;
	}
	
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("playermove_csgo.phrases");
	
	if (LibraryExists("playermove"))
	{
		g_PluginFlags |= PLUGIN_HAS_PLAYERMOVE_LIBRARY_LOADED;
	}
	
	if (view_as<bool>(g_PluginFlags & PLUGIN_HAS_PLAYERMOVE_LIBRARY_LOADED))
	{
		PlayerMove_AddTeam("t", CS_TEAM_T, "Terrorists");
		PlayerMove_AddTeam("ct", CS_TEAM_CT, "Counter-Terrorists");
	}
}

public void OnPluginEnd()
{
	if (!view_as<bool>(g_PluginFlags & PLUGIN_HAS_PLAYERMOVE_LIBRARY_LOADED))
	{
		return;
	}
	
	PlayerMove_RemoveTeam("t");
	PlayerMove_RemoveTeam("ct");
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "playermove", true))
	{
		g_PluginFlags |= PLUGIN_HAS_PLAYERMOVE_LIBRARY_LOADED;
		
		PlayerMove_AddTeam("t", CS_TEAM_T, "Terrorists");
		PlayerMove_AddTeam("ct", CS_TEAM_CT, "Counter-Terrorists");
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "playermove", true))
	{
		g_PluginFlags &= ~PLUGIN_HAS_PLAYERMOVE_LIBRARY_LOADED;
	}
}

public void PlayerMove_OnRenderTeamName(char[] buffer, int maxlen, int client, const char[] identifier)
{
	if (StrEqual(identifier, "t", true))
	{
		FormatEx(buffer, maxlen, "%T", "Terrorists", client);
	}
	else if (StrEqual(identifier, "ct", true))
	{
		FormatEx(buffer, maxlen, "%T", "Counter-Terrorists", client);
	}
}