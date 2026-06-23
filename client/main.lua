local GuiTimer     = 0
local hasSurfboard = false
local currentPlate = nil

local function RentSurfboard()
    if hasSurfboard then
        lib.notify({ title = 'Surf', description = 'Vc ja possui uma prancha na agua!', type = 'error' })
        return
    end

    local c = Config.SpawnCoords

    lib.requestModel('surfboard')
    local vehicle = CreateVehicle(GetHashKey('surfboard'), c.x, c.y, c.z, c.w, true, false)
    SetVehicleNumberPlateText(vehicle, ('SURF%04d'):format(math.random(1, 9999)))
    SetModelAsNoLongerNeeded(GetHashKey('surfboard'))

    Wait(200)
    local plate = GetVehicleNumberPlateText(vehicle):gsub('%W', '')

    hasSurfboard = true
    currentPlate = plate

    Entity(vehicle).state:set('keysIn', true, true)
    SetVehicleEngineOn(vehicle, true, true, false)
    exports.mri_Qcarkeys:GiveTempKeys(plate)

    lib.notify({
        title       = 'Surf',
        description = ('Vc pagou $%d, sua prancha ja esta na agua te esperando!'):format(Config.RentalPrice),
        type        = 'success',
    })

    TriggerServerEvent('rodz-surf:Buy', Config.RentalPrice)
end

-- Spawnar NPC e registrar ox_target
CreateThread(function()
    while not LocalPlayer.state.isLoggedIn do
        Wait(500)
    end
    Wait(1000)

    local model = Config.NPC.model
    lib.requestModel(model)
    local hash = GetHashKey(model)
    local c    = Config.NPC.coords

    local npc = CreatePed(6, hash, c.x, c.y, c.z, c.w, false, true)
    Wait(100)

    if not DoesEntityExist(npc) then
        print('^1[rodz-surf] Falha ao criar NPC')
        return
    end

    SetEntityInvincible(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
    FreezeEntityPosition(npc, true)
    SetPedRandomComponentVariation(npc, false)
    SetModelAsNoLongerNeeded(hash)

    exports.ox_target:addLocalEntity(npc, {
        {
            name     = 'surf_rent',
            icon     = 'fa-solid fa-water',
            label    = ('Alugar Prancha - $%d'):format(Config.RentalPrice),
            onSelect = function()
                RentSurfboard()
            end,
        },
    })
end)

-- Marker no ponto de devolucao
CreateThread(function()
    while true do
        Wait(0)
        local c    = Config.SpawnCoords
        local dist = #(GetEntityCoords(PlayerPedId()) - vector3(c.x, c.y, c.z))
        if dist < 5.0 then
            DrawMarker(27, c.x, c.y, c.z - 0.15, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 3.0, 3.0, 3.0, 0, 150, 255, 150, false, true, 2, false, false, false, false)
        else
            Wait(200)
        end
    end
end)

-- Devolucao da prancha
CreateThread(function()
    while true do
        Wait(0)
        local playerPed = PlayerPedId()
        local vehicle   = GetVehiclePedIsIn(playerPed, false)

        if vehicle == 0 or GetEntityModel(vehicle) ~= GetHashKey('surfboard') then
            Wait(500)
            goto continue
        end

        local c    = Config.SpawnCoords
        local dist = #(GetEntityCoords(playerPed) - vector3(c.x, c.y, c.z))

        if dist < 3.0 and IsControlJustPressed(0, 38) and (GetGameTimer() - GuiTimer) > 300 then
            GuiTimer = GetGameTimer()
            TaskLeaveVehicle(playerPed, vehicle, 0)
            Wait(1500)
            if DoesEntityExist(vehicle) then
                DeleteVehicle(vehicle)
            end
            if currentPlate then
                exports.mri_Qcarkeys:RemoveTempKeys(currentPlate)
                currentPlate = nil
            end
            hasSurfboard = false
            lib.notify({ title = 'Surf', description = 'Prancha devolvida, valeu!', type = 'success' })
        end

        ::continue::
    end
end)

-- Blip
CreateThread(function()
    local c    = Config.NPC.coords
    local blip = AddBlipForCoord(c.x, c.y, c.z)
    SetBlipSprite(blip, 409)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.6)
    SetBlipColour(blip, 0)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Surf Area')
    EndTextCommandSetBlipName(blip)
end)
