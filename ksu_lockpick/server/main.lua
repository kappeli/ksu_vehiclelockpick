local resourceName = GetCurrentResourceName()
local framework

local function startsWith(value, expected)
    return value:sub(1, #expected) == expected
end

local function detectFramework()
    if Config.Framework == 'qbcore' then
        framework = exports['qb-core']:GetCoreObject()
        return 'qbcore'
    end

    framework = exports['es_extended']:getSharedObject()
    return 'esx'
end

local activeFramework = detectFramework()

local function detectInventory()
    if Config.Inventory ~= 'auto' then
        return Config.Inventory
    end

    if GetResourceState('ox_inventory') == 'started' then
        return 'ox_inventory'
    end

    if GetResourceState('qb-inventory') == 'started' then
        return 'qb-inventory'
    end

    if GetResourceState('qs-inventory') == 'started' then
        return 'qs-inventory'
    end

    if GetResourceState('lj-inventory') == 'started' then
        return 'lj-inventory'
    end

    if GetResourceState('ps-inventory') == 'started' then
        return 'ps-inventory'
    end

    if GetResourceState('codem-inventory') == 'started' then
        return 'codem-inventory'
    end

    if GetResourceState('core_inventory') == 'started' then
        return 'core_inventory'
    end

    if activeFramework == 'qbcore' then
        return 'qb'
    end

    return 'esx'
end

local activeInventory = detectInventory()

local function getPlayer(source)
    if activeFramework == 'qbcore' then
        return framework.Functions.GetPlayer(source)
    end

    return framework.GetPlayerFromId(source)
end

local function hasItem(source, itemName)
    if activeInventory == 'ox_inventory' then
        local count = exports.ox_inventory:Search(source, 'count', itemName)
        return (count or 0) > 0
    end

    local player = getPlayer(source)
    if not player then
        return false
    end

    if activeInventory == 'qb-inventory' or activeInventory == 'lj-inventory' or activeInventory == 'ps-inventory' then
        local item = player.Functions.GetItemByName(itemName)
        return item and item.amount and item.amount > 0 or false
    end

    if activeInventory == 'qs-inventory' then
        local item = exports['qs-inventory']:GetItemTotalAmount(source, itemName)
        return (item or 0) > 0
    end

    if activeInventory == 'codem-inventory' then
        local item = exports['codem-inventory']:GetItemByName(source, itemName)
        return item and item.amount and item.amount > 0 or false
    end

    if activeInventory == 'core_inventory' then
        local item = exports['core_inventory']:getItem(source, itemName)
        return item and item.count and item.count > 0 or false
    end

    if activeInventory == 'qb' then
        local item = player.Functions.GetItemByName(itemName)
        return item and item.amount and item.amount > 0 or false
    end

    local item = player.getInventoryItem(itemName)
    return item and item.count and item.count > 0 or false
end

local function removeItem(source, itemName, amount)
    amount = amount or 1

    if activeInventory == 'ox_inventory' then
        return exports.ox_inventory:RemoveItem(source, itemName, amount)
    end

    local player = getPlayer(source)
    if not player then
        return false
    end

    if activeInventory == 'qb-inventory' or activeInventory == 'lj-inventory' or activeInventory == 'ps-inventory' or activeInventory == 'qb' then
        return player.Functions.RemoveItem(itemName, amount, false, nil)
    end

    if activeInventory == 'qs-inventory' then
        return exports['qs-inventory']:RemoveItem(source, itemName, amount)
    end

    if activeInventory == 'codem-inventory' then
        return exports['codem-inventory']:RemoveItem(source, itemName, amount)
    end

    if activeInventory == 'core_inventory' then
        return exports['core_inventory']:removeItem(source, itemName, amount)
    end

    player.removeInventoryItem(itemName, amount)
    return true
end

local callbacks = {}

callbacks.hasItem = function(source, itemName)
    return hasItem(source, itemName)
end

RegisterNetEvent('fvm_lockpick:server:callback', function(requestId, name, ...)
    local source = source
    local handler = callbacks[name]

    if not handler then
        TriggerClientEvent('fvm_lockpick:client:callback', source, requestId, false)
        return
    end

    TriggerClientEvent('fvm_lockpick:client:callback', source, requestId, handler(source, ...))
end)

RegisterNetEvent('fvm_lockpick:server:handleFail', function(itemName)
    local source = source

    if not Config.RemoveItemOnFail then
        return
    end

    local roll = math.random(1, 100)
    if roll > Config.RemoveItemChance then
        return
    end

    removeItem(source, itemName or Config.RequiredItem, 1)
end)

RegisterNetEvent('fvm_lockpick:server:setUnlocked', function(netId, plate)
    local source = source
    local vehicle = NetworkGetEntityFromNetworkId(netId)

    if vehicle == 0 then
        return
    end

    if plate and plate ~= '' then
        local vehiclePlate = string.gsub(GetVehicleNumberPlateText(vehicle), '^%s*(.-)%s*$', '%1')
        if vehiclePlate ~= plate then
            return
        end
    end

    TriggerClientEvent('fvm_lockpick:client:syncUnlock', -1, netId)
end)

CreateThread(function()
    local message = ('[%s] Framework: %s | Inventory: %s'):format(resourceName, activeFramework, activeInventory)
    print(message)
end)
