local currentRequest = 0
local pendingRequests = {}

local function requestServer(name, ...)
    currentRequest += 1

    local requestId = currentRequest
    local promise = promise.new()

    pendingRequests[requestId] = promise

    TriggerServerEvent('fvm_lockpick:server:callback', requestId, name, ...)

    return Citizen.Await(promise)
end

RegisterNetEvent('fvm_lockpick:client:callback', function(requestId, ...)
    local pending = pendingRequests[requestId]
    if not pending then
        return
    end

    pendingRequests[requestId] = nil
    pending:resolve({ ... })
end)

local function getPlate(vehicle)
    return string.gsub(GetVehicleNumberPlateText(vehicle), '^%s*(.-)%s*$', '%1')
end

local function notify(message)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, false)
end

local function isDriverDoorAccessible(vehicle, distance)
    local boneIndex = GetEntityBoneIndexByName(vehicle, 'door_dside_f')
    if boneIndex == -1 then
        return false
    end

    local boneCoords = GetWorldPositionOfEntityBone(vehicle, boneIndex)
    local playerCoords = GetEntityCoords(PlayerPedId())

    return #(playerCoords - boneCoords) <= (distance + 0.35)
end

local function isVehicleLocked(vehicle)
    local status = GetVehicleDoorLockStatus(vehicle)
    return status ~= 0 and status ~= 1
end

local function unlockVehicle(vehicle)
    SetVehicleDoorsLocked(vehicle, 1)
    SetVehicleDoorsLockedForAllPlayers(vehicle, false)
    SetVehicleNeedsToBeHotwired(vehicle, false)
    SetVehicleAlarm(vehicle, false)
    StartVehicleAlarm(vehicle)
end

local function tryLockpick(vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) or GetEntityType(vehicle) ~= 2 then
        notify(Lang('invalid_vehicle'))
        return
    end

    if not isDriverDoorAccessible(vehicle, Config.TargetDistance) then
        return
    end

    if not isVehicleLocked(vehicle) then
        return
    end

    local hasItemResponse = requestServer('hasItem', Config.RequiredItem)
    local hasItem = hasItemResponse and hasItemResponse[1]

    if not hasItem then
        notify(Lang('no_item'))
        return
    end

    local success = exports['t3_lockpick']:startLockpick(
        Config.Lockpick.item,
        Config.Lockpick.difficulty,
        Config.Lockpick.pins
    )

    if success then
        unlockVehicle(vehicle)
        TriggerServerEvent('fvm_lockpick:server:setUnlocked', VehToNet(vehicle), getPlate(vehicle))
        notify(Lang('unlocked'))
        return
    end

    TriggerServerEvent('fvm_lockpick:server:handleFail', Config.RequiredItem)
    notify(Lang('failed'))
end

CreateThread(function()
    exports.ox_target:addGlobalVehicle({
        {
            name = 'fvm_lockpick:vehicle',
            icon = Config.TargetIcon,
            label = Lang('target_label'),
            distance = Config.TargetDistance,
            bones = { 'door_dside_f' },
            canInteract = function(entity)
                if not entity or entity == 0 then
                    return false
                end

                if IsPedInAnyVehicle(PlayerPedId(), false) then
                    return false
                end

                return isVehicleLocked(entity) and isDriverDoorAccessible(entity, Config.TargetDistance)
            end,
            onSelect = function(data)
                tryLockpick(data.entity)
            end
        }
    })
end)

RegisterNetEvent('fvm_lockpick:client:syncUnlock', function(netId)
    local vehicle = NetToVeh(netId)
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        return
    end

    unlockVehicle(vehicle)
end)
