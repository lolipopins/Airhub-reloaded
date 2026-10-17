--// ============================================================================
--// AirHub — rivals extra tab (Оптимизированная версия без лагов)
--// ============================================================================
local H = getgenv().AirHub
if not H or not H._CoreLoaded then return end
if H.Rivals and H.Rivals._Loaded then return end

local Util        = H.Util
local RunService  = Util.RunService
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
    SeenTables    = setmetatable({}, {__mode = "k"}), -- Слабые ключи (защита от утечек памяти)
    Conns         = {},
}
R.Functions = R.Functions or {}

local function log(msg) print("[AirHub] rivals: " .. tostring(msg)) end

--// ============================================================================
--// СКАНИРОВАНИЕ ПАМЯТИ (Только для первичного поиска)
--// ============================================================================
local function scanGCForGuns()
    local ok, gc = pcall(getgc, true)
    if not ok or type(gc) ~= "table" then return end

    local found = 0
    for _, obj in pairs(gc) do
        if type(obj) == "table" and not R.Internal.SeenTables[obj] then
            -- Проверяем, есть ли в таблице оружейные статы
            if rawget(obj, "ShootSpread") ~= nil or rawget(obj, "ShootRecoil") ~= nil or rawget(obj, "ShootCooldown") ~= nil then
                table.insert(R.Internal.CachedTables, obj)
                R.Internal.SeenTables[obj] = true
                found = found + 1
            end
        end
    end
    if found > 0 then
        log("Кэшировано новых таблиц: " .. found .. " (Всего в кэше: " .. #R.Internal.CachedTables .. ")")
    end
end

--// ============================================================================
--// ПРИМЕНЕНИЕ МОДОВ (Очень быстрое, без getgc)
--// ============================================================================
local function applyMods()
    if not R.Settings.Enabled then return end
    
    for _, tbl in ipairs(R.Internal.CachedTables) do
        if R.Settings.NoSpread then
            if rawget(tbl, "ShootSpread") ~= nil then pcall(function() tbl.ShootSpread = R.Settings.SpreadValue end) end
            if rawget(tbl, "Spread") ~= nil then pcall(function() tbl.Spread = R.Settings.SpreadValue end) end
        end
        
        if R.Settings.NoRecoil then
            if rawget(tbl, "ShootRecoil") ~= nil then pcall(function() tbl.ShootRecoil = R.Settings.RecoilValue end) end
            if rawget(tbl, "Recoil") ~= nil then pcall(function() tbl.Recoil = R.Settings.RecoilValue end) end
        end
        
        if R.Settings.RapidFire then
            if rawget(tbl, "ShootCooldown") ~= nil then pcall(function() tbl.ShootCooldown = 0 end) end
            if rawget(tbl, "FireRate") ~= nil then pcall(function() tbl.FireRate = R.Settings.FireRateValue end) end
        end
        
        -- Проверяем вложенный Info (в Rivals статы бывают там)
        local info = rawget(tbl, "Info")
        if type(info) == "table" then
            if R.Settings.NoSpread and rawget(info, "ShootSpread") ~= nil then pcall(function() info.ShootSpread = R.Settings.SpreadValue end) end
            if R.Settings.NoRecoil and rawget(info, "ShootRecoil") ~= nil then pcall(function() info.ShootRecoil = R.Settings.RecoilValue end) end
            if R.Settings.RapidFire and rawget(info, "ShootCooldown") ~= nil then pcall(function() info.ShootCooldown = 0 end) end
        end
    end
end

--// ============================================================================
--// ХУК ВЫСТРЕЛА (Ловит новые пушки на лету)
--// ============================================================================
local function hookInput()
    local path = LocalPlayer.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem
    local ok, ClientItem = pcall(require, path)
    if not ok or not ClientItem or not ClientItem.Input then return end
    
    if getgenv().Rivals_Opt_Hooked then return end
    getgenv().Rivals_Opt_Hooked = true
    
    local oldInput = ClientItem.Input
    ClientItem.Input = function(self, ...)
        if R.Settings.Enabled and type(self) == "table" then
            -- Добавляем новую пушку в кэш, если ее там еще нет
            if not R.Internal.SeenTables[self] then
                table.insert(R.Internal.CachedTables, self)
                R.Internal.SeenTables[self] = true
            end
            -- Применяем моды прямо перед выстрелом
            applyMods()
        end
        return oldInput(self, ...)
    end
end

--// ============================================================================
--// ЗАПУСК / ОСТАНОВКА
--// ============================================================================
local function startRivals()
    scanGCForGuns()
    hookInput()
    applyMods()

    if not R.Internal.Conns.heartbeat then
        -- Оптимизированный цикл: обновляем только закэшированные таблицы
        R.Internal.Conns.heartbeat = RunService.Heartbeat:Connect(function()
            if H.ShuttingDown then return end
            applyMods()
        end)
    end

    -- Раз в 10 секунд делаем легкий ре-скан (на случай если пушка загрузилась без выстрела)
    if not R.Internal.Conns.rescan then
        task.spawn(function()
            while R.Settings.Enabled and not H.ShuttingDown do
                task.wait(10)
                if R.Settings.Enabled then
                    scanGCForGuns()
                end
            end
        end)
    end
end

local function stopRivals()
    R.Settings.Enabled = false
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
            if v then startRivals() else stopRivals() end
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
        Name = "Force Rescan Memory",
        Callback = function()
            scanGCForGuns()
        end,
    })

    print("[AirHub] rivals extra tab: optimized tab created")
end)

R.Functions.StopAll = function() stopRivals() end
