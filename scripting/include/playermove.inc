#if defined _playermove_included
 #endinput
#endif
#define _playermove_included

/**
 * Called before a team's name is rendered to a client.
 * 
 * @param buffer            Buffer to store the team's name.
 * @param maxlen            Maximum length of the buffer.
 * @param client            Client's index.
 * @param identifier        Team's identifier.
 */
forward void PlayerMove_OnRenderTeamName(char[] buffer, int maxlen, int client, const char[] identifier);

/**
 * Called before a client is moved to a different team.
 * 
 * @param client         Client's index.
 * @param team           Client's new team index.
 * @param oldTeam        Client's old team index.
 * @param admin          Admin's index (0 = server).
 */
forward void PlayerMove_OnMoveClient(int client, int team, int currentTeam, int admin);

/**
 * Called when a client is moved to a different team.
 * 
 * @param client         Client's index.
 * @param team           Client's new team index.
 * @param oldTeam        Client's old team index.
 * @param admin          Admin's index (0 = server).
 */
forward void PlayerMove_OnClientMoved(int client, int team, int oldTeam, int admin);

/**
 * Adds a team to the move command.
 * 
 * @param identifier        Team's identifier.
 * @param team              Team's index.
 * @param name              Team's name.
 */
native void PlayerMove_AddTeam(const char[] identifier, int team, const char[] name);

/**
 * Removes a team from the move command.
 * 
 * @param identifier        Team's identifier.
 */
native void PlayerMove_RemoveTeam(const char[] identifier);

/* DO NOT EDIT BELOW THIS LINE */

public SharedPlugin __pl_playermove = 
{
	name = "playermove",
	file = "playermove.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_playermove_SetNTVOptional()
{
	MarkNativeAsOptional("PlayerMove_AddTeam");
	MarkNativeAsOptional("PlayerMove_RemoveTeam");
}
#endif