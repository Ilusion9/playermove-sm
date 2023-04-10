#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <playermove>

public Plugin myinfo =
{
    name = "Player Move - DOD:S",
    author = "Ilusion9",
    description = "Provides methods of moving players to a different team in DOD:S.",
    version = "1.0",
    url = "https://github.com/Ilusion9/"
};

#define TEAM_ALLIES        2
#define TEAM_AXIS          3

#define PLUGIN_HAS_PLAYERMOVE_LIBRARY_LOADED        (1 << 0)

int g_PluginFlags;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_DODS)
	{
		strcopy(error, err_max, "Expected DOD:S Engine");
		return APLRes_Failure;
	}
	
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("playermove_dods.phrases");
	
	if (LibraryExists("playermove"))
	{
		g_PluginFlags |= PLUGIN_HAS_PLAYERMOVE_LIBRARY_LOADED;
	}
	
	if (view_as<bool>(g_PluginFlags & PLUGIN_HAS_PLAYERMOVE_LIBRARY_LOADED))
	{
		PlayerMove_AddTeam("allies", TEAM_ALLIES, "Team Allies");
		PlayerMove_AddTeam("axis", TEAM_AXIS, "Team Axis");
	}
}

public void OnPluginEnd()
{
	if (!view_as<bool>(g_PluginFlags & PLUGIN_HAS_PLAYERMOVE_LIBRARY_LOADED))
	{
		return;
	}
	
	PlayerMove_RemoveTeam("allies");
	PlayerMove_RemoveTeam("axis");
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "playermove", true))
	{
		g_PluginFlags |= PLUGIN_HAS_PLAYERMOVE_LIBRARY_LOADED;
		
		PlayerMove_AddTeam("allies", TEAM_ALLIES, "Team Allies");
		PlayerMove_AddTeam("axis", TEAM_AXIS, "Team Axis");
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
	if (StrEqual(identifier, "allies", true))
	{
		FormatEx(buffer, maxlength, "%T", "Team Allies", client);
	}
	else if (StrEqual(identifier, "axis", true))
	{
		FormatEx(buffer, maxlength, "%T", "Team Axis", client);
	}
}