--// ============================================================================
--// AirHub — rivals extra tab (airhubUI build)
--// Метод: Прямой поиск и изменение свойств через getgc()
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
    Conns = {},
    LoopActive = false,
}
R.Functions = R.Functions or {}

local function log(msg) 
    print("[AirHub] rivals: " .. tostring(msg)) 
end

--// ============================================================================
--// ULTRA MODIFICATION LOGIC (твой метод)
--// ============================================================================
local function toggleTableAttribute(attribute, value)
    if type(getgc) ~= "function" then return end
    
    local ok, gc = pcall(function()
        return getgc(true)
    end)
    if not ok or type(gc) ~= "table" then return end

    for _, gcVal in pairs(gc) do
        if type(gcVal) == "table" then
            -- Используем rawget, чтобы избежать срабатывания метаметодов
            if rawget(gcVal, attribute) ~= nil then
                pcall(function()
                    gcVal[attribute] = value
                end)
            end
        end
    end
end

local function applyAllMods()
    if not R.Settings.Enabled then return end
    
    -- 1. No Spread
    if R.Settings.NoSpread then
        toggleTableAttribute("ShootSpread", R.Settings.SpreadValue)
        toggleTableAttribute("Spread", R.Settings.SpreadValue)
        toggleTableAttribute("WeaponSpread", R.Settings.SpreadValue)
        toggleTableAttribute("Inaccuracy", R.Settings.SpreadValue)
    end

    -- 2. No Recoil
    if R.Settings.NoRecoil then
        toggleTableAttribute("ShootRecoil", R.Settings.RecoilValue)
        toggleTableAttribute("Recoil", R.Settings.RecoilValue)
        toggleTableAttribute("RecoilHorizontal", R.Settings.RecoilValue)
        toggleTableAttribute("RecoilVertical", R.Settings.RecoilValue)
        toggleTableAttribute("CameraRecoil", R.Settings.RecoilValue)
    end

    -- 3. Rapid Fire
    if R.Settings.RapidFire then
        toggleTableAttribute("ShootCooldown", 0)
        toggleTableAttribute("QuickShotCooldown", 0)
        toggleTableAttribute("Cooldown", 0)
        toggleTableAttribute("FireRate", R.Settings.FireRateValue)
    end
end

--// ============================================================================
--// BACKGROUND LOOP
--// ============================================================================
local function startLoop()
    if R.Internal.LoopActive then return end
    R.Internal.LoopActive = true
    
    task.spawn(function()
        while R.Internal.LoopActive and not H.ShuttingDown do
            if R.Settings.Enabled then
                applyAllMods()
            end
            task.wait(1) -- Сканируем память раз в секунду (оптимально для GC)
        end
    end)
end

local function stopLoop()
    R.Internal.LoopActive = false
    log("Mod loop stopped")
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
                startLoop()
                applyAllMods() -- Мгновенное применение при включении
            end
        end,
    })

    secMain:AddToggle({
        Name = "No Spread",
        Value = R.Settings.NoSpread,
        Callback = function(v) 
            R.Settings.NoSpread = v
            applyAllMods() 
        end,
    })
    secMain:AddSlider({
        Name = "Spread Value",
        Value = R.Settings.SpreadValue,
        Min = 0, Max = 10, Decimals = 2,
        Callback = function(v) 
            R.Settings.SpreadValue = v
            applyAllMods() 
        end,
    })

    secMain:AddToggle({
        Name = "No Recoil",
        Value = R.Settings.NoRecoil,
        Callback = function(v) 
            R.Settings.NoRecoil = v
            applyAllMods() 
        end,
    })
    secMain:AddSlider({
        Name = "Recoil Value",
        Value = R.Settings.RecoilValue,
        Min = 0, Max = 10, Decimals = 2,
        Callback = function(v) 
            R.Settings.RecoilValue = v
            applyAllMods() 
        end,
    })

    secMain:AddToggle({
        Name = "Rapid Fire",
        Value = R.Settings.RapidFire,
        Callback = function(v) 
            R.Settings.RapidFire = v
            applyAllMods() 
        end,
    })
    secMain:AddSlider({
        Name = "Fire Rate Value",
        Value = R.Settings.FireRateValue,
        Min = 0.001, Max = 0.5, Decimals = 3,
        Callback = function(v) 
            R.Settings.FireRateValue = v
            applyAllMods() 
        end,
    })

    local secDbg = tab:CreateSection({ Name = "Debug" })
    secDbg:AddButton({
        Name = "Force Apply Now",
        Callback = function()
            log("Manual force apply triggered")
            applyAllMods()
        end,
    })

    print("[AirHub] rivals extra tab: tab created")
end)

--// ============================================================================
--// PUBLIC CLEANUP
--// ============================================================================
R.Functions.StopAll = function()
    R.Settings.Enabled = false
    stopLoop()
end

log("extra tab loaded OK (getgc build)")
