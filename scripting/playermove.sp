#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sourcecolors>
#undef REQUIRE_PLUGIN
#include <adminmenu>

public Plugin myinfo =
{
    name = "Player Move",
    author = "Ilusion9",
    description = "Provides methods of moving players to a different team.",
    version = "1.0",
    url = "https://github.com/Ilusion9/"
};

#define MAX_IDENTIFIER_LENGTH        64

#define MAX_ARGS_LENGTH            256
#define MAX_OVERRIDE_LENGTH        256
#define MAX_TEAM_LENGTH            256

#define TEAM_NONE             0
#define TEAM_SPECTATOR        1

#define PLUGIN_IS_LOADED_LATE                      (1 << 0)
#define PLUGIN_HAS_ADMINMENU_LIBRARY_LOADED        (1 << 1)

enum struct ArgInfo
{
	char target[MAX_TARGET_LENGTH];
	char identifier[MAX_IDENTIFIER_LENGTH];
}

enum struct MenuInfo
{
	int targetId;
}

enum struct TeamInfo
{
	int team;
	char name[MAX_TEAM_LENGTH];
}

int g_PluginFlags;
ConVar g_Cvar_MoveNoImmunity;

GlobalForward g_Forward_OnRenderTeamToClient;
GlobalForward g_Forward_OnMoveClient;
GlobalForward g_Forward_OnClientMoved;

StringMap g_Map_Teams;
TopMenu g_TopMenu;

MenuInfo g_MenuInfo[MAXPLAYERS + 1];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (late)
	{
		g_PluginFlags |= PLUGIN_IS_LOADED_LATE;
	}
	
	CreateNative("PlayerMove_AddTeam", Native_AddTeam);
	CreateNative("PlayerMove_RemoveTeam", Native_RemoveTeam);
	
	RegPluginLibrary("playermove");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("playermove.phrases");
	LoadTranslations("common.phrases");
	
	g_Cvar_MoveNoImmunity = CreateConVar("sm_move_no_immunity", "0", "Ignore immunity rules when moving a player to a different team?", FCVAR_NONE, true, 0.0, true, 1.0);
	AutoExecConfig(true, "playermove");
	
	g_Forward_OnRenderTeamToClient = CreateGlobalForward("PlayerMove_OnRenderTeamToClient", ET_Ignore, Param_Cell, Param_String, Param_String, Param_Cell);
	g_Forward_OnMoveClient = CreateGlobalForward("PlayerMove_OnMoveClient", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	g_Forward_OnClientMoved = CreateGlobalForward("PlayerMove_OnClientMoved", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	
	g_Map_Teams = new StringMap();
	
	RegAdminCmd("sm_move", Command_Move, ADMFLAG_GENERIC, "sm_move <#userid|name> <team>");
	AddTeam("spec", TEAM_SPECTATOR, "Spectators");
	
	if (LibraryExists("adminmenu"))
	{
		g_PluginFlags |= PLUGIN_HAS_ADMINMENU_LIBRARY_LOADED;
	}
	
	if (view_as<bool>(g_PluginFlags & PLUGIN_HAS_ADMINMENU_LIBRARY_LOADED) 
		&& view_as<bool>(g_PluginFlags & PLUGIN_IS_LOADED_LATE))
	{
		TopMenu topMenu = GetAdminTopMenu();
		if (topMenu)
		{
			OnAdminMenuReady(topMenu);
		}
	}
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "adminmenu", true))
	{
		g_PluginFlags |= PLUGIN_HAS_ADMINMENU_LIBRARY_LOADED;
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "adminmenu", true))
	{
		g_PluginFlags &= ~PLUGIN_HAS_ADMINMENU_LIBRARY_LOADED;
	}
}

public void OnAdminMenuReady(Handle hTopMenu)
{
	TopMenu topMenu = TopMenu.FromHandle(hTopMenu);
	if (g_TopMenu == topMenu)
	{
		return;
	}
	
	g_TopMenu = topMenu;
	TopMenuObject category = g_TopMenu.FindCategory(ADMINMENU_PLAYERCOMMANDS);
	
	if (category != INVALID_TOPMENUOBJECT)
	{
		g_TopMenu.AddItem("sm_move", AdminMenu_Move, category, "sm_move", ADMFLAG_GENERIC);
	}
}

