local isJailed = false
local jailData = {}
local menuOpen = false
local isWorking = false
local minigameOpen = false
local currentTaskIndex = nil

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
    if not isJailed or not Config.ShowJailHud then
        return
    end

    local payload = {
        action = 'updateJailHud',
        admin = jailData.admin,
        reason = jailData.reason,
        jailType = jailData.jailTypeLabel or jailData.jailType,
        jailTypeKey = jailData.jailType
    }

    if jailData.jailType == 'standard' then
        payload.remainingSeconds = formatRemainingSeconds(jailData.endTime or getCurrentTime())
    else
        payload.tasksCompleted = jailData.tasksCompleted or 0
        payload.tasksRequired = jailData.tasksRequired or 0
    end

    SendNUIMessage(payload)
end

local function showJailHud()
    if not Config.ShowJailHud then
        return
    end

    local payload = {
        action = 'showJailHud',
        admin = jailData.admin or 'Unbekannt',
        reason = jailData.reason or '-',
        jailType = jailData.jailTypeLabel or jailData.jailType or 'Standard Jail',
        jailTypeKey = jailData.jailType
    }

    if jailData.jailType == 'standard' then
        payload.remainingSeconds = formatRemainingSeconds(jailData.endTime or getCurrentTime())
    else
        payload.tasksCompleted = jailData.tasksCompleted or 0
        payload.tasksRequired = jailData.tasksRequired or 0
    end

    SendNUIMessage(payload)
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

local function setMenuFocus(state)
    menuOpen = state
    SetNuiFocus(state, state)
    SetNuiFocusKeepInput(false)
end

local function closeMenu()
    setMenuFocus(false)
    SendNUIMessage({ action = 'closeMenu' })
end

local function playWorkScenario(scenario)
    local ped = PlayerPedId()
    TaskStartScenarioInPlace(ped, scenario, 0, true)
end

local function stopWorkScenario()
    ClearPedTasks(PlayerPedId())
end

local function getClosestTaskPoint()
    if not jailData.taskPoints then
        return nil
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local closestIndex = nil
    local closestDistance = Config.Markers.interactDistance + 1.0

    for index, point in ipairs(jailData.taskPoints) do
        local distance = #(coords - point.coords)
        if distance < closestDistance then
            closestDistance = distance
            closestIndex = index
        end
    end

    return closestIndex, closestDistance
end

local function drawTaskMarkers()
    if not jailData.taskPoints then
        return
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    for _, point in ipairs(jailData.taskPoints) do
        local distance = #(coords - point.coords)
        if distance <= Config.Markers.drawDistance then
            DrawMarker(
                Config.Markers.type,
                point.coords.x, point.coords.y, point.coords.z - 1.0,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                Config.Markers.scale.x, Config.Markers.scale.y, Config.Markers.scale.z,
                Config.Markers.color.r, Config.Markers.color.g, Config.Markers.color.b, Config.Markers.color.a,
                false, true, 2, false, nil, nil, false
            )
        end
    end
end

local function startCommunityTask(taskIndex)
    local point = jailData.taskPoints[taskIndex]
    if not point then
        return
    end

    isWorking = true
    notify(Config.Locale.working)
    playWorkScenario(point.scenario or 'WORLD_HUMAN_JANITOR')

    local duration = Config.JailTypes.community.taskDuration or 8000
    Wait(duration)

    stopWorkScenario()
    isWorking = false
    TriggerServerEvent('md_adminjail:completeTask', taskIndex, true)
end

local function openFacilityMinigame(taskIndex)
    currentTaskIndex = taskIndex
    minigameOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openMinigame',
        config = Config.FacilityMinigame
    })
end

local function tryStartTask()
    if isWorking or minigameOpen or menuOpen then
        return
    end

    local taskIndex, distance = getClosestTaskPoint()
    if not taskIndex or distance > Config.Markers.interactDistance then
        return
    end

    local point = jailData.taskPoints[taskIndex]

    if jailData.hasMinigame then
        openFacilityMinigame(taskIndex)
    else
        CreateThread(function()
            startCommunityTask(taskIndex)
        end)
    end
