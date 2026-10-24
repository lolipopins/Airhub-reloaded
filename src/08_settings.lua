--// ============================================================================
--// AirHub — 08_settings.lua (unified configs build)
--// Settings tab: Logs & Sounds + Main actions.
--// Config section REMOVED — configs now live in airhubUI's "Configs" tab
--// and save BOTH UI state AND AirHub settings in a single file.
--// ============================================================================
local H = getgenv().AirHub
if not H or not H._CoreLoaded then warn("[AirHub] 08_settings: core not loaded"); return end
if H._SettingsLoaded then warn("[AirHub] 08_settings: already loaded"); return end
H._SettingsLoaded = true

local Util            = H.Util
local ShowError       = Util.ShowError
local TeleportService = Util.TeleportService
local HttpService     = Util.HttpService
local LocalPlayer     = Util.LocalPlayer

local Window = getgenv().airhubUI_Window
if not Window then
    warn("[AirHub] 08_settings: airhubUI Window missing — Settings tab not created")
    return
end

H._UI = H._UI or {}
local SettingsTab = Window:AddTab({ Name = "Settings", Icon = ">" })
H._UI.SettingsTab = SettingsTab

--// ---------------------------------------------------------------------------
--// Defaults (in case 01_core didn't populate them)
--// ---------------------------------------------------------------------------
H.Logging = H.Logging or {
    Enabled = true, ShowHit = true, ShowMiss = true,
    Duration = 1, FontSize = 18,
}
H.Sounds = H.Sounds or {
    HitsoundEnabled = false, HitsoundID = 83717596220569, HitsoundVolume = 1,
    KillsoundEnabled = false, KillsoundID = 83717596220569, KillsoundVolume = 1,
}
H.Sound = H.Sounds

local soundIDs = {
    gamesense  = 83717596220569,
    neverlose  = 139452805868562,
    crit       = 122699784909910,
    primordial = 97511223764004,
}
local soundNames = { "gamesense", "neverlose", "crit", "primordial" }

local function soundNameForId(id)
    for name, sid in pairs(soundIDs) do
        if sid == id then return name end
    end
    return "gamesense"
end

--// ---------------------------------------------------------------------------
--// Reset All
--// ---------------------------------------------------------------------------
local function ResetEverything()
    local Hg = H

    -- Aimbot
    if Hg.Aimbot and Hg.Aimbot.Settings then
        local S = Hg.Aimbot.Settings
        S.Enabled = false
        S.WallCheck = false
        S.SilentAim = false
        S.TPAimEnabled = false
        S.WallbangEnabled = false
        S.UseBacktrack = false
        S.BacktrackAimAtGhost = false
        if S.TargetLock        then S.TargetLock.Enabled        = false end
        if S.MultiPoint        then S.MultiPoint.Enabled        = false end
        if S.MultiPointVisuals then S.MultiPointVisuals.Enabled = false end
        if S.AimLineVisuals    then S.AimLineVisuals.Enabled    = false end
        if S.AutoShoot         then S.AutoShoot.Enabled         = false end
        if Hg.Aimbot.Internal then
            Hg.Aimbot.Internal.CachedAimPos = nil
            if Hg.Aimbot.Internal.TargetLock then
                Hg.Aimbot.Internal.TargetLock.Active    = false
                Hg.Aimbot.Internal.TargetLock.Remaining = 0
            end
        end
        if Hg.Aimbot.CancelLock    then pcall(Hg.Aimbot.CancelLock)    end
        if Hg.Aimbot.FOVSettings   then Hg.Aimbot.FOVSettings.Enabled = false end
    end

    if Hg.WallHack and Hg.WallHack.Functions and Hg.WallHack.Functions.ResetSettings then
        pcall(Hg.WallHack.Functions.ResetSettings)
    end
    if Hg.AntiAim and Hg.AntiAim.Functions and Hg.AntiAim.Functions.ResetSettings then
        pcall(Hg.AntiAim.Functions.ResetSettings)
    end
    if Hg.ServerPosition and Hg.ServerPosition.Settings then
        Hg.ServerPosition.Settings.Enabled = false
        if Hg.ServerPosition.Stop then pcall(Hg.ServerPosition.Stop) end
    end

    if Hg.Fly         and Hg.Fly.Functions         and Hg.Fly.Functions.ResetSettings         then pcall(Hg.Fly.Functions.ResetSettings)         end
    if Hg.Bhop        and Hg.Bhop.Functions        and Hg.Bhop.Functions.ResetSettings        then pcall(Hg.Bhop.Functions.ResetSettings)        end
    if Hg.Speed       and Hg.Speed.Functions       and Hg.Speed.Functions.ResetSettings       then pcall(Hg.Speed.Functions.ResetSettings)       end
    if Hg.FastStop    and Hg.FastStop.Functions    and Hg.FastStop.Functions.ResetSettings    then pcall(Hg.FastStop.Functions.ResetSettings)    end
    if Hg.AutoStrafer and Hg.AutoStrafer.Functions and Hg.AutoStrafer.Functions.ResetSettings then pcall(Hg.AutoStrafer.Functions.ResetSettings) end
    if Hg.Noclip      and Hg.Noclip.Functions      and Hg.Noclip.Functions.ResetSettings      then pcall(Hg.Noclip.Functions.ResetSettings)      end

    if Hg.World    and Hg.World.Functions    and Hg.World.Functions.Restore   then pcall(Hg.World.Functions.Restore)   end
    if Hg.Exploits and Hg.Exploits.Functions and Hg.Exploits.Functions.StopAll then pcall(Hg.Exploits.Functions.StopAll) end
    if Hg.Quotas   and Hg.Quotas.Functions   and Hg.Quotas.Functions.StopAll  then pcall(Hg.Quotas.Functions.StopAll)  end

    -- Logging / sounds
    Hg.Logging.Enabled    = true
    Hg.Logging.ShowHit    = true
    Hg.Logging.ShowMiss   = true
    Hg.Logging.Duration   = 1
    Hg.Logging.FontSize   = 18
    Hg.Sounds.HitsoundEnabled  = false
    Hg.Sounds.KillsoundEnabled = false
    Hg.Sounds.HitsoundVolume   = 1
    Hg.Sounds.KillsoundVolume  = 1