public Action Command_Move(int client, int args)
{
	if (args < 1)
	{
		if (client 
			&& view_as<bool>(g_PluginFlags & PLUGIN_HAS_ADMINMENU_LIBRARY_LOADED) 
			&& g_TopMenu 
			&& GetCmdReplySource() == SM_REPLY_TO_CHAT)
		{
			DisplayMoveMenu(client);
		}
		else
		{
			ReplyToCommand(client, "[SM] Usage: sm_move <#userid|name> <team>");
		}
		
		return Plugin_Handled;
	}
	
	char arguments[MAX_ARGS_LENGTH];
	ArgInfo argInfo;
	
	GetCmdArgString(arguments, sizeof(arguments));
	
	int len = BreakString(arguments, argInfo.target, sizeof(ArgInfo::target));
	if (len == -1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_move <#userid|name> <team>");
		return Plugin_Handled;
	}
	
	BreakString(arguments[len], argInfo.identifier, sizeof(ArgInfo::identifier));
	
	int target = FindTarget_Ex(client, argInfo.target, g_Cvar_MoveNoImmunity.BoolValue ? COMMAND_FILTER_NO_IMMUNITY : 0);
	if (target == -1)
	{
		return Plugin_Handled;
	}
	
	PerformMove(client, target, argInfo.identifier, GetCmdReplySource());
	return Plugin_Handled;
}

public void AdminMenu_Move(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		FormatEx(buffer, maxlength, "%T", "Move player", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		DisplayMoveMenu(param);
	}
}

public int Menu_Move(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack 
			&& view_as<bool>(g_PluginFlags & PLUGIN_HAS_ADMINMENU_LIBRARY_LOADED) 
			&& g_TopMenu)
		{
			TopMenuObject category = g_TopMenu.FindCategory(ADMINMENU_PLAYERCOMMANDS);
			if (category != INVALID_TOPMENUOBJECT)
			{
				g_TopMenu.DisplayCategory(category, param1);
			}
		}
	}
	else if (action == MenuAction_Select)
	{
		char arg[MAX_TARGET_LENGTH];
		menu.GetItem(param2, arg, sizeof(arg));
		
		int userId = StringToInt(arg);
		int target = GetClientOfUserId(userId);
		
		if (!target)
		{
			PrintToChat(param1, "[SM] %t", "Player no longer available");
			return 0;
		}
		
		if (!IsClientInGame(target))
		{
			PrintToChat(param1, "[SM] %t", "Target is not in game");
			return 0;
		}
		
		if (!CanUserTarget(param1, target))
		{
			PrintToChat(param1, "[SM] %t", "Unable to target");
			return 0;
		}
		
		g_MenuInfo[param1].targetId = userId;
		DisplayMoveTeamMenu(param1, target);
	}
	
	return 0;
}

public int Menu_MoveTeam(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack 
			&& view_as<bool>(g_PluginFlags & PLUGIN_HAS_ADMINMENU_LIBRARY_LOADED) 
			&& g_TopMenu)
		{
			TopMenuObject category = g_TopMenu.FindCategory(ADMINMENU_PLAYERCOMMANDS);
			if (category != INVALID_TOPMENUOBJECT)
			{
				g_TopMenu.DisplayCategory(category, param1);
			}
		}
	}
	else if (action == MenuAction_Select)
	{
		int target = GetClientOfUserId(g_MenuInfo[param1].targetId);
		if (!target)
		{
			PrintToChat(param1, "[SM] %t", "Player no longer available");
			return 0;
		}
		
		if (!IsClientInGame(target))
		{
			PrintToChat(param1, "[SM] %t", "Target is not in game");
			return 0;
		}
		
		if (!CanUserTarget(param1, target))
		{
			PrintToChat(param1, "[SM] %t", "Unable to target");
			return 0;
		}
		
		char arg[MAX_IDENTIFIER_LENGTH];
		menu.GetItem(param2, arg, sizeof(arg));
		
		PerformMove(param1, target, arg, SM_REPLY_TO_CHAT);
	}
	
	return 0;
}

