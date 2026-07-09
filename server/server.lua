local ESX = nil
local jailedPlayers = {}
local jailedByLicense = {}

local function initESX()
    if Config.Framework ~= 'esx' then
        return
    end

    if exports['es_extended'] then
        ESX = exports['es_extended']:getSharedObject()
    else
        TriggerEvent('esx:getSharedObject', function(obj)
            ESX = obj
        end)
    end
end

initESX()

local function getPlayerLicense(source)
    for _, identifier in ipairs(GetPlayerIdentifiers(source)) do
        if identifier:find('license:', 1, true) then
            return identifier
        end
    end

    return nil
end

local function getPlayerNameSafe(source)
    if ESX then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            if xPlayer.getName then
                return xPlayer.getName()
            end

            local playerData = xPlayer.get and xPlayer.get('firstName')
            if playerData then
                return playerData
            end
        end
    end

    return GetPlayerName(source) or ('Spieler %s'):format(source)
end

local function getPlayerGroup(source)
    if ESX then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer and xPlayer.getGroup then
            return xPlayer.getGroup()
        end
    end

    return 'user'
end

local function hasPermission(source, permission)
    if source == 0 then
        return true
    end

    if Config.Framework == 'esx' then
        local group = getPlayerGroup(source)
        local groupPerms = Config.ESXGroups[group]

        if not groupPerms then
            return false
        end

        return groupPerms[permission] == true
    end

    local ace = Config.StandaloneAce[permission]
    return ace and IsPlayerAceAllowed(source, ace) or false
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
        if id and hasPermission(id, 'menu') then
            notify(id, message)
        end
    end
end

local function getJailTypeLabel(jailType)
    local data = Config.JailTypes[jailType]
    return data and data.label or jailType
end

local function buildPayload(entry)
    local payload = {
        active = true,
        jailType = entry.jailType,
        jailTypeLabel = getJailTypeLabel(entry.jailType),
        admin = entry.admin,
        reason = entry.reason,
        jailCoords = {
            x = Config.JailArea.coords.x,
            y = Config.JailArea.coords.y,
            z = Config.JailArea.coords.z,
            w = Config.JailArea.coords.w
        },
        radius = Config.JailArea.radius
    }

    if entry.jailType == 'standard' then
        payload.endTime = entry.endTime
        payload.remainingSeconds = math.max(entry.endTime - os.time(), 0)
    else
        payload.tasksRequired = entry.tasksRequired
        payload.tasksCompleted = entry.tasksCompleted
        payload.taskPoints = entry.jailType == 'community' and Config.CommunityServicePoints or Config.FacilityPoints
        payload.hasMinigame = entry.jailType == 'facility'
    end

    return payload
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
    if entry.jailType ~= 'standard' then
        return 0
    end

    return math.max(math.ceil((entry.endTime - os.time()) / 60), 0)
end

local function syncJailState(target, entry)
    TriggerClientEvent('md_adminjail:setJailed', target, buildPayload(entry))
end

local function formatPenalty(entry)
    if entry.jailType == 'standard' then
        return ('%s Min'):format(getRemainingMinutes(entry))
    end

    return ('%s/%s Aufgaben'):format(entry.tasksCompleted, entry.tasksRequired)
end

local function buildEntry(source, jailType, amount, reason, adminSource)
    local license = getPlayerLicense(source)
    local entry = {
        source = source,
        license = license,
        name = getPlayerNameSafe(source),
        jailType = jailType,
        reason = reason,
        admin = adminSource and getPlayerNameSafe(adminSource) or 'System',
        adminSource = adminSource,
        jailedAt = os.time()
    }

    if jailType == 'standard' then
        entry.minutes = amount
        entry.endTime = os.time() + (amount * 60)
    else
        entry.tasksRequired = amount
        entry.tasksCompleted = 0
    end

    return entry
end

