#include <amxmodx>
#include <reapi>
#include <cstrike>

#define PLUGIN_NAME    "Simple GunGame"
#define PLUGIN_VERSION "0.7.1"
#define PLUGIN_AUTHOR  "ToRRent"

#define TASK_RESPAWN  500
#define TASK_GRENADE  600

// cheapest to most expensive
new const g_PresetPriceAsc[] =
{
    CSW_GLOCK18, CSW_USP, CSW_P228, CSW_FIVESEVEN, CSW_ELITE, CSW_DEAGLE,
    CSW_TMP, CSW_MAC10, CSW_MP5NAVY, CSW_UMP45, CSW_P90,
    CSW_M3, CSW_XM1014,
    CSW_GALIL, CSW_FAMAS, CSW_AK47, CSW_M4A1, CSW_AUG, CSW_SG552,
    CSW_M249,
    CSW_SCOUT, CSW_SG550, CSW_G3SG1, CSW_AWP,
    CSW_HEGRENADE, CSW_KNIFE
}

// most expensive to cheapest
new const g_PresetPriceDesc[] =
{
    CSW_AWP, CSW_G3SG1, CSW_SG550, CSW_SCOUT, CSW_M249,
    CSW_SG552, CSW_AUG, CSW_M4A1, CSW_AK47, CSW_FAMAS, CSW_GALIL,
    CSW_XM1014, CSW_M3,
    CSW_P90, CSW_UMP45, CSW_MP5NAVY, CSW_MAC10, CSW_TMP,
    CSW_DEAGLE, CSW_ELITE, CSW_FIVESEVEN, CSW_P228, CSW_USP, CSW_GLOCK18,
    CSW_HEGRENADE, CSW_KNIFE
}

// class ascending
new const g_PresetClassic[] =
{
    CSW_GLOCK18, CSW_USP, CSW_P228, CSW_FIVESEVEN, CSW_ELITE, CSW_DEAGLE,
    CSW_M3, CSW_XM1014,
    CSW_TMP, CSW_MAC10, CSW_MP5NAVY, CSW_UMP45, CSW_P90,
    CSW_GALIL, CSW_FAMAS, CSW_AK47, CSW_M4A1, CSW_AUG, CSW_SG552,
    CSW_M249,
    CSW_SCOUT, CSW_SG550, CSW_G3SG1, CSW_AWP,
    CSW_HEGRENADE, CSW_KNIFE
}

// class descending
new const g_PresetClassicReverse[] =
{
    CSW_AWP, CSW_G3SG1, CSW_SG550, CSW_SCOUT, CSW_M249,
    CSW_SG552, CSW_AUG, CSW_M4A1, CSW_AK47, CSW_FAMAS, CSW_GALIL,
    CSW_P90, CSW_UMP45, CSW_MP5NAVY, CSW_MAC10, CSW_TMP,
    CSW_XM1014, CSW_M3,
    CSW_DEAGLE, CSW_ELITE, CSW_FIVESEVEN, CSW_P228, CSW_USP, CSW_GLOCK18,
    CSW_HEGRENADE, CSW_KNIFE
}

new g_weaponList[32]
new g_weaponCount

new g_points[33]
new g_level[33]
new g_deaths[33]

new g_syncScoreboardHud
new g_syncPlayerHud

new g_CvarXpNeeded
new g_CvarHightierXp
new g_CvarKnifeSteal
new g_CvarFF
new WeaponPreset:g_currentPreset
new bool:g_voteStarted
new bool:g_matchWon

new g_old_buytime
new g_old_immunitytime
new g_old_immunityeffects
new g_old_immunityunset
new g_old_give_c4
new g_old_map_weapons
new g_old_free_armor
new g_old_round_infinite
new g_old_timelimit

native csr_custom_win();
native csr_add_score(id, score);
native csr_get_score(id);