end

--// ---------------------------------------------------------------------------
--// Rejoin / Hop
--// ---------------------------------------------------------------------------
local function doRejoin()
    pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end)
end

local function getRequestFn()
    if type(syn) == "table" and type(syn.request) == "function" then return syn.request end
    if type(request) == "function" then return request end
    if type(http_request) == "function" then return http_request end
    return nil
end

local function doServerHop()
    local req = getRequestFn()
    if not req then
        ShowError("Server hop: no HTTP method available")
        return
    end
    local url = string.format(
        "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100",
        game.PlaceId
    )
    local ok, res = pcall(req, { Url = url, Method = "GET" })
    if not ok or not res or type(res.StatusCode) ~= "number" or res.StatusCode ~= 200 then
        ShowError("Server hop: HTTP " .. tostring(res and res.StatusCode))
        return
    end
    local okDec, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
    if not okDec or type(data) ~= "table" or type(data.data) ~= "table" then
        ShowError("Server hop: bad response body")
        return
    end
    local candidates = {}
    for _, srv in ipairs(data.data) do
        if srv.playing and srv.maxPlayers
           and srv.playing < srv.maxPlayers
           and srv.id ~= game.JobId then
            candidates[#candidates + 1] = srv.id
        end
    end
    if #candidates > 0 then
        local pick = candidates[math.random(1, #candidates)]
        TeleportService:TeleportToPlaceInstance(game.PlaceId, pick, LocalPlayer)
    else
        ShowError("Server hop: no open servers found")
    end
end

--// ---------------------------------------------------------------------------
--// LEFT COLUMN — Shot Logs & Sounds
--// ---------------------------------------------------------------------------
local logSec = SettingsTab:CreateSection({ Name = "Shot Logs & Sounds" })

logSec:AddToggle({
    Name = "Logs Enabled",
    Value = H.Logging.Enabled,
    Callback = function(v) H.Logging.Enabled = v end,
})
logSec:AddToggle({
    Name = "Show Hits",
    Value = H.Logging.ShowHit,
    Callback = function(v) H.Logging.ShowHit = v end,
})
logSec:AddToggle({
    Name = "Show Misses",
    Value = H.Logging.ShowMiss,
    Callback = function(v) H.Logging.ShowMiss = v end,
})
logSec:AddSlider({
    Name = "Duration (s)",
    Value = H.Logging.Duration,
    Min = 0.5, Max = 5, Decimals = 1,
    Callback = function(v) H.Logging.Duration = v end,
})
logSec:AddSlider({
    Name = "Font Size",
    Value = H.Logging.FontSize,
    Min = 12, Max = 30,
    Callback = function(v) H.Logging.FontSize = v end,
})

logSec:AddDivider({ Text = "HITSound" })
logSec:AddToggle({
    Name = "Hitsound Enabled",
    Value = H.Sounds.HitsoundEnabled,
    Callback = function(v) H.Sounds.HitsoundEnabled = v end,
})
logSec:AddDropdown({
    Name = "Hitsound",
    Value = soundNameForId(H.Sounds.HitsoundID),
    List = soundNames,
    Callback = function(v)
        if soundIDs[v] then H.Sounds.HitsoundID = soundIDs[v] end
    end,
})
logSec:AddSlider({
    Name = "Hitsound Volume",
    Value = H.Sounds.HitsoundVolume,
    Min = 0, Max = 10, Decimals = 1,
    Callback = function(v) H.Sounds.HitsoundVolume = v end,
})

logSec:AddDivider({ Text = "KILLSound" })
logSec:AddToggle({
    Name = "Killsound Enabled",
    Value = H.Sounds.KillsoundEnabled,
    Callback = function(v) H.Sounds.KillsoundEnabled = v end,
})
logSec:AddDropdown({
    Name = "Killsound",
    Value = soundNameForId(H.Sounds.KillsoundID),
    List = soundNames,
    Callback = function(v)
        if soundIDs[v] then H.Sounds.KillsoundID = soundIDs[v] end
    end,
})
logSec:AddSlider({
    Name = "Killsound Volume",
    Value = H.Sounds.KillsoundVolume,
    Min = 0, Max = 10, Decimals = 1,
    Callback = function(v) H.Sounds.KillsoundVolume = v end,
})

--// ---------------------------------------------------------------------------
--// RIGHT COLUMN — Main
--// ---------------------------------------------------------------------------
local mainSec = SettingsTab:CreateSection({ Name = "Main", Side = "Right" })

mainSec:AddButton({
    Name = "Reset All Settings",
    Callback = function()
        ResetEverything()
        ShowError("All settings reset")
    end,
})

mainSec:AddButton({
    Name = "Rejoin Server",
    Callback = function() doRejoin() end,
})

mainSec:AddButton({
    Name = "Server Hop (random)",
    Callback = function() doServerHop() end,
})

mainSec:AddDivider({ Text = "DANGER ZONE" })

mainSec:AddButton({
    Name = "Exit (Unload AirHub)",
    Callback = function()
        if Window and Window.Unload then Window:Unload() end
    end,
})

--// ---------------------------------------------------------------------------
--// RIGHT COLUMN — Configs (unified hint) + Info
--// ---------------------------------------------------------------------------
local cfgHintSec = SettingsTab:CreateSection({ Name = "Configs (unified)", Side = "Right" })
cfgHintSec:AddLabel({ Text = "Config save/load has moved to the 'Configs' tab." })
cfgHintSec:AddLabel({ Text = "ONE config saves BOTH UI state AND AirHub settings.", Color = Theme and Theme.Accent or Color3.fromRGB(77,107,254) })
cfgHintSec:AddLabel({ Text = "Load once → theme, toggles, cheat settings — everything restored." })
cfgHintSec:AddLabel({ Text = "Legacy AirHub/Configs/*.json auto-migrated on first load.", Color = Theme and Theme.Muted or Color3.fromRGB(156,163,175) })

local infoSec = SettingsTab:CreateSection({ Name = "Info", Side = "Right" })
infoSec:AddLabel({ Text = "airhubUI v1.9.3 · unified configs" })
infoSec:AddLabel({ Text = "RightShift — toggle menu" })
infoSec:AddLabel({ Text = "MMB on any row — bind menu" })
infoSec:AddLabel({ Text = "RMB on any row — options menu" })
infoSec:AddLabel({ Text = "Configs → airhubUI_Configs/" })

print("[AirHub] 08_settings: loaded OK (unified configs build)")
