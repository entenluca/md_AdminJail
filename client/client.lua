local isJailed = false
local jailData = {}
local panelOpen = false

local function notify(message)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, true)
end

local function getCurrentTime()
    return GetCloudTimeAsInt()
end

local function formatRemainingSeconds(endTime)
    return math.max(endTime - getCurrentTime(), 0)
end

local function updateJailHud()
    if not isJailed or not jailData.endTime then
        return
    end

    SendNUIMessage({
        action = 'updateJailHud',
        admin = jailData.admin,
        reason = jailData.reason,
        remainingSeconds = formatRemainingSeconds(jailData.endTime)
    })
end

local function showJailHud()
    if not Config.ShowJailTimer then
        return
    end

    SendNUIMessage({
        action = 'showJailHud',
        admin = jailData.admin or 'Unbekannt',
        reason = jailData.reason or '-',
        remainingSeconds = formatRemainingSeconds(jailData.endTime or getCurrentTime())
    })
end

local function hideJailHud()
    SendNUIMessage({ action = 'hideJailHud' })
end

local function teleportToCoords(coords)
    local ped = PlayerPedId()

    DoScreenFadeOut(300)
    while not IsScreenFadedOut() do
        Wait(0)
    end

    RequestCollisionAtCoord(coords.x, coords.y, coords.z)
    SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(ped, coords.w or 0.0)

    local timeout = GetGameTimer() + 5000
    while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < timeout do
        Wait(0)
    end

    DoScreenFadeIn(300)
end

local function setPanelFocus(state)
    panelOpen = state
    SetNuiFocus(state, state)
    SetNuiFocusKeepInput(false)
end

local function closePanel()
    setPanelFocus(false)
    SendNUIMessage({ action = 'close' })
end

RegisterNetEvent('md_adminjail:notify', function(message)
    notify(message)
end)

RegisterNetEvent('md_adminjail:setJailed', function(data)
    if data.active then
        isJailed = true
        jailData = data
        teleportToCoords(data.jailCoords)
        showJailHud()
    else
        isJailed = false
        jailData = {}
        hideJailHud()

        if data.releaseCoords then
            teleportToCoords(data.releaseCoords)
        end
    end
end)

RegisterNetEvent('md_adminjail:openPanel', function(players)
    setPanelFocus(true)
    SendNUIMessage({
        action = 'open',
        players = players
    })
end)

RegisterNUICallback('closePanel', function(_, cb)
    closePanel()
    cb('ok')
end)

RegisterNUICallback('unjailPlayer', function(data, cb)
    TriggerServerEvent('md_adminjail:unjailFromPanel', data.id)
    cb('ok')
end)

RegisterNUICallback('refreshPanel', function(_, cb)
    TriggerServerEvent('md_adminjail:requestPanel')
    cb('ok')
end)

RegisterCommand('+' .. Config.Commands.panel .. '_close', function()
    if panelOpen then
        closePanel()
    end
end, false)

RegisterKeyMapping('+' .. Config.Commands.panel .. '_close', 'AdminJail Panel schließen', 'keyboard', 'ESCAPE')

CreateThread(function()
    Wait(2000)
    TriggerServerEvent('md_adminjail:requestState')
end)

CreateThread(function()
    while true do
        if isJailed and jailData.jailCoords then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local jailCoords = jailData.jailCoords
            local distance = #(coords - vector3(jailCoords.x, jailCoords.y, jailCoords.z))

            if distance > (jailData.radius or Config.JailRadius) then
                teleportToCoords(jailCoords)
                notify('Du kannst das AdminJail nicht verlassen.')
            end

            if Config.DisableWeapons then
                DisablePlayerFiring(PlayerId(), true)
                DisableControlAction(0, 24, true)
                DisableControlAction(0, 25, true)
                DisableControlAction(0, 47, true)
                DisableControlAction(0, 58, true)
                DisableControlAction(0, 140, true)
                DisableControlAction(0, 141, true)
                DisableControlAction(0, 142, true)
                DisableControlAction(0, 143, true)
                DisableControlAction(0, 257, true)
                DisableControlAction(0, 263, true)
                DisableControlAction(0, 264, true)

                if IsPedArmed(ped, 7) and Config.StripWeapons then
                    RemoveAllPedWeapons(ped, true)
                end
            end

            Wait(0)
        else
            Wait(500)
        end
    end
end)

CreateThread(function()
    while true do
        if isJailed and Config.ShowJailTimer and jailData.endTime then
            updateJailHud()
            Wait(1000)
        else
            Wait(1000)
        end
    end
end)