public plugin_init()
{
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)

    SaveServerCvars()

    g_CvarXpNeeded    = register_cvar("gg_xp_needed",        "2")
    g_CvarHightierXp  = register_cvar("gg_hightier_xp_needed","5")
    g_CvarKnifeSteal  = register_cvar("gg_knife_steal",       "1")
    g_CvarFF          = get_cvar_pointer("mp_friendlyfire")

    RegisterHookChain(RG_CBasePlayer_Spawn,  "PlayerSpawn_Post",  true)
    RegisterHookChain(RG_CBasePlayer_Killed, "PlayerKilled_Post", true)
    RegisterHookChain(RG_CBasePlayer_ThrowGrenade,       "OnGrenadeThrown", false)
    RegisterHookChain(RG_CBasePlayerWeapon_DefaultDeploy, "OnWeaponDeploy",  false)
    register_logevent("Server_Restart",2,"1&Restart_Round_","1=Game_Commencing")

    g_syncScoreboardHud = CreateHudSyncObj()
    g_syncPlayerHud = CreateHudSyncObj()

    set_task(1.0, "Task_ShowTop", _, _, _, "b")
    set_task(1.0, "Task_ShowPlayerHUD", _, _, _, "b")

    g_currentPreset = WeaponPreset:0

    register_menucmd(register_menuid("gg_tutorial"), MENU_KEY_0, "Menu_TutorialClose")
}

public plugin_precache()
{
    precache_sound("buttons/bell1.wav")
    precache_sound("gungame/smb3_powerup.wav")
    precache_sound("gungame/smb3_powerdown.wav")

    precache_model("models/v_cobraknife.mdl")
    precache_sound("weapons/deltaforce/cobraknife/knife_deploy.wav")
    precache_sound("weapons/deltaforce/cobraknife/knife_swing_01.wav")
    precache_sound("weapons/deltaforce/cobraknife/knife_swing_miss_01.wav")
    precache_sound("weapons/deltaforce/cobraknife/melee_knife_01.wav")
    precache_sound("weapons/deltaforce/cobraknife/melee_knife_02.wav")
}

IsValidMap()
{
    new mapname[5]
    get_mapname(mapname, charsmax(mapname))

    return (strncmp(mapname, "gg_", 3) == 0
         || strncmp(mapname, "dm_", 3) == 0
         || strncmp(mapname, "fy_", 3) == 0)
}

public plugin_cfg()
{
    if(!IsValidMap())
    {
        log_amx("[GunGame] Map does not match gg_/dm_/fy_ - plugin disabled.")
        pause("a")
        return
    }

    g_currentPreset = WeaponPreset:random_num(0, 3)
    BuildWeaponPreset(g_currentPreset)
    ApplyGunGameCvars()
}

public plugin_end()
{
    RestoreServerCvars()
}

public Server_Restart()
{
    ResetAllPlayers()
    set_task(4.0, "Task_ResetData")
}

public Task_ResetData()
{
    for(new i = 1; i <= MaxClients; i++)
    {
        if(!is_user_connected(i))
            continue

            g_points[i] = 0
            g_level[i]  = 0
            g_deaths[i] = 0
    }
}

SaveServerCvars()
{
    g_old_buytime          = get_cvar_num("mp_buytime")
    g_old_immunitytime     = get_cvar_num("mp_respawn_immunitytime")
    g_old_immunityeffects  = get_cvar_num("mp_respawn_immunity_effects")
    g_old_immunityunset    = get_cvar_num("mp_respawn_immunity_force_unset")
    g_old_give_c4          = get_cvar_num("mp_give_player_c4")
    g_old_map_weapons      = get_cvar_num("mp_weapons_allow_map_placed")
    g_old_free_armor       = get_cvar_num("mp_free_armor")
    g_old_round_infinite   = get_cvar_num("mp_round_infinite")
    g_old_timelimit        = get_cvar_num("mp_timelimit")
}

