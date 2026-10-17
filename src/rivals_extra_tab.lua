--// ============================================================================
--// AirHub — rivals extra tab (airhubUI build)
--// Метод: Бесконечный цикл getgc + Хук ClientItem.Input
--// ============================================================================
local H = getgenv().AirHub
if not H or not H._CoreLoaded then 
    warn("[AirHub] rivals extra tab: core not loaded") 
    return 
end
if H.Rivals and H.Rivals._Loaded then 
    warn("[AirHub] rivals extra tab: already loaded") 
    return 
end

local Util        = H.Util
local RunService  = Util.RunService
local LocalPlayer = Util.LocalPlayer
local Track       = Util.Track

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
}
R.Functions = R.Functions or {}

local function log(msg) 
    print("[AirHub] rivals: " .. tostring(msg)) 
end

--// ============================================================================
--// ЯДРО МОДИФИКАЦИИ (getgc)
--// ============================================================================
local function applyModsToGc()
    if not R.Settings.Enabled then return end
    
    local ok, gc = pcall(getgc, true)
    if not ok or type(gc) ~= "table" then return end

    for _, gcVal in pairs(gc) do
        if type(gcVal) == "table" then
            -- 1. Проверяем прямые свойства (rawget чтобы избежать ошибок метатаблиц)
            if R.Settings.NoSpread then
                if rawget(gcVal, "ShootSpread") ~= nil then pcall(function() gcVal.ShootSpread = R.Settings.SpreadValue end) end
                if rawget(gcVal, "Spread") ~= nil then pcall(function() gcVal.Spread = R.Settings.SpreadValue end) end
            end

            if R.Settings.NoRecoil then
                if rawget(gcVal, "ShootRecoil") ~= nil then pcall(function() gcVal.ShootRecoil = R.Settings.RecoilValue end) end
                if rawget(gcVal, "Recoil") ~= nil then pcall(function() gcVal.Recoil = R.Settings.RecoilValue end) end
            end

            if R.Settings.RapidFire then
                if rawget(gcVal, "ShootCooldown") ~= nil then pcall(function() gcVal.ShootCooldown = 0 end) end
                if rawget(gcVal, "FireRate") ~= nil then pcall(function() gcVal.FireRate = R.Settings.FireRateValue end) end
            end

            -- 2. Проверяем вложенную таблицу .Info (в Rivals статы часто лежат там)
            local info = rawget(gcVal, "Info")
            if type(info) == "table" then
                if R.Settings.NoSpread then
                    if rawget(info, "ShootSpread") ~= nil then pcall(function() info.ShootSpread = R.Settings.SpreadValue end) end
                end
                if R.Settings.NoRecoil then
                    if rawget(info, "ShootRecoil") ~= nil then pcall(function() info.ShootRecoil = R.Settings.RecoilValue end) end
                end
                if R.Settings.RapidFire then
                    if rawget(info, "ShootCooldown") ~= nil then pcall(function() info.ShootCooldown = 0 end) end
                    if rawget(info, "FireRate") ~= nil then pcall(function() info.FireRate = R.Settings.FireRateValue end) end
                end
            end
        end
    end
end

--// ============================================================================
--// ХУК ВЫСТРЕЛА (Для надежности)
--// ============================================================================
local function hookInput()
    local ok, ClientItem = pcall(require, LocalPlayer.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem)
    if not ok or not ClientItem or not ClientItem.Input then return end
    
    if getgenv().Rivals_InputHooked then return end
    getgenv().Rivals_InputHooked = true
    
    local oldInput = ClientItem.Input
    ClientItem.Input = function(self, ...)
        if R.Settings.Enabled and type(self) == "table" then
            pcall(function()
                if R.Settings.NoSpread and rawget(self, "ShootSpread") ~= nil then self.ShootSpread = R.Settings.SpreadValue end
                if R.Settings.NoRecoil and rawget(self, "ShootRecoil") ~= nil then self.ShootRecoil = R.Settings.RecoilValue end
                if R.Settings.RapidFire and rawget(self, "ShootCooldown") ~= nil then self.ShootCooldown = 0 end
                
                if self.Info then
                    if R.Settings.NoSpread and rawget(self.Info, "ShootSpread") ~= nil then self.Info.ShootSpread = R.Settings.SpreadValue end
                    if R.Settings.NoRecoil and rawget(self.Info, "ShootRecoil") ~= nil then self.Info.ShootRecoil = R.Settings.RecoilValue end
                    if R.Settings.RapidFire and rawget(self.Info, "ShootCooldown") ~= nil then self.Info.ShootCooldown = 0 end
                end
            end)
        end
        return oldInput(self, ...)
    end
end

--// ============================================================================
--// ФОНОВЫЙ ЦИКЛ (Раз в 0.1 сек)
--// ============================================================================
local function startLoop()
    if R.Internal.LoopActive then return end
    R.Internal.LoopActive = true
    
    task.spawn(function()
        while R.Internal.LoopActive and not H.ShuttingDown do
            if R.Settings.Enabled then
                applyModsToGc()
            end
            task.wait(0.1)
        end
    end)
end

--// ============================================================================
--// UI (airhubUI)
--// ============================================================================
task.spawn(function()
    local deadline = tick() + 30
    while tick() < deadline do
        if H.ShuttingDown then return end
        if getgenv().airhubUI_Window then break end
        task.wait(0.25)
    end

    local Window = getgenv().airhubUI_Window
    if not Window then
        warn("[AirHub] rivals extra tab: airhubUI Window never appeared")
        return
    end

    local tab = Window:AddTab({ Name = "rivals", Icon = "R" })
    local secMain = tab:CreateSection({ Name = "Rivals Mods" })

    secMain:AddToggle({
        Name = "Enabled",
        Value = R.Settings.Enabled,
        Callback = function(v)
            R.Settings.Enabled = v
            if v then
                hookInput()
                applyModsToGc() -- Мгновенное применение
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

    local secDbg = tab:CreateSection({ Name = "Debug" })
    secDbg:AddButton({
        Name = "Force Apply Now",
        Callback = function()
            log("Manual force apply triggered")
            applyModsToGc()
        end,
    })

    print("[AirHub] rivals extra tab: tab created")
end)

startLoop()
R.Functions.StopAll = function() R.Settings.Enabled = false end
log("extra tab loaded OK (getgc loop + hook)")
