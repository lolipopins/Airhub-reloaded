--// ============================================================================
--// AirHub — 08_settings.lua (unified configs build, v2 — RU loc + tooltips)
--// Settings tab: Logs & Sounds + Main actions + Configs hint + Live Info.
--//
--// CHANGES v2:
--//   • RU/EN localization + tooltips on every control
--//   • NEW: Sound preview (▶ play directly from menu)
--//   • NEW: Custom Sound ID input for hit/kill sounds
--//   • NEW: Test Hit / Test Kill buttons
--//   • NEW: Join by Job ID (input + button)
--//   • NEW: Copy Job ID / Copy Config JSON in Main
--//   • NEW: Confirm Reset (double-click protection)
--//   • NEW: Live Info section — Place / Job / Players / Uptime / FPS / Ping
--//   • ResetAll also resets sound IDs + custom IDs + logging
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
local Players         = Util.Players

local Window = getgenv().airhubUI_Window
if not Window then
    warn("[AirHub] 08_settings: airhubUI Window missing — Settings tab not created")
    return
end

H._UI = H._UI or {}
local SettingsTab = Window:AddTab({ Name = "Settings", Icon = ">" })
H._UI.SettingsTab = SettingsTab

--// ---------------------------------------------------------------------------
--// Localization injection
--// ---------------------------------------------------------------------------
do
    local UI = getgenv().airhubUI
    if UI and UI.L and UI.L.en and UI.L.ru then
        local en = {
            set_sec_logs   = "Shot Logs & Sounds",
            set_sec_main   = "Main",
            set_sec_cfg    = "Configs (unified)",
            set_sec_info   = "Info",

            set_logs_enabled = "Logs Enabled",
            set_show_hits    = "Show Hits",
            set_show_miss    = "Show Misses",
            set_duration     = "Duration (s)",
            set_font_size    = "Font Size",

            set_hitsound     = "HITSound",
            set_hit_enabled  = "Hitsound Enabled",
            set_hit_sound    = "Hitsound",
            set_hit_volume   = "Hitsound Volume",
            set_hit_custom   = "Custom Hitsound ID (rbxassetid://...)",
            set_hit_test     = "▶ Test Hitsound",

            set_killsound    = "KILLSound",
            set_kill_enabled = "Killsound Enabled",
            set_kill_sound   = "Killsound",
            set_kill_volume  = "Killsound Volume",
            set_kill_custom  = "Custom Killsound ID (rbxassetid://...)",
            set_kill_test    = "▶ Test Killsound",

            set_reset_all    = "Reset All Settings",
            set_rejoin       = "Rejoin Server",
            set_hop          = "Server Hop (random)",
            set_copy_job     = "Copy Job ID",
            set_join_input   = "Job ID to join",
            set_join_btn     = "Join by Job ID",
            set_copy_cfg     = "Copy Config JSON",
            set_exit         = "Exit (Unload AirHub)",

            set_cfg_hint1 = "Config save/load lives in the 'Configs' tab.",
            set_cfg_hint2 = "ONE config saves BOTH UI state AND AirHub settings.",
            set_cfg_hint3 = "Load once → theme, toggles, cheat settings — everything restored.",
            set_cfg_hint4 = "Legacy AirHub/Configs/*.json auto-migrated on first load.",

            set_info_title   = "airhubUI v1.9.3 · unified configs",
            set_info_shift   = "RightShift — toggle menu",
            set_info_mmb     = "MMB on any row — bind menu",
            set_info_rmb     = "RMB on any row — options menu",
            set_info_folder  = "Configs → airhubUI_Configs/",
            set_info_place   = "Place ID: %d",
            set_info_job     = "Job ID: %s",
            set_info_players = "Players: %d/%d",
            set_info_uptime  = "Uptime: %02d:%02d:%02d",
            set_info_fps     = "FPS: %d",
            set_info_ping    = "Ping: %d ms",

            set_confirm_reset = "Click again to confirm Reset All (3s)",
            set_cfg_copied    = "Config JSON copied",
            set_job_copied    = "Job ID copied",
            set_job_invalid   = "Enter a valid Job ID first",
            set_join_ok       = "Joining server...",

            -- Tooltips
            tt_set_logs_enabled = "Master switch for shot logging (hit / miss / kill text)",
            tt_set_show_hits    = "Show a log entry when a shot hits",
            tt_set_show_miss    = "Show a log entry when a shot misses",
            tt_set_duration     = "How long each log entry stays on screen (seconds)",
            tt_set_font_size    = "Log text size in pixels (12-30)",
            tt_set_hit_enabled  = "Play a sound when a shot hits",
            tt_set_hit_sound    = "Preset hitsound. Choose 'Custom...' to enter your own ID below",
            tt_set_hit_volume   = "Hitsound volume multiplier (0-10)",
            tt_set_hit_custom   = "Only used when Hitsound preset = 'Custom...'. Paste rbxassetid://NUMBER",
            tt_set_hit_test     = "Play the current hitsound in-game right now",
            tt_set_kill_enabled = "Play a sound when you kill someone",
            tt_set_kill_sound   = "Preset killsound. Choose 'Custom...' to enter your own ID below",
            tt_set_kill_volume  = "Killsound volume multiplier (0-10)",
            tt_set_kill_custom  = "Only used when Killsound preset = 'Custom...'. Paste rbxassetid://NUMBER",
            tt_set_kill_test    = "Play the current killsound in-game right now",
            tt_set_reset_all    = "Reset ALL AirHub settings to defaults (double-click to confirm)",
            tt_set_rejoin       = "Reconnect to the same server instance",
            tt_set_hop          = "Pick a random open server on the same place",
            tt_set_copy_job     = "Copy game.JobId to clipboard",
            tt_set_join_input   = "Paste a Job ID (from Copy Job ID) to rejoin a specific server",
            tt_set_join_btn     = "Teleport to the server with the Job ID above",
            tt_set_copy_cfg     = "Copy the current full config (UI + cheat) as JSON to clipboard",
            tt_set_exit         = "Unload AirHub and destroy all UI",
        }
        local ru = {
            set_sec_logs   = "Логи выстрелов и звуки",
            set_sec_main   = "Основное",
            set_sec_cfg    = "Конфиги (единые)",
            set_sec_info   = "Информация",

            set_logs_enabled = "Логи включены",
            set_show_hits    = "Показывать попадания",
            set_show_miss    = "Показывать промахи",
            set_duration     = "Длительность (с)",
            set_font_size    = "Размер шрифта",

            set_hitsound     = "ЗВУК ПОПАДАНИЯ",
            set_hit_enabled  = "Hitsound включён",
            set_hit_sound    = "Звук попадания",
            set_hit_volume   = "Громкость hitsound",
            set_hit_custom   = "Свой ID hitsound (rbxassetid://...)",
            set_hit_test     = "▶ Тест hitsound",

            set_killsound    = "ЗВУК УБИЙСТВА",
            set_kill_enabled = "Killsound включён",
            set_kill_sound   = "Звук убийства",
            set_kill_volume  = "Громкость killsound",
            set_kill_custom  = "Свой ID killsound (rbxassetid://...)",
            set_kill_test    = "▶ Тест killsound",

            set_reset_all    = "Сбросить все настройки",
            set_rejoin       = "Переподключиться к серверу",
            set_hop          = "Server Hop (случайный)",
            set_copy_job     = "Скопировать Job ID",
            set_join_input   = "Job ID для входа",
            set_join_btn     = "Войти по Job ID",
            set_copy_cfg     = "Скопировать JSON конфига",
            set_exit         = "Выход (выгрузить AirHub)",

            set_cfg_hint1 = "Сохранение/загрузка конфигов — во вкладке 'Configs'.",
            set_cfg_hint2 = "ОДИН конфиг сохраняет И UI И настройки AirHub.",
            set_cfg_hint3 = "Загрузил один раз → тема, тоглы, настройки — всё восстановлено.",
            set_cfg_hint4 = "Старые AirHub/Configs/*.json авто-мигрируются при первом запуске.",

            set_info_title   = "airhubUI v1.9.3 · единые конфиги",
            set_info_shift   = "RightShift — открыть/закрыть меню",
            set_info_mmb     = "MMB по любой строке — меню биндов",
            set_info_rmb     = "RMB по любой строке — меню опций",
            set_info_folder  = "Конфиги → airhubUI_Configs/",
            set_info_place   = "Place ID: %d",
            set_info_job     = "Job ID: %s",
            set_info_players = "Игроков: %d/%d",
            set_info_uptime  = "Работает: %02d:%02d:%02d",
            set_info_fps     = "FPS: %d",
            set_info_ping    = "Ping: %d мс",

            set_confirm_reset = "Нажмите ещё раз для подтверждения сброса (3с)",
            set_cfg_copied    = "JSON конфига скопирован",
            set_job_copied    = "Job ID скопирован",
            set_job_invalid   = "Сначала введите корректный Job ID",
            set_join_ok       = "Подключение к серверу...",

            tt_set_logs_enabled = "Главный выключатель логов выстрелов (попадание / промах / килл)",
            tt_set_show_hits    = "Показывать запись лога при попадании",
            tt_set_show_miss    = "Показывать запись лога при промахе",
            tt_set_duration     = "Сколько держать каждую запись на экране (секунды)",
            tt_set_font_size    = "Размер текста логов в пикселях (12-30)",
            tt_set_hit_enabled  = "Играть звук при попадании",
            tt_set_hit_sound    = "Пресет звука попадания. Выбери 'Custom...' чтобы вписать свой ID",
            tt_set_hit_volume   = "Множитель громкости hitsound (0-10)",
            tt_set_hit_custom   = "Используется только при Hitsound preset = 'Custom...'. Вставь rbxassetid://NUMBER",
            tt_set_hit_test     = "Проиграть текущий hitsound прямо сейчас",
            tt_set_kill_enabled = "Играть звук при убийстве",
            tt_set_kill_sound   = "Пресет звука убийства. Выбери 'Custom...' чтобы вписать свой ID",
            tt_set_kill_volume  = "Множитель громкости killsound (0-10)",
            tt_set_kill_custom  = "Используется только при Killsound preset = 'Custom...'. Вставь rbxassetid://NUMBER",
            tt_set_kill_test    = "Проиграть текущий killsound прямо сейчас",
            tt_set_reset_all    = "Сбросить ВСЕ настройки AirHub (двойной клик для подтверждения)",
            tt_set_rejoin       = "Переподключение к тому же серверу",
            tt_set_hop          = "Случайный открытый сервер на том же месте",
            tt_set_copy_job     = "Копировать game.JobId в буфер обмена",
            tt_set_join_input   = "Вставь Job ID (из Copy Job ID) чтобы переподключиться к конкретному серверу",
            tt_set_join_btn     = "Телепорт на сервер с указанным Job ID",
            tt_set_copy_cfg     = "Скопировать полный текущий конфиг (UI + чит) как JSON",
            tt_set_exit         = "Выгрузить AirHub и уничтожить UI",
        }
        for k, v in pairs(en) do UI.L.en[k] = v end
        for k, v in pairs(ru) do UI.L.ru[k] = v end
        if UI.RefreshTheme then pcall(UI.RefreshTheme) end
    end