ApplyGunGameCvars()
{
    set_cvar_num("mp_buytime",                     0)  // No buying
    set_cvar_num("mp_timelimit",                   360)  // timelimit
    set_cvar_num("mp_round_infinite",              1)  // No round time limit
    set_cvar_num("mp_respawn_immunitytime",        2)  // 2s spawn protection duration
    set_cvar_num("mp_respawn_immunity_effects",    1)  // Visual immunity effect enabled
    set_cvar_num("mp_respawn_immunity_force_unset",2)  // Remove immunity when player attacks
    set_cvar_num("mp_give_player_c4",              0)  // Disable bomb — disables bomb objective
    set_cvar_num("mp_weapons_allow_map_placed",    0)  // No picking up weapons from ground
    set_cvar_num("mp_free_armor",                  2)  // Full armor + helmet on every spawn

}

RestoreServerCvars()
{
    set_cvar_num("mp_buytime",                     g_old_buytime)
    set_cvar_num("mp_timelimit",                   g_old_timelimit)
    set_cvar_num("mp_round_infinite",              g_old_round_infinite)
    set_cvar_num("mp_respawn_immunitytime",        g_old_immunitytime)
    set_cvar_num("mp_respawn_immunity_effects",    g_old_immunityeffects)
    set_cvar_num("mp_respawn_immunity_force_unset",g_old_immunityunset)
    set_cvar_num("mp_give_player_c4",              g_old_give_c4)
    set_cvar_num("mp_weapons_allow_map_placed",    g_old_map_weapons)
    set_cvar_num("mp_free_armor",                  g_old_free_armor)
}

BuildWeaponPreset(WeaponPreset:preset)
{
    g_weaponCount = 0

    switch(preset)
    {
        case 0:
        {
            g_weaponCount = sizeof(g_PresetPriceAsc)
            for(new i = 0; i < g_weaponCount; i++)
                g_weaponList[i] = g_PresetPriceAsc[i]
        }
        case 1:
        {
            g_weaponCount = sizeof(g_PresetPriceDesc)
            for(new i = 0; i < g_weaponCount; i++)
                g_weaponList[i] = g_PresetPriceDesc[i]
        }
        case 2:
        {
            g_weaponCount = sizeof(g_PresetClassic)
            for(new i = 0; i < g_weaponCount; i++)
                g_weaponList[i] = g_PresetClassic[i]
        }
        case 3:
        {
            g_weaponCount = sizeof(g_PresetClassicReverse)
            for(new i = 0; i < g_weaponCount; i++)
                g_weaponList[i] = g_PresetClassicReverse[i]
        }
    }
}

public client_putinserver(id)
{
    g_points[id] = 0
    g_level[id]  = GetWorstPlayerLevel(id)
    g_deaths[id] = 0

    set_task(3.0, "Task_ShowTutorial", id)
}

public Task_ShowTutorial(id)
{
    if(!is_user_connected(id))
        return

    new menutext[256]

    if(get_pcvar_num(g_CvarKnifeSteal))
        formatex(menutext, 255, "\yWelcome to Simple GunGame\w^n^n\y1 Kill\w = \r1 XP^n\y1 Headshot\w = \r2 XP^n\yKnife Kill\w = \rSteal 1 XP^n\yHandicap\w = \r5 Deaths = 1 XP^n^n\r0. \wClose")
    else
        formatex(menutext, 255, "\yWelcome to Simple GunGame\w^n^n\y1 Kill\w = \r1 XP^n\y1 Headshot\w = \r2 XP^n\yHandicap\w = \r5 Deaths = 1 XP^n^n\r0. \wClose")

    show_menu(id, MENU_KEY_0, menutext, -1, "gg_tutorial")
}

public Menu_TutorialClose(id, key)
{
    return PLUGIN_HANDLED
}

GetWorstPlayerLevel(exclude)
{
    new worst = 999

    for(new i = 1; i <= MaxClients; i++)
    {
        if(i == exclude || !is_user_connected(i))
            continue

        if(g_level[i] < worst)
            worst = g_level[i]
    }

    return (worst == 999) ? 0 : worst
}

public PlayerSpawn_Post(id)
{
    if(!is_user_alive(id))
        return

    GiveLevelWeapon(id)
}

