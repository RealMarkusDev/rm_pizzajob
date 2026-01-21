local QBCore = nil
local ESX = nil

-- State Management
local state = {
    isWorking = false,
    hasPizza = false,
    vehicle = nil,
    prop = nil,
    blip = nil,
    zone = nil,
    bossPed = nil,
    customerPed = nil 
}

-- Showroom / Preview State
local showroom = {
    cam = nil,
    vehicle = nil
}

-- =============================================================================
--  FRAMEWORK & INIT
-- =============================================================================

CreateThread(function()
    -- Framework Detection
    if GetResourceState('es_extended') == 'started' then
        ESX = exports['es_extended']:getSharedObject()
    elseif GetResourceState('qb-core') == 'started' then
        QBCore = exports['qb-core']:GetCoreObject()
    end

    InitBoss()
end)

-- Helper: Native Framework Notification
function ShowNotify(msg, type)
    if ESX then
        ESX.ShowNotification(msg)
    elseif QBCore then
        if type == 'inform' then type = 'primary' end
        QBCore.Functions.Notify(msg, type)
    else
        lib.notify({ description = msg, type = type })
    end
end

-- =============================================================================
--  SHOWROOM / CAMERA LOGIC
-- =============================================================================

function SetupShowroom(model)
    if not Config.ShowVehicle.enabled then return end

    if not DoesCamExist(showroom.cam) then
        showroom.cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
        SetCamCoord(showroom.cam, Config.ShowVehicle.camCoords)
        PointCamAtCoord(showroom.cam, Config.ShowVehicle.camLookAt)
        SetCamActive(showroom.cam, true)
        RenderScriptCams(true, true, 500, true, true)
    end

    if DoesEntityExist(showroom.vehicle) then
        DeleteEntity(showroom.vehicle)
    end

    if model then
        lib.requestModel(model)
        local coords = Config.ShowVehicle.spawnCoords
        showroom.vehicle = CreateVehicle(GetHashKey(model), coords.x, coords.y, coords.z, coords.w, false, false)
        
        SetEntityHeading(showroom.vehicle, coords.w)
        SetVehicleDirtLevel(showroom.vehicle, 0.0)
        SetVehicleColours(showroom.vehicle, 111, 111)
        SetModelAsNoLongerNeeded(model)
        
        SetVehicleEngineOn(showroom.vehicle, true, true, false)
    end
end

function CloseShowroom()
    if DoesEntityExist(showroom.vehicle) then
        DeleteEntity(showroom.vehicle)
    end
    showroom.vehicle = nil

    if DoesCamExist(showroom.cam) then
        RenderScriptCams(false, true, 500, true, true)
        DestroyCam(showroom.cam, false)
    end
    showroom.cam = nil
end

-- =============================================================================
--  NUI CALLBACKS
-- =============================================================================

RegisterNUICallback('CloseMenu', function(_, cb)
    SetNuiFocus(false, false)
    CloseShowroom()
    cb('ok')
end)

RegisterNUICallback('previewVehicle', function(data, cb)
    if data.model then
        SetupShowroom(data.model)
    else
        if DoesEntityExist(showroom.vehicle) then DeleteEntity(showroom.vehicle) end
    end
    cb('ok')
end)

RegisterNUICallback('startJob', function(data, cb)
    SetNuiFocus(false, false)
    CloseShowroom()

    local netId, firstLocation = lib.callback.await('markus-pizzajob:server:startShift', false, data.vehicleModel)
    
    if netId and firstLocation then
        StartWorkLoop(netId, firstLocation)
    else
        ShowNotify('Vehicle spawn failed. Not enough money or Garage blocked?', 'error')
    end
    
    cb('ok')
end)

RegisterNUICallback('confirmFinish', function(_, cb)
    SetNuiFocus(false, false)
    CloseShowroom()

    local success = lib.callback.await('markus-pizzajob:server:payout', false)
    if success then
        CleanupJob()
        ShowNotify('Shift ended. Payment received.', 'success')
    end
    cb('ok')
end)

-- =============================================================================
--  JOB LOGIC
-- =============================================================================

function StartWorkLoop(netId, firstLoc)
    state.isWorking = true
    
    while not NetworkDoesEntityExistWithNetworkId(netId) do Wait(100) end
    state.vehicle = NetworkGetEntityFromNetworkId(netId)

    SetupVehicleTarget()
    SetRoute(firstLoc)

    ShowNotify('Head to the location marked on GPS.', 'inform')
