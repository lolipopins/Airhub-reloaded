--// ============================================================================
--// AirHub — rivals extra tab (Manual Apply/Reset)
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
H.Rivals = H.Rivals or {}
local R = H.Rivals
R._Loaded = true

R.Settings = R.Settings or {
    SpreadValue   = 0,
    RecoilValue   = 0,
    FireRateValue = 0.01,
}

R.Internal = R.Internal or {
    Originals = setmetatable({}, {__mode = "k"}), -- Слабые ключи для таблиц
}
R.Functions = R.Functions or {}

local function log(msg) 
    print("[AirHub] rivals: " .. tostring(msg)) 
end

--// ============================================================================
--// ЛОГИКА ПРИМЕНЕНИЯ И СБРОСА
--// ============================================================================
local function applyMods()
    if type(getgc) ~= "function" then 
        log("getgc is not supported in this executor")
        return 
    end

    local gc = getgc(true)
    local modifiedCount = 0

    for _, obj in pairs(gc) do
        if type(obj) == "table" then
            local function processTable(tbl)
                if type(tbl) ~= "table" then return end
                local changed = false
                
                -- 1. Spread
                local spreadFields = {"ShootSpread", "Spread", "WeaponSpread", "Inaccuracy"}
                for _, field in ipairs(spreadFields) do
                    if rawget(tbl, field) ~= nil then
                        if not R.Internal.Originals[tbl] then R.Internal.Originals[tbl] = {} end
                        if R.Internal.Originals[tbl][field] == nil then 
                            R.Internal.Originals[tbl][field] = tbl[field] 
                        end
                        pcall(function() tbl[field] = R.Settings.SpreadValue end)
                        changed = true
                    end
                end

                -- 2. Recoil
                local recoilFields = {"ShootRecoil", "Recoil", "RecoilHorizontal", "RecoilVertical", "CameraRecoil"}
                for _, field in ipairs(recoilFields) do
                    if rawget(tbl, field) ~= nil then
                        if not R.Internal.Originals[tbl] then R.Internal.Originals[tbl] = {} end
                        if R.Internal.Originals[tbl][field] == nil then 
                            R.Internal.Originals[tbl][field] = tbl[field] 
                        end
                        pcall(function() tbl[field] = R.Settings.RecoilValue end)
                        changed = true
                    end
                end

                -- 3. Rapid Fire
                local rateFields = {"ShootCooldown", "QuickShotCooldown", "Cooldown", "FireRate"}
                for _, field in ipairs(rateFields) do
                    if rawget(tbl, field) ~= nil then
                        if not R.Internal.Originals[tbl] then R.Internal.Originals[tbl] = {} end
                        if R.Internal.Originals[tbl][field] == nil then 
                            R.Internal.Originals[tbl][field] = tbl[field] 
                        end
                        pcall(function() tbl[field] = R.Settings.FireRateValue end)
                        changed = true
                    end
                end

                if changed then
                    modifiedCount = modifiedCount + 1
                end
            end

            -- Обрабатываем саму таблицу
            processTable(obj)
            
            -- Обрабатываем вложенные таблицы (например, obj.Info)
            local info = rawget(obj, "Info")
            if type(info) == "table" then
                processTable(info)
            end
        end
    end

    log("Applied mods to " .. modifiedCount .. " tables.")
end

local function resetMods()
    local resetCount = 0
    for tbl, props in pairs(R.Internal.Originals) do
        for k, v in pairs(props) do
            pcall(function() 
                tbl[k] = v 
            end)
        end
        resetCount = resetCount + 1
    end
    R.Internal.Originals = setmetatable({}, {__mode = "k"}) -- Очищаем кэш
    log("Reset " .. resetCount .. " tables to original values.")
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
        Name = "Apply Mods",
        Callback = function()
            applyMods()
        end,
    })

    secMain:AddButton({
        Name = "Reset to Original",
        Callback = function()
            resetMods()
        end,
    })

    print("[AirHub] rivals extra tab: loaded")
end)

R.Functions.StopAll = function()
    resetMods()
end