GiveLevelWeapon(id)
{
    rg_remove_all_items(id)

    new weapon = g_weaponList[g_level[id]]

    if(weapon == CSW_HEGRENADE)
    {
        rg_give_item(id, "weapon_hegrenade", GT_APPEND)
    }
    else if(weapon != CSW_KNIFE)
    {
        new entname[32]
        WeaponEntityName(weapon, entname, 31)
        rg_give_item(id, entname, GT_APPEND)
    }

    rg_give_item(id, "weapon_knife", GT_APPEND)
}

public Task_ShowPlayerHUD()
{
    new players[32], num
    get_players(players, num, "a")

    new wname[16]

    for(new i = 0; i < num; i++)
    {
        new id = players[i]

        WeaponDisplayName(g_weaponList[g_level[id]], wname, charsmax(wname))

        set_hudmessage(255, 200, 0, -1.0, 0.75, 0, 0.0, 1.1, 0.0, 0.1)
        if(g_weaponList[g_level[id]] == CSW_KNIFE) ShowSyncHudMsg(id, g_syncPlayerHud, "FINAL KNIFE  |  1 KILL TO WIN  |  TOP %d",  GetPlayerRank(id))
        else ShowSyncHudMsg(id, g_syncPlayerHud, "LVL %d/%d  -  %s  |  XP %d/%d  |  TOP %d", g_level[id] + 1, g_weaponCount, wname, g_points[id], GetNeededPoints(id), GetPlayerRank(id))
    }
}


GetPlayerRank(id)
{
    new rank = 1

    for(new i = 1; i <= MaxClients; i++)
    {
        if(i == id || !is_user_connected(i))
            continue

        if(g_level[i] > g_level[id])
            rank++
    }

    return rank
}

public PlayerKilled_Post(victim, attacker)
{
    if(g_matchWon)
        return

    if(is_user_connected(victim))
    {
        remove_task(victim + TASK_RESPAWN)
        set_task(2.0, "Task_Respawn", victim + TASK_RESPAWN)
    }

    if(!is_user_connected(attacker))
        return

    if(attacker == victim)
    {
        g_points[attacker]--
        CheckLevelDown(attacker)
        return
    }

    if(cs_get_user_team(attacker) == cs_get_user_team(victim) && get_pcvar_num(g_CvarFF) == 1)
    {
        g_points[attacker]--
        CheckLevelDown(attacker)
        return
    }

    new weapon = get_user_weapon(attacker)
    new bool:headshot = bool:get_member(victim, m_bHeadshotKilled)

    if(weapon == CSW_KNIFE)
    {
        if(get_pcvar_num(g_CvarKnifeSteal))
        {
            g_points[victim]--
            CheckLevelDown(victim)
        }

        g_points[attacker]++
    }
    else if(headshot)
        g_points[attacker] += 2
    else
        g_points[attacker]++

    client_cmd(attacker, "spk buttons/bell1.wav")
    CheckLevelUp(attacker)

    g_deaths[victim]++

    if(g_deaths[victim] % 5 == 0 && g_weaponList[g_level[victim]] != CSW_KNIFE)
    {
        g_points[victim]++
        CheckLevelUp(victim)
    }
}

public OnGrenadeThrown(id)
{
    if(!is_user_connected(id) || !is_user_alive(id))
        return

    if(g_weaponList[g_level[id]] != CSW_HEGRENADE)
        return

    remove_task(id + TASK_GRENADE)
    set_task(2.0, "Task_ReplenishGrenade", id + TASK_GRENADE)
}

public Task_ReplenishGrenade(taskid)
{
    new id = taskid - TASK_GRENADE

    if(!is_user_connected(id) || !is_user_alive(id))
        return

    if(g_weaponList[g_level[id]] != CSW_HEGRENADE)
        return

    rg_give_item(id, "weapon_hegrenade", GT_APPEND)
}

public Task_Respawn(taskid)
{
    new id = taskid - TASK_RESPAWN

    if(!is_user_connected(id) || is_user_alive(id))
        return

    rg_round_respawn(id)
}

