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

local function formatRemainingTime(endTime)
    local remaining = math.max(endTime - getCurrentTime(), 0)
    return math.ceil(remaining / 60)
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
    else
        isJailed = false
        jailData = {}

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
            local minutes = formatRemainingTime(jailData.endTime)
            local text = Config.Locale.jail_timer:format(minutes, jailData.reason or '-')

            SetTextFont(4)
            SetTextScale(0.45, 0.45)
            SetTextColour(255, 80, 80, 220)
            SetTextOutline()
            SetTextCentre(true)
            BeginTextCommandDisplayText('STRING')
            AddTextComponentSubstringPlayerName(text)
            EndTextCommandDisplayText(0.5, 0.92)

            Wait(0)
        else
            Wait(1000)
        end
    end
end)
