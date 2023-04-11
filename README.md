# Description
Provides methods of moving players to a different team. 
You can use forwards and natives to add teams for different games. 
The Spectators team is added by default.

# Dependencies
Sourcecolors (include file) - https://github.com/Ilusion9/sourcecolors-inc-sm

# Commands
```
sm_move <#userid|name> <team>
```

## Commands for CS:GO and CS:S
```
sm_move <#userid|name> <t|ct|spec>
```

## Commands for DOD:S
```
sm_move <#userid|name> <allies|axis|spec>
```

## Commands for HL2:DM and TF2
```
sm_move <#userid|name> <red|blue|spec>
```

# Convars
```
sm_move_no_immunity - Ignore immunity rules when moving a player to a different team?
```

# Overrides
```
sm_move_from_<team>_access
sm_move_to_<team>_access
```

## Overrides for CS:GO and CS:S
```
sm_move_from_t_access
sm_move_to_t_access
```
```
sm_move_from_ct_access
sm_move_to_ct_access
```
```
sm_move_from_spec_access
sm_move_to_spec_access
```

## Overrides for DOD:S
```
sm_move_from_allies_access
sm_move_to_allies_access
```
```
sm_move_from_axis_access
sm_move_to_axis_access
```
```
sm_move_from_spec_access
sm_move_to_spec_access
```

## Overrides for HL2:DM and TF2
```
sm_move_from_red_access
sm_move_to_red_access
```
```
sm_move_from_blue_access
sm_move_to_blue_access
```
```
sm_move_from_spec_access
sm_move_to_spec_access
```

# Forwards
```sourcepawn
/**
 * Called before a team's name is rendered to a client.
 * 
 * @param client            Client's index (0 = server).
 * @param identifier        Team's identifier.
 * @param buffer            Buffer to store the team's name.
 * @param maxlength         Maximum length of the buffer.
 */
forward void PlayerMove_OnRenderTeamToClient(int client, const char[] identifier, char[] buffer, int maxlength);

/**
 * Called before a client is moved to a different team.
 * 
 * @param client         Client's index.
 * @param team           Client's new team index.
 * @param oldTeam        Client's old team index.
 * @param admin          Admin's index (0 = server).
 */
forward void PlayerMove_OnMoveClient(int client, int team, int oldTeam, int admin);

/**
 * Called when a client is moved to a different team.
 * 
 * @param client         Client's index.
 * @param team           Client's new team index.
 * @param oldTeam        Client's old team index.
 * @param admin          Admin's index (0 = server).
 */
forward void PlayerMove_OnClientMoved(int client, int team, int oldTeam, int admin);
```

# Functions
```sourcepawn
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
```