void OnRenderTeamToClient(int client, const char[] identifier, char[] buffer, int maxlength)
{
	if (StrEqual(identifier, "spec", true))
	{
		FormatEx(buffer, maxlength, "%T", "Spectators", client);
		return;
	}
	
	Call_StartForward(g_Forward_OnRenderTeamToClient);
	Call_PushCell(client);
	Call_PushString(identifier);
	Call_PushStringEx(buffer, maxlength, SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushCell(maxlength);
	Call_Finish();
}

void AddTeam(const char[] identifier, int team, const char[] name)
{
	TeamInfo teamInfo;
	teamInfo.team = team;
	
	strcopy(teamInfo.name, sizeof(TeamInfo::name), name);
	g_Map_Teams.SetArray(identifier, teamInfo, sizeof(TeamInfo));
}

void DisplayMoveMenu(int client)
{
	Menu menu = new Menu(Menu_Move);
	menu.SetTitle("%T", "Move player param", client, "");
	
	AddTargetsToMenu2(menu, client, g_Cvar_MoveNoImmunity.BoolValue ? COMMAND_FILTER_NO_IMMUNITY : 0);
	
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

void DisplayMoveTeamMenu(int client, int target)
{
	char identifier[MAX_IDENTIFIER_LENGTH];
	char targetName[MAX_NAME_LENGTH];
	char teamName[MAX_TEAM_LENGTH];
	
	Menu menu = new Menu(Menu_MoveTeam);
	StringMapSnapshot snapshot = g_Map_Teams.Snapshot();
	
	TeamInfo teamInfo;
	
	GetClientName(target, targetName, sizeof(targetName));
	menu.SetTitle("%T\n%T", "Move player param", client, targetName, "Team param", client, "");
	
	for (int i = 0; i < snapshot.Length; i++)
	{
		snapshot.GetKey(i, identifier, sizeof(identifier));
		g_Map_Teams.GetArray(identifier, teamInfo, sizeof(TeamInfo));
		
		strcopy(teamName, sizeof(teamName), teamInfo.name);
		OnRenderTeamToClient(client, identifier, teamName, sizeof(teamName));
		
		CRemoveTags(teamName, sizeof(teamName));
		menu.AddItem(identifier, teamName);
	}
	
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
	
	delete snapshot;
}

void PerformMove(int client, int target, char[] identifier, ReplySource replySource)
{
	TeamInfo teamInfo;
	if (!g_Map_Teams.GetArray(identifier, teamInfo, sizeof(TeamInfo)))
	{
		ReplySource currentSource = SetCmdReplySource(replySource);
		CReplyToCommand(client, "[SM] %t", "Invalid team specified");
		SetCmdReplySource(currentSource);
		
		return;
	}
	
	int oldTeam = GetClientTeam(target);
	if (teamInfo.team == oldTeam)
	{
		ReplySource currentSource = SetCmdReplySource(replySource);
		CReplyToCommand(client, "[SM] %t", "Player already on team", teamInfo.name);
		SetCmdReplySource(currentSource);
		
		return;
	}
	
	char fromOverride[MAX_OVERRIDE_LENGTH];
	FormatEx(fromOverride, sizeof(fromOverride), "sm_move_from_%s_access", identifier);
	
	if (!CheckCommandAccess(client, fromOverride, ADMFLAG_GENERIC, true))
	{
		ReplySource currentSource = SetCmdReplySource(replySource);
		CReplyToCommand(client, "[SM] %t", "No access to move players from team", teamInfo.name);
		SetCmdReplySource(currentSource);
		
		return;
	}
	
	char toOverride[MAX_OVERRIDE_LENGTH];
	FormatEx(toOverride, sizeof(toOverride), "sm_move_to_%s_access", identifier);
	
	if (!CheckCommandAccess(client, toOverride, ADMFLAG_GENERIC, true))
	{
		ReplySource currentSource = SetCmdReplySource(replySource);
		CReplyToCommand(client, "[SM] %t", "No access to move players to team", teamInfo.name);
		SetCmdReplySource(currentSource);
		
		return;
	}
	
	Call_StartForward(g_Forward_OnMoveClient);
	Call_PushCell(target);
	Call_PushCell(teamInfo.team);
	Call_PushCell(oldTeam);
	Call_PushCell(client);
	Call_Finish();
	
	char teamName[MAX_TEAM_LENGTH];
	char targetName[MAX_NAME_LENGTH];
	
	GetClientName(target, targetName, sizeof(targetName));
	LogAction(client, target, "\"%L\" moved \"%L\" (team \"%s\")", client, target, teamInfo.name);
	
	for (int i = 0; i <= MaxClients; i++)
	{
		if (i && !IsClientConnected(i))
		{
			continue;
		}
		
		strcopy(teamName, sizeof(teamName), teamInfo.name);
		OnRenderTeamToClient(i, identifier, teamName, sizeof(teamName));
		
		CSetChatTextParams(target);
		CShowActivityToTarget(client, i, "[SM]\x04 ", "\x01%t", "Moved player", targetName, teamName);
	}
	
	if (IsPlayerAlive(target))
	{
		ForcePlayerSuicide(target);
	}
	
	ChangeClientTeam(target, teamInfo.team);
	
	Call_StartForward(g_Forward_OnClientMoved);
	Call_PushCell(target);
	Call_PushCell(teamInfo.team);
	Call_PushCell(oldTeam);
	Call_PushCell(client);
	Call_Finish();
}

void CShowActivityToTarget(int client, int target, const char[] tag, const char[] format, any ...)
{
	int author;
	bool setParams = CGetChatTextParams(author);
	
	char name[MAX_NAME_LENGTH];
	char buffer[SOURCECOLORS_MAX_MESSAGE_LENGTH];
	
	if (client == target)
	{
		SetGlobalTransTarget(client);
		
		VFormat(buffer, sizeof(buffer), format, 5);
		Format(buffer, sizeof(buffer), "%s%s", tag, buffer);
		
		if (client)
		{
			if (setParams)
			{
				CSetChatTextParams(author);
			}
			
			CPrintToChat(client, buffer);
		}
		
		CRemoveTags(buffer, sizeof(buffer));
		PrintToConsole(client, buffer);
	}
	else if (target && FormatActivitySource(client, target, name, sizeof(name)))
	{
		SetGlobalTransTarget(target);
		VFormat(buffer, sizeof(buffer), format, 5);
		
		if (setParams)
		{
			CSetChatTextParams(author);
		}
		
		CPrintToChat(target, "%s%s: %s", tag, name, buffer);
	}
	
	if (setParams)
	{
		CResetChatTextParams();
	}
}

int FindTarget_Ex(int client, const char[] target, int flags = 0)
{
	bool isTargetNameML;
	
	int targetCount;
	int targetList[1];
	
	char targetName[MAX_NAME_LENGTH];
	
	if ((targetCount = ProcessTargetString(target, client, targetList, sizeof(targetList), flags | COMMAND_FILTER_NO_MULTI, targetName, sizeof(targetName), isTargetNameML)) > 0)
	{
		return targetList[0];
	}
	
	ReplyToTargetError(client, targetCount);
	return -1;
}

public any Native_AddTeam(Handle plugin, int numParams)
{
	char identifier[MAX_IDENTIFIER_LENGTH];
	char teamName[MAX_TEAM_LENGTH];
	
	GetNativeString(1, identifier, sizeof(identifier));
	GetNativeString(3, teamName, sizeof(teamName));
	
	AddTeam(identifier, GetNativeCell(2), teamName);
	return 0;
}

public any Native_RemoveTeam(Handle plugin, int numParams)
{
	char identifier[MAX_IDENTIFIER_LENGTH];
	GetNativeString(1, identifier, sizeof(identifier));
	
	g_Map_Teams.Remove(identifier);
	return 0;
}