local function releasePlayer(target, adminSource, silent, reason)
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
            x = Config.JailArea.release.x,
            y = Config.JailArea.release.y,
            z = Config.JailArea.release.z,
            w = Config.JailArea.release.w
        }
    })

    if not silent then
        notify(target, Config.Locale.unjailed_notify)

        if adminSource then
            notifyAdmins(Config.Locale.admin_notify_unjail:format(
                getPlayerNameSafe(adminSource),
                entry.name
            ))

            Discord.SendLog('Spieler freigelassen', nil, Config.Discord.colors.unjail, {
                { name = 'Admin', value = getPlayerNameSafe(adminSource), inline = true },
                { name = 'Spieler', value = entry.name, inline = true },
                { name = 'Typ', value = getJailTypeLabel(entry.jailType), inline = true },
                { name = 'Grund', value = entry.reason, inline = false }
            })
        elseif reason == 'autorelease' then
            Discord.SendLog('Automatische Entlassung', nil, Config.Discord.colors.autorelease, {
                { name = 'Spieler', value = entry.name, inline = true },
                { name = 'Typ', value = getJailTypeLabel(entry.jailType), inline = true },
                { name = 'Grund', value = entry.reason, inline = false }
            })
        end
    end

    return true
end

local function jailPlayer(target, jailType, amount, reason, adminSource)
    if isPlayerJailed(target) then
        return false, 'already_jailed'
    end

    if not Config.JailTypes[jailType] then
        return false, 'invalid_type'
    end

    local entry = buildEntry(target, jailType, amount, reason, adminSource)
    jailedPlayers[target] = entry

    if entry.license then
        jailedByLicense[entry.license] = entry
    end

    syncJailState(target, entry)

    notify(target, Config.Locale.jailed_notify:format(
        entry.admin,
        getJailTypeLabel(jailType),
        reason
    ))

    if adminSource then
        notifyAdmins(Config.Locale.admin_notify_jail:format(
            entry.admin,
            entry.name,
            getJailTypeLabel(jailType),
            reason
        ))

        Discord.SendLog('Spieler bestraft', nil, Config.Discord.colors.jail, {
            { name = 'Admin', value = entry.admin, inline = true },
            { name = 'Spieler', value = entry.name, inline = true },
            { name = 'Typ', value = getJailTypeLabel(jailType), inline = true },
            { name = 'Wert', value = jailType == 'standard' and (amount .. ' Min') or (amount .. ' Aufgaben'), inline = true },
            { name = 'Grund', value = reason, inline = false }
        })
    end

    return true
end

local function editPlayer(target, amount, adminSource)
    local entry = getJailedEntry(target)
    if not entry then
        return false, 'not_jailed'
    end

    if entry.jailType == 'standard' then
        entry.minutes = amount
        entry.endTime = os.time() + (amount * 60)
    else
        entry.tasksRequired = amount
    end

    syncJailState(target, entry)

    if adminSource then
        Discord.SendLog('Strafe bearbeitet', nil, Config.Discord.colors.edit, {
            { name = 'Admin', value = getPlayerNameSafe(adminSource), inline = true },
            { name = 'Spieler', value = entry.name, inline = true },
            { name = 'Typ', value = getJailTypeLabel(entry.jailType), inline = true },
            { name = 'Neuer Wert', value = entry.jailType == 'standard' and (amount .. ' Min') or (amount .. ' Aufgaben'), inline = true }
        })
    end

    return true
end

