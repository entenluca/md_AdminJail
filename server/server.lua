local jailedPlayers = {}
local jailedByLicense = {}

local function getPlayerLicense(source)
    for _, identifier in ipairs(GetPlayerIdentifiers(source)) do
        if identifier:find('license:', 1, true) then
            return identifier
        end
    end

    return nil
end

local function getFrameworkPlayerName(source)
    if Config.Framework == 'esx' then
        local ESX = exports['es_extended']:getSharedObject()
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            return xPlayer.getName()
        end
    elseif Config.Framework == 'qbcore' then
        local QBCore = exports['qb-core']:GetCoreObject()
        local player = QBCore.Functions.GetPlayer(source)
        if player then
            return player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
        end
    end

    return GetPlayerName(source) or ('Spieler %s'):format(source)
end

local function isAdmin(source)
    return IsPlayerAceAllowed(source, Config.AdminPermission)
end

local function notify(source, message)
    TriggerClientEvent('md_adminjail:notify', source, message)
end

local function notifyAdmins(message)
    if not Config.NotifyAdmins then
        return
    end

    for _, playerId in ipairs(GetPlayers()) do
        local id = tonumber(playerId)
        if id and isAdmin(id) then
            notify(id, message)
        end
    end
end

local function buildJailEntry(source, minutes, reason, adminSource)
    local endTime = os.time() + (minutes * 60)
    local license = getPlayerLicense(source)

    return {
        source = source,
        license = license,
        name = getFrameworkPlayerName(source),
        minutes = minutes,
        reason = reason,
        admin = adminSource and getFrameworkPlayerName(adminSource) or 'System',
        adminSource = adminSource,
        endTime = endTime,
        jailedAt = os.time()
    }
end

local function getJailedEntry(target)
    if not target then
        return nil
    end

    local entry = jailedPlayers[target]
    if entry then
        entry.source = target
        return entry
    end

    local license = getPlayerLicense(target)
    if not license then
        return nil
    end

    entry = jailedByLicense[license]
    if not entry then
        return nil
    end

    entry.source = target
    jailedPlayers[target] = entry
    return entry
end

local function isPlayerJailed(target)
    return getJailedEntry(target) ~= nil
end

local function getRemainingMinutes(entry)
    local remaining = math.ceil((entry.endTime - os.time()) / 60)
    return math.max(remaining, 0)
end

local function syncJailState(target, entry)
    TriggerClientEvent('md_adminjail:setJailed', target, {
        active = true,
        admin = entry.admin,
        reason = entry.reason,
        endTime = entry.endTime,
        totalMinutes = entry.minutes,
        jailCoords = {
            x = Config.JailCoords.x,
            y = Config.JailCoords.y,
            z = Config.JailCoords.z,
            w = Config.JailCoords.w
        },
        radius = Config.JailRadius
    })
end

local function releasePlayer(target, adminSource, silent)
    local entry = getJailedEntry(target)
    if not entry then
        return false
    end

    if entry.license then
        jailedByLicense[entry.license] = nil
    end

    jailedPlayers[target] = nil

    TriggerClientEvent('md_adminjail:setJailed', target, {
        active = false,
        releaseCoords = {
            x = Config.ReleaseCoords.x,
            y = Config.ReleaseCoords.y,
            z = Config.ReleaseCoords.z,
            w = Config.ReleaseCoords.w
        }
    })

    if not silent then
        notify(target, Config.Locale.unjailed_notify)

        if adminSource then
            notifyAdmins(Config.Locale.admin_unjail_notify:format(
                getFrameworkPlayerName(adminSource),
                entry.name
            ))
        end
    end

    return true
end

local function jailPlayer(target, minutes, reason, adminSource)
    if isPlayerJailed(target) then
        return false, 'already_jailed'
    end

    local entry = buildJailEntry(target, minutes, reason, adminSource)
    jailedPlayers[target] = entry

    if entry.license then
        jailedByLicense[entry.license] = entry
    end

    syncJailState(target, entry)

    notify(target, Config.Locale.jailed_notify:format(
        entry.admin,
        minutes,
        reason
    ))

    if adminSource then
        notifyAdmins(Config.Locale.admin_jail_notify:format(
            entry.admin,
            entry.name,
            minutes,
            reason
        ))
    end

    return true
end

local function getPanelData()
    local data = {}

    for _, playerId in ipairs(GetPlayers()) do
        local source = tonumber(playerId)
        local entry = source and getJailedEntry(source)

        if entry then
            local remaining = getRemainingMinutes(entry)
            if remaining <= 0 then
                releasePlayer(source, nil, true)
            else
                data[#data + 1] = {
                    id = source,
                    name = entry.name,
                    minutes = remaining,
                    totalMinutes = entry.minutes,
                    reason = entry.reason,
                    admin = entry.admin,
                    jailedAt = entry.jailedAt
                }
            end
        end
    end

    table.sort(data, function(a, b)
        return a.jailedAt > b.jailedAt
    end)

    return data
end

local function parseTargetId(input)
    local target = tonumber(input)
    if not target or not GetPlayerName(target) then
        return nil
    end

    return target