end

function SetRoute(coords)
    -- Handle GPS Blip
    if state.blip then RemoveBlip(state.blip) end
    state.blip = AddBlipForCoord(coords)
    SetBlipSprite(state.blip, 1)
    SetBlipRoute(state.blip, true)
    SetBlipColour(state.blip, 5) 
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Pizza Customer")
    EndTextCommandSetBlipName(state.blip)

    -- Create door interaction zone
    if state.zone then exports.ox_target:removeZone(state.zone) end
    
    state.zone = exports.ox_target:addSphereZone({
        coords = coords,
        radius = 1.5,
        debug = Config.Debug,
        options = {
            {
                name = 'knock_door',
                icon = 'fa-solid fa-hand-fist', -- Knock icon
                label = Config.Work.labels.knock, -- Knock label
                canInteract = function() return state.isWorking and state.hasPizza end,
                onSelect = function()
                    KnockAtDoor(coords) -- Start NPC sequence
                end
            }
        }
    })
end

-- Phase 1: Knock at the door
function KnockAtDoor(coords)
    lib.requestAnimDict('timetable@jimmy@doorknock@')
    TaskPlayAnim(cache.ped, 'timetable@jimmy@doorknock@', 'knockdoor_idle', 3.0, 1.0, -1, 49, 0, true, true, true)

    if lib.progressCircle({
        duration = 2000,
        label = Config.Work.labels.waiting,
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true }
    }) then
        if state.zone then exports.ox_target:removeZone(state.zone) end
        SpawnCustomer(coords)
    end
    ClearPedTasks(cache.ped)
end