end

-- Localize helper (T from airhubUI if present)
local function T(key, ...)
    local UI = getgenv().airhubUI
    if UI and UI.T then
        local ok, res = pcall(UI.T, key, ...)
        if ok and type(res) == "string" then return res end
    end
    return key
end

--// ---------------------------------------------------------------------------
--// Defaults
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

-- Sound presets
local soundPresets = {
    ["gamesense"]  = 83717596220569,
    ["neverlose"]  = 139452805868562,
    ["crit"]       = 122699784909910,
    ["primordial"] = 97511223764004,
}
local soundOrder = { "gamesense", "neverlose", "crit", "primordial" }
local CUSTOM_OPTION = "Custom..."

local function buildSoundList()
    local list = {}
    for _, name in ipairs(soundOrder) do list[#list + 1] = name end
    list[#list + 1] = CUSTOM_OPTION
    return list
end
local SOUND_LIST = buildSoundList()

local function soundNameForId(id)
    for name, sid in pairs(soundPresets) do
        if sid == id then return name end
    end
    return CUSTOM_OPTION
end

-- Preview helper — plays a sound via camera, auto-destroys after 5s
local previewSounds = {}
local function PlayPreviewById(id)
    if not id or id <= 0 then return end
    local cam = workspace.CurrentCamera
    if not cam then return end
    local ok, snd = pcall(function()
        local s = Instance.new("Sound")
        s.SoundId = "rbxassetid://" .. tostring(id)
        s.Volume = 1
        s.Parent = cam
        s:Play()
        return s
    end)
    if ok and snd then
        previewSounds[#previewSounds + 1] = snd
        task.delay(5, function()
            pcall(function() snd:Destroy() end)
            for i = #previewSounds, 1, -1 do
                if previewSounds[i] == snd then table.remove(previewSounds, i) end
            end
        end)
    end
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

    -- Logging / sounds — reset ALL including IDs
    Hg.Logging.Enabled    = true
    Hg.Logging.ShowHit    = true
    Hg.Logging.ShowMiss   = true
    Hg.Logging.Duration   = 1
    Hg.Logging.FontSize   = 18

    Hg.Sounds.HitsoundEnabled  = false
    Hg.Sounds.KillsoundEnabled = false
    Hg.Sounds.HitsoundVolume   = 1
    Hg.Sounds.KillsoundVolume  = 1
    Hg.Sounds.HitsoundID       = soundPresets["gamesense"]
    Hg.Sounds.KillsoundID      = soundPresets["gamesense"]
    Hg.Sounds.HitsoundCustomId = ""
    Hg.Sounds.KillsoundCustomId = ""
end

--// ---------------------------------------------------------------------------
--// Rejoin / Hop / Join
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
        ShowError(T("n_fs_unavailable") ~= "n_fs_unavailable" and T("n_fs_unavailable") or "Server hop: no HTTP method available")
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

local function doJoinByJob(jobId)
    if not jobId or jobId == "" then
        ShowError(T("set_job_invalid"))
        return
    end
    jobId = jobId:gsub("%s+", "")
    ShowError(T("set_join_ok"))
    task.wait(0.15)
    pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, LocalPlayer)
    end)
end

local function doCopyJob()
    local sc = rawget(_G, "setclipboard") or rawget(_G, "toclipboard")
    if type(sc) == "function" then
        pcall(sc, game.JobId)
        ShowError(T("set_job_copied"))
    end
end

local function doCopyConfig()
    if H.Config and H.Config.Serialize then
        local ok, data = pcall(H.Config.Serialize, true)
        if ok and data then
            local okEnc, str = pcall(function() return HttpService:JSONEncode(data) end)
            if okEnc and str then
                local sc = rawget(_G, "setclipboard") or rawget(_G, "toclipboard")
                if type(sc) == "function" then
                    pcall(sc, str)
                    ShowError(T("set_cfg_copied"))
                    return
                end
                print("[AirHub] Config JSON: " .. str)
            end
        end
    end
end

--// ---------------------------------------------------------------------------
--// LEFT COLUMN — Shot Logs & Sounds
--// ---------------------------------------------------------------------------
local logSec = SettingsTab:CreateSection({ Name = "set_sec_logs" })

logSec:AddToggle({
    Name = "set_logs_enabled",
    Value = H.Logging.Enabled,
    Callback = function(v) H.Logging.Enabled = v end,
    Tooltip = "tt_set_logs_enabled",
})
logSec:AddToggle({
    Name = "set_show_hits",
    Value = H.Logging.ShowHit,
    Callback = function(v) H.Logging.ShowHit = v end,
    Tooltip = "tt_set_show_hits",
})
logSec:AddToggle({
    Name = "set_show_miss",
    Value = H.Logging.ShowMiss,
    Callback = function(v) H.Logging.ShowMiss = v end,
    Tooltip = "tt_set_show_miss",
})
logSec:AddSlider({
    Name = "set_duration",
    Value = H.Logging.Duration,
    Min = 0.5, Max = 5, Decimals = 1,
    Callback = function(v) H.Logging.Duration = v end,
    Tooltip = "tt_set_duration",
})
logSec:AddSlider({
    Name = "set_font_size",
    Value = H.Logging.FontSize,
    Min = 12, Max = 30,
    Callback = function(v) H.Logging.FontSize = v end,
    Tooltip = "tt_set_font_size",
})

-- HITSound
logSec:AddDivider({ Text = "set_hitsound" })
logSec:AddToggle({
    Name = "set_hit_enabled",
    Value = H.Sounds.HitsoundEnabled,
    Callback = function(v) H.Sounds.HitsoundEnabled = v end,
    Tooltip = "tt_set_hit_enabled",
})
local hitSoundRef = logSec:AddDropdown({
    Name = "set_hit_sound",
    Value = soundNameForId(H.Sounds.HitsoundID),
    List = SOUND_LIST,
    Callback = function(v)
        if soundPresets[v] then
            H.Sounds.HitsoundID = soundPresets[v]
        end
        -- Preview on select
        local id = H.Sounds.HitsoundID
        if v == CUSTOM_OPTION and H.Sounds.HitsoundCustomId and H.Sounds.HitsoundCustomId ~= "" then
            local n = tonumber(H.Sounds.HitsoundCustomId:match("%d+") or "")
            if n then id = n end
        end
        PlayPreviewById(id)
    end,
    Tooltip = "tt_set_hit_sound",
})
logSec:AddSlider({
    Name = "set_hit_volume",
    Value = H.Sounds.HitsoundVolume,
    Min = 0, Max = 10, Decimals = 1,
    Callback = function(v) H.Sounds.HitsoundVolume = v end,
    Tooltip = "tt_set_hit_volume",
})
logSec:AddInput({
    Name = "set_hit_custom",
    Value = H.Sounds.HitsoundCustomId or "",
    Callback = function(v)
        H.Sounds.HitsoundCustomId = v or ""
        if H.Sounds.HitsoundCustomId ~= "" then
            local n = tonumber(H.Sounds.HitsoundCustomId:match("%d+") or "")
            if n then H.Sounds.HitsoundID = n end
        end
    end,
    Tooltip = "tt_set_hit_custom",
})
logSec:AddButton({
    Name = "set_hit_test",
    Callback = function()
        PlayPreviewById(H.Sounds.HitsoundID)
    end,
    Tooltip = "tt_set_hit_test",
})

-- KILLSound
logSec:AddDivider({ Text = "set_killsound" })
logSec:AddToggle({
    Name = "set_kill_enabled",
    Value = H.Sounds.KillsoundEnabled,
    Callback = function(v) H.Sounds.KillsoundEnabled = v end,
    Tooltip = "tt_set_kill_enabled",
})
logSec:AddDropdown({
    Name = "set_kill_sound",
    Value = soundNameForId(H.Sounds.KillsoundID),
    List = SOUND_LIST,
    Callback = function(v)
        if soundPresets[v] then
            H.Sounds.KillsoundID = soundPresets[v]
        end
        local id = H.Sounds.KillsoundID
        if v == CUSTOM_OPTION and H.Sounds.KillsoundCustomId and H.Sounds.KillsoundCustomId ~= "" then
            local n = tonumber(H.Sounds.KillsoundCustomId:match("%d+") or "")
            if n then id = n end
        end
        PlayPreviewById(id)
    end,
    Tooltip = "tt_set_kill_sound",
})
logSec:AddSlider({
    Name = "set_kill_volume",
    Value = H.Sounds.KillsoundVolume,
    Min = 0, Max = 10, Decimals = 1,
    Callback = function(v) H.Sounds.KillsoundVolume = v end,
    Tooltip = "tt_set_kill_volume",
})
logSec:AddInput({
    Name = "set_kill_custom",
    Value = H.Sounds.KillsoundCustomId or "",
    Callback = function(v)
        H.Sounds.KillsoundCustomId = v or ""
        if H.Sounds.KillsoundCustomId ~= "" then
            local n = tonumber(H.Sounds.KillsoundCustomId:match("%d+") or "")
            if n then H.Sounds.KillsoundID = n end
        end
    end,
    Tooltip = "tt_set_kill_custom",
})
logSec:AddButton({
    Name = "set_kill_test",
    Callback = function()
        PlayPreviewById(H.Sounds.KillsoundID)
    end,
    Tooltip = "tt_set_kill_test",
})

--// ---------------------------------------------------------------------------
--// RIGHT COLUMN — Main
--// ---------------------------------------------------------------------------
local mainSec = SettingsTab:CreateSection({ Name = "set_sec_main", Side = "Right" })

-- Confirm-reset mechanism
local resetClickToken = 0
mainSec:AddButton({
    Name = "set_reset_all",
    Callback = function()
        resetClickToken = resetClickToken + 1
        local myToken = resetClickToken
        if resetClickToken >= 2 then
            resetClickToken = 0
            ResetEverything()
            ShowError("Reset done")
            return
        end
        ShowError(T("set_confirm_reset"))
        task.delay(3, function()
            if resetClickToken == myToken then resetClickToken = 0 end
        end)
    end,
    Tooltip = "tt_set_reset_all",
})

mainSec:AddButton({
    Name = "set_rejoin",
    Callback = function() doRejoin() end,
    Tooltip = "tt_set_rejoin",
})
mainSec:AddButton({
    Name = "set_hop",
    Callback = function() doServerHop() end,
    Tooltip = "tt_set_hop",
})
mainSec:AddButton({
    Name = "set_copy_job",
    Callback = function() doCopyJob() end,
    Tooltip = "tt_set_copy_job",
})
mainSec:AddButton({
    Name = "set_copy_cfg",
    Callback = function() doCopyConfig() end,
    Tooltip = "tt_set_copy_cfg",
})

-- Join by Job ID
local jobIdRef = mainSec:AddInput({
    Name = "set_join_input",
    Value = "",
    Callback = function(v) end,
    Tooltip = "tt_set_join_input",
})
mainSec:AddButton({
    Name = "set_join_btn",
    Callback = function()
        local jid = ""
        if jobIdRef and jobIdRef.Get then
            jid = jobIdRef:Get() or ""
        end
        doJoinByJob(jid)
    end,
    Tooltip = "tt_set_join_btn",
})

mainSec:AddDivider({ Text = "DANGER ZONE" })

mainSec:AddButton({
    Name = "set_exit",
    Callback = function()
        if Window and Window.Unload then Window:Unload() end
    end,
    Tooltip = "tt_set_exit",
})

--// ---------------------------------------------------------------------------
--// RIGHT COLUMN — Configs hint
--// ---------------------------------------------------------------------------
local cfgHintSec = SettingsTab:CreateSection({ Name = "set_sec_cfg", Side = "Right" })
cfgHintSec:AddLabel({ Text = "set_cfg_hint1" })
cfgHintSec:AddLabel({ Text = "set_cfg_hint2",
    Color = Theme and Theme.Accent or Color3.fromRGB(77,107,254) })
cfgHintSec:AddLabel({ Text = "set_cfg_hint3" })
cfgHintSec:AddLabel({ Text = "set_cfg_hint4",
    Color = Theme and Theme.Muted or Color3.fromRGB(156,163,175) })

--// ---------------------------------------------------------------------------
--// RIGHT COLUMN — Live Info
--// ---------------------------------------------------------------------------
local infoSec = SettingsTab:CreateSection({ Name = "set_sec_info", Side = "Right" })
infoSec:AddLabel({ Text = "set_info_title" })
infoSec:AddLabel({ Text = "set_info_shift" })
infoSec:AddLabel({ Text = "set_info_mmb" })
infoSec:AddLabel({ Text = "set_info_rmb" })
infoSec:AddLabel({ Text = "set_info_folder" })

local placeLbl  = infoSec:AddLabel({ Text = string.format(T("set_info_place"), game.PlaceId) })
local jobLbl    = infoSec:AddLabel({ Text = string.format(T("set_info_job"), tostring(game.JobId or "?")) })
local playLbl   = infoSec:AddLabel({ Text = string.format(T("set_info_players"), #Players:GetPlayers(), Players.MaxPlayers) })
local uptimeLbl = infoSec:AddLabel({ Text = string.format(T("set_info_uptime"), 0, 0, 0) })
local fpsLbl    = infoSec:AddLabel({ Text = string.format(T("set_info_fps"), 0) })
local pingLbl   = infoSec:AddLabel({ Text = string.format(T("set_info_ping"), 0) })

-- Uptime + FPS sampler
local sessionStart = tick()
local fpsFrames, fpsAccum, currentFPS = 0, 0, 0
local ui = getgenv().airhubUI
local rs = game:GetService("RunService")
pcall(function()
    rs.RenderStepped:Connect(function(dt)
        fpsFrames = fpsFrames + 1
        fpsAccum  = fpsAccum + dt
        if fpsAccum >= 0.5 then
            currentFPS = math.floor(fpsFrames / fpsAccum + 0.5)
            fpsFrames, fpsAccum = 0, 0
        end
    end)
end)

local function updateInfo()
    local up = math.floor(tick() - sessionStart)
    local hh = math.floor(up / 3600)
    local mm = math.floor((up % 3600) / 60)
    local ss = up % 60
    if uptimeLbl and uptimeLbl.Set then
        uptimeLbl:Set(string.format(T("set_info_uptime"), hh, mm, ss))
    end
    if playLbl and playLbl.Set then
        playLbl:Set(string.format(T("set_info_players"), #Players:GetPlayers(), Players.MaxPlayers))
    end
    if fpsLbl and fpsLbl.Set then
        fpsLbl:Set(string.format(T("set_info_fps"), currentFPS))
    end
    if pingLbl and pingLbl.Set then
        local ok, p = pcall(function() return math.floor(LocalPlayer:GetNetworkPing() * 1000 + 0.5) end)
        pingLbl:Set(string.format(T("set_info_ping"), ok and p or 0))
    end
    if jobLbl and jobLbl.Set then
        jobLbl:Set(string.format(T("set_info_job"), tostring(game.JobId or "?")))
    end
end

task.spawn(function()
    while not H.ShuttingDown do
        pcall(updateInfo)
        task.wait(0.5)
    end
end)

print("[AirHub] 08_settings: loaded OK v2 (RU loc + tooltips + preview + join by JobID + live info)")