end

RegisterNetEvent('md_adminjail:notify', function(message)
    notify(message)
end)

RegisterNetEvent('md_adminjail:setJailed', function(data)
    if data.active then
        local wasJailed = isJailed
        isJailed = true
        jailData = data

        if not wasJailed then
            teleportToCoords(data.jailCoords)
        end

        showJailHud()
    else
        isJailed = false
        jailData = {}
        isWorking = false
        minigameOpen = false
        currentTaskIndex = nil
        stopWorkScenario()
        hideJailHud()

        if data.releaseCoords then
            teleportToCoords(data.releaseCoords)
        end
    end
end)

RegisterNetEvent('md_adminjail:openMenu', function(data)
    setMenuFocus(true)
    SendNUIMessage({
        action = 'openMenu',
        players = data.players,
        onlinePlayers = data.onlinePlayers,
        jailTypes = data.jailTypes,
        permissions = data.permissions
    })
end)

RegisterNUICallback('closeMenu', function(_, cb)
    closeMenu()
    cb('ok')
end)

RegisterNUICallback('refreshMenu', function(_, cb)
    TriggerServerEvent('md_adminjail:requestMenu')
    cb('ok')
end)

RegisterNUICallback('createJail', function(data, cb)
    TriggerServerEvent('md_adminjail:createJail', data)
    cb('ok')
end)

RegisterNUICallback('editJail', function(data, cb)
    TriggerServerEvent('md_adminjail:editJail', data)
    cb('ok')
end)

RegisterNUICallback('releaseJail', function(data, cb)
    TriggerServerEvent('md_adminjail:releaseJail', data.id)
    cb('ok')
end)

RegisterNUICallback('minigameResult', function(data, cb)
    minigameOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeMinigame' })

    if currentTaskIndex then
        TriggerServerEvent('md_adminjail:completeTask', currentTaskIndex, data.success == true)
        currentTaskIndex = nil
    end

    cb('ok')
end)

CreateThread(function()
    Wait(2500)
    TriggerServerEvent('md_adminjail:requestState')
end)

CreateThread(function()
    while true do
        if isJailed and jailData.jailCoords then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local jailCoords = jailData.jailCoords
            local distance = #(coords - vector3(jailCoords.x, jailCoords.y, jailCoords.z))

            if distance > (jailData.radius or Config.JailArea.radius) then
                teleportToCoords(jailCoords)
                notify(Config.Locale.cannot_leave)
            end

            if Config.Security.disableWeapons then
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

                if Config.Security.stripWeapons and IsPedArmed(ped, 7) then
                    RemoveAllPedWeapons(ped, true)
                end
            end

            if Config.Security.blockVehicle then
                DisableControlAction(0, 23, true)
                DisableControlAction(0, 75, true)
            end

            if Config.Security.blockJump then
                DisableControlAction(0, 22, true)
            end

            if jailData.jailType ~= 'standard' then
                drawTaskMarkers()

                if not isWorking and not minigameOpen then
                    local taskIndex, taskDistance = getClosestTaskPoint()
                    if taskIndex and taskDistance <= Config.Markers.interactDistance then
                        BeginTextCommandDisplayHelp('STRING')
                        AddTextComponentSubstringPlayerName(Config.Locale.press_to_work)
                        EndTextCommandDisplayHelp(0, false, true, -1)

                        if IsControlJustReleased(0, 38) then
                            tryStartTask()
                        end
                    end
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
        if isJailed and jailData.jailType == 'standard' and Config.ShowJailHud then
            updateJailHud()
            Wait(1000)
        elseif isJailed and jailData.jailType ~= 'standard' and Config.ShowJailHud then
            updateJailHud()
            Wait(1000)
        else
            Wait(1000)
        end
    end
end)

RegisterCommand('+' .. Config.Commands.main .. '_close', function()
    if menuOpen then
        closeMenu()
    end
end, false)

RegisterKeyMapping('+' .. Config.Commands.main .. '_close', 'AdminJail Menü schließen', 'keyboard', 'ESCAPE')