end

RegisterNetEvent('md_adminjail:requestPanel', function()
    local source = source

    if not isAdmin(source) then
        notify(source, Config.Locale.no_permission)
        return
    end

    TriggerClientEvent('md_adminjail:openPanel', source, getPanelData())
end)

RegisterNetEvent('md_adminjail:unjailFromPanel', function(targetId)
    local source = source

    if not isAdmin(source) then
        notify(source, Config.Locale.no_permission)
        return
    end

    local target = parseTargetId(targetId)
    if not target then
        notify(source, Config.Locale.player_not_found)
        return
    end

    if releasePlayer(target, source) then
        notify(source, Config.Locale.unjail_success:format(getFrameworkPlayerName(target)))
        TriggerClientEvent('md_adminjail:openPanel', source, getPanelData())
    else
        notify(source, Config.Locale.not_jailed)
    end
end)

RegisterNetEvent('md_adminjail:requestState', function()
    local source = source
    local entry = getJailedEntry(source)

    if not entry then
        TriggerClientEvent('md_adminjail:setJailed', source, { active = false })
        return
    end

    local remaining = getRemainingMinutes(entry)
    if remaining <= 0 then
        releasePlayer(source, nil, true)
        return
    end

    syncJailState(source, entry)
end)

AddEventHandler('playerDropped', function()
    local source = source
    local entry = getJailedEntry(source)

    if entry and entry.license then
        jailedByLicense[entry.license] = entry
    end

    jailedPlayers[source] = nil
end)

AddEventHandler('playerJoining', function()
    local source = source

    SetTimeout(5000, function()
        if not GetPlayerName(source) then
            return
        end

        local entry = getJailedEntry(source)
        if not entry then
            return
        end

        if getRemainingMinutes(entry) <= 0 then
            releasePlayer(source, nil, true)
            return
        end

        syncJailState(source, entry)
    end)
end)

CreateThread(function()
    while true do
        Wait(30000)

        for _, playerId in ipairs(GetPlayers()) do
            local source = tonumber(playerId)
            local entry = source and getJailedEntry(source)

            if entry and getRemainingMinutes(entry) <= 0 then
                releasePlayer(source, nil, false)
            end
        end
    end
end)

RegisterCommand(Config.Commands.jail, function(source, args)
    if source == 0 then
        print(('[md_AdminJail] %s'):format(Config.Locale.usage_jail:format(Config.Commands.jail)))
        return
    end

    if not isAdmin(source) then
        notify(source, Config.Locale.no_permission)
        return
    end

    local target = parseTargetId(args[1])
    local minutes = tonumber(args[2])
    local reason = table.concat(args, ' ', 3)

    if not target then
        notify(source, Config.Locale.player_not_found)
        return
    end

    if not minutes or minutes < 1 or minutes > Config.MaxJailMinutes then
        notify(source, Config.Locale.invalid_minutes:format(Config.MaxJailMinutes))
        return
    end

    if reason == '' then
        notify(source, Config.Locale.missing_reason)
        return
    end

    local success, errorKey = jailPlayer(target, minutes, reason, source)

    if success then
        notify(source, Config.Locale.jail_success:format(getFrameworkPlayerName(target), minutes))
    elseif errorKey == 'already_jailed' then
        notify(source, Config.Locale.already_jailed)
    end
end, false)

RegisterCommand(Config.Commands.unjail, function(source, args)
    if source == 0 then
        print(('[md_AdminJail] %s'):format(Config.Locale.usage_unjail:format(Config.Commands.unjail)))
        return
    end

    if not isAdmin(source) then
        notify(source, Config.Locale.no_permission)
        return
    end

    local target = parseTargetId(args[1])
    if not target then
        notify(source, Config.Locale.player_not_found)
        return
    end

    if releasePlayer(target, source) then
        notify(source, Config.Locale.unjail_success:format(getFrameworkPlayerName(target)))
    else
        notify(source, Config.Locale.not_jailed)
    end
end, false)

RegisterCommand(Config.Commands.panel, function(source)
    if source == 0 then
        print('[md_AdminJail] Panel nur ingame verfügbar.')
        return
    end

    if not isAdmin(source) then
        notify(source, Config.Locale.no_permission)
        return
    end

    TriggerClientEvent('md_adminjail:openPanel', source, getPanelData())
    notify(source, Config.Locale.panel_opened)
end, false)

TriggerEvent('chat:addSuggestion', '/' .. Config.Commands.jail, 'Spieler ins AdminJail setzen', {
    { name = 'id', help = 'Spieler ID' },
    { name = 'minuten', help = 'Haftzeit in Minuten' },
    { name = 'grund', help = 'Grund für AdminJail' }
})

TriggerEvent('chat:addSuggestion', '/' .. Config.Commands.unjail, 'Spieler aus AdminJail entlassen', {
    { name = 'id', help = 'Spieler ID' }
})

TriggerEvent('chat:addSuggestion', '/' .. Config.Commands.panel, 'AdminJail Panel öffnen')