IsHighTierWeapon(csw)
{
    return (csw == CSW_DEAGLE
         || csw == CSW_AK47
         || csw == CSW_M4A1
         || csw == CSW_FAMAS
         || csw == CSW_AWP)
}

GetNeededPoints(id)
{
    new weapon = g_weaponList[g_level[id]]

    if(weapon == CSW_KNIFE)
        return 1

    if(IsHighTierWeapon(weapon))
        return get_pcvar_num(g_CvarHightierXp)

    return get_pcvar_num(g_CvarXpNeeded)
}

CheckLevelUp(id)
{
    new needed = GetNeededPoints(id)

    if(g_points[id] < needed)
        return

    g_points[id] = 0
    g_deaths[id] = 0
    g_level[id]++
    client_cmd(id, "spk gungame/smb3_powerup.wav")
    new playername[32]
    get_user_name(id, playername, 31)
    if(g_weaponList[g_level[id]] == CSW_KNIFE) client_print_color(0, print_team_default, "^4[GunGame]^1 ^3%s^1 is on final level!", playername)

    CheckLeaderForVote()

    if(g_level[id] >= g_weaponCount)
    {
        new name[32]
        get_user_name(id, name, 31)

        for(new i = 1; i <= MaxClients; i++)
        {
            if(is_user_connected(i) && LibraryExists("csr", LibType_Library))
                csr_add_score(i, g_level[i]*100)
            if(is_user_alive(i))
            {
                rg_remove_all_items(i)
                rg_give_item(i, "weapon_knife", GT_APPEND)
            }
        }

        client_print_color(0, print_team_default,
            "^4[GunGame]^1 ^3%s^1 won the match with the final knife kill!", name)

        g_matchWon = true
        FinishTheMap()

        return
    }

    if(is_user_alive(id))
        GiveLevelWeapon(id)
}

CheckLevelDown(id)
{
    if(g_points[id] >= 0)
        return

    g_points[id] = 0
    g_deaths[id] = 0
    g_level[id]--
    client_cmd(id, "spk gungame/smb3_powerdown.wav")

    if(is_user_alive(id))
        GiveLevelWeapon(id)
}

ResetAllPlayers()
{
    for(new i = 1; i <= MaxClients; i++)
    {
        if(!is_user_connected(i))
            continue

        g_points[i] = 0
        g_level[i]  = 0
        g_deaths[i] = 0
    }

    g_voteStarted   = false
    g_matchWon      = false
    g_currentPreset = WeaponPreset:random_num(0, 3)
    BuildWeaponPreset(g_currentPreset)
}

TriggerMapVote()
{
    new plugin
    new oldWinLimit
    new oldMaxRounds

    plugin = is_plugin_loaded("Galileo")
    if(plugin == -1) plugin = is_plugin_loaded("Galileo - Multi Map Vote")

    if(plugin != -1)
    {
        log_amx("[GunGame] Triggering vote via Galileo")
        server_cmd("gal_startvote -nochange")
        return
    }

    plugin = is_plugin_loaded("Nextmap Chooser")
    if(plugin != -1)
    {
        log_amx("[GunGame] Triggering vote via mapchooser.amxx")

        oldWinLimit  = get_cvar_num("mp_winlimit")
        oldMaxRounds = get_cvar_num("mp_maxrounds")

        set_cvar_num("mp_winlimit",  0)
        set_cvar_num("mp_maxrounds", -1)

        if(callfunc_begin_i(get_func_id("voteNextmap", plugin), plugin) == 1)
            callfunc_end()

        set_cvar_num("mp_winlimit",  oldWinLimit)
        set_cvar_num("mp_maxrounds", oldMaxRounds)
        return
    }

    plugin = is_plugin_loaded("Nextmap Chooser 4")
    if(plugin != -1)
    {
        log_amx("[GunGame] Triggering vote via Nextmap Chooser 4")

        oldWinLimit  = get_cvar_num("mp_winlimit")
        oldMaxRounds = get_cvar_num("mp_maxrounds")

        set_cvar_num("mp_winlimit",  0)
        set_cvar_num("mp_maxrounds", 1)

        if(callfunc_begin_i(get_func_id("buyFinished", plugin), plugin) == 1)
            callfunc_end()

        if(callfunc_begin_i(get_func_id("voteNextmap", plugin), plugin) == 1)
        {
            callfunc_push_str("", false)
            callfunc_end()
        }

        set_cvar_num("mp_winlimit",  oldWinLimit)
        set_cvar_num("mp_maxrounds", oldMaxRounds)
        return
    }
}

