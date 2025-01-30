local cooldownActive = false
local RobbedRegisters = {}

CreateThread(function()
    TriggerServerEvent('cy_storerobbery:GetSave')
    AddTargetModel('prop_till_01', {
        {
            icon = 'fa-solid fa-cash-register',
            label = "Røv kassaapparat",
            distance = 2.0,
            action = function(entity)
                if type(entity) == 'table' then entity = entity.entity end
                local coords = GetEntityCoords(entity)
                local coordsID = tostring(math.floor(coords.x+coords.y+coords.z))
                if RobbedRegisters[coordsID] then return TriggerEvent('ox_lib:notify',{title = 'Register blev for nyligt røvet.', type = 'error'})end
                if math.abs(GetEntityHeading(entity)-GetEntityHeading(PlayerPedId())) > 70 then return TriggerEvent('ox_lib:notify',{title = 'Du er ikke bag disken!', type = 'error'}) end
                RequestAnimDict("streamed_core_fps")
                while (not HasAnimDictLoaded("melee@small_wpn@streamed_core_fps")) do Citizen.Wait(0) end
                TaskPlayAnim(PlayerPedId(),"melee@small_wpn@streamed_core_fps","car_down_attack",1.0,-1.0, -1, 1, 1, true, true, true)
                local success = lib.skillCheck({'easy', 'easy', {areaSize = 60, speedMultiplier = 1}, 'hard'}, {'w', 'a', 's', 'd'})
                local looted = false
                local m = math.random(Config.Min, Config.Max)
                if success then
                    ClearPedTasks(PlayerPedId())
                    Wait(500)
                    lib.playAnim(PlayerPedId(),"oddjobs@shop_robbery@rob_till","loop",1.0,-1.0, -1, 1, 1, true, true, true)
                    SetEntityHeading(PlayerPedId(), math.abs(GetEntityHeading(entity)))
                    CreationCamHead(1.2)
                    exports['ps-dispatch']:StoreRobbery(1)
                    exports.peuren_minigames:StartLooting({
                        [math.random(1,12)] = {item = "money", amount = m}
                    }, 700, {x = 4, y = 3}, function(index)
                        TriggerServerEvent('cy_storerobbery:Reward', coordsID, m)
                        looted = true
                        return true
                    end)
                    if looted then ResetCamera() else ResetCamera() end
                else
                    ClearPedTasks(PlayerPedId())
                end
            end,
            
            canInteract = function(entity)
                for i, shop in pairs(Shops) do
                    if #(GetEntityCoords(entity) - shop.counter) < 10.0 then
                        local weaponinhand = exports.ox_inventory:getCurrentWeapon()
                        if weaponinhand then
                            local weaponName = weaponinhand.name
                            if weaponName == "WEAPON_CROWBAR" then
                                return true
                            end
                        else
                            return false
                        end
                    end
                end
                return false
            end,
        }
    })
end)
function ResetCamera()
    RenderScriptCams(false, false, 0, true, false)
    DestroyAllCams(true)
    ClearPedTasks(PlayerPedId())
end
function CreationCamHead(distance)
    cam = CreateCam('DEFAULT_SCRIPTED_CAMERA')

    local coordsCam = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 0.5 + distance, 0.65)
    local coordsPly = GetEntityCoords(PlayerPedId())
    SetCamCoord(cam, coordsCam)
    PointCamAtCoord(cam, coordsPly['x'], coordsPly['y'], coordsPly['z'] + 0.65)

    SetCamActive(cam, true)
    RenderScriptCams(true, true, 500, true, true)
end
function AddTargetModel(model, options)
    for i, option in pairs(options) do option.onSelect = option.action end
        exports.ox_target:addModel(model, options)
end

RegisterNetEvent('cy_storerobbery:UpdateRegister', function(NewData)
    RobbedRegisters = NewData
end)

