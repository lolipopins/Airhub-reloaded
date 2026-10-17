--// ============================================================================
--// AirHub — rivals extra tab (airhubUI build)
--// Ported from Rivals Mini: No Spread / No Recoil / Rapid Fire
--// ============================================================================
local H = getgenv().AirHub
if not H or not H._CoreLoaded then warn("[AirHub] rivals extra tab: core not loaded") return end
if H.Rivals and H.Rivals._Loaded then warn("[AirHub] rivals extra tab: already loaded") return end

local Util        = H.Util
local Players     = Util.Players
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
    GunRegistry   = {},
    Conns         = {},
    ClientItem    = nil,
    Path          = nil,
    Hooked        = false,
    ReapplyActive = false,
    OriginalInput = nil,
}
R.Functions = R.Functions or {}

--// ============================================================================
--// CLIENT ITEM FINDER
--// ============================================================================
local function findClientItem()
    local candidates = {
        { "PlayerScripts", "Modules", "ClientReplicatedClasses", "ClientFighter", "ClientItem" },
        { "PlayerScripts", "ClientReplicatedClasses", "ClientFighter", "ClientItem" },
        { "PlayerScripts", "Modules", "ClientFighter", "ClientItem" },
        { "PlayerScripts", "Modules", "ClientReplicatedClasses", "ClientItem" },
        { "PlayerScripts", "ClientItem" },
    }
    for _, path in ipairs(candidates) do
        local node, ok = LocalPlayer, true
        for _, name in ipairs(path) do
            local child = node and node:FindFirstChild(name)
            if not child then ok = false; break end
            node = child
        end
        if ok and node then
            local rok, mod = pcall(require, node)
            if rok and type(mod) == "table" then
                return mod, path
            end
        end
    end
    return nil, nil
end

local function findClientItemFallback()
    local ok, modules = pcall(function()
        return getloadedmodules and getloadedmodules() or {}
    end)
    if ok and modules then
        for _, m in ipairs(modules) do
            local nm = tostring(m):lower()
            if nm:find("clientitem") and type(m) == "table" and m.Input then
                return m
            end
        end
    end
    return nil
end

local function ensureClientItem()
    if R.Internal.ClientItem then return R.Internal.ClientItem end
    local mod, path = findClientItem()
    if not mod then mod = findClientItemFallback() end
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
    if not ClientItem then return 0 end
    R.Internal.GunRegistry = {}
    local registry = R.Internal.GunRegistry

    for key, value in pairs(ClientItem) do
        if type(value) == "table" then
            if value.Info and type(value.Info) == "table" then
                registry[tostring(key)] = { Info = value.Info, Original = {}, Instance = value }
            elseif value.Info == nil and value.ShootRecoil ~= nil then
                registry[tostring(key)] = { Info = value, Original = {}, Instance = value }
            end
        end
    end

    local function walk(t, depth)
        if depth > 4 or type(t) ~= "table" then return end
        for k, v in pairs(t) do
            if type(k) == "string" and type(v) == "table" then
                if v.Info and type(v.Info) == "table" and not registry[k] then
                    registry[k] = { Info = v.Info, Original = {}, Instance = v }
                end
                walk(v, depth + 1)
            end
        end
    end
    walk(ClientItem, 0)

    local n = 0
    for _ in pairs(registry) do n = n + 1 end
    return n
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

    -- Сохраняем оригиналы один раз
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

    -- No Spread
    if R.Settings.Enabled and R.Settings.NoSpread then
        setKeys(SPREAD_KEYS, R.Settings.SpreadValue)
    else
        restoreKeys(SPREAD_KEYS)
    end

    -- No Recoil
    if R.Settings.Enabled and R.Settings.NoRecoil then
        setKeys(RECOIL_KEYS, R.Settings.RecoilValue)
    else
        restoreKeys(RECOIL_KEYS)
    end

    -- Rapid Fire
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
    if R.Internal.Hooked then return end
    local ClientItem = ensureClientItem()
    if not ClientItem or not ClientItem.Input then return end

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

    if hookfunction then
        R.Internal.OriginalInput = hookfunction(ClientItem.Input, hookedInput)
    elseif hookmetamethod then
        R.Internal.OriginalInput = ClientItem.Input
        ClientItem.Input = hookedInput
    else
        warn("[AirHub] rivals: no hookfunction/hookmetamethod available")
        R.Internal.OriginalInput = function() end
    end
    R.Internal.Hooked = true
end

--// ============================================================================
--// START / STOP
--// ============================================================================
local function startRivals()
    local count = scanGuns()
    print("[AirHub] rivals: guns found = " .. tostring(count))
    installHook()
    applyAll()

    if not R.Internal.ReapplyActive then
        R.Internal.ReapplyActive = true
        R.Internal.Conns.reapply = RunService.Heartbeat:Connect(function()
            if H.ShuttingDown then return end
            if not R.Settings.Enabled then return end
            R.Internal._t = (R.Internal._t or 0) + 1
            if R.Internal._t % 120 == 0 then
                if next(R.Internal.GunRegistry) == nil then
                    scanGuns()
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

    --// ========================================================================
    --// SECTION — Rivals Mods
    --// ========================================================================
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

    print("[AirHub] rivals extra tab: tab created")
end)

--// ============================================================================
--// PUBLIC CLEANUP
--// ============================================================================
R.Functions.StopAll = function()
    stopRivals()
end

print("[AirHub] rivals extra tab: loaded OK (airhubUI build)")
