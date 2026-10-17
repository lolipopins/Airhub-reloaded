--// ============================================================================
--// AirHub — rivals extra tab (Apply to ALL weapons)
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
local LocalPlayer = Util.LocalPlayer

H.Rivals = H.Rivals or {}
local R = H.Rivals
R._Loaded = true

R.Settings = R.Settings or {
    SpreadValue   = 0,
    RecoilValue   = 0,
    FireRateValue = 0.01,
    Applied       = false,
}

R.Internal = R.Internal or {
    Originals = setmetatable({}, {__mode = "k"}),
    Hooked    = false,
    OldInput  = nil,
}

local SPREAD_FIELDS = {"ShootSpread", "Spread", "WeaponSpread", "Inaccuracy"}
local RECOIL_FIELDS = {"ShootRecoil", "Recoil", "RecoilHorizontal", "RecoilVertical", "CameraRecoil"}
local RATE_FIELDS   = {"ShootCooldown", "QuickShotCooldown", "Cooldown", "FireRate"}

--// ============================================================================
--// ЛОГИКА ПРИМЕНЕНИЯ
--// ============================================================================
local function applyStatsToTable(tbl)
    if type(tbl) ~= "table" then return false end
    local changed = false
    
    local function setVal(field, value)
        if rawget(tbl, field) ~= nil then
            if not R.Internal.Originals[tbl] then 
                R.Internal.Originals[tbl] = {} 
            end
            if R.Internal.Originals[tbl][field] == nil then 
                R.Internal.Originals[tbl][field] = tbl[field] 
            end
            pcall(function() tbl[field] = value end)
            changed = true
        end
    end

    for _, f in ipairs(SPREAD_FIELDS) do setVal(f, R.Settings.SpreadValue) end
    for _, f in ipairs(RECOIL_FIELDS) do setVal(f, R.Settings.RecoilValue) end
    for _, f in ipairs(RATE_FIELDS) do setVal(f, R.Settings.FireRateValue) end

    return changed
end

local function applyMods()
    if type(getgc) ~= "function" then return end
    local gc = getgc(true)
    local count = 0
    
    for _, obj in pairs(gc) do
        if type(obj) == "table" then
            if applyStatsToTable(obj) then count = count + 1 end
            local info = rawget(obj, "Info")
            if type(info) == "table" then
                if applyStatsToTable(info) then count = count + 1 end
            end
        end
    end
    print("[Rivals] Applied mods to " .. count .. " tables")
end

local function resetMods()
    local count = 0
    for tbl, fields in pairs(R.Internal.Originals) do
        for f, v in pairs(fields) do
            pcall(function() tbl[f] = v end)
        end
        count = count + 1
    end
    R.Internal.Originals = setmetatable({}, {__mode = "k"})
    print("[Rivals] Reset " .. count .. " tables to original values")
end

--// ============================================================================
--// ХУК ВЫСТРЕЛА (Применяет ко ВСЕМУ оружию)
--// ============================================================================
local function findClientItem()
    local node = LocalPlayer
    local names = {"PlayerScripts", "Modules", "ClientReplicatedClasses", "ClientFighter", "ClientItem"}
    for _, name in ipairs(names) do
        node = node:FindFirstChild(name)
        if not node then return nil end
    end
    local ok, mod = pcall(require, node)
    if ok and type(mod) == "table" then return mod end
    return nil
end

local function hookInput()
    if R.Internal.Hooked then return end
    local ClientItem = findClientItem()
    if not ClientItem or not ClientItem.Input then return end
    
    R.Internal.OldInput = ClientItem.Input
    
    local function newInput(self, ...)
        if R.Settings.Applied and type(self) == "table" then
            pcall(function()
                applyStatsToTable(self)
                if type(self.Info) == "table" then
                    applyStatsToTable(self.Info)
                end
            end)
        end
        return R.Internal.OldInput(self, ...)
    end
    
    local success = pcall(function()
        if hookfunction then
            hookfunction(ClientItem.Input, newInput)
        else
            ClientItem.Input = newInput
        end
    end)

    if success then
        R.Internal.Hooked = true
        print("[Rivals] ClientItem.Input hooked (Auto-Apply enabled)")
    end
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

    secMain:AddSlider({
        Name = "Spread Value",
        Value = R.Settings.SpreadValue,
        Min = 0, Max = 10, Decimals = 2,
        Callback = function(v) R.Settings.SpreadValue = v end,
    })

    secMain:AddSlider({
        Name = "Recoil Value",
        Value = R.Settings.RecoilValue,
        Min = 0, Max = 10, Decimals = 2,
        Callback = function(v) R.Settings.RecoilValue = v end,
    })

    secMain:AddSlider({
        Name = "Rapid Fire (Cooldown)",
        Value = R.Settings.FireRateValue,
        Min = 0.001, Max = 0.5, Decimals = 3,
        Callback = function(v) R.Settings.FireRateValue = v end,
    })

    secMain:AddButton({
        Name = "Apply to All Weapons",
        Callback = function()
            R.Settings.Applied = true
            applyMods()
            hookInput()
        end,
    })

    secMain:AddButton({
        Name = "Reset to Original",
        Callback = function()
            R.Settings.Applied = false
            resetMods()
        end,
    })

    print("[AirHub] rivals extra tab: loaded")
end)

R.Functions.StopAll = function()
    R.Settings.Applied = false
    resetMods()
end
