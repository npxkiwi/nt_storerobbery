local QBCore = exports['qb-core']:GetCoreObject()

local Data = nil
local RobbedRegisters = nil
local  TimeSeconds = {
    ['days'] = 86400,
    ['hours'] = 3600,
    ['minutes'] = 60,
    ['seconds'] = 1,
}

function sendLogs(color, name, message, footer, logs)
    local embed = {
          {
              ["color"] = color,
              ["title"] = "**".. name .."**",
              ["description"] = message,
              ["footer"] = {
                  ["text"] = footer,
              },
          }
      }
  
    PerformHttpRequest(logs, function(err, text, headers) end, 'POST', json.encode({username = name, embeds = embed}), { ['Content-Type'] = 'application/json' })
end

CreateThread(function() 
    Data = json.decode(LoadResourceFile('cy_storerobbery', 'Save.json')) or {}
    local currentTime = os.time()
    local TimePassed = 0
    if Data.lastSave then
        TimePassed = FormatTime(os.difftime(currentTime, Data.lastSave))
    end
    if not Data.lastSave or TimePassed[Config.storeCooldown.time] >= Config.storeCooldown.amount then
        Data.lastSave = currentTime
        Data.RobbedRegisters  = {}
        SaveResourceFile('cy_storerobbery', 'Save.json', json.encode(Data), -1)
        CooldownLoop(0)
    else
        CooldownLoop(TimePassed['seconds'])
    end
    RobbedRegisters = Data.RobbedRegisters
end)

RegisterNetEvent('cy_storerobbery:GetSave', function()
    local src = source
    TriggerClientEvent('cy_storerobbery:UpdateRegister', src, RobbedRegisters)
end)
RegisterNetEvent('cy_storerobbery:Reward', function(id, amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if RobbedRegisters[id] == true then return end
    RobbedRegisters[id] = true
    TriggerClientEvent('cy_storerobbery:UpdateRegister', -1, RobbedRegisters)
    UpdateFile()
    AddItem(src, 'money', amount)
    DoNotification(src, "Du modtog ".. format_int(amount) .." DDK", "success")
    sendLogs(7730498, "CY STORE ROBBERY", "Player: ".. Player.PlayerData.name .. "\nMoney Amount: " ..format_int(amount).. " DDK", "Lavet af Notepad", Config.Logs.RegisterRobbed)
end)

function UpdateFile()
    Data.RobbedRegisters = RobbedRegisters
    SaveResourceFile('cy_storerobbery', 'Save.json', json.encode(Data), -1)
end

function FormatTime(time)
    local days = math.floor(time/86400)
    local hours = math.floor(math.modf(time, 86400)/3600)
    local minutes = math.floor(math.modf(time,3600)/60)
    local seconds = math.floor(math.modf(time,60))
    return {days = days,hours = hours,minutes = minutes,seconds = seconds}
end

function format_int(number)

    local i, j, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')
  
    -- reverse the int-string and append a comma to all blocks of 3 digits
    int = int:reverse():gsub("(%d%d%d)", "%1,")
  
    -- reverse the int-string back remove an optional comma and put the 
    -- optional minus and fractional part back
    return minus .. int:reverse():gsub("^,", "") .. fraction
  end

function CooldownLoop(secondsPassed)
    SetTimeout(((TimeSeconds[Config.storeCooldown.time] * Config.storeCooldown.amount) - secondsPassed) *1000, function()
        local currentTime = os.time()
        Data.lastSave = currentTime
        Data.RobbedRegisters = {}
        SaveResourceFile('cy_storerobbery', 'Save.json', json.encode(Data), -1)
        CooldownLoop(0)
    end)
end