CheckLeaderForVote()
{
    if(g_voteStarted)
        return

    for(new i = 1; i <= MaxClients; i++)
    {
        if(!is_user_connected(i))
            continue

        if(g_level[i] >= g_weaponCount - 6)
        {
            g_voteStarted = true
            TriggerMapVote()
            break
        }
    }
}

public Task_ShowTop()
{
    new players[32], num
    get_players(players, num)

    new top[5]
    top[0] = top[1] = top[2] = top[3] = top[4] = 0

    for(new i = 0; i < num; i++)
    {
        new id = players[i]

        if(!top[0] || g_level[id] > g_level[top[0]])
        {
            top[4] = top[3]; top[3] = top[2]; top[2] = top[1]; top[1] = top[0]; top[0] = id
        }
        else if(!top[1] || g_level[id] > g_level[top[1]])
        {
            top[4] = top[3]; top[3] = top[2]; top[2] = top[1]; top[1] = id
        }
        else if(!top[2] || g_level[id] > g_level[top[2]])
        {
            top[4] = top[3]; top[3] = top[2]; top[2] = id
        }
        else if(!top[3] || g_level[id] > g_level[top[3]])
        {
            top[4] = top[3]; top[3] = id
        }
        else if(!top[4] || g_level[id] > g_level[top[4]])
        {
            top[4] = id
        }
    }

    // Build base lines (no highlight)
    new line[5][64]
    new wname[16]
    new pname[16]

    for(new s = 0; s < 5; s++)
    {
        if(!top[s] || !is_user_connected(top[s]))
        {
            formatex(line[s], 63, "%d. ---", s + 1)
        }
        else
        {
            get_user_name(top[s], pname, 15)
            WeaponDisplayName(g_weaponList[g_level[top[s]]], wname, 15)
            formatex(line[s], 63, "%d. %s - %s - LVL %d", s + 1, pname, wname, g_level[top[s]] + 1)
        }
    }

    // Send per-player so we can prefix the viewer's own slot
    new text[386]
    new myline[5][64]

    for(new p = 0; p < num; p++)
    {
        new viewer = players[p]

        for(new s = 0; s < 5; s++)
        {
            if(top[s] == viewer)
                formatex(myline[s], 63, "        %s", line[s])
            else
                copy(myline[s], 63, line[s])
        }

        formatex(text, 385, "-- RANKING --^n%s^n%s^n%s^n%s^n%s",
            myline[0], myline[1], myline[2], myline[3], myline[4])

        set_hudmessage(255, 200, 0, 0.01, 0.18, 0, 0.0, 1.1, 0.0, 0.1, -1)
        ShowSyncHudMsg(viewer, g_syncScoreboardHud, text)
    }
}

public FinishTheMap()
{
    if(LibraryExists("csr", LibType_Library)) csr_custom_win()
    ResetAllPlayers()
    set_cvar_float("mp_timelimit", 0.01)
    set_task(10.0, "Task_RestoreCvars")
}

public Task_RestoreCvars()
{
    set_cvar_num("mp_timelimit", g_old_timelimit)
}

public OnWeaponDeploy(weaponEnt)
{
    if(get_member(weaponEnt, m_iId) != CSW_KNIFE)
        return HC_CONTINUE

    new id = get_member(weaponEnt, m_pPlayer)

    if(id < 1 || id > MaxClients)
        return HC_CONTINUE

    if(g_weaponList[g_level[id]] != CSW_KNIFE)
        return HC_CONTINUE

    SetHookChainArg(2, ATYPE_STRING, "models/v_cobraknife.mdl")

    return HC_CONTINUE
}

