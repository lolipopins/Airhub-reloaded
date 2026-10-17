--// ============================================================================
--// AirHub — rivals extra tab (Chunked GC + Robust Hook)
--// ============================================================================
local H = getgenv().AirHub
if not H or not H._CoreLoaded then return end
if H.Rivals and H.Rivals._Loaded then return end

local Util        = H.Util
local LocalPlayer = Util.LocalPlayer

H.Rivals = H.Rivals or {}
local R = H.Rivals
R._Loaded = true

R.Settings = R.Settings or {
    Enabled       = false,
    NoSpread      = true,
    NoRecoil      = true,
    RapidFire     = true,
    SpreadValue   = 0,
    RecoilValue   = 0,
    FireRateValue = 0.01,
}

R.Internal = R.Internal or {
    LoopActive = false,
    Hooked     = false,
}
R.Functions = R.Functions or {}

local function log(msg) print("[AirHub] rivals: " .. tostring(msg)) end

--// ============================================================================
--// РЕКУРСИВНОЕ ПРИМЕНЕНИЕ СТАТОВ (Ищет во вложенных таблицах)
--// ============================================================================
local function applyStats(tbl, depth)
    if type(tbl) ~= "table" or depth > 3 then return end
    
    -- Применяем статы, если нашли
    if R.Settings.NoSpread then
        if tbl.ShootSpread ~= nil then tbl.ShootSpread = R.Settings.SpreadValue end
        if tbl.Spread ~= nil then tbl.Spread = R.Settings.SpreadValue end
        if tbl.Inaccuracy ~= nil then tbl.Inaccuracy = R.Settings.SpreadValue end
        if tbl.WeaponSpread ~= nil then tbl.WeaponSpread = R.Settings.SpreadValue end
    end
    
    if R.Settings.NoRecoil then
        if tbl.ShootRecoil ~= nil then tbl.ShootRecoil = R.Settings.RecoilValue end
        if tbl.Recoil ~= nil then tbl.Recoil = R.Settings.RecoilValue end
        if tbl.CameraRecoil ~= nil then tbl.CameraRecoil = R.Settings.RecoilValue end
    end
    
    if R.Settings.RapidFire then
        if tbl.ShootCooldown ~= nil then tbl.ShootCooldown = 0 end
        if tbl.Cooldown ~= nil then tbl.Cooldown = 0 end
        if tbl.FireRate ~= nil then tbl.FireRate = R.Settings.FireRateValue end
    end

    -- Рекурсивно проверяем вложенные таблицы (например, .Info)
    for k, v in pairs(tbl) do
        if type(v) == "table" and k ~= "Parent" then
            applyStats(v, depth + 1)
        end
    end
end

--// ============================================================================
--// ФОНОВЫЙ СКАН (Без лагов, порциями)
--// ============================================================================
local function startBackgroundScan()
    if R.Internal.LoopActive then return end
    R.Internal.LoopActive = true
    
    task.spawn(function()
        while R.Internal.LoopActive and not H.ShuttingDown do
            if R.Settings.Enabled then
                local ok, gc = pcall(getgc, true)
                if ok and type(gc) == "table" then
                    local count = 0
                    for _, obj in pairs(gc) do
                        if type(obj) == "table" then
                            -- Быстрая проверка, есть ли тут оружейные статы
                            if obj.ShootSpread ~= nil or obj.ShootRecoil ~= nil or obj.ShootCooldown ~= nil then
                                applyStats(obj, 0)
                            end
                        end
                        
                        -- Каждые 1000 таблиц делаем паузу, чтобы не лагало
                        count = count + 1
                        if count % 1000 == 0 then
                            task.wait()
                        end
                    end
                end
            end
            task.wait(2) -- Спим 2 секунды перед следующим сканом
        end
    end)
end

--// ============================================================================
--// ХУК ВЫСТРЕЛА (Мгновенное применение)
--// ============================================================================
local function hookInput()
    if R.Internal.Hooked then return end
    
    local path = LocalPlayer.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem
    local ok, ClientItem = pcall(require, path)
    if not ok or not ClientItem or not ClientItem.Input then return end
    
    local oldInput = ClientItem.Input
    local newInput = function(self, ...)
        if R.Settings.Enabled and type(self) == "table" then
            -- Применяем статы прямо к объекту оружия перед выстрелом
            applyStats(self, 0)
        end
        return oldInput(self, ...)
    end

    if hookfunction then
        hookfunction(ClientItem.Input, newInput)
    else
        ClientItem.Input = newInput
    end
    
    R.Internal.Hooked = true
    log("Input hook installed")
end

--// ============================================================================
--// UI (airhubUI)
--// ============================================================================
task.spawn(function()
    local deadline = tick() + 30
    while tick() < deadline do
        if getgenv().airhubUI_Window then break end
        task.wait(0.25)
    end

    local Window = getgenv().airhubUI_Window
    if not Window then return end

    local tab = Window:AddTab({ Name = "rivals", Icon = "R" })
    local secMain = tab:CreateSection({ Name = "Rivals Mods" })

    secMain:AddToggle({
        Name = "Enabled",
        Value = R.Settings.Enabled,
        Callback = function(v)
            R.Settings.Enabled = v
            if v then
                hookInput()
                startBackgroundScan()
            end
        end,
    })

    secMain:AddToggle({
        Name = "No Spread",
        Value = R.Settings.NoSpread,
        Callback = function(v) R.Settings.NoSpread = v end,
    })
    secMain:AddSlider({
        Name = "Spread Value",
        Value = R.Settings.SpreadValue,
        Min = 0, Max = 10, Decimals = 2,
        Callback = function(v) R.Settings.SpreadValue = v end,
    })

    secMain:AddToggle({
        Name = "No Recoil",
        Value = R.Settings.NoRecoil,
        Callback = function(v) R.Settings.NoRecoil = v end,
    })
    secMain:AddSlider({
        Name = "Recoil Value",
        Value = R.Settings.RecoilValue,
        Min = 0, Max = 10, Decimals = 2,
        Callback = function(v) R.Settings.RecoilValue = v end,
    })

    secMain:AddToggle({
        Name = "Rapid Fire",
        Value = R.Settings.RapidFire,
        Callback = function(v) R.Settings.RapidFire = v end,
    })
    secMain:AddSlider({
        Name = "Fire Rate Value",
        Value = R.Settings.FireRateValue,
        Min = 0.001, Max = 0.5, Decimals = 3,
        Callback = function(v) R.Settings.FireRateValue = v end,
    })

    print("[AirHub] rivals extra tab: loaded")
end)

R.Functions.StopAll = function() 
    R.Settings.Enabled = false 
    R.Internal.LoopActive = false
end
