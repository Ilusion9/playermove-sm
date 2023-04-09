#pragma semicolon 1
#pragma dynamic 8000
#pragma newdecls required

#include <sourcemod>
#include <tf2>
#undef REQUIRE_PLUGIN
#include <playermove>

public Plugin myinfo =
{
    name = "Player Move - TF2",
    author = "Ilusion9",
    description = "Provides methods of moving players to a different team in TF2.",
    version = "1.0",
    url = "https://github.com/Ilusion9/"
};

#define PLUGIN_HAS_PLAYERMOVE_LIBRARY_LOADED        (1 << 0)

int g_PluginFlags;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_TF2)
	{
		strcopy(error, err_max, "Expected TF2 Engine");
		return APLRes_Failure;
	}
	
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("playermove_tf2.phrases");
	
	if (LibraryExists("playermove"))
	{
		g_PluginFlags |= PLUGIN_HAS_PLAYERMOVE_LIBRARY_LOADED;
	}
	
	if (view_as<bool>(g_PluginFlags & PLUGIN_HAS_PLAYERMOVE_LIBRARY_LOADED))
	{
		PlayerMove_AddTeam("red", view_as<int>(TFTeam_Red), "Team Red");
		PlayerMove_AddTeam("blue", view_as<int>(TFTeam_Blue), "Team Blue");
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
		
		PlayerMove_AddTeam("red", view_as<int>(TFTeam_Red), "Team Red");
		PlayerMove_AddTeam("blue", view_as<int>(TFTeam_Blue), "Team Blue");
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