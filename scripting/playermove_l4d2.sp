#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <playermove>

public Plugin myinfo =
{
    name = "Player Move - L4D2",
    author = "Ilusion9",
    description = "Provides methods of moving players to a different team in L4D2.",
    version = "1.0",
    url = "https://github.com/Ilusion9/"
};

#define TEAM_SURVIVORS        2
#define TEAM_INFECTED         3

#define PLUGIN_HAS_PLAYERMOVE_LIBRARY_LOADED        (1 << 0)

int g_PluginFlags;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Expected L4D2 Engine");
		return APLRes_Failure;
	}
	
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("playermove_l4d2.phrases");
	
	if (LibraryExists("playermove"))
	{
		g_PluginFlags |= PLUGIN_HAS_PLAYERMOVE_LIBRARY_LOADED;
	}
	
	if (view_as<bool>(g_PluginFlags & PLUGIN_HAS_PLAYERMOVE_LIBRARY_LOADED))
	{
		PlayerMove_AddTeam("survivors", TEAM_SURVIVORS, "Survivors");
		PlayerMove_AddTeam("infected", TEAM_INFECTED, "Infected");
	}
}

public void OnPluginEnd()
{
	if (!view_as<bool>(g_PluginFlags & PLUGIN_HAS_PLAYERMOVE_LIBRARY_LOADED))
	{
		return;
	}
	
	PlayerMove_RemoveTeam("survivors");
	PlayerMove_RemoveTeam("infected");
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "playermove", true))
	{
		g_PluginFlags |= PLUGIN_HAS_PLAYERMOVE_LIBRARY_LOADED;
		
		PlayerMove_AddTeam("survivors", TEAM_SURVIVORS, "Survivors");
		PlayerMove_AddTeam("infected", TEAM_INFECTED, "Infected");
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "playermove", true))
	{
		g_PluginFlags &= ~PLUGIN_HAS_PLAYERMOVE_LIBRARY_LOADED;
	}
}

public void PlayerMove_OnRenderTeamToClient(int client, const char[] identifier, char[] buffer, int maxlength)
{
	if (StrEqual(identifier, "survivors", true))
	{
		FormatEx(buffer, maxlength, "%T", "Survivors", client);
	}
	else if (StrEqual(identifier, "infected", true))
	{
		FormatEx(buffer, maxlength, "%T", "Infected", client);
	}
}