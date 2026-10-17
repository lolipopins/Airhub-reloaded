--// ============================================================================
--// AirHub — rivals extra tab (airhubUI build) — ULTRA SEARCH
--// ============================================================================
local H = getgenv().AirHub
if not H or not H._CoreLoaded then warn("[AirHub] rivals extra tab: core not loaded") return end
if H.Rivals and H.Rivals._Loaded then warn("[AirHub] rivals extra tab: already loaded") return end

local Util        = H.Util
local Players     = Util.Players
local RunService  = Util.RunService
local LocalPlayer = Util.LocalPlayer
local ReplicatedStorage = Util.ReplicatedStorage
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
    GunRegistry   = {},
    Conns         = {},
    ClientItem    = nil,
    Path          = nil,
    Hooked        = false,
    ReapplyActive = false,
    OriginalInput = nil,
    FoundBy       = nil,
}
R.Functions = R.Functions or {}

local function log(msg) print("[AirHub] rivals: " .. tostring(msg)) end
local function logwarn(msg) warn("[AirHub] rivals: " .. tostring(msg)) end

--// ============================================================================
--// ULTRA SEARCH: ищем любые таблицы с оружейными полями
--// ============================================================================
local GUN_FIELDS = {
    "ShootRecoil", "ShootSpread", "FireRate", "Damage", "Cooldown",
    "Ammo", "ReloadTime", "Spread", "Recoil", "Inaccuracy",
    "WeaponSpread", "CameraRecoil", "ShootCooldown", "QuickShotCooldown"
}

local function hasGunFields(tbl)
    if type(tbl) ~= "table" then return false end
    local count = 0
    for _, field in ipairs(GUN_FIELDS) do
        if tbl[field] ~= nil then
            count = count + 1
        end
    end
    return count >= 3 -- минимум 3 оружейных поля
end

local function isClientItem(tbl)
    if type(tbl) ~= "table" then return false end
    if tbl.Input then return true end
    -- Если есть куча вложенных таблиц с Info — это тоже ClientItem
    local infoCount = 0
    for _, v in pairs(tbl) do
        if type(v) == "table" and v.Info then
            infoCount = infoCount + 1
        end
    end
    return infoCount >= 3
end

-- Поиск через getgc
local function findTablesInGC()
    local found = {}
    local ok, gc = pcall(function()
        if type(getgc) ~= "function" then return nil end
        return getgc(true)
    end)
    if not ok or type(gc) ~= "table" then return found end

    for _, obj in ipairs(gc) do
        if type(obj) == "table" then
            if isClientItem(obj) then
                table.insert(found, { type = "ClientItem", tbl = obj })
            elseif hasGunFields(obj) then
                table.insert(found, { type = "GunTable", tbl = obj })
            end
        end
    end
    return found
end

-- Поиск через getloadedmodules
local function findTablesInModules()
    local found = {}
    local ok, modules = pcall(function()
        if type(getloadedmodules) ~= "function" then return nil end
        return getloadedmodules()
    end)
    if not ok or type(modules) ~= "table" then return found end

    for _, m in ipairs(modules) do
        if type(m) == "table" then
            if isClientItem(m) then
                table.insert(found, { type = "ClientItem", tbl = m })
            elseif hasGunFields(m) then
                table.insert(found, { type = "GunTable", tbl = m })
            end
        end
    end
    return found
end

-- Поиск по путям (стандартные)
local function findClientItemByPaths()
    local candidates = {
        { "PlayerScripts", "Modules", "ClientReplicatedClasses", "ClientFighter", "ClientItem" },
        { "PlayerScripts", "ClientReplicatedClasses", "ClientFighter", "ClientItem" },
        { "PlayerScripts", "Modules", "ClientFighter", "ClientItem" },
        { "PlayerScripts", "Modules", "ClientReplicatedClasses", "ClientItem" },
        { "PlayerScripts", "ClientItem" },
        { "PlayerScripts", "Modules", "Weapons", "ClientItem" },
        { "PlayerScripts", "Modules", "ClientWeapons", "ClientItem" },
    }
    for _, path in ipairs(candidates) do
        local node = LocalPlayer
        local ok = true
        for _, name in ipairs(path) do
            local child = node and node:FindFirstChild(name)
            if not child then ok = false; break end
            node = child
        end
        if ok and node then
            local rok, mod = pcall(require, node)
            if rok and type(mod) == "table" then
                if isClientItem(mod) or hasGunFields(mod) then
                    log("found via path: " .. table.concat(path, "/"))
                    return mod, path
                end
            end
        end
    end
    return nil, nil
