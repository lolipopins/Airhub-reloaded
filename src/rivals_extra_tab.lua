--// ============================================================================
--// AirHub — rivals extra tab (airhubUI build)
--// Ported from Rivals Mini: No Spread / No Recoil / Rapid Fire
--// + расширенный поиск ClientItem (getloadedmodules / getgc / рекурсия)
--// + исправлены предупреждения Luau LSP (Type Checking & Semicolons)
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

--// ============================================================================
--// LOGGING
--// ============================================================================
local function log(msg)
    print("[AirHub] rivals: " .. tostring(msg))
end

local function logwarn(msg)
    warn("[AirHub] rivals: " .. tostring(msg))
end

--// ============================================================================
--// CLIENT ITEM FINDER (многоуровневый)
--// ============================================================================

-- Стратегия 1: стандартные пути
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
            if not child then
                ok = false
                break
            end
            node = child
        end
        
        if ok and node then
            local rok, mod = pcall(require, node)
            if rok and type(mod) == "table" then
                log("found via path: " .. table.concat(path, "/"))
                return mod, path
            end
        end
    end
    return nil, nil
end

-- Стратегия 2: getloadedmodules()
local function findClientItemByLoadedModules()
    local ok, modules = pcall(function()
        if type(getloadedmodules) ~= "function" then
            return nil
        end
        return getloadedmodules()
    end)
    
    if not ok or type(modules) ~= "table" then 
        return nil 
    end
    
    for _, m in ipairs(modules) do
        if type(m) == "table" then
            local nm = tostring(m):lower()
            if nm:find("clientitem") or nm:find("clientweapon") then
                if m.Input or m.ShootRecoil then
                    log("found via getloadedmodules: " .. tostring(m))
                    return m
                end
            end
        end
    end
    
    -- Ещё одна попытка: ищем любой модуль с .Input и кучей оружейных полей
    for _, m in ipairs(modules) do
        if type(m) == "table" and m.Input then
            local infoCount = 0
            for _, v in pairs(m) do
                if type(v) == "table" and v.Info then 
                    infoCount = infoCount + 1 
                end
            end
            if infoCount >= 3 then
                log("found via getloadedmodules (heuristic): " .. tostring(m))
                return m
            end
        end
    end
    
    return nil
end

-- Стратегия 3: getgc(true) — только таблицы, в которых есть Input и Info-структуры
local function findClientItemByGc()
    local ok, gc = pcall(function()
        if type(getgc) ~= "function" then 
            return nil 
        end
        return getgc(true)
    end)
    
    if not ok or type(gc) ~= "table" then 
        return nil 
    end
    
    for _, obj in ipairs(gc) do
        if type(obj) == "table" and obj.Input then
            local hasInfo = false
            for _, v in pairs(obj) do
                if type(v) == "table" and v.Info then 
                    hasInfo = true
                    break 
                end
            end
            if hasInfo then
                log("found via getgc")
                return obj
            end
        end
    end
    
    return nil
end

-- Стратегия 4: рекурсивный обход контейнера на поиск ModuleScript по имени
local function deepFindModule(root, name, depth, visited)
    if depth > 6 or not root then 
        return nil 
    end
    
    visited = visited or {}
    if visited[root] then 
        return nil 
    end
    visited[root] = true
    
    local child = root:FindFirstChild(name)
    if child and child:IsA("ModuleScript") then
        local rok, mod = pcall(require, child)
        if rok and type(mod) == "table" then 
            return mod, child 
        end
    end
    
    for _, c in ipairs(root:GetChildren()) do
        local found, instance = deepFindModule(c, name, depth + 1, visited)
        if found then 
            return found, instance 
        end
    end
    
    return nil
end

local function findClientItemByRecursiveScan()
    local roots = {
        { LocalPlayer:FindFirstChild("PlayerScripts"), "PlayerScripts" },
        { ReplicatedStorage, "ReplicatedStorage" },
    }
    local namesToTry = { "ClientItem", "ClientWeapon", "WeaponClient", "ClientWeapons" }
    
    for _, rootInfo in ipairs(roots) do
        local root, rootName = rootInfo[1], rootInfo[2]
        if root then
            for _, name in ipairs(namesToTry) do
                local mod, inst = deepFindModule(root, name, 0)
                if mod then
                    log("found via recursive scan: " .. rootName .. "/.../" .. name .. " (" .. tostring(inst:GetFullName()) .. ")")
                    return mod
                end
            end
        end
    end
    return nil
