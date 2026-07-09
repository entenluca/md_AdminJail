Config = {}

Config.Framework = 'esx' -- esx | standalone

Config.Commands = {
    main = 'adminjail',
    alias = 'ajail'
}

Config.MaxJailMinutes = 1440
Config.MaxTasks = 50

Config.JailTypes = {
    standard = {
        label = 'Standard Jail',
        icon = 'clock',
        usesTime = true,
        defaultAmount = 15
    },
    community = {
        label = 'Community Service',
        icon = 'broom',
        usesTasks = true,
        defaultAmount = 10,
        taskDuration = 8000
    },
    facility = {
        label = 'Facility Management',
        icon = 'toilet',
        usesTasks = true,
        defaultAmount = 5,
        hasMinigame = true
    }
}

Config.JailArea = {
    coords = vector4(1690.85, 2591.34, 45.91, 180.0),
    radius = 45.0,
    release = vector4(1847.16, 2585.98, 45.67, 270.0)
}

Config.Security = {
    disableWeapons = true,
    stripWeapons = true,
    blockAttack = true,
    blockVehicle = true,
    blockJump = false
}

Config.Markers = {
    type = 1,
    scale = vector3(1.2, 1.2, 0.8),
    color = { r = 255, g = 90, b = 90, a = 140 },
    drawDistance = 35.0,
    interactDistance = 2.0
}

Config.CommunityServicePoints = {
    { coords = vector3(1685.2, 2588.4, 45.91), label = 'Hof fegen', scenario = 'WORLD_HUMAN_JANITOR' },
    { coords = vector3(1696.8, 2586.1, 45.91), label = 'Müll sammeln', scenario = 'WORLD_HUMAN_JANITOR' },
    { coords = vector3(1702.4, 2594.7, 45.91), label = 'Bereich reinigen', scenario = 'WORLD_HUMAN_JANITOR' },
    { coords = vector3(1688.9, 2598.2, 45.91), label = 'Gang säubern', scenario = 'WORLD_HUMAN_JANITOR' },
    { coords = vector3(1694.1, 2602.5, 45.91), label = 'Hofrand fegen', scenario = 'WORLD_HUMAN_JANITOR' }
}

Config.FacilityPoints = {
    { coords = vector3(1691.5, 2589.8, 45.91), label = 'Toilette reinigen' },
    { coords = vector3(1698.2, 2591.4, 45.91), label = 'Waschbecken putzen' },
    { coords = vector3(1700.6, 2597.3, 45.91), label = 'Oberfläche desinfizieren' },
    { coords = vector3(1687.4, 2593.6, 45.91), label = 'Sanitärbereich säubern' }
}

Config.FacilityMinigame = {
    spots = 6,
    timeLimit = 12,
    requiredCleans = 5
}

Config.ESXGroups = {
    superadmin = { menu = true, commands = true, jail = true, unjail = true, edit = true },
    admin = { menu = true, commands = true, jail = true, unjail = true, edit = true },
    mod = { menu = true, commands = true, jail = true, unjail = false, edit = false },
    support = { menu = true, commands = false, jail = false, unjail = false, edit = false }
}

Config.StandaloneAce = {
    menu = 'adminjail.menu',
    commands = 'adminjail.commands',
    jail = 'adminjail.jail',
    unjail = 'adminjail.unjail',
    edit = 'adminjail.edit'
}

Config.Discord = {
    enabled = false,
    logsWebhook = '',
    statsWebhook = '',
    botName = 'md_AdminJail',
    avatar = '',
    colors = {
        jail = 16724736,
        unjail = 3066993,
        edit = 16753920,
        autorelease = 9807270,
        stats = 3447003
    }
}

Config.NotifyAdmins = true
Config.ShowJailHud = true

Config.Locale = {
    no_permission = 'Du hast keine Berechtigung für diese Aktion.',
    player_not_found = 'Spieler nicht gefunden.',
    invalid_type = 'Ungültiger Jail-Typ. Nutze: standard, community, facility',
    invalid_amount = 'Ungültiger Wert. Mindestens 1, maximal %s.',
    missing_reason = 'Bitte gib einen Grund an.',
    already_jailed = 'Dieser Spieler ist bereits im AdminJail.',
    not_jailed = 'Dieser Spieler ist nicht im AdminJail.',
    jail_success = '%s wurde bestraft (%s).',
    unjail_success = '%s wurde freigelassen.',
    edit_success = 'Strafe von %s wurde aktualisiert.',
    jailed_notify = 'Du wurdest von %s bestraft (%s). Grund: %s',
    unjailed_notify = 'Du wurdest aus dem AdminJail entlassen.',
    task_done = 'Aufgabe abgeschlossen (%s/%s).',
    all_tasks_done = 'Alle Aufgaben erledigt. Du wurdest freigelassen.',
    go_to_marker = 'Gehe zum markierten Punkt: %s',
    press_to_work = 'Drücke [E] um zu arbeiten',
    working = 'Arbeit läuft...',
    cannot_leave = 'Du kannst den Jail-Bereich nicht verlassen.',
    minigame_failed = 'Reinigung fehlgeschlagen. Versuche es erneut.',
    admin_notify_jail = '[AdminJail] %s hat %s bestraft (%s). Grund: %s',
    admin_notify_unjail = '[AdminJail] %s hat %s freigelassen.',
    usage = 'Verwendung: /%s [jail|release|edit|menu] ...',
    usage_jail = '/%s jail [ID] [standard|community|facility] [Zeit/Tasks] [Grund]',
    usage_release = '/%s release [ID]',
    usage_edit = '/%s edit [ID] [neue Zeit/Tasks]'
}