WeaponDisplayName(csw, name[], len)
{
    switch(csw)
    {
        case CSW_GLOCK18:   copy(name, len, "Glock")
        case CSW_USP:       copy(name, len, "USP")
        case CSW_P228:      copy(name, len, "P228")
        case CSW_DEAGLE:    copy(name, len, "Deagle")
        case CSW_FIVESEVEN: copy(name, len, "Five-Seven")
        case CSW_ELITE:     copy(name, len, "Berettas")
        case CSW_M3:        copy(name, len, "M3")
        case CSW_XM1014:    copy(name, len, "XM1014")
        case CSW_TMP:       copy(name, len, "TMP")
        case CSW_MAC10:     copy(name, len, "MAC10")
        case CSW_MP5NAVY:   copy(name, len, "MP5")
        case CSW_UMP45:     copy(name, len, "UMP45")
        case CSW_P90:       copy(name, len, "P90")
        case CSW_FAMAS:     copy(name, len, "Famas")
        case CSW_GALIL:     copy(name, len, "Galil")
        case CSW_AK47:      copy(name, len, "AK-47")
        case CSW_M4A1:      copy(name, len, "M4A1")
        case CSW_AUG:       copy(name, len, "AUG")
        case CSW_SG552:     copy(name, len, "SG-552")
        case CSW_SG550:     copy(name, len, "SG-550")
        case CSW_G3SG1:     copy(name, len, "G3SG1")
        case CSW_SCOUT:     copy(name, len, "Scout")
        case CSW_AWP:       copy(name, len, "AWP")
        case CSW_M249:      copy(name, len, "M249")
        case CSW_HEGRENADE: copy(name, len, "Grenade")
        case CSW_KNIFE:     copy(name, len, "Knife")
        default:            copy(name, len, "WINNER")
    }
}

WeaponEntityName(csw, ent[], len)
{
    switch(csw)
    {
        case CSW_GLOCK18:   copy(ent, len, "weapon_glock18")
        case CSW_USP:       copy(ent, len, "weapon_usp")
        case CSW_P228:      copy(ent, len, "weapon_p228")
        case CSW_DEAGLE:    copy(ent, len, "weapon_deagle")
        case CSW_FIVESEVEN: copy(ent, len, "weapon_fiveseven")
        case CSW_ELITE:     copy(ent, len, "weapon_elite")
        case CSW_M3:        copy(ent, len, "weapon_m3")
        case CSW_XM1014:    copy(ent, len, "weapon_xm1014")
        case CSW_TMP:       copy(ent, len, "weapon_tmp")
        case CSW_MAC10:     copy(ent, len, "weapon_mac10")
        case CSW_MP5NAVY:   copy(ent, len, "weapon_mp5navy")
        case CSW_UMP45:     copy(ent, len, "weapon_ump45")
        case CSW_P90:       copy(ent, len, "weapon_p90")
        case CSW_FAMAS:     copy(ent, len, "weapon_famas")
        case CSW_GALIL:     copy(ent, len, "weapon_galil")
        case CSW_AK47:      copy(ent, len, "weapon_ak47")
        case CSW_M4A1:      copy(ent, len, "weapon_m4a1")
        case CSW_AUG:       copy(ent, len, "weapon_aug")
        case CSW_SG552:     copy(ent, len, "weapon_sg552")
        case CSW_SG550:     copy(ent, len, "weapon_sg550")
        case CSW_G3SG1:     copy(ent, len, "weapon_g3sg1")
        case CSW_SCOUT:     copy(ent, len, "weapon_scout")
        case CSW_AWP:       copy(ent, len, "weapon_awp")
        case CSW_M249:      copy(ent, len, "weapon_m249")
        case CSW_HEGRENADE: copy(ent, len, "weapon_hegrenade")
        case CSW_KNIFE:     copy(ent, len, "weapon_knife")
        default:            copy(ent, len, "weapon_knife")
    }
}