end

local function findClientItem()
    local mod, path = findClientItemByPaths()
    if mod then 
        R.Internal.FoundBy = "paths"
        return mod, path 
    end

    mod = findClientItemByLoadedModules()
    if mod then 
        R.Internal.FoundBy = "getloadedmodules"
        return mod 
    end

    mod = findClientItemByGc()
    if mod then 
        R.Internal.FoundBy = "getgc"
        return mod 
    end

    mod = findClientItemByRecursiveScan()
    if mod then 
        R.Internal.FoundBy = "recursive"
        return mod 
    end

    return nil
end

local function ensureClientItem()
    if R.Internal.ClientItem then 
        return R.Internal.ClientItem 
    end
    local mod, path = findClientItem()
    if mod then
        R.Internal.ClientItem = mod
        R.Internal.Path = path
    end
    return mod
end

--// ============================================================================
--// GUN REGISTRY
--// ============================================================================
local function scanGuns()
    local ClientItem = ensureClientItem()
    if not ClientItem then 
        return 0 
    end
    
    local registry = R.Internal.GunRegistry
    local before = 0
    for _ in pairs(registry) do 
        before = before + 1 
    end

    for key, value in pairs(ClientItem) do
        if type(value) == "table" then
            if value.Info and type(value.Info) == "table" then
                registry[tostring(key)] = registry[tostring(key)] or { Info = value.Info, Original = {}, Instance = value }
            elseif value.Info == nil and value.ShootRecoil ~= nil then
                registry[tostring(key)] = registry[tostring(key)] or { Info = value, Original = {}, Instance = value }
            end
        end
    end

    local function walk(t, depth, visited)
        if depth > 4 or type(t) ~= "table" then 
            return 
        end
        
        visited = visited or {}
        if visited[t] then 
            return 
        end
        visited[t] = true
        
        for k, v in pairs(t) do
            if type(k) == "string" and type(v) == "table" then
                if v.Info and type(v.Info) == "table" and not registry[k] then
                    registry[k] = { Info = v.Info, Original = {}, Instance = v }
                end
                walk(v, depth + 1, visited)
            end
        end
    end
    walk(ClientItem, 0)

    local after = 0
    for _ in pairs(registry) do 
        after = after + 1 
    end

    -- Если ClientItem найден, но ничего не нашли — логируем структуру
    if after == 0 and ClientItem then
        local keys = {}
        local i = 0
        for k, v in pairs(ClientItem) do
            i = i + 1
            if i <= 20 then
                keys[#keys + 1] = tostring(k) .. "(" .. type(v) .. ")"
            end
        end
        logwarn("ClientItem found, but no guns. Structure keys: " .. table.concat(keys, ", "))
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
    if not info then 
        return 
    end

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
                pcall(function()
                    info[k] = value
                end)
            end
        end
    end
    
    local function restoreKeys(keys)
        for _, k in ipairs(keys) do
            if entry.Original[k] ~= nil then
                pcall(function()
                    info[k] = entry.Original[k]
                end)
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
            pcall(function()
                info.FireRate = R.Settings.FireRateValue
            end)
        end
    else
        restoreKeys(RATE_KEYS)
        if entry.Original.FireRate ~= nil then
            pcall(function()
                info.FireRate = entry.Original.FireRate
            end)
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
    if R.Internal.Hooked then 
        return true 
    end
    
    local ClientItem = ensureClientItem()
    if not ClientItem then 
        return false 
    end
    
    -- Проверяем, что Input это функция (убирает ошибку Expected this to be '(...any) -> (...any)')
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
            local targetFn = ClientItem.Input :: any -- Каст для LSP, чтобы не ругался на тип
            R.Internal.OriginalInput = hookfunction(targetFn, hookedInput)
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
    
    for _ in pairs(R.Internal.GunRegistry) do 
        count = count + 1 
    end
    
    log("scan: +" .. tostring(added) .. " (total " .. tostring(count) .. ") foundBy=" .. tostring(R.Internal.FoundBy or "?"))
    installHook()
    applyAll()

    if not R.Internal.ReapplyActive then
        R.Internal.ReapplyActive = true
        R.Internal.Conns.reapply = RunService.Heartbeat:Connect(function()
            if H.ShuttingDown then 
                return 
            end
            if not R.Settings.Enabled then 
                return 
            end
            
            R.Internal._t = (R.Internal._t or 0) + 1
            if R.Internal._t % 120 == 0 then
                local before = 0
                for _ in pairs(R.Internal.GunRegistry) do 
                    before = before + 1 
                end
                
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
        pcall(function() 
            R.Internal.Conns.reapply:Disconnect() 
        end)
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
    for _ in pairs(R.Internal.GunRegistry) do 
        count = count + 1 
    end
    
    log("rescan: +" .. tostring(added) .. " (total " .. tostring(count) .. ") foundBy=" .. tostring(R.Internal.FoundBy or "?"))
    
    if not R.Internal.Hooked then 
        installHook() 
    end
    applyAll()
end

--// ============================================================================
--// UI (airhubUI)
--// ============================================================================
task.spawn(function()
    local deadline = tick() + 30
    while tick() < deadline do
        if H.ShuttingDown then 
            return 
        end
        if getgenv().airhubUI_Window then 
            break 
        end
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
                startRivals()
            else
                stopRivals()
            end
        end,
    })

    secMain:AddToggle({
        Name = "No Spread",
        Value = R.Settings.NoSpread,
        Callback = function(v) 
            R.Settings.NoSpread = v
            applyAll() 
        end,
    })
    
    secMain:AddSlider({
        Name = "Spread Value",
        Value = R.Settings.SpreadValue,
        Min = 0, Max = 10, Decimals = 2,
        Callback = function(v) 
            R.Settings.SpreadValue = v
            applyAll() 
        end,
    })

    secMain:AddToggle({
        Name = "No Recoil",
        Value = R.Settings.NoRecoil,
        Callback = function(v) 
            R.Settings.NoRecoil = v
            applyAll() 
        end,
    })
    
    secMain:AddSlider({
        Name = "Recoil Value",
        Value = R.Settings.RecoilValue,
        Min = 0, Max = 10, Decimals = 2,
        Callback = function(v) 
            R.Settings.RecoilValue = v
            applyAll() 
        end,
    })

    secMain:AddToggle({
        Name = "Rapid Fire",
        Value = R.Settings.RapidFire,
        Callback = function(v) 
            R.Settings.RapidFire = v
            applyAll() 
        end,
    })
    
    secMain:AddSlider({
        Name = "Fire Rate Value",
        Value = R.Settings.FireRateValue,
        Min = 0.001, Max = 0.5, Decimals = 3,
        Callback = function(v) 
            R.Settings.FireRateValue = v
            applyAll() 
        end,
    })

    --// Debug section
    local secDbg = tab:CreateSection({ Name = "Debug" })
    secDbg:AddButton({
        Name = "Rescan ClientItem",
        Callback = function() 
            fullRescan() 
        end,
    })
    
    secDbg:AddButton({
        Name = "Print Status",
        Callback = function()
            local count = 0
            for _ in pairs(R.Internal.GunRegistry) do 
                count = count + 1 
            end
            
            log("ClientItem=" .. tostring(R.Internal.ClientItem ~= nil)
                .. " hooked=" .. tostring(R.Internal.Hooked)
                .. " guns=" .. tostring(count)
                .. " foundBy=" .. tostring(R.Internal.FoundBy or "?"))
                
            if R.Internal.ClientItem then
                local i = 0
                for k, v in pairs(R.Internal.ClientItem) do
                    i = i + 1
                    if i <= 15 then 
                        log("  key: " .. tostring(k) .. " (" .. type(v) .. ")") 
                    end
                end
                if i == 0 then 
                    log("  ClientItem is empty table") 
                end
                if i > 15 then 
                    log("  ... (" .. tostring(i - 15) .. " more)") 
                end
            end
        end,
    })

    print("[AirHub] rivals extra tab: tab created")
end)

--// ============================================================================
--// PUBLIC CLEANUP
--// ============================================================================
R.Functions.StopAll = function()
    stopRivals()
end

log("extra tab loaded OK (airhubUI build)")
