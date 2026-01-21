local QBCore = nil
local ESX = nil

local Sessions = {}

-- =============================================================================
--  FRAMEWORK DETECTION & BRIDGE
-- =============================================================================

if GetResourceState('es_extended') == 'started' then
    ESX = exports['es_extended']:getSharedObject()
elseif GetResourceState('qb-core') == 'started' then
    QBCore = exports['qb-core']:GetCoreObject()
end

-- HELPER: GIVE MONEY 
local function GivePaycheck(source, amount)
    if amount <= 0 then return end
    
    if ESX then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then 
            if Config.Payout.account == 'money' or Config.Payout.account == 'cash' then
                xPlayer.addInventoryItem('money', amount)
            else
                xPlayer.addAccountMoney(Config.Payout.account, amount) 
            end
        end
    elseif QBCore then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then 
            Player.Functions.AddMoney('cash', amount) 
        end
    end
end

-- HELPER: GET MONEY
local function GetPlayerMoney(source)
    if ESX then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            if Config.Payout.account == 'money' or Config.Payout.account == 'cash' then
                return xPlayer.getInventoryItem('money').count
            else
                return xPlayer.getAccount(Config.Payout.account).money
            end
        end
    elseif QBCore then
        local Player = QBCore.Functions.GetPlayer(source)
        return Player and Player.Functions.GetMoney('cash') or 0
    end
    return 0
end

-- HELPER: REMOVE MONEY
local function RemoveMoney(source, amount)
    if ESX then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then 
            if Config.Payout.account == 'money' or Config.Payout.account == 'cash' then
                xPlayer.removeInventoryItem('money', amount)
            else
                xPlayer.removeAccountMoney(Config.Payout.account, amount)
            end
        end
    elseif QBCore then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then Player.Functions.RemoveMoney('cash', amount) end
    end
end

-- =============================================================================
--  LOGIC & UTILS
-- =============================================================================

local function GenerateNextLocation(source)
    local session = Sessions[source]
    if not session then return nil end

    local newIndex = math.random(#Config.Routes)
 
    if newIndex == session.currentTargetIndex then
        newIndex = math.random(#Config.Routes)
    end

    session.currentTargetIndex = newIndex
    return Config.Routes[newIndex]
end

local function CleanupSession(source)
    local session = Sessions[source]
    if not session then return end

    -- If the vehicle still exists, delete it
    if DoesEntityExist(session.vehicleEntity) then
        DeleteEntity(session.vehicleEntity)
    end
    
    Sessions[source] = nil
end

-- =============================================================================
--  CALLBACKS
-- =============================================================================

-- 1. START SHIFT
lib.callback.register('markus-pizzajob:server:startShift', function(source, model)
    if Sessions[source] then return false end

    -- Handle Vehicle Price
    local vehiclePrice = 0
    for _, cat in pairs(Config.Fleet) do
        for _, veh in pairs(cat.vehicles) do
            if veh.model == model then vehiclePrice = veh.price break end
        end
    end

    -- Money Check
    if vehiclePrice > 0 then
        local currentMoney = GetPlayerMoney(source)
        if currentMoney < vehiclePrice then
            return false 
        end
        RemoveMoney(source, vehiclePrice)
    end

    -- Server-side Vehicle Spawn
    local coords = Config.Garage.spawnPoint
    local veh = CreateVehicle(GetHashKey(model), coords.x, coords.y, coords.z, coords.w, true, true)
    
    local attempts = 0
    while not DoesEntityExist(veh) and attempts < 10 do
        Wait(50)
        attempts = attempts + 1
    end

    if not DoesEntityExist(veh) then return false end

    local netId = NetworkGetNetworkIdFromEntity(veh)
    
    -- Initialize Session
    Sessions[source] = {
        vehicleEntity = veh,
        netId = netId,
        totalMoney = 0,
        drops = 0,
        currentTargetIndex = 0
    }

    local firstLoc = GenerateNextLocation(source)
    
    return netId, firstLoc
end)

-- 2. COMPLETE DELIVERY (NEXT DROP)
lib.callback.register('markus-pizzajob:server:nextDrop', function(source)
    local session = Sessions[source]
    if not session then return false end

    local playerPed = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(playerPed)
    local targetCoords = Config.Routes[session.currentTargetIndex]
    
    if not targetCoords then return false end

    local dist = #(playerCoords - targetCoords)
    if dist > 30.0 then 
        print(string.format("^1[Markus Pizza] EXPLOIT WARNING: Player %s tried to complete drop far from target (Dist: %s)^7", source, dist))
        return false 
    end

    local reward = math.random(Config.Payout.min, Config.Payout.max)
    session.totalMoney = session.totalMoney + reward
    session.drops = session.drops + 1

    local nextLoc = GenerateNextLocation(source)

    return {
        nextLoc = nextLoc,
        reward = reward
    }
end)

-- 3. GET STATS (For End Shift NUI)
lib.callback.register('markus-pizzajob:server:getStats', function(source)
    local session = Sessions[source]
    if not session then return false end

    return {
        money = session.totalMoney,
        drops = session.drops
    }
end)

-- 4. PAYOUT & FINISH
lib.callback.register('markus-pizzajob:server:payout', function(source)
    local session = Sessions[source]
    if not session then return false end

    if session.totalMoney > 0 then
        GivePaycheck(source, session.totalMoney)
    end

    CleanupSession(source)
    return true
end)

-- =============================================================================
--  EVENT HANDLERS
-- =============================================================================

AddEventHandler('playerDropped', function()
    CleanupSession(source)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        for src, session in pairs(Sessions) do
            if DoesEntityExist(session.vehicleEntity) then
                DeleteEntity(session.vehicleEntity)
            end
        end
    end
end)