end

-- Главный поиск
local function findClientItem()
    -- 1. Стандартные пути
    local mod, path = findClientItemByPaths()
    if mod then
        R.Internal.FoundBy = "paths"
        return mod, path
    end

    -- 2. getloadedmodules
    local found = findTablesInModules()
    if #found > 0 then
        log("Found " .. #found .. " table(s) in loaded modules:")
        for i, f in ipairs(found) do
            log("  " .. i .. ": " .. f.type .. " (" .. tostring(f.tbl) .. ")")
        end
        R.Internal.FoundBy = "getloadedmodules"
        return found[1].tbl
    end

    -- 3. getgc
    found = findTablesInGC()
    if #found > 0 then
        log("Found " .. #found .. " table(s) in GC:")
        for i, f in ipairs(found) do
            log("  " .. i .. ": " .. f.type .. " (" .. tostring(f.tbl) .. ")")
        end
        R.Internal.FoundBy = "getgc"
        return found[1].tbl
    end

    return nil
end

local function ensureClientItem()
    if R.Internal.ClientItem then return R.Internal.ClientItem end
    local mod, path = findClientItem()
    if mod then
        R.Internal.ClientItem = mod
        R.Internal.Path = path
    end
    return mod
end

--// ============================================================================
--// GUN REGISTRY (агрессивный сбор)
--// ============================================================================
local function scanGuns()
    local ClientItem = ensureClientItem()
    if not ClientItem then return 0 end
    local registry = R.Internal.GunRegistry
    local before = 0
    for _ in pairs(registry) do before = before + 1 end

    -- Если это ClientItem с вложенными Info
    if isClientItem(ClientItem) then
        for key, value in pairs(ClientItem) do
            if type(value) == "table" and value.Info and type(value.Info) == "table" then
                registry[tostring(key)] = registry[tostring(key)] or { Info = value.Info, Original = {}, Instance = value }
            end
        end
    end

    -- Если это одиночная таблица с полями
    if hasGunFields(ClientItem) then
        local name = "Gun_" .. tostring(math.random(1000, 9999))
        registry[name] = registry[name] or { Info = ClientItem, Original = {}, Instance = ClientItem }
    end

    -- Рекурсивный обход
    local function walk(t, depth, visited)
        if depth > 5 or type(t) ~= "table" then return end
        visited = visited or {}
        if visited[t] then return end
        visited[t] = true

        for k, v in pairs(t) do
            if type(k) == "string" and type(v) == "table" then
                if v.Info and type(v.Info) == "table" then
                    registry[k] = registry[k] or { Info = v.Info, Original = {}, Instance = v }
                elseif hasGunFields(v) then
                    registry[k] = registry[k] or { Info = v, Original = {}, Instance = v }
                end
                walk(v, depth + 1, visited)
            end
        end
    end
    walk(ClientItem, 0)

    local after = 0
    for _ in pairs(registry) do after = after + 1 end

    -- Если ничего не нашли — выводим ключи ClientItem
    if after == 0 and ClientItem then
        local keys = {}
        local i = 0
        for k, v in pairs(ClientItem) do
            i = i + 1
            if i <= 30 then
                keys[#keys + 1] = tostring(k) .. "(" .. type(v) .. ")"
            end
        end
        logwarn("ClientItem found, but no guns. Keys: " .. table.concat(keys, ", "))
    end

    return after - before
end

--// ============================================================================
--// APPLY MODS
--// ============================================================================
local SPREAD_KEYS = { "ShootSpread", "Spread", "WeaponSpread", "Inaccuracy" }
local RECOIL_KEYS = { "ShootRecoil", "Recoil", "RecoilHorizontal", "RecoilVertical", "CameraRecoil" }
local RATE_KEYS   = { "ShootCooldown", "QuickShotCooldown", "Cooldown" }

local function applyToGun(name, entry)
    local info = entry.Info
    if not info then return end

    if not next(entry.Original) then
        for k, v in pairs(info) do
            if type(v) == "number" or type(v) == "boolean" then
                entry.Original[k] = v
            end
        end
    end

    local function setKeys(keys, value)
        for _, k in ipairs(keys) do
            if info[k] ~= nil then
                pcall(function() info[k] = value end)
            end
        end
    end

    local function restoreKeys(keys)
        for _, k in ipairs(keys) do
            if entry.Original[k] ~= nil then
                pcall(function() info[k] = entry.Original[k] end)
            end
        end
    end

    if R.Settings.Enabled and R.Settings.NoSpread then
        setKeys(SPREAD_KEYS, R.Settings.SpreadValue)
    else
        restoreKeys(SPREAD_KEYS)
    end

    if R.Settings.Enabled and R.Settings.NoRecoil then
        setKeys(RECOIL_KEYS, R.Settings.RecoilValue)
    else
        restoreKeys(RECOIL_KEYS)
    end

    if R.Settings.Enabled and R.Settings.RapidFire then
        setKeys(RATE_KEYS, 0)
        if info.FireRate ~= nil then
            pcall(function() info.FireRate = R.Settings.FireRateValue end)
        end
    else
        restoreKeys(RATE_KEYS)
        if entry.Original.FireRate ~= nil then
            pcall(function() info.FireRate = entry.Original.FireRate end)
        end
    end
end

local function applyAll()
    for name, entry in pairs(R.Internal.GunRegistry) do
        pcall(applyToGun, name, entry)
    end
end

--// ============================================================================
--// HOOK ClientItem.Input
--// ============================================================================
local function installHook()
    if R.Internal.Hooked then return true end
    local ClientItem = ensureClientItem()
    if not ClientItem then return false end
    if type(ClientItem.Input) ~= "function" then
        logwarn("ClientItem has no valid .Input function — cannot hook")
        return false
    end

    local originalInput = ClientItem.Input
    local function hookedInput(self, ...)
        if type(self) == "table" then
            pcall(function()
                local matched = false
                for name, entry in pairs(R.Internal.GunRegistry) do
                    if entry.Instance == self or (entry.Info and self.Info and entry.Info == self.Info) then
                        applyToGun(name, entry)
                        matched = true
                        break
                    end
                end
                if not matched and self.Info then
                    local name = tostring(self.Name or ("UnknownGun_" .. tostring(math.random(1000, 9999))))
                    R.Internal.GunRegistry[name] = { Info = self.Info, Original = {}, Instance = self }
                    applyToGun(name, R.Internal.GunRegistry[name])
                end
            end)
        end
        return originalInput(self, ...)
    end

    local ok = pcall(function()
        if hookfunction then
            R.Internal.OriginalInput = hookfunction(ClientItem.Input :: any, hookedInput)
        elseif hookmetamethod then
            R.Internal.OriginalInput = ClientItem.Input
            ClientItem.Input = hookedInput
        else
            error("no hookfunction/hookmetamethod")
        end
    end)

    if ok then
        R.Internal.Hooked = true
        log("ClientItem.Input hooked successfully")
        return true
    else
        logwarn("hook install failed — fallback to polling only")
        return false
    end
end

--// ============================================================================
--// START / STOP
--// ============================================================================
local function startRivals()
    R.Internal._t = 0
    local added = scanGuns()
    local count = 0
    for _ in pairs(R.Internal.GunRegistry) do count = count + 1 end
    log("scan: +" .. tostring(added) .. " (total " .. tostring(count) .. ") foundBy=" .. tostring(R.Internal.FoundBy or "?"))
    installHook()
    applyAll()

    if not R.Internal.ReapplyActive then
        R.Internal.ReapplyActive = true
        R.Internal.Conns.reapply = RunService.Heartbeat:Connect(function()
            if H.ShuttingDown then return end
            if not R.Settings.Enabled then return end
            R.Internal._t = (R.Internal._t or 0) + 1
            if R.Internal._t % 120 == 0 then
                local before = 0
                for _ in pairs(R.Internal.GunRegistry) do before = before + 1 end
                if before == 0 then
                    scanGuns()
                    installHook()
                elseif not R.Internal.Hooked then
                    installHook()
                end
                applyAll()
            end
        end)
    end
end

local function stopRivals()
    R.Settings.Enabled = false
    applyAll()
    if R.Internal.Conns.reapply then
        pcall(function() R.Internal.Conns.reapply:Disconnect() end)
        R.Internal.Conns.reapply = nil
    end
    R.Internal.ReapplyActive = false
end

local function fullRescan()
    log("manual rescan requested")
    R.Internal.ClientItem = nil
    R.Internal.Path = nil
    R.Internal.FoundBy = nil
    R.Internal.GunRegistry = {}

    local added = scanGuns()
    local count = 0
    for _ in pairs(R.Internal.GunRegistry) do count = count + 1 end
    log("rescan: +" .. tostring(added) .. " (total " .. tostring(count) .. ") foundBy=" .. tostring(R.Internal.FoundBy or "?"))
    if not R.Internal.Hooked then installHook() end
    applyAll()
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
            if v then startRivals() else stopRivals() end
        end,
    })

    secMain:AddToggle({
        Name = "No Spread",
        Value = R.Settings.NoSpread,
        Callback = function(v) R.Settings.NoSpread = v; applyAll() end,
    })
    secMain:AddSlider({
        Name = "Spread Value",
        Value = R.Settings.SpreadValue,
        Min = 0, Max = 10, Decimals = 2,
        Callback = function(v) R.Settings.SpreadValue = v; applyAll() end,
    })

    secMain:AddToggle({
        Name = "No Recoil",
        Value = R.Settings.NoRecoil,
        Callback = function(v) R.Settings.NoRecoil = v; applyAll() end,
    })
    secMain:AddSlider({
        Name = "Recoil Value",
        Value = R.Settings.RecoilValue,
        Min = 0, Max = 10, Decimals = 2,
        Callback = function(v) R.Settings.RecoilValue = v; applyAll() end,
    })

    secMain:AddToggle({
        Name = "Rapid Fire",
        Value = R.Settings.RapidFire,
        Callback = function(v) R.Settings.RapidFire = v; applyAll() end,
    })
    secMain:AddSlider({
        Name = "Fire Rate Value",
        Value = R.Settings.FireRateValue,
        Min = 0.001, Max = 0.5, Decimals = 3,
        Callback = function(v) R.Settings.FireRateValue = v; applyAll() end,
    })

    local secDbg = tab:CreateSection({ Name = "Debug" })
    secDbg:AddButton({
        Name = "Rescan ClientItem",
        Callback = function() fullRescan() end,
    })
    secDbg:AddButton({
        Name = "Print Status",
        Callback = function()
            local count = 0
            for _ in pairs(R.Internal.GunRegistry) do count = count + 1 end
            log("ClientItem=" .. tostring(R.Internal.ClientItem ~= nil)
                .. " hooked=" .. tostring(R.Internal.Hooked)
                .. " guns=" .. tostring(count)
                .. " foundBy=" .. tostring(R.Internal.FoundBy or "?"))
            if R.Internal.ClientItem then
                local i = 0
                for k, v in pairs(R.Internal.ClientItem) do
                    i = i + 1
                    if i <= 15 then log("  key: " .. tostring(k) .. " (" .. type(v) .. ")") end
                end
                if i == 0 then log("  ClientItem is empty table") end
                if i > 15 then log("  ... (" .. tostring(i - 15) .. " more)") end
            end
        end,
    })

    print("[AirHub] rivals extra tab: tab created")
end)

R.Functions.StopAll = function() stopRivals() end
log("extra tab loaded OK (airhubUI build)")
