--// ============================================================================
--// AirHub — rivals extra tab (Zero-Lag версия)
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
    CachedTables  = {},
    SeenTables    = setmetatable({}, {__mode = "k"}), 
}
R.Functions = R.Functions or {}

local function log(msg) print("[AirHub] rivals: " .. tostring(msg)) end

--// ============================================================================
--// ПРИМЕНЕНИЕ (Срабатывает только при выстреле или по кнопке)
--// ============================================================================
local function applyMods()
    if not R.Settings.Enabled then return end
    
    for _, tbl in ipairs(R.Internal.CachedTables) do
        if R.Settings.NoSpread then
            if tbl.ShootSpread then tbl.ShootSpread = R.Settings.SpreadValue end
            if tbl.Spread then tbl.Spread = R.Settings.SpreadValue end
        end
        
        if R.Settings.NoRecoil then
            if tbl.ShootRecoil then tbl.ShootRecoil = R.Settings.RecoilValue end
            if tbl.Recoil then tbl.Recoil = R.Settings.RecoilValue end
        end
        
        if R.Settings.RapidFire then
            if tbl.ShootCooldown then tbl.ShootCooldown = 0 end
            if tbl.FireRate then tbl.FireRate = R.Settings.FireRateValue end
        end
        
        -- Вложенный Info
        local info = tbl.Info
        if type(info) == "table" then
            if R.Settings.NoSpread and info.ShootSpread then info.ShootSpread = R.Settings.SpreadValue end
            if R.Settings.NoRecoil and info.ShootRecoil then info.ShootRecoil = R.Settings.RecoilValue end
            if R.Settings.RapidFire and info.ShootCooldown then info.ShootCooldown = 0 end
        end
    end
end

--// ============================================================================
--// ХУК ВЫСТРЕЛА (Главная защита от лагов)
--// ============================================================================
local function hookInput()
    local path = LocalPlayer.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem
    local ok, ClientItem = pcall(require, path)
    if not ok or not ClientItem or not ClientItem.Input then return end
    
    if getgenv().Rivals_ZeroLag_Hooked then return end
    getgenv().Rivals_ZeroLag_Hooked = true
    
    local oldInput = ClientItem.Input
    ClientItem.Input = function(self, ...)
        if R.Settings.Enabled and type(self) == "table" then
            -- Применяем статы прямо перед выстрелом (это мгновенно)
            if R.Settings.NoSpread then
                if self.ShootSpread then self.ShootSpread = R.Settings.SpreadValue end
                if self.Spread then self.Spread = R.Settings.SpreadValue end
            end
            if R.Settings.NoRecoil then
                if self.ShootRecoil then self.ShootRecoil = R.Settings.RecoilValue end
            end
            if R.Settings.RapidFire then
                if self.ShootCooldown then self.ShootCooldown = 0 end
            end
        end
        return oldInput(self, ...)
    end
end

--// ============================================================================
--// ЕДИНОРАЗОВЫЙ СКАН (Только при нажатии Enable)
--// ============================================================================
local function scanOnce()
    local ok, gc = pcall(getgc, true)
    if not ok or type(gc) ~= "table" then return end

    local found = 0
    for _, obj in pairs(gc) do
        if type(obj) == "table" and not R.Internal.SeenTables[obj] then
            if obj.ShootSpread or obj.ShootRecoil or obj.ShootCooldown then
                table.insert(R.Internal.CachedTables, obj)
                R.Internal.SeenTables[obj] = true
                found = found + 1
            end
        end
    end
    log("Найдено и закэшировано таблиц оружия: " .. found)
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
                scanOnce()  -- Вызывается 1 раз!
                applyMods() -- Мгновенно применяем то, что нашли
            end
        end,
    })

    secMain:AddToggle({
        Name = "No Spread",
        Value = R.Settings.NoSpread,
        Callback = function(v) R.Settings.NoSpread = v; applyMods() end,
    })
    secMain:AddSlider({
        Name = "Spread Value",
        Value = R.Settings.SpreadValue,
        Min = 0, Max = 10, Decimals = 2,
        Callback = function(v) R.Settings.SpreadValue = v; applyMods() end,
    })

    secMain:AddToggle({
        Name = "No Recoil",
        Value = R.Settings.NoRecoil,
        Callback = function(v) R.Settings.NoRecoil = v; applyMods() end,
    })
    secMain:AddSlider({
        Name = "Recoil Value",
        Value = R.Settings.RecoilValue,
        Min = 0, Max = 10, Decimals = 2,
        Callback = function(v) R.Settings.RecoilValue = v; applyMods() end,
    })

    secMain:AddToggle({
        Name = "Rapid Fire",
        Value = R.Settings.RapidFire,
        Callback = function(v) R.Settings.RapidFire = v; applyMods() end,
    })
    secMain:AddSlider({
        Name = "Fire Rate Value",
        Value = R.Settings.FireRateValue,
        Min = 0.001, Max = 0.5, Decimals = 3,
        Callback = function(v) R.Settings.FireRateValue = v; applyMods() end,
    })

    local secDbg = tab:CreateSection({ Name = "Debug" })
    secDbg:AddButton({
        Name = "Manual Rescan (может вызвать 1 сек. фриз)",
        Callback = function()
            scanOnce()
            applyMods()
        end,
    })

    print("[AirHub] rivals extra tab: zero-lag tab created")
end)

R.Functions.StopAll = function() R.Settings.Enabled = false end