-- Phase 2: Spawn Customer
function SpawnCustomer(coords)
    local model = Config.Customers[math.random(#Config.Customers)]
    lib.requestModel(model)


    state.customerPed = CreatePed(4, GetHashKey(model), coords.x, coords.y, coords.z, 0.0, true, true)
    
    TaskTurnPedToFaceEntity(state.customerPed, cache.ped, -1)
    SetEntityInvincible(state.customerPed, true)
    SetBlockingOfNonTemporaryEvents(state.customerPed, true)

    exports.ox_target:addLocalEntity(state.customerPed, {
        {
            name = 'handover_pizza',
            icon = 'fa-solid fa-pizza-slice',
            label = Config.Work.labels.give_pizza,
            canInteract = function() return state.isWorking and state.hasPizza end,
            onSelect = function()
                FinishDelivery()
            end
        }
    })

    ShowNotify("Customer is here!", "inform")
    SetModelAsNoLongerNeeded(model)
end

-- Phase 3: Actual delivery 
function FinishDelivery()
    local customer = state.customerPed
    
    local dict = Config.Work.handover.dict
    local anim = Config.Work.handover.anim
    lib.requestAnimDict(dict)

    TaskPlayAnim(cache.ped, dict, anim, 8.0, -8.0, 2000, 49, 0, false, false, false)
    if DoesEntityExist(customer) then
        TaskPlayAnim(customer, dict, anim, 8.0, -8.0, 2000, 49, 0, false, false, false)
    end

    Wait(1000)
    TogglePizza(false) 

    local result = lib.callback.await('markus-pizzajob:server:nextDrop', false)
    
    if result then
        ShowNotify(string.format(Config.Work.payoutMessage, result.reward), 'success')
        
        -- NPC Cleanup
        if DoesEntityExist(customer) then
            exports.ox_target:removeLocalEntity(customer, 'handover_pizza')
            TaskWanderStandard(customer, 10.0, 10) 
            SetEntityAsNoLongerNeeded(customer)
            
            SetTimeout(10000, function()
                if DoesEntityExist(customer) then DeleteEntity(customer) end
            end)
            state.customerPed = nil
        end

        SetRoute(result.nextLoc)
    else
        ShowNotify('No more deliveries. Return to HQ.', 'inform')
        if state.blip then RemoveBlip(state.blip) end
        if state.customerPed then DeleteEntity(state.customerPed) end
    end
end

function CleanupJob()
    state.isWorking = false
    state.hasPizza = false
    
    if state.vehicle then
        exports.ox_target:removeLocalEntity(state.vehicle, {'take_pizza', 'return_pizza'})
    end
    
    if state.blip then RemoveBlip(state.blip) end
    if state.zone then exports.ox_target:removeZone(state.zone) end
    
    if state.customerPed and DoesEntityExist(state.customerPed) then 
        DeleteEntity(state.customerPed) 
    end
    
    if state.prop then DeleteEntity(state.prop) end
    
    state.vehicle = nil
end

-- =============================================================================
--  PROP & ANIMATION
-- =============================================================================

function SetupVehicleTarget()
    local class = GetVehicleClass(state.vehicle)
    local useBones = Config.TargetBones.cars 

    if class == 8 or class == 13 then
        useBones = Config.TargetBones.bikes
    end

    exports.ox_target:addLocalEntity(state.vehicle, {
        {
            name = 'take_pizza',
            icon = 'fa-solid fa-box-open',
            label = 'Take Pizza',
            bones = useBones,
            canInteract = function() return state.isWorking and not state.hasPizza end,
            onSelect = function() TogglePizza(true) end
        },
        {
            name = 'return_pizza',
            icon = 'fa-solid fa-rotate-left',
            label = 'Return Pizza',
            bones = useBones, 
            canInteract = function() return state.isWorking and state.hasPizza end,
            onSelect = function() TogglePizza(false) end
        }
    })
end

function TogglePizza(enable)
    state.hasPizza = enable

    if not enable then
        if DoesEntityExist(state.prop) then DeleteEntity(state.prop) end
        ClearPedTasks(cache.ped)
        return
    end

    lib.requestModel(Config.Work.propName)
    lib.requestAnimDict(Config.Work.animDict)

    local coords = GetEntityCoords(cache.ped)
    state.prop = CreateObject(GetHashKey(Config.Work.propName), coords.x, coords.y, coords.z, true, true, true)
    
    AttachEntityToEntity(state.prop, cache.ped, GetPedBoneIndex(cache.ped, 28422), 
        0.01, -0.1, -0.159, 20.0, 0.0, 0.0, 
        true, true, false, true, 0, true
    )

    TaskPlayAnim(cache.ped, Config.Work.animDict, Config.Work.animClip, 5.0, 5.0, -1, 51, 0, 0, 0, 0)
    SetModelAsNoLongerNeeded(Config.Work.propName)
end

-- =============================================================================
--  NPC / BOSS
-- =============================================================================

function InitBoss()
    local cfg = Config.Location
    
    if cfg.blip.enabled then
        local blip = AddBlipForCoord(cfg.coords)
        SetBlipSprite(blip, cfg.blip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, cfg.blip.scale)
        SetBlipColour(blip, cfg.blip.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(cfg.blip.label)
        EndTextCommandSetBlipName(blip)
    end

    lib.requestModel(cfg.pedModel)
    state.bossPed = CreatePed(0, GetHashKey(cfg.pedModel), cfg.coords.x, cfg.coords.y, cfg.coords.z, cfg.coords.w, false, false)
    SetEntityInvincible(state.bossPed, true)
    FreezeEntityPosition(state.bossPed, true)
    SetBlockingOfNonTemporaryEvents(state.bossPed, true)
    
    exports.ox_target:addLocalEntity(state.bossPed, {
        {
            name = 'pizzajob_menu',
            icon = 'fa-solid fa-pizza-slice',
            label = 'Fleet Management',
            canInteract = function() return not state.isWorking end,
            onSelect = function()
                SetNuiFocus(true, true)
                SendNUIMessage({
                    action = "openMenu",
                    data = { categories = Config.Fleet }
                })
            end
        },
        {
            name = 'pizzajob_finish',
            icon = 'fa-solid fa-flag-checkered',
            label = 'Finish Shift',
            canInteract = function() return state.isWorking end,
            onSelect = function()
                local stats = lib.callback.await('markus-pizzajob:server:getStats', false)
                if stats then
                    SetNuiFocus(true, true)
                    SendNUIMessage({
                        action = "openFinish",
                        data = { total = stats.money, deliveries = stats.drops }
                    })
                end
            end
        }
    })
end

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        if state.bossPed then DeleteEntity(state.bossPed) end
        if state.prop then DeleteEntity(state.prop) end
        if state.customerPed then DeleteEntity(state.customerPed) end
        if state.blip then RemoveBlip(state.blip) end
        CloseShowroom()
    end
end)