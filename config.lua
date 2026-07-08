Config = {}

-- ACE Permission: add_ace group.admin adminjail.admin allow
Config.AdminPermission = 'adminjail.admin'

-- Jail location (Bolingbroke Penitentiary yard)
Config.JailCoords = vector4(1690.85, 2591.34, 45.91, 180.0)

-- Release location (outside prison)
Config.ReleaseCoords = vector4(1847.16, 2585.98, 45.67, 270.0)

-- Max distance from jail center before player is teleported back
Config.JailRadius = 35.0

-- Max jail time in minutes
Config.MaxJailMinutes = 1440

-- Commands
Config.Commands = {
    jail = 'adminjail',
    unjail = 'adminjailrelease',
    panel = 'adminjailpanel'
}

-- Disable weapons and combat while jailed
Config.DisableWeapons = true

-- Strip weapons when jailed
Config.StripWeapons = true

-- Show remaining jail time on screen
Config.ShowJailTimer = true

-- Notify all admins when someone is jailed/unjailed
Config.NotifyAdmins = true

-- Framework: 'standalone', 'esx', 'qbcore'
Config.Framework = 'standalone'

-- Locale
Config.Locale = {
    no_permission = 'Du hast keine Berechtigung für AdminJail.',
    player_not_found = 'Spieler nicht gefunden.',
    invalid_minutes = 'Ungültige Haftzeit. Mindestens 1 Minute, maximal %s.',
    missing_reason = 'Bitte gib einen Grund an.',
    jail_success = '%s wurde für %s Minute(n) eingesperrt.',
    unjail_success = '%s wurde freigelassen.',
    already_jailed = 'Dieser Spieler ist bereits im AdminJail.',
    not_jailed = 'Dieser Spieler ist nicht im AdminJail.',
    jailed_notify = 'Du wurdest von %s für %s Minute(n) ins AdminJail gesetzt. Grund: %s',
    unjailed_notify = 'Du wurdest aus dem AdminJail entlassen.',
    admin_jail_notify = '[AdminJail] %s hat %s für %s Minute(n) eingesperrt. Grund: %s',
    admin_unjail_notify = '[AdminJail] %s hat %s freigelassen.',
    jail_timer = 'AdminJail: noch %s Minute(n) | Grund: %s',
    panel_opened = 'AdminJail Panel geöffnet.',
    usage_jail = 'Verwendung: /%s [ID] [Minuten] [Grund]',
    usage_unjail = 'Verwendung: /%s [ID]'
}
