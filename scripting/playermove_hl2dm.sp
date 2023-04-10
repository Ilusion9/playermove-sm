#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <playermove>

public Plugin myinfo =
{
    name = "Player Move - HL2:DM",
    author = "Ilusion9",
    description = "Provides methods of moving players to a different team in HL2:DM.",
    version = "1.0",
    url = "https://github.com/Ilusion9/"
};

#define TEAM_RED         2
#define TEAM_BLUE        3

#define PLUGIN_HAS_PLAYERMOVE_LIBRARY_LOADED        (1 << 0)

int g_PluginFlags;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_HL2DM)
	{
		strcopy(error, err_max, "Expected HL2:DM Engine");
		return APLRes_Failure;
	}
	
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("playermove_hl2dm.phrases");
	
	if (LibraryExists("playermove"))
	{
		g_PluginFlags |= PLUGIN_HAS_PLAYERMOVE_LIBRARY_LOADED;
	}
	
	if (view_as<bool>(g_PluginFlags & PLUGIN_HAS_PLAYERMOVE_LIBRARY_LOADED))
	{
		PlayerMove_AddTeam("red", TEAM_RED, "Team Red");
		PlayerMove_AddTeam("blue", TEAM_BLUE, "Team Blue");
	}
}

public void OnPluginEnd()
{
	if (!view_as<bool>(g_PluginFlags & PLUGIN_HAS_PLAYERMOVE_LIBRARY_LOADED))
	{
		return;
	}
	
	PlayerMove_RemoveTeam("red");
	PlayerMove_RemoveTeam("blue");
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "playermove", true))
	{
		g_PluginFlags |= PLUGIN_HAS_PLAYERMOVE_LIBRARY_LOADED;
		
		PlayerMove_AddTeam("red", TEAM_RED, "Team Red");
		PlayerMove_AddTeam("blue", TEAM_BLUE, "Team Blue");
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
	if (StrEqual(identifier, "red", true))
	{
		FormatEx(buffer, maxlength, "%T", "Team Red", client);
	}
	else if (StrEqual(identifier, "blue", true))
	{
		FormatEx(buffer, maxlength, "%T", "Team Blue", client);
	}
}