local function getPanelData()
    local data = {}

    for _, playerId in ipairs(GetPlayers()) do
        local source = tonumber(playerId)
        local entry = source and getJailedEntry(source)

        if entry then
            if entry.jailType == 'standard' and getRemainingMinutes(entry) <= 0 then
                releasePlayer(source, nil, false, 'autorelease')
            else
                data[#data + 1] = {
                    id = source,
                    name = entry.name,
                    jailType = entry.jailType,
                    jailTypeLabel = getJailTypeLabel(entry.jailType),
                    reason = entry.reason,
                    admin = entry.admin,
                    penalty = formatPenalty(entry),
                    amount = entry.jailType == 'standard' and getRemainingMinutes(entry) or entry.tasksRequired,
                    progress = entry.jailType == 'standard' and getRemainingMinutes(entry) or entry.tasksCompleted,
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

local function validateAmount(jailType, amount)
    if not amount or amount < 1 then
        return false
    end

    if jailType == 'standard' then
        return amount <= Config.MaxJailMinutes
    end

    return amount <= Config.MaxTasks
end

local function openMenu(source)
    TriggerClientEvent('md_adminjail:openMenu', source, {
        players = getPanelData(),
        jailTypes = Config.JailTypes,
        permissions = {
            jail = hasPermission(source, 'jail'),
            unjail = hasPermission(source, 'unjail'),
            edit = hasPermission(source, 'edit')
        }
    })
end

local function handleCommand(source)
    if source == 0 then
        print(('[md_AdminJail] Nutze ingame: /%s oder /%s'):format(Config.Commands.main, Config.Commands.alias))
        return
    end

    if not hasPermission(source, 'menu') then
        notify(source, Config.Locale.no_permission)
        return
    end

    openMenu(source)
end

RegisterNetEvent('md_adminjail:requestMenu', function()
    local source = source

    if not hasPermission(source, 'menu') then
        notify(source, Config.Locale.no_permission)
        return
    end

    openMenu(source)
end)

RegisterNetEvent('md_adminjail:createJail', function(data)
    local source = source

    if not hasPermission(source, 'jail') then
        notify(source, Config.Locale.no_permission)
        return
    end

    local target = parseTargetId(data.id)
    local jailType = data.jailType and string.lower(data.jailType) or 'standard'
    local amount = tonumber(data.amount)
    local reason = data.reason or ''

    if not target then
        notify(source, Config.Locale.player_not_found)
        return
    end

    if not Config.JailTypes[jailType] then
        notify(source, Config.Locale.invalid_type)
        return
    end

    if not validateAmount(jailType, amount) then
        local maxValue = jailType == 'standard' and Config.MaxJailMinutes or Config.MaxTasks
        notify(source, Config.Locale.invalid_amount:format(maxValue))
        return
    end

    if reason == '' then
        notify(source, Config.Locale.missing_reason)
        return
    end

    local success, errorKey = jailPlayer(target, jailType, amount, reason, source)
    if success then
        notify(source, Config.Locale.jail_success:format(getPlayerNameSafe(target), getJailTypeLabel(jailType)))
        openMenu(source)
    elseif errorKey == 'already_jailed' then
        notify(source, Config.Locale.already_jailed)
    end
end)

RegisterNetEvent('md_adminjail:editJail', function(data)
    local source = source

    if not hasPermission(source, 'edit') then
        notify(source, Config.Locale.no_permission)
        return
    end

    local target = parseTargetId(data.id)
    local amount = tonumber(data.amount)

    if not target then
        notify(source, Config.Locale.player_not_found)
        return
    end

    local entry = getJailedEntry(target)
    if not entry then
        notify(source, Config.Locale.not_jailed)
        return
    end

    if not validateAmount(entry.jailType, amount) then
        local maxValue = entry.jailType == 'standard' and Config.MaxJailMinutes or Config.MaxTasks
        notify(source, Config.Locale.invalid_amount:format(maxValue))
        return
    end

    if editPlayer(target, amount, source) then
        notify(source, Config.Locale.edit_success:format(getPlayerNameSafe(target)))
        openMenu(source)
    end
end)

RegisterNetEvent('md_adminjail:releaseJail', function(targetId)
    local source = source

    if not hasPermission(source, 'unjail') then
        notify(source, Config.Locale.no_permission)
        return
    end

    local target = parseTargetId(targetId)
    if not target then
        notify(source, Config.Locale.player_not_found)
        return
    end

    if releasePlayer(target, source) then
        notify(source, Config.Locale.unjail_success:format(getPlayerNameSafe(target)))
        openMenu(source)
    else
        notify(source, Config.Locale.not_jailed)
    end
end)

RegisterNetEvent('md_adminjail:completeTask', function(taskIndex, minigameSuccess)
    local source = source
    local entry = getJailedEntry(source)

    if not entry or entry.jailType == 'standard' then
        return
    end

    if entry.jailType == 'facility' and minigameSuccess == false then
        notify(source, Config.Locale.minigame_failed)
        return
    end

    local points = entry.jailType == 'community' and Config.CommunityServicePoints or Config.FacilityPoints
    local point = points[taskIndex]

    if not point then
        return
    end

    local ped = GetPlayerPed(source)
    if ped <= 0 then
        return
    end

    local playerCoords = GetEntityCoords(ped)
    if #(playerCoords - point.coords) > (Config.Markers.interactDistance + 2.5) then
        return
    end

    entry.tasksCompleted = entry.tasksCompleted + 1

    if entry.tasksCompleted >= entry.tasksRequired then
        releasePlayer(source, nil, false, 'autorelease')
        notify(source, Config.Locale.all_tasks_done)
        return
    end

    if entry.license then
        jailedByLicense[entry.license] = entry
    end

    notify(source, Config.Locale.task_done:format(entry.tasksCompleted, entry.tasksRequired))
    syncJailState(source, entry)
end)

RegisterNetEvent('md_adminjail:requestState', function()
    local source = source
    local entry = getJailedEntry(source)

    if not entry then
        TriggerClientEvent('md_adminjail:setJailed', source, { active = false })
        return
    end

    if entry.jailType == 'standard' and getRemainingMinutes(entry) <= 0 then
        releasePlayer(source, nil, false, 'autorelease')
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

AddEventHandler('esx:playerLoaded', function(playerId)
    SetTimeout(3000, function()
        local source = playerId
        local entry = getJailedEntry(source)

        if not entry then
            return
        end

        if entry.jailType == 'standard' and getRemainingMinutes(entry) <= 0 then
            releasePlayer(source, nil, false, 'autorelease')
            return
        end

        syncJailState(source, entry)
    end)
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

        if entry.jailType == 'standard' and getRemainingMinutes(entry) <= 0 then
            releasePlayer(source, nil, false, 'autorelease')
            return
        end

        syncJailState(source, entry)
    end)
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    SetTimeout(4000, function()
        local fields = {}
        local count = 0

        for _, playerId in ipairs(GetPlayers()) do
            local source = tonumber(playerId)
            local entry = source and getJailedEntry(source)

            if entry then
                count = count + 1
                fields[#fields + 1] = {
                    name = entry.name,
                    value = ('%s | %s | %s'):format(getJailTypeLabel(entry.jailType), formatPenalty(entry), entry.reason),
                    inline = false
                }
            end
        end

        if count == 0 then
            fields[#fields + 1] = {
                name = 'Status',
                value = 'Keine aktiven Jails',
                inline = false
            }
        end

        Discord.SendStats('Server Start - AdminJail Statistik', ('Aktive Jails: **%s**'):format(count), fields)
    end)
end)

CreateThread(function()
    while true do
        Wait(30000)

        for _, playerId in ipairs(GetPlayers()) do
            local source = tonumber(playerId)
            local entry = source and getJailedEntry(source)

            if entry and entry.jailType == 'standard' and getRemainingMinutes(entry) <= 0 then
                releasePlayer(source, nil, false, 'autorelease')
            end
        end
    end
end)

RegisterCommand(Config.Commands.main, function(source)
    handleCommand(source)
end, false)

RegisterCommand(Config.Commands.alias, function(source)
    handleCommand(source)
end, false)

TriggerEvent('chat:addSuggestion', '/' .. Config.Commands.main, 'AdminJail Menü öffnen')
TriggerEvent('chat:addSuggestion', '/' .. Config.Commands.alias, 'AdminJail Menü öffnen')
