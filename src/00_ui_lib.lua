--=============================================================
-- airhubUI v1.9.3 — Fixed: RightShift toggle (removed _showing/_hiding deadlock)
--=============================================================

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local CoreGui          = game:GetService("CoreGui")
local HttpService      = game:GetService("HttpService")
local LocalPlayer      = Players.LocalPlayer

-- ══════════════════════════════════════════════════════════════
-- CONFIG
-- ══════════════════════════════════════════════════════════════
local Config = {
    Language = "en",
    Version = "1.9.3",
    WindowWidth = 720, WindowHeight = 500,
    MinWidth = 520, MinHeight = 380,
    ToggleKey = Enum.KeyCode.RightShift,
    AnimSpeed = 0.15, MenuAnim = 0.32, MenuCloseAnim = 0.20, PopupAnim = 0.18,
    CornerRadius = UDim.new(0, 8), BaseCornerRadius = 8,
    CurrentFontFamily = Enum.Font.Code, CurrentFontName = "Code", CurrentFontScale = 1.0,
    PopupZ = 5000, OverlayZ = 4000, NotifyZ = 6000, TooltipZ = 7000,
    StatusBar = true,
    MenuTransparency = 0.06, TabTransparency = 0, SectionTransparency = 0, ElementTransparency = 0,
    NotificationDuration = 3, NotificationPosition = "top-right",
    TooltipDelay = 0.05,
    RainbowCallbackInterval = 4,
}

-- ══════════════════════════════════════════════════════════════
-- LOCALIZATION
-- ══════════════════════════════════════════════════════════════════
local L = {
    en = {
        tab_settings = "Settings", tab_configs = "Configs", tab_binds = "Binds",
        sec_theme = "Theme Presets", sec_window = "Window", sec_font = "Font",
        sec_anim = "Animation", sec_menu_colors = "Menu Colors", sec_text_colors = "Text Colors",
        sec_accent = "Accent Colors", sec_transparency = "Transparency",
        sec_notifications = "Notifications", sec_tooltips = "Tooltips",
        sec_actions = "Actions", sec_general = "General",
        lbl_preset = "Preset", lbl_title = "Title", lbl_width = "Width", lbl_height = "Height",
        lbl_sidebar_width = "Sidebar Width", lbl_corner_radius = "Corner Radius",
        lbl_status_bar = "Status Bar", lbl_font_family = "Font Family", lbl_font_size = "Font Size",
        lbl_menu_open = "Menu Open Speed", lbl_menu_close = "Menu Close Speed",
        lbl_popup_speed = "Popup Speed", lbl_menu_bg = "Menu Background",
        lbl_sidebar = "Sidebar", lbl_panel = "Panel", lbl_section_bg = "Section Background",
        lbl_element = "Element", lbl_element_hover = "Element Hover",
        lbl_outline = "Outline / Border", lbl_text = "Text", lbl_subtext = "SubText",
        lbl_muted = "Muted", lbl_accent = "Accent", lbl_accent2 = "Accent 2",
        lbl_success = "Success", lbl_danger = "Danger", lbl_warning = "Warning",
        lbl_on_accent = "On Accent", lbl_duration = "Duration", lbl_position = "Position",
        lbl_delay = "Delay", lbl_language = "Language",
        lbl_transparency_menu = "Menu", lbl_transparency_tabs = "Tabs",
        lbl_transparency_sections = "Sections", lbl_transparency_elements = "Elements",
        btn_test_notif = "Test Notification", btn_reset_light = "Reset to airhubUI Light",
        btn_reset_dark = "Reset to airhubUI Dark", btn_unload = "Unload Menu",
        btn_reshow = "Re-show Window",
        tt_preset = "Switch full color scheme + font + text size",
        tt_title = "Window title (header + status bar)",
        tt_width = "Window width (520-1200 px)", tt_height = "Window height (380-900 px)",
        tt_sidebar_width = "Sidebar tabs width",
        tt_corner_radius = "Corner rounding (0 = flat, 24 = round)",
        tt_status_bar = "Show bottom FPS / ping / uptime bar",
        tt_font_family = "Font for all text elements",
        tt_font_size = "Text size multiplier (0.6x - 1.8x)",
        tt_menu_open = "Menu open animation duration",
        tt_menu_close = "Menu close animation duration",
        tt_popup_speed = "Popups appear speed", tt_menu_bg = "Main window background",
        tt_sidebar = "Sidebar background", tt_panel = "Panel / section header background",
        tt_section_bg = "Section container background",
        tt_element = "Base element background", tt_element_hover = "Hover background",
        tt_outline = "Border / stroke color", tt_text = "Main text color",
        tt_subtext = "Secondary text", tt_muted = "Muted / dim text",
        tt_accent = "Primary accent", tt_accent2 = "Secondary accent",
        tt_success = "Success notifications", tt_danger = "Errors / destructive actions",
        tt_warning = "Warnings", tt_on_accent = "Text on accent background",
        tt_duration = "How long notifications stay (sec)",
        tt_position = "Screen corner for notifications", tt_delay = "Tooltip hover delay",
        tt_language = "Menu language",
        tt_transparency_menu = "Main window transparency (0-50%)",
        tt_transparency_tabs = "Tabs buttons transparency",
        tt_transparency_sections = "Sections background transparency",
        tt_transparency_elements = "Element transparency",
        tt_test_notif = "Show a test notification",
        tt_reset_light = "Reset to default light theme", tt_reset_dark = "Reset to dark theme",
        tt_unload = "Fully unload menu from memory", tt_reshow = "Force show window",
        sec_file_configs = "File Configs", sec_clipboard = "Clipboard Fallback",
        sec_inmemory = "In-Memory Presets",
        lbl_config_name = "Config Name", lbl_saved_configs = "Saved Configs",
        lbl_preset_name = "Preset Name",
        lbl_fs_available = "Filesystem available",
        lbl_fs_unavailable = "Filesystem NOT available — use Clipboard",
        lbl_folder_path = "Files saved to %s/ (or root with %s prefix).",
        lbl_clipboard_fallback_hint = "Use if filesystem is unavailable.",
        lbl_inmemory_hint = "Presets stored in memory only. Lost on unload.",
        lbl_actions = "ACTIONS",
        btn_save_file = "Save to File", btn_load_file = "Load from File",
        btn_delete_file = "Delete File", btn_refresh_list = "Refresh List",
        btn_copy_clipboard = "Copy to Clipboard", btn_paste_clipboard = "Paste from Clipboard",
        btn_save_preset = "Save Current as Preset", btn_load_preset = "Load Preset",
        btn_delete_preset = "Delete Preset",
        tt_config_name = "Config name (without .json)",
        tt_saved_configs = "Configs saved on disk", tt_preset_name = "Preset name",
        tt_save_file = "Save current config to disk", tt_load_file = "Load config from disk",
        tt_delete_file = "Delete config file", tt_refresh_list = "Refresh config list",
        tt_copy_clipboard = "Copy JSON config to clipboard",
        tt_paste_clipboard = "Load config from clipboard",
        tt_save_preset = "Save current as in-memory preset",
        tt_load_preset = "Load in-memory preset", tt_delete_preset = "Delete in-memory preset",
        sec_active_binds = "Active Binds",
        lbl_binds_hint1 = "MMB (middle-click) on any row — open bind menu.",
        lbl_binds_hint2 = "Keybinds work independently of the menu.",
        lbl_binds_hint3 = "Adding a key does NOT activate the function.",
        lbl_live_status = "LIVE STATUS", btn_binds_refresh = "Refresh",
        btn_binds_clear = "Clear All (Reset)",
        lbl_binds_empty = "Empty. Middle-click any component.",
        tt_binds_refresh = "Refresh bind list", tt_binds_clear = "Remove all binds",
        n_theme_applied = "Applied: %s", n_theme_reset_light = "Reset to airhubUI Light",
        n_theme_reset_dark = "Reset to airhubUI Dark", n_font_applied = "Applied: %s",
        n_unloading = "Unloading...", n_config = "Config",
        n_enter_name = "Enter a name first", n_saved_to = "Saved: %s",
        n_save_failed = "Save failed: %s", n_fs_unavailable = "Filesystem unavailable",
        n_fs_unavail_clipboard = "FS unavailable — copied to clipboard",
        n_fs_unavail_console = "FS unavailable — printed to console",
        n_loaded = "Loaded: %s", n_load_failed = "Load failed: %s",
        n_deleted = "Deleted: %s", n_delete_failed = "Delete failed: %s",
        n_delfile_missing = "delfile not supported by executor",
        n_list_refreshed = "List refreshed", n_printed_console = "Printed to console (F9)",
        n_copied = "Copied to clipboard", n_loaded_clipboard = "Loaded from clipboard",
        n_clipboard_empty = "Clipboard empty", n_invalid = "Invalid: %s",
        n_preset_saved = "Preset saved: %s", n_preset_deleted = "Preset deleted: %s",
        n_preset_not_found = "Not found: %s", n_binds_cleared = "All binds cleared",
        n_test_notif_title = "Test", n_test_notif_text = "This is a test notification",
        n_lang_changed = "Language: %s",
        status_ready = "ready",
        ph_search = "Search...", ph_my_config = "my_config",
        ph_my_preset = "My Preset", ph_airhubui = "airhubUI",
        lang_en = "English", lang_ru = "Русский",
    },
    ru = {
        tab_settings = "Настройки", tab_configs = "Конфиги", tab_binds = "Бинды",
        sec_theme = "Пресеты тем", sec_window = "Окно", sec_font = "Шрифт",
        sec_anim = "Анимация", sec_menu_colors = "Цвета меню",
        sec_text_colors = "Цвета текста", sec_accent = "Акцентные цвета",
        sec_transparency = "Прозрачность", sec_notifications = "Уведомления",
        sec_tooltips = "Подсказки", sec_actions = "Действия", sec_general = "Основное",
        lbl_preset = "Пресет", lbl_title = "Заголовок", lbl_width = "Ширина",
        lbl_height = "Высота", lbl_sidebar_width = "Ширина сайдбара",
        lbl_corner_radius = "Скругление углов", lbl_status_bar = "Статус-бар",
        lbl_font_family = "Семейство шрифта", lbl_font_size = "Размер шрифта",
        lbl_menu_open = "Скорость открытия", lbl_menu_close = "Скорость закрытия",
        lbl_popup_speed = "Скорость попапов", lbl_menu_bg = "Фон меню",
        lbl_sidebar = "Сайдбар", lbl_panel = "Панель", lbl_section_bg = "Фон секции",
        lbl_element = "Элемент", lbl_element_hover = "Элемент (hover)",
        lbl_outline = "Обводка / границы", lbl_text = "Текст", lbl_subtext = "Подтекст",
        lbl_muted = "Приглушённый", lbl_accent = "Акцент", lbl_accent2 = "Акцент 2",
        lbl_success = "Успех", lbl_danger = "Опасность", lbl_warning = "Предупреждение",
        lbl_on_accent = "На акценте", lbl_duration = "Длительность",
        lbl_position = "Позиция", lbl_delay = "Задержка", lbl_language = "Язык",
        lbl_transparency_menu = "Меню", lbl_transparency_tabs = "Табы",
        lbl_transparency_sections = "Секции", lbl_transparency_elements = "Элементы",
        btn_test_notif = "Тест уведомления", btn_reset_light = "Сброс на airhubUI Light",
        btn_reset_dark = "Сброс на airhubUI Dark", btn_unload = "Выгрузить меню",
        btn_reshow = "Показать окно",
        tt_preset = "Переключить всю цветовую схему + шрифт + размер",
        tt_title = "Заголовок окна (шапка + статус-бар)",
        tt_width = "Ширина окна (520-1200 px)", tt_height = "Высота окна (380-900 px)",
        tt_sidebar_width = "Ширина панели табов",
        tt_corner_radius = "Скругление углов (0 = прямые, 24 = круглые)",
        tt_status_bar = "Показывать нижнюю строку FPS / ping / uptime",
        tt_font_family = "Шрифт для всех текстовых элементов",
        tt_font_size = "Множитель размера текста (0.6x - 1.8x)",
        tt_menu_open = "Длительность открытия меню",
        tt_menu_close = "Длительность закрытия меню",
        tt_popup_speed = "Скорость появления попапов",
        tt_menu_bg = "Фон главного окна", tt_sidebar = "Фон боковой панели",
        tt_panel = "Фон панелей и заголовков секций",
        tt_section_bg = "Фон контейнеров секций",
        tt_element = "Фон элементов (тоглы, слайдеры)",
        tt_element_hover = "Фон при наведении", tt_outline = "Цвет границ и рамок",
        tt_text = "Основной цвет текста", tt_subtext = "Вторичный текст",
        tt_muted = "Приглушённый текст", tt_accent = "Главный акцент",
        tt_accent2 = "Дополнительный акцент", tt_success = "Успешные уведомления",
        tt_danger = "Ошибки / опасные действия", tt_warning = "Предупреждения",
        tt_on_accent = "Текст на акцентном фоне",
        tt_duration = "Сколько показывать уведомление (сек)",
        tt_position = "Угол экрана для уведомлений",
        tt_delay = "Задержка перед показом подсказки", tt_language = "Язык меню",
        tt_transparency_menu = "Прозрачность главного окна (0-50%)",
        tt_transparency_tabs = "Прозрачность кнопок табов",
        tt_transparency_sections = "Прозрачность фона секций",
        tt_transparency_elements = "Прозрачность элементов",
        tt_test_notif = "Показать тестовое уведомление",
        tt_reset_light = "Сбросить к светлой теме",
        tt_reset_dark = "Сбросить к тёмной теме",
        tt_unload = "Полностью выгрузить меню из памяти",
        tt_reshow = "Принудительно показать окно",
        sec_file_configs = "Файловые конфиги", sec_clipboard = "Clipboard (резерв)",
        sec_inmemory = "Пресеты в памяти",
        lbl_config_name = "Имя конфига", lbl_saved_configs = "Сохранённые конфиги",
        lbl_preset_name = "Имя пресета",
        lbl_fs_available = "Файловая система доступна",
        lbl_fs_unavailable = "Файловая система НЕДОСТУПНА — используйте Clipboard",
        lbl_folder_path = "Файлы сохраняются в %s/ (или в корень с префиксом %s).",
        lbl_clipboard_fallback_hint = "Используйте если файловая система недоступна.",
        lbl_inmemory_hint = "Пресеты хранятся только в памяти. Пропадают при выгрузке.",
        lbl_actions = "ДЕЙСТВИЯ",
        btn_save_file = "Сохранить в файл", btn_load_file = "Загрузить из файла",
        btn_delete_file = "Удалить файл", btn_refresh_list = "Обновить список",
        btn_copy_clipboard = "Копировать в clipboard",
        btn_paste_clipboard = "Вставить из clipboard",
        btn_save_preset = "Сохранить как пресет",
        btn_load_preset = "Загрузить пресет", btn_delete_preset = "Удалить пресет",
        tt_config_name = "Имя конфига (без .json)",
        tt_saved_configs = "Конфиги сохранённые на диск",
        tt_preset_name = "Имя пресета",
        tt_save_file = "Сохранить текущий конфиг на диск",
        tt_load_file = "Загрузить конфиг с диска",
        tt_delete_file = "Удалить файл конфига",
        tt_refresh_list = "Обновить список конфигов",
        tt_copy_clipboard = "Копировать JSON-конфиг в clipboard",
        tt_paste_clipboard = "Загрузить конфиг из clipboard",
        tt_save_preset = "Сохранить текущий как пресет в памяти",
        tt_load_preset = "Загрузить пресет из памяти",
        tt_delete_preset = "Удалить пресет из памяти",
        sec_active_binds = "Активные бинды",
        lbl_binds_hint1 = "MMB (клик колесом) на любую строку — открыть меню биндов.",
        lbl_binds_hint2 = "Кейбинды работают через свою клавишу, независимо от меню.",
        lbl_binds_hint3 = "Добавление ключа не активирует функцию.",
        lbl_live_status = "СТАТУС В РЕАЛЬНОМ ВРЕМЕНИ",
        btn_binds_refresh = "Обновить", btn_binds_clear = "Очистить всё",
        lbl_binds_empty = "Пусто. Наведи MMB на любой компонент.",
        tt_binds_refresh = "Обновить список биндов",
        tt_binds_clear = "Удалить все бинды",
        n_theme_applied = "Применено: %s", n_theme_reset_light = "Сброс на airhubUI Light",
        n_theme_reset_dark = "Сброс на airhubUI Dark", n_font_applied = "Применено: %s",
        n_unloading = "Выгрузка...", n_config = "Конфиг",
        n_enter_name = "Сначала введите имя", n_saved_to = "Сохранено: %s",
        n_save_failed = "Сохранение не удалось: %s",
        n_fs_unavailable = "Файловая система недоступна",
        n_fs_unavail_clipboard = "ФС недоступна — скопировано в clipboard",
        n_fs_unavail_console = "ФС недоступна — выведено в консоль",
        n_loaded = "Загружено: %s", n_load_failed = "Загрузка не удалась: %s",
        n_deleted = "Удалено: %s", n_delete_failed = "Удаление не удалось: %s",
        n_delfile_missing = "delfile не поддерживается экзекутором",
        n_list_refreshed = "Список обновлён",
        n_printed_console = "Выведено в консоль (F9)",
        n_copied = "Скопировано в clipboard", n_loaded_clipboard = "Загружено из clipboard",
        n_clipboard_empty = "Clipboard пуст", n_invalid = "Неверно: %s",
        n_preset_saved = "Пресет сохранён: %s", n_preset_deleted = "Пресет удалён: %s",
        n_preset_not_found = "Не найдено: %s", n_binds_cleared = "Все бинды очищены",
        n_test_notif_title = "Тест", n_test_notif_text = "Это тестовое уведомление",
        n_lang_changed = "Язык: %s",
        status_ready = "готово",
        ph_search = "Поиск...", ph_my_config = "мой_конфиг",
        ph_my_preset = "Мой пресет", ph_airhubui = "airhubUI",
        lang_en = "English", lang_ru = "Русский",
    },
}

local function T(key, ...)
    if not key then return "" end
    local lang = L[Config.Language or "en"] or L.en
    local s = lang[key] or L.en[key] or key
    if type(s) ~= "string" then return tostring(s) end
    if select("#", ...) > 0 and s:find("%%") then
        local ok, res = pcall(string.format, s, ...)
        if ok then return res end
    end
    return s
end

local function tPlaceholder(inst, key)
    inst:SetAttribute("_tPlaceholder", key)
    inst.PlaceholderText = T(key)
    return inst
end

-- ══════════════════════════════════════════════════════════════
-- FPS + PING
-- ══════════════════════════════════════════════════════════════
local currentFPS = 60
do
    local fc, ft = 0, 0
    RunService.RenderStepped:Connect(function(dt)
        fc = fc + 1; ft = ft + dt
        if ft >= 0.5 then
            currentFPS = math.floor(fc / ft + 0.5)
            fc, ft = 0, 0
        end
    end)
end
local function getPing()
    local ok, p = pcall(function() return math.floor(LocalPlayer:GetNetworkPing() * 1000 + 0.5) end)
    return ok and p or 0
end

-- ══════════════════════════════════════════════════════════════
-- CLIPBOARD
-- ══════════════════════════════════════════════════════════════
local _clipSetFn, _clipSetName = nil, nil
local _clipGetFn, _clipGetName = nil, nil
local function _findGlobal(name)
    local fn = rawget(getfenv(), name)
    if type(fn) == "function" then return fn end
    if getgenv then
        local g = getgenv()
        if g and type(g[name]) == "function" then return g[name] end
    end
    return nil
end
local function detectClipboard()
    _clipSetFn, _clipSetName = nil, nil
    _clipGetFn, _clipGetName = nil, nil
    for _, name in ipairs({"setclipboard", "toclipboard", "writeclipboard", "set_clipboard"}) do
        local fn = _findGlobal(name)
        if fn then _clipSetFn = fn; _clipSetName = name; break end
    end
    for _, name in ipairs({"getclipboard", "fromclipboard", "readclipboard", "get_clipboard"}) do
        local fn = _findGlobal(name)
        if fn then _clipGetFn = fn; _clipGetName = name; break end
    end
end
detectClipboard()
local function trySetClipboard(str)
    if not _clipSetFn then detectClipboard() end
    if not _clipSetFn then return false, "no set-clipboard" end
    local ok, err = pcall(_clipSetFn, str)
    return ok, ok and _clipSetName or tostring(err)
end
local function tryGetClipboard()
    if not _clipGetFn then detectClipboard() end
    if not _clipGetFn then return nil, "no get-clipboard" end
    local ok, val = pcall(_clipGetFn)
    if ok and type(val) == "string" then return val, _clipGetName end
    return nil, "get-clipboard failed"
end

-- ══════════════════════════════════════════════════════════════
-- FILE CONFIG SYSTEM
-- ══════════════════════════════════════════════════════════════
local CONFIG_FOLDER = "airhubUI_Configs"
local ROOT_PREFIX = "airhubUI_"
local _configPathCache = {}

local function canReadWrite() return type(writefile) == "function" and type(readfile) == "function" end
local function canDelete() return type(delfile) == "function" end
local function fsAvailable() return canReadWrite() end
local function safeFileName(name)
    local c = tostring(name or ""):gsub("[^%w%-_]", "_")
    if c == "" then return nil end
    return c
end
local function tryPaths(name)
    local fname = safeFileName(name)
    if not fname then return {} end
    return {
        CONFIG_FOLDER .. "/" .. fname .. ".json",
        CONFIG_FOLDER .. "\\" .. fname .. ".json",
        ROOT_PREFIX .. fname .. ".json",
        fname .. ".json",
    }
end
local function ensureFolder()
    if type(makefolder) ~= "function" then return end
    local exists = false
    if type(isfolder) == "function" then
        local ok, r = pcall(isfolder, CONFIG_FOLDER)
        exists = ok and r
    end
    if not exists then pcall(makefolder, CONFIG_FOLDER) end
end
local function tryRead(path)
    if type(readfile) ~= "function" then return false end
    local ok, data = pcall(readfile, path)
    if not ok or type(data) ~= "string" or data == "" then return false end
    return true, data
end
local function writeConfigFile(name, jsonStr)
    if not canReadWrite() then return false, "writefile/readfile missing" end
    if type(jsonStr) ~= "string" or jsonStr == "" then
        return false, "empty json string"
    end
    ensureFolder()
    local errors = {}
    for _, path in ipairs(tryPaths(name)) do
        local wOk = pcall(writefile, path, jsonStr)
        if wOk then
            local rOk, data = tryRead(path)
            if rOk and data == jsonStr then
                _configPathCache[name] = path
                return true, path
            else
                table.insert(errors, path .. " (unreadable)")
            end
        else
            table.insert(errors, path .. " (write fail)")
        end
    end
    return false, table.concat(errors, " | ")
end
local function readConfigFile(name)
    if type(readfile) ~= "function" then return nil, "readfile missing" end
    local cached = _configPathCache[name]
    if cached then
        local ok, data = tryRead(cached)
        if ok then return data end
    end
    for _, path in ipairs(tryPaths(name)) do
        local ok, data = tryRead(path)
        if ok then _configPathCache[name] = path; return data end
    end
    if type(listfiles) == "function" then
        local fname = safeFileName(name)
        local dirs = {CONFIG_FOLDER, CONFIG_FOLDER .. "/", CONFIG_FOLDER .. "\\", "."}
        local seen = {}
        for _, dir in ipairs(dirs) do
            if not seen[dir] then
                seen[dir] = true
                local ok, files = pcall(listfiles, dir)
                if ok and type(files) == "table" then
                    for _, p in ipairs(files) do
                        local fullPath = tostring(p)
                        local basename = fullPath:match("([^/\\]+)$") or fullPath
                        local n = basename:match("^" .. ROOT_PREFIX .. "(.-)%.json$")
                                  or basename:match("^(.-)%.json$")
                        if n == fname then
                            local rOk, data = tryRead(fullPath)
                            if rOk then _configPathCache[name] = fullPath; return data end
                        end
                    end
                end
            end
        end
    end
    return nil, "not found"
end
local function deleteConfigFile(name)
    if type(delfile) ~= "function" then return false, "delfile missing" end
    local deleted = false
    for _, path in ipairs(tryPaths(name)) do
        local ok = pcall(delfile, path)
        if ok then deleted = true; _configPathCache[name] = nil end
    end
    if type(listfiles) == "function" then
        local fname = safeFileName(name)
        local dirs = {CONFIG_FOLDER, CONFIG_FOLDER .. "/", CONFIG_FOLDER .. "\\", "."}
        local seen = {}
        for _, dir in ipairs(dirs) do
            if not seen[dir] then
                seen[dir] = true
                local ok, files = pcall(listfiles, dir)
                if ok and type(files) == "table" then
                    for _, p in ipairs(files) do
                        local fullPath = tostring(p)
                        local basename = fullPath:match("([^/\\]+)$") or fullPath
                        local n = basename:match("^" .. ROOT_PREFIX .. "(.-)%.json$")
                                  or basename:match("^(.-)%.json$")
                        if n == fname then
                            local ok2 = pcall(delfile, fullPath)
                            if ok2 then deleted = true; _configPathCache[name] = nil end
                        end
                    end
                end
            end
        end
    end
    return deleted
end
local function listDiskConfigs()
    ensureFolder()
    local out, seen = {}, {}
    if type(listfiles) ~= "function" then return out end
    local function addFromDir(dir, prefix)
        local ok, files = pcall(listfiles, dir)
        if ok and type(files) == "table" then
            for _, p in ipairs(files) do
                local basename = tostring(p):match("([^/\\]+)$") or tostring(p)
                local n
                if prefix then
                    n = basename:match("^" .. ROOT_PREFIX .. "(.-)%.json$")
                else
                    n = basename:match("^(.-)%.json$")
                end
                if n and n ~= "" and not seen[n] then
                    seen[n] = true; out[#out+1] = n
                end
            end
        end
    end
    addFromDir(CONFIG_FOLDER, false)
    addFromDir(CONFIG_FOLDER .. "/", false)
    addFromDir(CONFIG_FOLDER .. "\\", false)
    addFromDir(".", true)
    table.sort(out)
    return out
end

-- ══════════════════════════════════════════════════════════════
-- FONT CATALOG
-- ══════════════════════════════════════════════════════════════
local FontCatalog = {
    ["Code"] = Enum.Font.Code, ["Gotham"] = Enum.Font.Gotham,
    ["GothamBold"] = Enum.Font.GothamBold, ["GothamSemibold"] = Enum.Font.GothamSemibold,
    ["Arial"] = Enum.Font.Arial, ["ArialBold"] = Enum.Font.ArialBold,
    ["SourceSans"] = Enum.Font.SourceSans, ["SourceSansBold"] = Enum.Font.SourceSansBold,
    ["SourceSansSemibold"] = Enum.Font.SourceSansSemibold,
    ["Roboto"] = Enum.Font.Roboto, ["RobotoMono"] = Enum.Font.RobotoMono,
    ["Ubuntu"] = Enum.Font.Ubuntu, ["Fantasy"] = Enum.Font.Fantasy,
    ["Antique"] = Enum.Font.Antique, ["Arcade"] = Enum.Font.Arcade,
    ["SciFi"] = Enum.Font.SciFi, ["Bangers"] = Enum.Font.Bangers,
    ["PatrickHand"] = Enum.Font.PatrickHand,
}

-- ══════════════════════════════════════════════════════════════
-- THEME
-- ══════════════════════════════════════════════════════════════
local Theme = {
    Background   = Color3.fromRGB(245, 246, 249), BackgroundAlt= Color3.fromRGB(250, 251, 253),
    Sidebar      = Color3.fromRGB(240, 242, 246), Panel        = Color3.fromRGB(255, 255, 255),
    Section      = Color3.fromRGB(250, 251, 253), Element      = Color3.fromRGB(255, 255, 255),
    ElementHover = Color3.fromRGB(238, 241, 246), Accent       = Color3.fromRGB(77, 107, 254),
    AccentHover  = Color3.fromRGB(102, 128, 255), Accent2      = Color3.fromRGB(220, 90, 130),
    Cyan         = Color3.fromRGB(80, 180, 220),  Green        = Color3.fromRGB(60, 200, 130),
    Text         = Color3.fromRGB(26, 29, 35),    SubText      = Color3.fromRGB(107, 114, 128),
    Muted        = Color3.fromRGB(156, 163, 175), Outline      = Color3.fromRGB(226, 229, 235),
    OutlineLight = Color3.fromRGB(203, 208, 218), Danger       = Color3.fromRGB(220, 60, 90),
    Success      = Color3.fromRGB(60, 200, 130),  Warning      = Color3.fromRGB(240, 180, 60),
    OnAccent     = Color3.fromRGB(255, 255, 255),
}

local ThemePresets = {
    ["airhubUI Light"] = {
        Background = Color3.fromRGB(245, 246, 249), Sidebar = Color3.fromRGB(240, 242, 246),
        Panel = Color3.fromRGB(255, 255, 255), Section = Color3.fromRGB(250, 251, 253),
        Element = Color3.fromRGB(255, 255, 255), ElementHover = Color3.fromRGB(238, 241, 246),
        Accent = Color3.fromRGB(77, 107, 254), Accent2 = Color3.fromRGB(220, 90, 130),
        Text = Color3.fromRGB(26, 29, 35), SubText = Color3.fromRGB(107, 114, 128),
        Muted = Color3.fromRGB(156, 163, 175), Outline = Color3.fromRGB(226, 229, 235),
        OnAccent = Color3.fromRGB(255, 255, 255), Font = "Code", FontSize = 1.0,
    },
    ["airhubUI Dark"] = {
        Background = Color3.fromRGB(14, 15, 19), Sidebar = Color3.fromRGB(18, 19, 24),
        Panel = Color3.fromRGB(22, 23, 29), Section = Color3.fromRGB(25, 26, 33),
        Element = Color3.fromRGB(30, 32, 40), ElementHover = Color3.fromRGB(38, 40, 50),
        Accent = Color3.fromRGB(120, 150, 255), Accent2 = Color3.fromRGB(240, 120, 160),
        Text = Color3.fromRGB(235, 238, 245), SubText = Color3.fromRGB(160, 168, 184),
        Muted = Color3.fromRGB(110, 118, 134), Outline = Color3.fromRGB(48, 50, 60),
        OnAccent = Color3.fromRGB(14, 15, 19), Font = "Code", FontSize = 1.0,
    },
    ["Smoke"] = {
        Background = Color3.fromRGB(232, 234, 238), Sidebar = Color3.fromRGB(222, 225, 230),
        Panel = Color3.fromRGB(245, 247, 250), Section = Color3.fromRGB(238, 240, 244),
        Element = Color3.fromRGB(250, 251, 253), ElementHover = Color3.fromRGB(228, 231, 236),
        Accent = Color3.fromRGB(90, 100, 120), Accent2 = Color3.fromRGB(160, 130, 180),
        Text = Color3.fromRGB(35, 38, 44), SubText = Color3.fromRGB(110, 116, 128),
        Muted = Color3.fromRGB(160, 165, 175), Outline = Color3.fromRGB(200, 205, 215),
        OnAccent = Color3.fromRGB(245, 247, 250), Font = "Gotham", FontSize = 1.0,
    },
    ["Mint"] = {
        Background = Color3.fromRGB(240, 250, 246), Sidebar = Color3.fromRGB(228, 244, 238),
        Panel = Color3.fromRGB(252, 255, 254), Section = Color3.fromRGB(244, 252, 249),
        Element = Color3.fromRGB(252, 255, 253), ElementHover = Color3.fromRGB(226, 244, 236),
        Accent = Color3.fromRGB(60, 200, 130), Accent2 = Color3.fromRGB(80, 180, 220),
        Text = Color3.fromRGB(20, 40, 32), SubText = Color3.fromRGB(90, 120, 108),
        Muted = Color3.fromRGB(150, 175, 165), Outline = Color3.fromRGB(200, 224, 214),
        OnAccent = Color3.fromRGB(255, 255, 255), Font = "GothamSemibold", FontSize = 1.0,
    },
    ["Rose"] = {
        Background = Color3.fromRGB(252, 244, 246), Sidebar = Color3.fromRGB(248, 232, 236),
        Panel = Color3.fromRGB(255, 252, 253), Section = Color3.fromRGB(252, 246, 248),
        Element = Color3.fromRGB(255, 253, 254), ElementHover = Color3.fromRGB(246, 230, 235),
        Accent = Color3.fromRGB(220, 90, 130), Accent2 = Color3.fromRGB(240, 120, 100),
        Text = Color3.fromRGB(45, 22, 30), SubText = Color3.fromRGB(130, 90, 105),
        Muted = Color3.fromRGB(190, 150, 165), Outline = Color3.fromRGB(232, 208, 216),
        OnAccent = Color3.fromRGB(255, 255, 255), Font = "GothamSemibold", FontSize = 1.0,
    },
    ["Violet"] = {
        Background = Color3.fromRGB(246, 244, 252), Sidebar = Color3.fromRGB(238, 232, 250),
        Panel = Color3.fromRGB(253, 252, 255), Section = Color3.fromRGB(247, 244, 253),
        Element = Color3.fromRGB(253, 252, 255), ElementHover = Color3.fromRGB(238, 232, 250),
        Accent = Color3.fromRGB(140, 100, 220), Accent2 = Color3.fromRGB(220, 90, 160),
        Text = Color3.fromRGB(32, 22, 45), SubText = Color3.fromRGB(110, 90, 140),
        Muted = Color3.fromRGB(175, 155, 200), Outline = Color3.fromRGB(220, 210, 235),
        OnAccent = Color3.fromRGB(255, 255, 255), Font = "Gotham", FontSize = 1.0,
    },
    ["Sky"] = {
        Background = Color3.fromRGB(240, 246, 252), Sidebar = Color3.fromRGB(228, 238, 248),
        Panel = Color3.fromRGB(252, 254, 255), Section = Color3.fromRGB(242, 248, 253),
        Element = Color3.fromRGB(252, 254, 255), ElementHover = Color3.fromRGB(226, 238, 248),
        Accent = Color3.fromRGB(80, 180, 220), Accent2 = Color3.fromRGB(77, 107, 254),
        Text = Color3.fromRGB(20, 35, 50), SubText = Color3.fromRGB(85, 115, 140),
        Muted = Color3.fromRGB(150, 175, 195), Outline = Color3.fromRGB(200, 218, 232),
        OnAccent = Color3.fromRGB(255, 255, 255), Font = "Gotham", FontSize = 1.0,
    },
    ["Amber"] = {
        Background = Color3.fromRGB(253, 248, 240), Sidebar = Color3.fromRGB(250, 240, 224),
        Panel = Color3.fromRGB(255, 253, 250), Section = Color3.fromRGB(253, 249, 242),
        Element = Color3.fromRGB(255, 254, 251), ElementHover = Color3.fromRGB(248, 238, 222),
        Accent = Color3.fromRGB(240, 180, 60), Accent2 = Color3.fromRGB(240, 120, 100),
        Text = Color3.fromRGB(45, 35, 20), SubText = Color3.fromRGB(130, 110, 80),
        Muted = Color3.fromRGB(185, 165, 135), Outline = Color3.fromRGB(232, 220, 200),
        OnAccent = Color3.fromRGB(45, 35, 20), Font = "GothamSemibold", FontSize = 1.0,
    },
    ["Cyber"] = {
        Background = Color3.fromRGB(10, 12, 18), Sidebar = Color3.fromRGB(14, 16, 24),
        Panel = Color3.fromRGB(18, 20, 30), Section = Color3.fromRGB(20, 22, 32),
        Element = Color3.fromRGB(24, 27, 38), ElementHover = Color3.fromRGB(32, 36, 50),
        Accent = Color3.fromRGB(0, 220, 255), Accent2 = Color3.fromRGB(255, 0, 170),
        Text = Color3.fromRGB(220, 240, 255), SubText = Color3.fromRGB(140, 160, 190),
        Muted = Color3.fromRGB(90, 105, 135), Outline = Color3.fromRGB(38, 44, 60),
        OnAccent = Color3.fromRGB(10, 12, 18), Font = "SciFi", FontSize = 1.0,
    },
    ["Matrix"] = {
        Background = Color3.fromRGB(8, 14, 10), Sidebar = Color3.fromRGB(10, 18, 12),
        Panel = Color3.fromRGB(12, 22, 15), Section = Color3.fromRGB(14, 24, 17),
        Element = Color3.fromRGB(18, 30, 22), ElementHover = Color3.fromRGB(24, 40, 30),
        Accent = Color3.fromRGB(60, 255, 90), Accent2 = Color3.fromRGB(0, 220, 150),
        Text = Color3.fromRGB(200, 255, 210), SubText = Color3.fromRGB(120, 180, 130),
        Muted = Color3.fromRGB(80, 130, 90), Outline = Color3.fromRGB(30, 50, 35),
        OnAccent = Color3.fromRGB(8, 14, 10), Font = "Code", FontSize = 1.0,
    },
    ["Nord"] = {
        Background = Color3.fromRGB(46, 52, 64), Sidebar = Color3.fromRGB(59, 66, 82),
        Panel = Color3.fromRGB(67, 76, 94), Section = Color3.fromRGB(59, 66, 82),
        Element = Color3.fromRGB(76, 86, 106), ElementHover = Color3.fromRGB(86, 97, 118),
        Accent = Color3.fromRGB(136, 192, 208), Accent2 = Color3.fromRGB(180, 142, 173),
        Text = Color3.fromRGB(236, 239, 244), SubText = Color3.fromRGB(216, 222, 233),
        Muted = Color3.fromRGB(180, 190, 205), Outline = Color3.fromRGB(76, 86, 106),
        OnAccent = Color3.fromRGB(46, 52, 64), Font = "SourceSansSemibold", FontSize = 1.0,
    },
    ["Dracula"] = {
        Background = Color3.fromRGB(40, 42, 54), Sidebar = Color3.fromRGB(48, 50, 63),
        Panel = Color3.fromRGB(56, 58, 74), Section = Color3.fromRGB(50, 52, 66),
        Element = Color3.fromRGB(68, 71, 90), ElementHover = Color3.fromRGB(80, 83, 105),
        Accent = Color3.fromRGB(189, 147, 249), Accent2 = Color3.fromRGB(255, 121, 198),
        Text = Color3.fromRGB(248, 248, 242), SubText = Color3.fromRGB(210, 210, 220),
        Muted = Color3.fromRGB(160, 162, 180), Outline = Color3.fromRGB(68, 71, 90),
        OnAccent = Color3.fromRGB(40, 42, 54), Font = "GothamSemibold", FontSize = 1.0,
    },
}

-- ══════════════════════════════════════════════════════════════
-- THEME REGISTRY
-- ══════════════════════════════════════════════════════════════
local ThemedBg, ThemedText, ThemedStroke = {}, {}, {}
local TransparencyRegistry, VisibilityWatchers, SectionStates = {}, {}, {}
local RowNameLabels = setmetatable({}, {__mode = "k"})
local bindListening = false
local openPickerMenu = nil

local function themeBg(i, k) i.BackgroundColor3 = Theme[k]; ThemedBg[#ThemedBg+1] = {inst=i,key=k}; return i end
local function themeText(i, k) i.TextColor3 = Theme[k]; ThemedText[#ThemedText+1] = {inst=i,key=k}; return i end
local function themeStroke(i, k)
    if i:IsA("UIStroke") then i.Color = Theme[k] end
    ThemedStroke[#ThemedStroke+1] = {inst=i,key=k}; return i
end
local function regTransparency(i, cat, base)
    TransparencyRegistry[#TransparencyRegistry+1] = {inst=i, category=cat or "Element", base=base or 0}
    return i
end
local function applyTransparencyTo(cat)
    local t = Config[cat .. "Transparency"] or 0
    for _, r in ipairs(TransparencyRegistry) do
        if r.inst and r.inst.Parent and r.category == cat then
            r.inst.BackgroundTransparency = math.clamp(r.base + t * (1 - r.base), 0, 1)
        end
    end
end
local function refreshTheme()
    for _, e in ipairs(ThemedBg) do
        if e.inst and e.inst.Parent then pcall(function() e.inst.BackgroundColor3 = Theme[e.key] end) end
    end
    for _, e in ipairs(ThemedText) do
        if e.inst and e.inst.Parent then pcall(function() e.inst.TextColor3 = Theme[e.key] end) end
    end
    for _, e in ipairs(ThemedStroke) do
        if e.inst and e.inst.Parent then pcall(function() e.inst.Color = Theme[e.key] end) end
    end
end

local AllConnections = {}
local function _T(c) table.insert(AllConnections, c); return c end

local BindRegistry, BindOrder = {}, {}
local RainbowControllers = {}
local PopupStack = {}
local rainbowFrameCounter = 0

local function getSafeParent()
    if gethui then
        local ok, hui = pcall(gethui)
        if ok and hui then return hui end
    end
    if protect_gui and type(protect_gui) == "function" then
        local ok = pcall(protect_gui, nil)
        if ok then return CoreGui end
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end
local function new(c, p, parent)
    local i = Instance.new(c)
    for k, v in pairs(p or {}) do i[k] = v end
    if parent then i.Parent = parent end
    return i
end
local function tween(inst, props, dur, style, dir)
    local t = TweenService:Create(inst, TweenInfo.new(dur or Config.AnimSpeed,
        style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
    t:Play(); return t
end
local function addCorner(i, r)
    r = r or Config.CornerRadius
    if typeof(r) == "UDim2" then r = UDim.new(r.X.Scale, r.X.Offset) end
    if typeof(r) ~= "UDim" then r = UDim.new(0, 8) end
    local c = new("UICorner", {CornerRadius = r}, i)
    c:SetAttribute("_baseRadius", r.Offset)
    c:SetAttribute("_baseScale", r.Scale)
    return c
end
local function addStroke(i, c, t, tr)
    return new("UIStroke", {Color = c or Theme.Outline, Thickness = t or 1,
        Transparency = tr or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, i)
end
local function addPadding(i, px, py)
    py = py or px
    return new("UIPadding", {PaddingTop = UDim.new(0,py), PaddingBottom = UDim.new(0,py),
        PaddingLeft = UDim.new(0,px), PaddingRight = UDim.new(0,px)}, i)
end
local function keyName(k)
    if not k then return "None" end
    if type(k) == "string" then
        if k == "WheelUp" then return "WU" end
        if k == "WheelDown" then return "WD" end
        return k
    end
    local ok, name = pcall(function() return k.Name end)
    if not ok or type(name) ~= "string" then return tostring(k) end
    local ok2, enumType = pcall(function() return k.EnumType end)
    if ok2 and enumType then
        local ok3, typeName = pcall(function() return enumType.Name end)
        if ok3 and typeName == "UserInputType" then
            if k == Enum.UserInputType.MouseButton1 then return "MB1" end
            if k == Enum.UserInputType.MouseButton2 then return "MB2" end
            if k == Enum.UserInputType.MouseButton3 then return "MB3" end
            if k == Enum.UserInputType.MouseWheel then return "Wheel" end
        end
    end
    return name
end
local function readInputKey(inp)
    if inp.UserInputType == Enum.UserInputType.MouseWheel then
        return inp.Position.Z > 0 and "WheelUp" or "WheelDown"
    end
    if inp.KeyCode and inp.KeyCode ~= Enum.KeyCode.Unknown then return inp.KeyCode end
    return inp.UserInputType
end
local function isListenableInput(inp)
    local ut = inp.UserInputType
    if ut == Enum.UserInputType.Keyboard then return true end
    if ut == Enum.UserInputType.MouseButton1
       or ut == Enum.UserInputType.MouseButton2
       or ut == Enum.UserInputType.MouseButton3 then return true end
    if ut == Enum.UserInputType.MouseWheel then return true end
    return false
end
local function addBrackets(parent, size, thick, color)
    size = size or 12; thick = thick or 2; color = color or Theme.Accent
    local function bracket(xS, xO, yS, yO, w, h, ax, ay)
        new("Frame", {BackgroundColor3 = color, BackgroundTransparency = 0.15, BorderSizePixel = 0,
            AnchorPoint = Vector2.new(ax, ay), Position = UDim2.new(xS, xO, yS, yO),
            Size = UDim2.new(0, w, 0, h), ZIndex = (parent.ZIndex or 1) + 1}, parent)
    end
    bracket(0,0,0,0,size,thick,0,0); bracket(0,0,0,0,thick,size,0,0)
    bracket(1,0,0,0,size,thick,1,0); bracket(1,0,0,0,thick,size,1,0)
    bracket(0,0,1,0,size,thick,0,1); bracket(0,0,1,0,thick,size,0,1)
    bracket(1,0,1,0,size,thick,1,1); bracket(1,0,1,0,thick,size,1,1)
end

local MODE_COLORS = {
    Toggle = Color3.fromRGB(60, 200, 130),
    Hold = Color3.fromRGB(240, 180, 60),
    OnHoldDisable = Color3.fromRGB(220, 60, 90),
}
local MODE_SHORT = { Toggle = "TGL", Hold = "HLD", OnHoldDisable = "OHD" }

-- ══════════════════════════════════════════════════════════════
-- SEARCH HIGHLIGHT
-- ══════════════════════════════════════════════════════════════
local HIGHLIGHT_COLOR = "rgb(77, 107, 254)"
local function highlightLabel(lbl, query)
    if not lbl or not lbl.Parent then return end
    local orig = lbl:GetAttribute("_hlOrig")
    if orig == nil then orig = lbl.Text; lbl:SetAttribute("_hlOrig", orig) end
    if not query or query == "" then lbl.RichText = false; lbl.Text = orig; return end
    local lower = string.lower(orig); local qlen = #query
    if qlen == 0 or not string.find(lower, query, 1, true) then
        lbl.RichText = false; lbl.Text = orig; return
    end
    local parts = {}; local i = 1
    while i <= #orig do
        local s = string.find(lower, query, i, true)
        if not s then table.insert(parts, orig:sub(i)); break end
        local e = s + qlen - 1
        if s > i then table.insert(parts, orig:sub(i, s - 1)) end
        table.insert(parts, '<font color="' .. HIGHLIGHT_COLOR .. '"><b>' .. orig:sub(s, e) .. '</b></font>')
        i = e + 1
    end
    lbl.RichText = true; lbl.Text = table.concat(parts)
end
local function markSearch(row, name, nameLabel)
    row:SetAttribute("SearchName", string.lower(name or ""))
    if nameLabel then RowNameLabels[row] = nameLabel end
end

-- ══════════════════════════════════════════════════════════════
-- BIND SYSTEM
-- ══════════════════════════════════════════════════════════════
local function matchesKey(stored, input)
    if not stored then return false end
    if stored == "WheelUp" or stored == "WheelDown" then
        return input.UserInputType == Enum.UserInputType.MouseWheel and stored == readInputKey(input)
    end
    return stored == input.KeyCode or stored == input.UserInputType
end
local function findActiveKey(bind)
    for _, e in ipairs(bind.keys) do if e.mode == "Hold" and e.held then return e, true end end
    for _, e in ipairs(bind.keys) do if e.mode == "Toggle" and e.toggled then return e, true end end
    for _, e in ipairs(bind.keys) do if e.mode == "OnHoldDisable" and e.held then return e, false end end
    return nil, false
end
local function isBindActive(bind)
    if not bind then return false end
    for _, e in ipairs(bind.keys) do
        if (e.mode == "Toggle" and e.toggled) then return true end
        if (e.mode == "Hold" or e.mode == "OnHoldDisable") and e.held then return true end
    end
    return false
end
local function fireBind(bind, skipCallback)
    if not bind then return end
    local entry, active = findActiveKey(bind)
    local val, src, md
    if active and entry then val, src, md = entry.value, entry.key, entry.mode end
    if not skipCallback and bind.callback then
        pcall(bind.callback, val, src and keyName(src) or nil, md, bind)
    end
end
local function RegisterBind(id, name, callback, btype, default)
    if BindRegistry[id] then
        BindRegistry[id].callback = callback
        BindRegistry[id].name = name
        if default ~= nil then BindRegistry[id].default = default end
        return BindRegistry[id]
    end
    local b = {id = id, name = name, callback = callback, type = btype or "Toggle", default = default, keys = {}}
    BindRegistry[id] = b
    table.insert(BindOrder, id)
    return b
end
local function AddBindKey(bindId, key, mode, value, silent)
    local b = BindRegistry[bindId]; if not b then return end
    local e = {key = key, mode = mode or "Toggle", value = value, held = false, toggled = false}
    table.insert(b.keys, e)
    if silent == false then fireBind(b) end
    return e
end
local function RemoveBindKey(bindId, idx, silent)
    local b = BindRegistry[bindId]; if not b then return end
    table.remove(b.keys, idx)
    if silent == false then fireBind(b) end
end
local function ClearBind(id, silent)
    local b = BindRegistry[id]; if not b then return end
    b.keys = {}
    if silent == false then fireBind(b) end
end

_T(UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    for _, id in ipairs(BindOrder) do
        local b = BindRegistry[id]
        if b then
            for _, e in ipairs(b.keys) do
                if matchesKey(e.key, input) then
                    if e.mode == "Toggle" then
                        e.toggled = not e.toggled; fireBind(b)
                    elseif e.mode == "Hold" or e.mode == "OnHoldDisable" then
                        e.held = true; fireBind(b)
                    end
                end
            end
        end
    end
end))
_T(UserInputService.InputEnded:Connect(function(input)
    for _, id in ipairs(BindOrder) do
        local b = BindRegistry[id]
        if b then
            for _, e in ipairs(b.keys) do
                if matchesKey(e.key, input) then
                    if e.mode == "Hold" or e.mode == "OnHoldDisable" then
                        e.held = false; fireBind(b)
                    end
                end
            end
        end
    end
end))

-- ══════════════════════════════════════════════════════════════
-- RAINBOW
-- ══════════════════════════════════════════════════════════════
local rainbowTime = 0
_T(RunService.RenderStepped:Connect(function(dt)
    if #RainbowControllers == 0 then return end
    rainbowFrameCounter = rainbowFrameCounter + 1
    rainbowTime = (rainbowTime + dt * 0.20) % 1
    for i = #RainbowControllers, 1, -1 do
        local c = RainbowControllers[i]
        if not c then table.remove(RainbowControllers, i)
        elseif not c.root or not c.root.Parent then
            if not c.keepAlive then table.remove(RainbowControllers, i) end
        elseif c.active and type(c.setFromRainbow) == "function" then
            pcall(c.setFromRainbow, (rainbowTime * (c.speed or 1)) % 1, rainbowFrameCounter)
        end
    end
end))

-- ══════════════════════════════════════════════════════════════
-- NOTIFICATIONS
-- ══════════════════════════════════════════════════════════════
local NotificationHolder
local function ensureNotifHolder(parent)
    if NotificationHolder and NotificationHolder.Parent then return NotificationHolder end
    local pos = Config.NotificationPosition or "top-right"
    local posUDim, anchor, align
    if pos == "top-right" then
        posUDim = UDim2.new(1,-16,0,16); anchor = Vector2.new(1,0); align = Enum.HorizontalAlignment.Right
    elseif pos == "top-left" then
        posUDim = UDim2.new(0,16,0,16); anchor = Vector2.new(0,0); align = Enum.HorizontalAlignment.Left
    elseif pos == "bottom-right" then
        posUDim = UDim2.new(1,-16,1,-16); anchor = Vector2.new(1,1); align = Enum.HorizontalAlignment.Right
    else
        posUDim = UDim2.new(0,16,1,-16); anchor = Vector2.new(0,1); align = Enum.HorizontalAlignment.Left
    end
    NotificationHolder = new("Frame", {Name = "airhubUINotifications", BackgroundTransparency = 1,
        Position = posUDim, Size = UDim2.new(0,320,1,-32),
        AnchorPoint = anchor, ZIndex = Config.NotifyZ}, parent)
    new("UIListLayout", {Padding = UDim.new(0,8), SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = align}, NotificationHolder)
    return NotificationHolder
end
local function resetNotifHolder()
    if NotificationHolder then NotificationHolder:Destroy(); NotificationHolder = nil end
end
local function Notify(title, text, kind, duration)
    local holder = ensureNotifHolder(NotificationHolder and NotificationHolder.Parent or getSafeParent())
    duration = duration or Config.NotificationDuration or 3
    local accent, icon = Theme.Accent, "i"
    if kind == "success" then accent, icon = Theme.Success, "+"
    elseif kind == "error" then accent, icon = Theme.Danger, "x"
    elseif kind == "warning" then accent, icon = Theme.Warning, "!" end
    local pos = Config.NotificationPosition or "top-right"
    local isRight = pos == "top-right" or pos == "bottom-right"
    local startX = isRight and 24 or -24
    local n = new("Frame", {Name = "Notification", BorderSizePixel = 0,
        Size = UDim2.new(1,0,0,62),
        Position = isRight and UDim2.new(1,startX,0,0) or UDim2.new(0,-startX,0,0),
        ZIndex = Config.NotifyZ + 1}, holder)
    themeBg(n, "Panel"); addCorner(n, UDim.new(0,10)); addStroke(n, Theme.Outline, 1, 0.15)
    new("Frame", {BackgroundColor3 = accent, BorderSizePixel = 0,
        Size = UDim2.new(0,3,1,-16), Position = UDim2.new(0,8,0,8), ZIndex = Config.NotifyZ + 2}, n)
    local iconBg = new("Frame", {BackgroundColor3 = accent, BackgroundTransparency = 0.86, BorderSizePixel = 0,
        Position = UDim2.new(0,18,0,10), Size = UDim2.new(0,22,0,22), ZIndex = Config.NotifyZ + 2}, n)
    addCorner(iconBg, UDim.new(0,6))
    new("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0), Font = Config.CurrentFontFamily,
        Text = icon, TextColor3 = accent, TextSize = 13, ZIndex = Config.NotifyZ + 3}, iconBg)
    local tl = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0,48,0,8),
        Size = UDim2.new(1,-58,0,14), Font = Config.CurrentFontFamily, Text = tostring(title or "Notice"),
        TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = Config.NotifyZ + 2}, n)
    themeText(tl, "Text")
    local dl = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0,48,0,26),
        Size = UDim2.new(1,-58,0,26), Font = Config.CurrentFontFamily, Text = text or "", TextSize = 11,
        TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = Config.NotifyZ + 2}, n)
    themeText(dl, "SubText")
    local progBg = new("Frame", {BorderSizePixel = 0,
        Position = UDim2.new(0,8,1,-6), Size = UDim2.new(1,-16,0,3), ZIndex = Config.NotifyZ + 2}, n)
    themeBg(progBg, "ElementHover"); addCorner(progBg, UDim.new(1,0))
    local progFill = new("Frame", {BackgroundColor3 = accent, BorderSizePixel = 0,
        Size = UDim2.new(1,0,1,0), ZIndex = Config.NotifyZ + 3}, progBg)
    addCorner(progFill, UDim.new(1,0))
    tween(progFill, {Size = UDim2.new(0,0,1,0)}, duration, Enum.EasingStyle.Linear)
    tween(n, {Position = UDim2.new(0,0,0,0)})
    task.delay(duration, function()
        if n and n.Parent then
            tween(n, {Position = isRight and UDim2.new(1,startX,0,0) or UDim2.new(0,-startX,0,0)})
            task.wait(Config.AnimSpeed)
            if n then n:Destroy() end
        end
    end)
end

-- ══════════════════════════════════════════════════════════════
-- OVERLAY + POPUPS
-- ══════════════════════════════════════════════════════════════
local Overlay
local function ensureOverlay(gui)
    if Overlay and Overlay.Parent == gui then return Overlay end
    if Overlay and Overlay.Parent then Overlay:Destroy() end
    Overlay = new("Frame", {Name = "airhubUIOverlay", BackgroundTransparency = 1,
        Size = UDim2.new(1,0,1,0), ZIndex = Config.OverlayZ, Active = false}, gui)
    PopupStack = {}
    return Overlay
end
local function pushPopup(frame, posFn, closeFn, popupOpts)
    popupOpts = popupOpts or {}
    if not Overlay or not Overlay.Parent then return end
    if not frame then return end
    if frame.Parent ~= Overlay then
        local ok = pcall(function() frame.Parent = Overlay end)
        if not ok then return end
    end
    frame.Visible = true
    local us = frame:FindFirstChildOfClass("UIScale")
    if not us then us = Instance.new("UIScale"); us.Parent = frame end
    us.Scale = 0.92
    tween(us, {Scale = 1}, Config.PopupAnim, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    table.insert(PopupStack, {frame = frame, positionFn = posFn, closeFn = closeFn,
        us = us, keepAlive = popupOpts.keepAlive})
    if posFn then pcall(posFn) end
end
local function closeTopPopup()
    local top = table.remove(PopupStack)
    if not top or not top.frame then return end
    local f = top.frame
    if top.closeFn then pcall(top.closeFn) end
    if top.keepAlive then
        if top.us and top.us.Parent then tween(top.us, {Scale = 0.92}, Config.PopupAnim * 0.6) end
        task.delay(Config.PopupAnim * 0.6 + 0.02, function()
            if f and f.Parent then
                f.Visible = false
                if top.us and top.us.Parent then top.us.Scale = 1 end
            end
        end)
        return
    end
    if top.us and top.us.Parent then
        local tw = tween(top.us, {Scale = 0.92}, Config.PopupAnim * 0.6)
        tw.Completed:Connect(function() if f and f.Parent then f:Destroy() end end)
    else
        if f and f.Parent then f:Destroy() end
    end
end
local function closeAllPopups() while #PopupStack > 0 do closeTopPopup() end end

_T(RunService.RenderStepped:Connect(function()
    for i = #PopupStack, 1, -1 do
        local p = PopupStack[i]
        if p.frame and p.frame.Parent and p.frame.Visible and p.positionFn then
            pcall(p.positionFn)
        end
    end
end))
_T(UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Escape then closeTopPopup(); return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1
       and input.UserInputType ~= Enum.UserInputType.Touch then return end
    if #PopupStack == 0 then return end
    local mp = UserInputService:GetMouseLocation()
    for i = #PopupStack, 1, -1 do
        local p = PopupStack[i].frame
        if p and p.Parent and p.Visible then
            local ap, as = p.AbsolutePosition, p.AbsoluteSize
            if mp.X >= ap.X and mp.X <= ap.X + as.X and mp.Y >= ap.Y and mp.Y <= ap.Y + as.Y then return end
        end
    end
    closeTopPopup()
end))

-- ══════════════════════════════════════════════════════════════
-- TOOLTIP
-- ══════════════════════════════════════════════════════════════
local Tooltip
local function ensureTooltip()
    if Tooltip and Tooltip.Parent then return Tooltip end
    if not Overlay or not Overlay.Parent then return nil end
    Tooltip = new("Frame", {Name = "airhubUITooltip", BorderSizePixel = 0,
        Size = UDim2.new(0,0,0,24), AutomaticSize = Enum.AutomaticSize.X,
        Position = UDim2.new(0,0,0,0), Visible = false, ZIndex = Config.TooltipZ}, Overlay)
    themeBg(Tooltip, "Panel"); addCorner(Tooltip, UDim.new(0,6))
    addStroke(Tooltip, Theme.Outline, 1, 0.15)
    addPadding(Tooltip, 10, 4)
    local txt = new("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(0,0,1,0),
        AutomaticSize = Enum.AutomaticSize.X, Font = Config.CurrentFontFamily,
        Text = "", TextSize = 11, Name = "Text", TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = Config.TooltipZ + 1}, Tooltip)
    themeText(txt, "Text")
    return Tooltip
end
local function showTooltip(anchor, text)
    local t = ensureTooltip(); if not t then return end
    t:FindFirstChild("Text").Text = T(text); t.Visible = true
    local ap, as = anchor.AbsolutePosition, anchor.AbsoluteSize
    local vp = workspace.CurrentCamera.ViewportSize
    local tw = t.AbsoluteSize.X
    local tx = math.clamp(ap.X, 4, vp.X - tw - 4)
    local ty = ap.Y - 30; if ty < 4 then ty = ap.Y + as.Y + 6 end
    t.Position = UDim2.fromOffset(tx, ty)
end
local function hideTooltip() if Tooltip then Tooltip.Visible = false end end
local function attachTooltip(frame, text)
    if not text then return end
    local hideToken = 0
    local function enter()
        hideToken = hideToken + 1
        local token = hideToken
        task.delay(Config.TooltipDelay or 0.05, function()
            if hideToken == token then pcall(showTooltip, frame, text) end
        end)
    end
    local function leave()
        local token = hideToken + 1; hideToken = token
        task.delay(0.05, function() if hideToken == token then hideTooltip() end end)
    end
    local targets = {frame}
    for _, d in ipairs(frame:GetDescendants()) do
        if d:IsA("GuiObject") then targets[#targets+1] = d end
    end
    for _, t in ipairs(targets) do t.MouseEnter:Connect(enter); t.MouseLeave:Connect(leave) end
end

local function getSectionState(section)
    if not SectionStates[section] then SectionStates[section] = {} end
    return SectionStates[section]
end
local function reevaluateVisibility()
    for i = #VisibilityWatchers, 1, -1 do
        local w = VisibilityWatchers[i]
        if not w.element or not w.element.Parent then table.remove(VisibilityWatchers, i)
        else
            local ok, visible = pcall(w.predicate, w.state)
            w.element.Visible = ok and (visible and true or false) or false
        end
    end
end
local function watchVisibility(element, predicate, state)
    table.insert(VisibilityWatchers, {element = element, predicate = predicate, state = state})
    local ok, visible = pcall(predicate, state)
    element.Visible = ok and (visible and true or false) or false
end

-- ══════════════════════════════════════════════════════════════
-- COLORPICKER UI
-- ══════════════════════════════════════════════════════════════
local function buildColorpickerUI(parent, opts)
    opts = opts or {}
    local color = opts.Color or Color3.fromRGB(77, 107, 254)
    local alpha = opts.Alpha or 0
    local h, s, v = Color3.toHSV(color)
    local rainbowEnabled = opts.Rainbow or false
    local rainbowSpeed = opts.RainbowSpeed or 1
    local onChange = opts.OnChange or function() end
    local W = opts.Width or 260
    local root = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(0,W,0,390)}, parent)
    
    local localConnections = {}
    local function TC(c) table.insert(localConnections, c); _T(c); return c end
    
    local previewBg = new("Frame", {BackgroundColor3 = Color3.fromRGB(230,232,238), BorderSizePixel = 0,
        Position = UDim2.new(0,0,0,0), Size = UDim2.new(1,0,0,32), ClipsDescendants = true}, root)
    addCorner(previewBg, UDim.new(0,6)); addStroke(previewBg, Theme.Outline, 1)
    for i = 0, 4 do
        for j = 0, 1 do
            new("Frame", {BackgroundColor3 = Color3.fromRGB(200,204,210), BorderSizePixel = 0,
                Position = UDim2.new(i/5,0,j/2,0), Size = UDim2.new(1/10,0,1/2,0)}, previewBg)
            new("Frame", {BackgroundColor3 = Color3.fromRGB(200,204,210), BorderSizePixel = 0,
                Position = UDim2.new((i+0.5)/5,0,1/2,0), Size = UDim2.new(1/10,0,1/2,0)}, previewBg)
        end
    end
    local previewColor = new("Frame", {BackgroundColor3 = color, BackgroundTransparency = alpha,
        BorderSizePixel = 0, Size = UDim2.new(1,0,1,0)}, previewBg)
    
    local sv = new("Frame", {BackgroundColor3 = Color3.fromHSV(h,1,1), BorderSizePixel = 0,
        Position = UDim2.new(0,0,0,40), Size = UDim2.new(1,0,0,120), ClipsDescendants = true}, root)
    addCorner(sv, UDim.new(0,6)); addStroke(sv, Theme.Outline, 1)
    new("ImageLabel", {BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0),
        Image = "rbxassetid://4155801252"}, sv)
    local satO = new("Frame", {BackgroundColor3 = Color3.fromRGB(255,255,255),
        BackgroundTransparency = 1-s, BorderSizePixel = 0, Size = UDim2.new(1,0,1,0)}, sv)
    local valO = new("Frame", {BackgroundColor3 = Color3.fromRGB(0,0,0),
        BackgroundTransparency = 1-v, BorderSizePixel = 0, Size = UDim2.new(1,0,1,0)}, sv)
    
    local svKnob = new("Frame", {BackgroundColor3 = Color3.fromRGB(255,255,255), BackgroundTransparency = 0.5,
        AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new(s,0,1-v,0), Size = UDim2.new(0,12,0,12)}, sv)
    addCorner(svKnob, UDim.new(1,0)); addStroke(svKnob, Theme.Outline, 2)
    
    local hueBg = new("Frame", {BackgroundColor3 = Color3.fromRGB(255,255,255), BorderSizePixel = 0,
        Position = UDim2.new(0,0,0,168), Size = UDim2.new(1,0,0,14), ClipsDescendants = true}, root)
    addCorner(hueBg, UDim.new(1,0)); addStroke(hueBg, Theme.Outline, 1)
    new("UIGradient", {Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)),
        ColorSequenceKeypoint.new(1/6, Color3.fromRGB(255,255,0)),
        ColorSequenceKeypoint.new(2/6, Color3.fromRGB(0,255,0)),
        ColorSequenceKeypoint.new(3/6, Color3.fromRGB(0,255,255)),
        ColorSequenceKeypoint.new(4/6, Color3.fromRGB(0,0,255)),
        ColorSequenceKeypoint.new(5/6, Color3.fromRGB(255,0,255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255,0,0))}}, hueBg)
    local hueKnob = new("Frame", {BackgroundColor3 = Color3.fromRGB(255,255,255), BackgroundTransparency = 0.5,
        AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new(h,0,0.5,0), Size = UDim2.new(0,12,0,12)}, hueBg)
    addCorner(hueKnob, UDim.new(1,0)); addStroke(hueKnob, Theme.Outline, 2)
    
    local alphaBg = new("Frame", {BackgroundColor3 = Color3.fromRGB(230,232,238), BorderSizePixel = 0,
        Position = UDim2.new(0,0,0,190), Size = UDim2.new(1,0,0,14), ClipsDescendants = true}, root)
    addCorner(alphaBg, UDim.new(1,0)); addStroke(alphaBg, Theme.Outline, 1)
    for i = 0, 4 do
        for j = 0, 1 do
            new("Frame", {BackgroundColor3 = Color3.fromRGB(200,204,210), BorderSizePixel = 0,
                Position = UDim2.new(i/5,0,j/2,0), Size = UDim2.new(1/10,0,1/2,0)}, alphaBg)
            new("Frame", {BackgroundColor3 = Color3.fromRGB(200,204,210), BorderSizePixel = 0,
                Position = UDim2.new((i+0.5)/5,0,1/2,0), Size = UDim2.new(1/10,0,1/2,0)}, alphaBg)
        end
    end
    local alphaFill = new("Frame", {BackgroundColor3 = color, BorderSizePixel = 0,
        Size = UDim2.new(1,0,1,0)}, alphaBg)
    local alphaGrad = new("UIGradient", {Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, alpha), NumberSequenceKeypoint.new(1, 0)}), Rotation = 0}, alphaFill)
    local alphaKnob = new("Frame", {BackgroundColor3 = Color3.fromRGB(255,255,255), BackgroundTransparency = 0.5,
        AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new(1-alpha,0,0.5,0), Size = UDim2.new(0,12,0,12)}, alphaBg)
    addCorner(alphaKnob, UDim.new(1,0)); addStroke(alphaKnob, Theme.Outline, 2)
    
    local inputHolder = new("Frame", {BackgroundTransparency = 1, Position = UDim2.new(0,0,0,212),
        Size = UDim2.new(1,0,0,50)}, root)
        
    local hexBg = new("Frame", {BorderSizePixel = 0, Position = UDim2.new(0,0,0,0),
        Size = UDim2.new(1,0,0,22)}, inputHolder)
    themeBg(hexBg, "ElementHover"); addCorner(hexBg, UDim.new(0,4))
    local hexLbl = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0,8,0,0),
        Size = UDim2.new(0,25,1,0), Font = Config.CurrentFontFamily, Text = "Hex",
        TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left}, hexBg)
    themeText(hexLbl, "SubText")
    local hexInp = new("TextBox", {BackgroundTransparency = 1, Position = UDim2.new(0,35,0,0),
        Size = UDim2.new(1,-40,1,0), Font = Config.CurrentFontFamily, Text = "", TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false}, hexBg)
    themeText(hexInp, "Text")
    
    local function makeRGBInput(xOff, w, name)
        local bg = new("Frame", {BorderSizePixel = 0, Position = UDim2.new(0,xOff,0,26),
            Size = UDim2.new(0,w,0,22)}, inputHolder)
        themeBg(bg, "ElementHover"); addCorner(bg, UDim.new(0,4))
        local lbl = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0,6,0,0),
            Size = UDim2.new(0,12,1,0), Font = Config.CurrentFontFamily, Text = name,
            TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left}, bg)
        themeText(lbl, "SubText")
        local inp = new("TextBox", {BackgroundTransparency = 1, Position = UDim2.new(0,18,0,0),
            Size = UDim2.new(1,-22,1,0), Font = Config.CurrentFontFamily, Text = "0", TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false}, bg)
        themeText(inp, "Text")
        return inp
    end
    local rInp = makeRGBInput(0, (W-10)/3, "R")
    local gInp = makeRGBInput((W-10)/3 + 5, (W-10)/3, "G")
    local bInp = makeRGBInput((W-10)/3*2 + 10, (W-10)/3, "B")
    
    local rbRow = new("Frame", {BorderSizePixel = 0, Position = UDim2.new(0,0,0,272),
        Size = UDim2.new(1,0,0,28)}, root)
    themeBg(rbRow, "ElementHover"); addCorner(rbRow, UDim.new(0,6))
    local rbLabel = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0,10,0,0),
        Size = UDim2.new(0.7,-10,1,0), Font = Config.CurrentFontFamily, Text = "Rainbow Mode",
        TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left}, rbRow)
    themeText(rbLabel, "Text")
    local rbSw = new("Frame", {BackgroundColor3 = rainbowEnabled and Theme.Accent or Color3.fromRGB(214, 218, 226),
        BorderSizePixel = 0, Position = UDim2.new(1,-38,0.5,-8), Size = UDim2.new(0,30,0,16)}, rbRow)
    addCorner(rbSw, UDim.new(1,0))
    local rbKnob = new("Frame", {BackgroundColor3 = Color3.fromRGB(255,255,255), BorderSizePixel = 0,
        Position = rainbowEnabled and UDim2.new(1,-14,0,2) or UDim2.new(0,2,0,2),
        Size = UDim2.new(0,12,0,12)}, rbSw)
    addCorner(rbKnob, UDim.new(1,0))
    local rbToggle = new("TextButton", {BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0), Text = ""}, rbRow)
    
    local rbSpeedFrame = new("Frame", {BorderSizePixel = 0, Position = UDim2.new(0,0,0,306),
        Size = UDim2.new(1,0,0,34)}, root)
    themeBg(rbSpeedFrame, "ElementHover"); addCorner(rbSpeedFrame, UDim.new(0,6))
    local rbSpeedLbl = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0,10,0,4),
        Size = UDim2.new(0.6,-10,0,14), Font = Config.CurrentFontFamily, Text = "Rainbow Speed",
        TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left}, rbSpeedFrame)
    themeText(rbSpeedLbl, "SubText")
    local rbSpeedVal = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(1,-40,0,4),
        Size = UDim2.new(0,30,0,14), Font = Config.CurrentFontFamily, Text = string.format("%.1f", rainbowSpeed),
        TextSize = 10, TextColor3 = Theme.Accent, TextXAlignment = Enum.TextXAlignment.Right}, rbSpeedFrame)
    local rbSpeedTrack = new("Frame", {BorderSizePixel = 0,
        Position = UDim2.new(0,10,1,-12), Size = UDim2.new(1,-20,0,4)}, rbSpeedFrame)
    themeBg(rbSpeedTrack, "Panel"); addCorner(rbSpeedTrack, UDim.new(1,0))
    local rbSpeedFill = new("Frame", {BorderSizePixel = 0,
        Size = UDim2.new(math.clamp((rainbowSpeed - 0.1) / 4.9, 0, 1),0,1,0)}, rbSpeedTrack)
    themeBg(rbSpeedFill, "Accent"); addCorner(rbSpeedFill, UDim.new(1,0))
    local rbSpeedKnob = new("Frame", {BackgroundColor3 = Color3.fromRGB(255,255,255), BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new(math.clamp((rainbowSpeed - 0.1) / 4.9, 0, 1),0,0.5,0),
        Size = UDim2.new(0,10,0,10)}, rbSpeedTrack)
    addCorner(rbSpeedKnob, UDim.new(1,0)); addStroke(rbSpeedKnob, Theme.Accent, 2)
    
    local closeBtn = new("TextButton", {BorderSizePixel = 0, Position = UDim2.new(0,0,0,350),
        Size = UDim2.new(1,0,0,28), Font = Config.CurrentFontFamily, Text = "Done", TextSize = 11,
        AutoButtonColor = false}, root)
    themeBg(closeBtn, "Accent"); closeBtn.TextColor3 = Theme.OnAccent
    addCorner(closeBtn, UDim.new(0,6))
    
    local function updateSpeedVis(val)
        local rel = math.clamp((val - 0.1) / 4.9, 0, 1)
        rbSpeedFill.Size = UDim2.new(rel,0,1,0)
        rbSpeedKnob.Position = UDim2.new(rel,0,0.5,0)
        rbSpeedVal.Text = string.format("%.1f", val)
    end
    
    local rainbowCtrl = {
        active = rainbowEnabled, speed = rainbowSpeed, root = root,
        keepAlive = true,
        setFromRainbow = function(hv, frame)
            h = hv; s = 1; v = 1
            color = Color3.fromHSV(h, s, v)
            if sv and sv.Parent then sv.BackgroundColor3 = Color3.fromHSV(h,1,1) end
            if satO and satO.Parent then satO.BackgroundTransparency = 0 end
            if valO and valO.Parent then valO.BackgroundTransparency = 0 end
            if svKnob and svKnob.Parent then svKnob.Position = UDim2.new(1,0,0,0) end
            if alphaFill and alphaFill.Parent then alphaFill.BackgroundColor3 = color end
            if previewColor and previewColor.Parent then previewColor.BackgroundColor3 = color end
            if frame and (frame % (Config.RainbowCallbackInterval or 4) == 0) then
                local hexStr = string.format("#%02X%02X%02X",
                    math.floor(color.R*255+0.5), math.floor(color.G*255+0.5), math.floor(color.B*255+0.5))
                if hexInp and hexInp.Parent then hexInp.Text = hexStr end
                if rInp and rInp.Parent then rInp.Text = tostring(math.floor(color.R*255+0.5)) end
                if gInp and gInp.Parent then gInp.Text = tostring(math.floor(color.G*255+0.5)) end
                if bInp and bInp.Parent then bInp.Text = tostring(math.floor(color.B*255+0.5)) end
                pcall(onChange, color, alpha, {rainbowEnabled = true, rainbowSpeed = rainbowSpeed})
            end
        end,
    }
    table.insert(RainbowControllers, rainbowCtrl)
    
    local function hexStr(c) return string.format("#%02X%02X%02X",
        math.floor(c.R*255+0.5), math.floor(c.G*255+0.5), math.floor(c.B*255+0.5)) end
        
    local function applyMain()
        color = Color3.fromHSV(h, s, v)
        if sv and sv.Parent then sv.BackgroundColor3 = Color3.fromHSV(h,1,1) end
        if satO and satO.Parent then satO.BackgroundTransparency = 1-s end
        if valO and valO.Parent then valO.BackgroundTransparency = 1-v end
        if svKnob and svKnob.Parent then svKnob.Position = UDim2.new(s,0,1-v,0) end
        if alphaFill and alphaFill.Parent then alphaFill.BackgroundColor3 = color end
        if previewColor and previewColor.Parent then previewColor.BackgroundColor3 = color end
        if previewColor and previewColor.Parent then previewColor.BackgroundTransparency = alpha end
        if hexInp and hexInp.Parent then hexInp.Text = hexStr(color) end
        if rInp and rInp.Parent then rInp.Text = tostring(math.floor(color.R*255+0.5)) end
        if gInp and gInp.Parent then gInp.Text = tostring(math.floor(color.G*255+0.5)) end
        if bInp and bInp.Parent then bInp.Text = tostring(math.floor(color.B*255+0.5)) end
    end
    applyMain()
    
    local function disableRainbow()
        if rainbowEnabled then
            rainbowEnabled = false; rainbowCtrl.active = false
            tween(rbSw, {BackgroundColor3 = Color3.fromRGB(214, 218, 226)})
            tween(rbKnob, {Position = UDim2.new(0,2,0,2)})
            pcall(onChange, color, alpha, {rainbowEnabled = false, rainbowSpeed = rainbowSpeed})
        end
    end
    
    local svDrag, hueDrag, alphaDrag, speedDrag = false, false, false, false
    
    sv.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            svDrag = true; disableRainbow()
            local rx = math.clamp((i.Position.X - sv.AbsolutePosition.X) / sv.AbsoluteSize.X, 0, 1)
            local ry = math.clamp((i.Position.Y - sv.AbsolutePosition.Y) / sv.AbsoluteSize.Y, 0, 1)
            s, v = rx, 1 - ry; applyMain()
            pcall(onChange, color, alpha, {rainbowEnabled = false, rainbowSpeed = rainbowSpeed})
        end
    end)
    hueBg.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            hueDrag = true; disableRainbow()
            h = math.clamp((i.Position.X - hueBg.AbsolutePosition.X) / hueBg.AbsoluteSize.X, 0, 1)
            applyMain(); pcall(onChange, color, alpha, {rainbowEnabled = false, rainbowSpeed = rainbowSpeed})
        end
    end)
    alphaBg.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            alphaDrag = true
            local rel = math.clamp((i.Position.X - alphaBg.AbsolutePosition.X) / alphaBg.AbsoluteSize.X, 0, 1)
            alpha = 1 - rel
            alphaKnob.Position = UDim2.new(rel, 0, 0.5, 0)
            if alphaGrad then
                alphaGrad.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, alpha), NumberSequenceKeypoint.new(1, 0)})
            end
            if previewColor then previewColor.BackgroundTransparency = alpha end
            pcall(onChange, color, alpha, {rainbowEnabled = rainbowEnabled, rainbowSpeed = rainbowSpeed})
        end
    end)
    rbSpeedTrack.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            speedDrag = true
            local rel = math.clamp((i.Position.X - rbSpeedTrack.AbsolutePosition.X) / rbSpeedTrack.AbsoluteSize.X, 0, 1)
            rainbowSpeed = 0.1 + 4.9 * rel
            updateSpeedVis(rainbowSpeed)
            rainbowCtrl.speed = rainbowSpeed
            pcall(onChange, color, alpha, {rainbowEnabled = rainbowEnabled, rainbowSpeed = rainbowSpeed})
        end
    end)
    
    TC(UserInputService.InputChanged:Connect(function(i)
        if i.UserInputType ~= Enum.UserInputType.MouseMovement and i.UserInputType ~= Enum.UserInputType.Touch then return end
        if svDrag and sv and sv.Parent then
            local rx = math.clamp((i.Position.X - sv.AbsolutePosition.X) / sv.AbsoluteSize.X, 0, 1)
            local ry = math.clamp((i.Position.Y - sv.AbsolutePosition.Y) / sv.AbsoluteSize.Y, 0, 1)
            s, v = rx, 1 - ry; applyMain()
            pcall(onChange, color, alpha, {rainbowEnabled = false, rainbowSpeed = rainbowSpeed})
        end
        if hueDrag and hueBg and hueBg.Parent then
            h = math.clamp((i.Position.X - hueBg.AbsolutePosition.X) / hueBg.AbsoluteSize.X, 0, 1)
            applyMain(); pcall(onChange, color, alpha, {rainbowEnabled = false, rainbowSpeed = rainbowSpeed})
        end
        if alphaDrag and alphaBg and alphaBg.Parent then
            local rel = math.clamp((i.Position.X - alphaBg.AbsolutePosition.X) / alphaBg.AbsoluteSize.X, 0, 1)
            alpha = 1 - rel
            alphaKnob.Position = UDim2.new(rel, 0, 0.5, 0)
            if alphaGrad then
                alphaGrad.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, alpha), NumberSequenceKeypoint.new(1, 0)})
            end
            if previewColor then previewColor.BackgroundTransparency = alpha end
            pcall(onChange, color, alpha, {rainbowEnabled = rainbowEnabled, rainbowSpeed = rainbowSpeed})
        end
        if speedDrag and rbSpeedTrack and rbSpeedTrack.Parent then
            local rel = math.clamp((i.Position.X - rbSpeedTrack.AbsolutePosition.X) / rbSpeedTrack.AbsoluteSize.X, 0, 1)
            rainbowSpeed = 0.1 + 4.9 * rel
            updateSpeedVis(rainbowSpeed)
            rainbowCtrl.speed = rainbowSpeed
            pcall(onChange, color, alpha, {rainbowEnabled = rainbowEnabled, rainbowSpeed = rainbowSpeed})
        end
    end))
    TC(UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            svDrag, hueDrag, alphaDrag, speedDrag = false, false, false, false
        end
    end))
    
    hexInp.FocusLost:Connect(function()
        local txt = hexInp.Text:gsub("#","")
        if #txt == 6 then
            local r = tonumber(txt:sub(1,2),16)
            local g = tonumber(txt:sub(3,4),16)
            local b = tonumber(txt:sub(5,6),16)
            if r and g and b then
                disableRainbow()
                color = Color3.fromRGB(r,g,b); h, s, v = Color3.toHSV(color)
                applyMain(); pcall(onChange, color, alpha, {rainbowEnabled = false, rainbowSpeed = rainbowSpeed})
                return
            end
        end
        hexInp.Text = hexStr(color)
    end)
    
    local function applyRGB()
        local r = tonumber(rInp.Text) or math.floor(color.R*255+0.5)
        local g = tonumber(gInp.Text) or math.floor(color.G*255+0.5)
        local b = tonumber(bInp.Text) or math.floor(color.B*255+0.5)
        r = math.clamp(math.floor(r), 0, 255)
        g = math.clamp(math.floor(g), 0, 255)
        b = math.clamp(math.floor(b), 0, 255)
        disableRainbow()
        color = Color3.fromRGB(r,g,b); h, s, v = Color3.toHSV(color)
        applyMain()
        pcall(onChange, color, alpha, {rainbowEnabled = false, rainbowSpeed = rainbowSpeed})
    end
    rInp.FocusLost:Connect(applyRGB)
    gInp.FocusLost:Connect(applyRGB)
    bInp.FocusLost:Connect(applyRGB)
    
    rbToggle.MouseButton1Click:Connect(function()
        rainbowEnabled = not rainbowEnabled
        tween(rbSw, {BackgroundColor3 = rainbowEnabled and Theme.Accent or Color3.fromRGB(214, 218, 226)})
        tween(rbKnob, {Position = rainbowEnabled and UDim2.new(1,-14,0,2) or UDim2.new(0,2,0,2)})
        rainbowCtrl.active = rainbowEnabled
        if not rainbowEnabled then
            applyMain()
            pcall(onChange, color, alpha, {rainbowEnabled = false, rainbowSpeed = rainbowSpeed})
        else
            pcall(onChange, color, alpha, {rainbowEnabled = true, rainbowSpeed = rainbowSpeed})
        end
    end)
    
    closeBtn.MouseButton1Click:Connect(function()
        rainbowCtrl.keepAlive = false
        rainbowCtrl.active = false
        if opts.OnClose then opts.OnClose() end
    end)
    
    return root, {
        Get = function() return color, alpha, {rainbowEnabled = rainbowEnabled, rainbowSpeed = rainbowSpeed} end,
        Set = function(c, a, rbData) 
            color = c; if a then alpha = a end; h, s, v = Color3.toHSV(c); 
            if rbData then
                rainbowEnabled = rbData.rainbowEnabled or false
                rainbowSpeed = rbData.rainbowSpeed or 1
                rainbowCtrl.active = rainbowEnabled
                rainbowCtrl.speed = rainbowSpeed
                tween(rbSw, {BackgroundColor3 = rainbowEnabled and Theme.Accent or Color3.fromRGB(214, 218, 226)})
                tween(rbKnob, {Position = rainbowEnabled and UDim2.new(1,-14,0,2) or UDim2.new(0,2,0,2)})
                updateSpeedVis(rainbowSpeed)
            end
            applyMain() 
        end,
        GetRainbow = function() return rainbowEnabled, rainbowSpeed end,
        Destroy = function() 
            rainbowCtrl.active = false
            rainbowCtrl.keepAlive = false
            svDrag, hueDrag, alphaDrag, speedDrag = false, false, false, false
            for _, c in ipairs(localConnections) do pcall(function() c:Disconnect() end) end
            localConnections = {}
        end,
    }
end

-- ══════════════════════════════════════════════════════════════
-- KEYBIND MODE PICKER
-- ══════════════════════════════════════════════════════════════
local function handleKeybindPress(anchor, opt, state, explicitId)
    local modes = opt.Modes
    local id = explicitId or opt.Key or opt.Name or "kb"
    if not modes or #modes == 0 then
        if opt.Callback then pcall(opt.Callback, state[opt.Key], state) end
        return
    end
    if #modes == 1 then
        local modeKey = "__kbOn_" .. tostring(id)
        local cur = not (state[modeKey] or false)
        state[modeKey] = cur
        state["__kbActive_" .. tostring(id)] = cur and modes[1] or nil
        if opt.Callback then pcall(opt.Callback, modes[1], state, cur) end
        return
    end
    if openPickerMenu then openPickerMenu(anchor, opt, state, modes, id) end
end

local function openPickerMenuImpl(anchor, opt, state, modes, explicitId)
    local id = explicitId or opt.Key or opt.Name or "kb"
    local itemH = 32
    local listH = math.min(#modes * (itemH + 4) + 12, 280)
    local popup = new("Frame", {BackgroundColor3 = Theme.Panel, BorderSizePixel = 0,
        Size = UDim2.new(0, 240, 0, listH), Visible = true, ZIndex = Config.PopupZ + 80}, nil)
    addCorner(popup, UDim.new(0,10))
    addStroke(popup, Theme.Outline, 1, 0.1)
    new("Frame", {BackgroundColor3 = Theme.Accent, BorderSizePixel = 0,
        Size = UDim2.new(0,3,0,listH-16), Position = UDim2.new(0,8,0,8),
        ZIndex = Config.PopupZ + 81}, popup)
    local pickerTitle = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0,18,0,10),
        Size = UDim2.new(1,-28,0,14), Font = Config.CurrentFontFamily,
        Text = T(opt.Name or "Keybind"), TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = Config.PopupZ + 81}, popup)
    themeText(pickerTitle, "Text")
    local scroll = new("ScrollingFrame", {BackgroundTransparency = 1, BorderSizePixel = 0,
        Position = UDim2.new(0,8,0,32), Size = UDim2.new(1,-16,1,-40),
        CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Accent,
        ZIndex = Config.PopupZ + 81}, popup)
    new("UIListLayout", {Padding = UDim.new(0,4), SortOrder = Enum.SortOrder.LayoutOrder}, scroll)
    local active = state["__kbActive_" .. tostring(id)]
    for i, item in ipairs(modes) do
        local ib = new("TextButton", {BorderSizePixel = 0,
            Size = UDim2.new(1,0,0,itemH), LayoutOrder = i,
            Font = Config.CurrentFontFamily, Text = "  " .. tostring(item),
            TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false, ZIndex = Config.PopupZ + 82}, scroll)
        addCorner(ib, UDim.new(0,6))
        if item == active then
            themeBg(ib, "Accent"); ib.TextColor3 = Theme.OnAccent
        else themeBg(ib, "ElementHover"); themeText(ib, "Text") end
        ib.MouseButton1Click:Connect(function()
            state["__kbActive_" .. tostring(id)] = item
            if opt.Callback then pcall(opt.Callback, item, state) end
            closeTopPopup()
        end)
    end
    pushPopup(popup, function()
        if not anchor or not anchor.Parent then return end
        local ap, as = anchor.AbsolutePosition, anchor.AbsoluteSize
        local vp = workspace.CurrentCamera.ViewportSize
        local x, y = ap.X + as.X + 8, ap.Y
        if x + 240 > vp.X then x = ap.X - 248 end
        if y + listH > vp.Y then y = vp.Y - listH - 8 end
        if y < 4 then y = 4 end
        popup.Position = UDim2.fromOffset(x, y)
    end, function() end)
end
openPickerMenu = openPickerMenuImpl

-- ══════════════════════════════════════════════════════════════
-- BIND POPUP
-- ══════════════════════════════════════════════════════════════
local BIND_MODES = {"Toggle", "Hold", "OnHoldDisable"}
local function openBindMenu(anchor, bindId, offsetX)
    local bind = BindRegistry[bindId]; if not bind then return end
    offsetX = offsetX or 0
    local hasValue = bind.type ~= "Button" and bind.type ~= "Label"
    local popupH = hasValue and 440 or 400
    local popup = new("Frame", {Name = "BindPopup", BorderSizePixel = 0,
        Size = UDim2.new(0,340,0,popupH), Visible = false, ZIndex = Config.PopupZ + 50}, nil)
    themeBg(popup, "Panel"); addCorner(popup, UDim.new(0,10))
    addStroke(popup, Theme.Outline, 1, 0.1)
    new("Frame", {BackgroundColor3 = Theme.Accent, BorderSizePixel = 0,
        Size = UDim2.new(0,3,0,popupH-16), Position = UDim2.new(0,8,0,8),
        ZIndex = Config.PopupZ + 51}, popup)
    local titleLbl = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0,20,0,10),
        Size = UDim2.new(1,-30,0,16), Font = Config.CurrentFontFamily,
        Text = bind.name or "?", TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = Config.PopupZ + 51}, popup)
    themeText(titleLbl, "Text")
    local listScroll = new("ScrollingFrame", {BackgroundTransparency = 1, BorderSizePixel = 0,
        Position = UDim2.new(0,10,0,32), Size = UDim2.new(1,-20,0,popupH - 122),
        CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3, ZIndex = Config.PopupZ + 51}, popup)
    listScroll.ScrollBarImageColor3 = Theme.Accent
    new("UIListLayout", {Padding = UDim.new(0,6), SortOrder = Enum.SortOrder.LayoutOrder}, listScroll)
    local function refresh()
        for _, c in ipairs(listScroll:GetChildren()) do
            if not c:IsA("UIListLayout") then c:Destroy() end
        end
        for i, e in ipairs(bind.keys) do
            local r = new("Frame", {BorderSizePixel = 0,
                Size = UDim2.new(1,0,0, hasValue and 66 or 36),
                LayoutOrder = i, ZIndex = Config.PopupZ + 52}, listScroll)
            themeBg(r, "ElementHover"); addCorner(r, UDim.new(0,6))
            local modeStrip = new("Frame", {BackgroundColor3 = MODE_COLORS[e.mode] or Theme.Accent,
                BorderSizePixel = 0, Position = UDim2.new(0,0,0,0),
                Size = UDim2.new(0,3,1,0), ZIndex = Config.PopupZ + 53}, r)
            addCorner(modeStrip, UDim.new(0,3))
            local kb = new("TextButton", {BorderSizePixel = 0,
                Position = UDim2.new(0,8,0,7), Size = UDim2.new(0,110,0,22),
                Font = Config.CurrentFontFamily, Text = keyName(e.key), TextSize = 11,
                AutoButtonColor = false, ZIndex = Config.PopupZ + 53}, r)
            themeBg(kb, "Panel"); themeText(kb, "Text"); addCorner(kb, UDim.new(0,4))
            kb.MouseButton1Click:Connect(function()
                kb.Text = "Press..."
                kb.TextColor3 = Theme.Warning
                bindListening = true
                local c
                c = UserInputService.InputBegan:Connect(function(inp, gpe)
                    if gpe then return end
                    if not isListenableInput(inp) then return end
                    local nk = readInputKey(inp)
                    e.key = nk
                    kb.Text = keyName(nk); kb.TextColor3 = Theme.Text
                    bindListening = false; c:Disconnect()
                end)
                _T(c)
            end)
            local mb = new("TextButton", {BorderSizePixel = 0,
                Position = UDim2.new(0,124,0,7), Size = UDim2.new(0,110,0,22),
                Font = Config.CurrentFontFamily, Text = MODE_SHORT[e.mode] or e.mode, TextSize = 11,
                AutoButtonColor = false, ZIndex = Config.PopupZ + 53}, r)
            themeBg(mb, "Panel")
            mb.TextColor3 = MODE_COLORS[e.mode] or Theme.Text
            addCorner(mb, UDim.new(0,4))
            mb.MouseButton1Click:Connect(function()
                local ix = 1
                for j, m in ipairs(BIND_MODES) do
                    if m == e.mode then ix = j; break end
                end
                ix = (ix % #BIND_MODES) + 1
                e.mode = BIND_MODES[ix]
                mb.Text = MODE_SHORT[e.mode] or e.mode
                mb.TextColor3 = MODE_COLORS[e.mode] or Theme.Text
                modeStrip.BackgroundColor3 = MODE_COLORS[e.mode] or Theme.Accent
            end)
            local del = new("TextButton", {BackgroundColor3 = Theme.Danger, BackgroundTransparency = 0.7,
                BorderSizePixel = 0, Position = UDim2.new(1,-36,0,7), Size = UDim2.new(0,28,0,22),
                Font = Config.CurrentFontFamily, Text = "x", TextColor3 = Theme.Danger, TextSize = 12,
                AutoButtonColor = false, ZIndex = Config.PopupZ + 53}, r)
            addCorner(del, UDim.new(0,4))
            del.MouseButton1Click:Connect(function() RemoveBindKey(bindId, i); refresh() end)
            if hasValue then
                local vl = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0,10,0,38),
                    Size = UDim2.new(0,50,0,20), Font = Config.CurrentFontFamily, Text = "Value",
                    TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = Config.PopupZ + 53}, r)
                themeText(vl, "SubText")
                local vb = new("TextBox", {BorderSizePixel = 0,
                    Position = UDim2.new(0,62,0,38), Size = UDim2.new(1,-72,0,20),
                    Font = Config.CurrentFontFamily, Text = tostring(e.value or bind.default or ""),
                    TextSize = 11, ClearTextOnFocus = false, ZIndex = Config.PopupZ + 53}, r)
                themeBg(vb, "Panel"); themeText(vb, "Text")
                addCorner(vb, UDim.new(0,4)); addPadding(vb, 6)
                vb.FocusLost:Connect(function()
                    local raw = vb.Text
                    if raw == "" then e.value = nil; return end
                    local n = tonumber(raw)
                    if n then e.value = n
                    elseif raw == "true" then e.value = true
                    elseif raw == "false" then e.value = false
                    else e.value = raw end
                end)
            end
        end
    end
    local addBtn = new("TextButton", {BorderSizePixel = 0,
        Position = UDim2.new(0,10,1,-80), Size = UDim2.new(1,-20,0,30),
        Font = Config.CurrentFontFamily, Text = "+ Add Key", TextColor3 = Theme.OnAccent,
        TextSize = 11, AutoButtonColor = false, ZIndex = Config.PopupZ + 51}, popup)
    themeBg(addBtn, "Accent"); addCorner(addBtn, UDim.new(0,6))
    addBtn.MouseButton1Click:Connect(function()
        AddBindKey(bindId, nil, "Toggle", hasValue and (bind.default or 1) or true)
        refresh()
    end)
    local clearBtn = new("TextButton", {BackgroundColor3 = Theme.Danger, BackgroundTransparency = 0.85,
        BorderSizePixel = 0, Position = UDim2.new(0,10,1,-42), Size = UDim2.new(0.5,-14,0,30),
        Font = Config.CurrentFontFamily, Text = "Clear", TextColor3 = Theme.Danger,
        TextSize = 11, AutoButtonColor = false, ZIndex = Config.PopupZ + 51}, popup)
    addCorner(clearBtn, UDim.new(0,6))
    clearBtn.MouseButton1Click:Connect(function() ClearBind(bindId); refresh() end)
    local closeBtn = new("TextButton", {BorderSizePixel = 0,
        Position = UDim2.new(0.5,4,1,-42), Size = UDim2.new(0.5,-14,0,30),
        Font = Config.CurrentFontFamily, Text = "Close", TextSize = 11,
        AutoButtonColor = false, ZIndex = Config.PopupZ + 51}, popup)
    themeBg(closeBtn, "ElementHover"); themeText(closeBtn, "Text"); addCorner(closeBtn, UDim.new(0,6))
    closeBtn.MouseButton1Click:Connect(function() closeTopPopup() end)
    refresh()
    pushPopup(popup, function()
        if not anchor or not anchor.Parent then return end
        local ap, as = anchor.AbsolutePosition, anchor.AbsoluteSize
        local vp = workspace.CurrentCamera.ViewportSize
        local x, y = ap.X + as.X + 8 + offsetX, ap.Y
        if x + 340 > vp.X then x = ap.X - 348 - offsetX end
        if y + popupH > vp.Y then y = vp.Y - popupH - 8 end
        if y < 4 then y = 4 end
        popup.Position = UDim2.fromOffset(x, y)
    end, function() end)
end

local lastOpenTime = 0
local function canOpenBind()
    local now = tick()
    if now - lastOpenTime < 0.15 then return false end
    lastOpenTime = now
    return true
end
local function attachRowMMB(row, bindId)
    if not bindId then return end
    local function handler(input)
        if bindListening then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton3 then return end
        if not row or not row.Parent then return end
        if not canOpenBind() then return end
        openBindMenu(row, bindId, 0)
    end
    row.InputBegan:Connect(handler)
    for _, d in ipairs(row:GetDescendants()) do
        if d:IsA("GuiObject") then d.InputBegan:Connect(handler) end
    end
end
local function attachRowRMB(row, meta, hasOptions)
    if not hasOptions then return end
    local function handler(input)
        if bindListening then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton2 then return end
        if not canOpenBind() then return end
        if openOptionsMenu then openOptionsMenu(row, meta) end
    end
    row.InputBegan:Connect(handler)
    for _, d in ipairs(row:GetDescendants()) do
        if d:IsA("GuiObject") then d.InputBegan:Connect(handler) end
    end
end
local function attachRowBinds(row, bindId, meta)
    local hasOptions = meta and meta.Options and #meta.Options > 0
    attachRowRMB(row, meta, hasOptions)
    attachRowMMB(row, bindId)
end

function openOptionsMenu(anchor, meta)
    if not meta then return end
    local popup = new("Frame", {BorderSizePixel = 0, Size = UDim2.new(0,300,0,80),
        Visible = false, ZIndex = Config.PopupZ}, nil)
    themeBg(popup, "Panel"); addCorner(popup, UDim.new(0,10))
    addStroke(popup, Theme.Outline, 1, 0.1)
    local closeBtn = new("TextButton", {BorderSizePixel = 0,
        Position = UDim2.new(0,10,1,-38), Size = UDim2.new(1,-20,0,28),
        Font = Config.CurrentFontFamily, Text = "Close", TextSize = 11,
        AutoButtonColor = false, ZIndex = Config.PopupZ + 2}, popup)
    themeBg(closeBtn, "ElementHover"); themeText(closeBtn, "Text")
    addCorner(closeBtn, UDim.new(0,6))
    closeBtn.MouseButton1Click:Connect(function() closeTopPopup() end)
    pushPopup(popup, function()
        if not anchor or not anchor.Parent then return end
        local ap, as = anchor.AbsolutePosition, anchor.AbsoluteSize
        local vp = workspace.CurrentCamera.ViewportSize
        local x, y = ap.X + as.X + 8, ap.Y
        if x + 300 > vp.X then x = ap.X - 308 end
        popup.Position = UDim2.fromOffset(x, y)
    end, function() end)
end

-- ══════════════════════════════════════════════════════════════
-- HELPERS
-- ══════════════════════════════════════════════════════════════
local function registerVisibleIf(element, predicate, section)
    local st = getSectionState(section)
    watchVisibility(element, predicate, st)
end
local function makeBindId(prefix)
    return (prefix or "bind") .. "_" .. tostring(os.clock()) .. "_" .. tostring(math.random(1,99999))
end
local function round(n) return math.floor(n + 0.5) end

-- ══════════════════════════════════════════════════════════════
-- COMPONENTS
-- ══════════════════════════════════════════════════════════════
local function createToggle(section, opts)
    local userState = opts.Value or false
    local eff = userState
    local row = new("Frame", {BorderSizePixel = 0, Size = UDim2.new(1,0,0,36)}, section.Content)
    themeBg(row, "Element"); regTransparency(row, "Element", 0); addCorner(row, UDim.new(0,8))
    addStroke(row, Theme.Outline, 1, 0.35)
    local nameLbl = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0,14,0,0),
        Size = UDim2.new(1,-100,1,0), Font = Config.CurrentFontFamily, Text = T(opts.Name or ""),
        TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left}, row)
    if opts.Name then nameLbl:SetAttribute("_tKey", opts.Name) end
    themeText(nameLbl, "Text")
    markSearch(row, T(opts.Name or ""), nameLbl)
    local stateLbl = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(1,-84,0,0),
        Size = UDim2.new(0,34,1,0), Font = Config.CurrentFontFamily, Text = eff and "ON" or "OFF",
        TextSize = 10, TextXAlignment = Enum.TextXAlignment.Right}, row)
    stateLbl.TextColor3 = eff and Theme.Accent or Theme.Muted
    local sw = new("Frame", {BackgroundColor3 = eff and Theme.Accent or Color3.fromRGB(214, 218, 226),
        BorderSizePixel = 0, Position = UDim2.new(1,-46,0.5,-9), Size = UDim2.new(0,36,0,18)}, row)
    addCorner(sw, UDim.new(1,0))
    local knob = new("Frame", {BackgroundColor3 = Color3.fromRGB(255,255,255), BorderSizePixel = 0,
        Position = eff and UDim2.new(1,-18,0,2) or UDim2.new(0,2,0,2),
        Size = UDim2.new(0,14,0,14)}, sw)
    addCorner(knob, UDim.new(1,0))
    local function setVis(v)
        tween(sw, {BackgroundColor3 = v and Theme.Accent or Color3.fromRGB(214, 218, 226)})
        tween(knob, {Position = v and UDim2.new(1,-18,0,2) or UDim2.new(0,2,0,2)})
        stateLbl.Text = v and "ON" or "OFF"
        stateLbl.TextColor3 = v and Theme.Accent or Theme.Muted
    end
    local function setEff(v, fromUser)
        eff = v and true or false; setVis(eff)
        if fromUser and opts.Callback then pcall(opts.Callback, eff) end
        if opts.Key then getSectionState(section)[opts.Key] = eff; reevaluateVisibility() end
    end
    local click = new("TextButton", {BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0), Text = ""}, row)
    click.MouseButton1Click:Connect(function() userState = not userState; setEff(userState, true) end)
    local bindId = opts.BindId or makeBindId("bind_tgl")
    local bind = RegisterBind(bindId, T(opts.Name or ""),
        function(ov) setEff(ov ~= nil and (ov and true or false) or userState, true) end,
        "Toggle", true)
    if opts.Key then getSectionState(section)[opts.Key] = eff end
    local meta = {Name = T(opts.Name or ""), Type = "Toggle", Element = row, BindId = bindId,
        Options = opts.Options, State = getSectionState(section),
        Set = function(v) userState = v; setEff(v, false) end}
    attachRowBinds(row, bindId, meta)
    if opts.Tooltip then attachTooltip(row, opts.Tooltip) end
    if opts.VisibleIf then registerVisibleIf(row, opts.VisibleIf, section) end
    return {Set = meta.Set, Get = function() return eff end, BindId = bindId,
        _meta = meta, _rawName = opts.Name, _type = "Toggle"}
end

local function createSlider(section, opts)
    local min, max = opts.Min or 0, opts.Max or 100
    local dec = opts.Decimals or 0
    local userV = opts.Value or min
    local effV = userV
    local row = new("Frame", {BorderSizePixel = 0, Size = UDim2.new(1,0,0,52)}, section.Content)
    themeBg(row, "Element"); regTransparency(row, "Element", 0); addCorner(row, UDim.new(0,8))
    addStroke(row, Theme.Outline, 1, 0.35)
    local nameLbl = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0,14,0,6),
        Size = UDim2.new(1,-90,0,16), Font = Config.CurrentFontFamily, Text = T(opts.Name or ""),
        TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left}, row)
    if opts.Name then nameLbl:SetAttribute("_tKey", opts.Name) end
    themeText(nameLbl, "Text")
    markSearch(row, T(opts.Name or ""), nameLbl)
    local vLbl = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(1,-80,0,6),
        Size = UDim2.new(0,68,0,16), Font = Config.CurrentFontFamily, Text = tostring(effV), TextSize = 11,
        TextColor3 = Theme.Accent, TextXAlignment = Enum.TextXAlignment.Right}, row)
    local track = new("Frame", {BorderSizePixel = 0,
        Position = UDim2.new(0,12,1,-20), Size = UDim2.new(1,-24,0,6)}, row)
    themeBg(track, "ElementHover"); addCorner(track, UDim.new(1,0))
    local fill = new("Frame", {BorderSizePixel = 0,
        Size = UDim2.new((effV-min)/(max-min),0,1,0)}, track)
    themeBg(fill, "Accent"); addCorner(fill, UDim.new(1,0))
    local knob = new("Frame", {BackgroundColor3 = Color3.fromRGB(255,255,255), BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new((effV-min)/(max-min),0,0.5,0),
        Size = UDim2.new(0,14,0,14)}, track)
    addCorner(knob, UDim.new(1,0)); addStroke(knob, Theme.Accent, 2)
    local function rnd(n) local m = 10^dec; return math.floor(n*m+0.5)/m end
    local function update(v)
        local rel = (v-min)/(max-min)
        vLbl.Text = tostring(v); fill.Size = UDim2.new(rel,0,1,0)
        knob.Position = UDim2.new(rel,0,0.5,0)
    end
    local function setEff(v, fromUser)
        v = math.clamp(v, min, max); effV = v; update(v)
        if fromUser and opts.Callback then pcall(opts.Callback, v) end
        if opts.Key then getSectionState(section)[opts.Key] = v; reevaluateVisibility() end
    end
    local drag = false
    local function fromX(x)
        local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        userV = rnd(min + (max-min)*rel); setEff(userV, true)
    end
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = true; fromX(i.Position.X) end
    end)
    _T(UserInputService.InputChanged:Connect(function(i)
        if drag and i.UserInputType == Enum.UserInputType.MouseMovement then fromX(i.Position.X) end
    end))
    _T(UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
    end))
    local bindId = opts.BindId or makeBindId("bind_sld")
    RegisterBind(bindId, T(opts.Name or ""), function(ov)
        if ov ~= nil then local v = tonumber(ov); if v then setEff(v, true) end
        else setEff(userV, true) end
    end, "Slider", (min+max)/2)
    if opts.Key then getSectionState(section)[opts.Key] = effV end
    local meta = {Name = T(opts.Name or ""), Type = "Slider", Element = row, BindId = bindId,
        Options = opts.Options, State = getSectionState(section),
        Set = function(v) userV = math.clamp(v, min, max); setEff(userV, false) end}
    attachRowBinds(row, bindId, meta)
    if opts.Tooltip then attachTooltip(row, opts.Tooltip) end
    if opts.VisibleIf then registerVisibleIf(row, opts.VisibleIf, section) end
    return {Set = meta.Set, Get = function() return effV end, BindId = bindId,
        _meta = meta, _rawName = opts.Name, _type = "Slider"}
end

local function createButton(section, opts)
    local btn = new("TextButton", {BorderSizePixel = 0, Size = UDim2.new(1,0,0,36),
        Font = Config.CurrentFontFamily, Text = T(opts.Name or ""), TextSize = 12, AutoButtonColor = false}, section.Content)
    if opts.Name then btn:SetAttribute("_tKey", opts.Name) end
    themeBg(btn, "Element"); regTransparency(btn, "Element", 0); themeText(btn, "Text")
    addStroke(btn, Theme.Outline, 1, 0.35); addCorner(btn, UDim.new(0,8))
    markSearch(btn, T(opts.Name or ""), btn)
    btn.MouseEnter:Connect(function() tween(btn, {BackgroundColor3 = Theme.Accent, TextColor3 = Theme.OnAccent}) end)
    btn.MouseLeave:Connect(function() tween(btn, {BackgroundColor3 = Theme.Element, TextColor3 = Theme.Text}) end)
    btn.MouseButton1Click:Connect(function() if opts.Callback then pcall(opts.Callback) end end)
    local bindId = opts.BindId or makeBindId("bind_btn")
    RegisterBind(bindId, T(opts.Name or ""),
        function(ov) if ov ~= false then if opts.Callback then pcall(opts.Callback) end end end, "Button", true)
    local meta = {Name = T(opts.Name or ""), Type = "Button", Element = btn, BindId = bindId,
        Options = opts.Options, State = getSectionState(section),
        Set = function() if opts.Callback then pcall(opts.Callback) end end}
    attachRowBinds(btn, bindId, meta)
    if opts.Tooltip then attachTooltip(btn, opts.Tooltip) end
    if opts.VisibleIf then registerVisibleIf(btn, opts.VisibleIf, section) end
    return btn
end

local function createLabel(section, opts)
    local text = opts.Text or opts.Name or ""
    local lbl = new("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(1,0,0,20),
        Font = Config.CurrentFontFamily, Text = T(text), TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true}, section.Content)
    lbl:SetAttribute("_tKey", text)
    if opts.Color then lbl.TextColor3 = opts.Color else themeText(lbl, "SubText") end
    markSearch(lbl, T(text), lbl)
    if opts.VisibleIf then registerVisibleIf(lbl, opts.VisibleIf, section) end
    return lbl
end

local function createDivider(section, opts)
    local h = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1,0,0,22)}, section.Content)
    local lbl = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0,0,0,0),
        Size = UDim2.new(1,0,1,-4), Font = Config.CurrentFontFamily, Text = T(opts.Text or ""),
        TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left}, h)
    lbl:SetAttribute("_tKey", opts.Text or "")
    if opts.Color then lbl.TextColor3 = opts.Color else themeText(lbl, "Muted") end
    markSearch(h, T(opts.Text or ""), lbl)
    if opts.VisibleIf then registerVisibleIf(h, opts.VisibleIf, section) end
    return h
end

local function createInput(section, opts)
    local value = opts.Value or ""
    local row = new("Frame", {BorderSizePixel = 0, Size = UDim2.new(1,0,0,36)}, section.Content)
    themeBg(row, "Element"); regTransparency(row, "Element", 0); addCorner(row, UDim.new(0,8))
    addStroke(row, Theme.Outline, 1, 0.35)
    local nameLbl = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0,14,0,0),
        Size = UDim2.new(0.45,-14,1,0), Font = Config.CurrentFontFamily,
        Text = T(opts.Name or ""), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left}, row)
    if opts.Name then nameLbl:SetAttribute("_tKey", opts.Name) end
    themeText(nameLbl, "Text")
    markSearch(row, T(opts.Name or ""), nameLbl)
    local input = new("TextBox", {BorderSizePixel = 0, Position = UDim2.new(0.45,0,0.5,-11),
        Size = UDim2.new(0.55,-14,0,22), Font = Config.CurrentFontFamily,
        Text = value, TextSize = 11, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left}, row)
    if opts.Placeholder then tPlaceholder(input, opts.Placeholder) end
    themeBg(input, "ElementHover"); themeText(input, "Text")
    addCorner(input, UDim.new(0,6)); addPadding(input, 8, 0)
    input.FocusLost:Connect(function()
        value = input.Text
        if opts.Callback then pcall(opts.Callback, value) end
    end)
    local meta = {Name = T(opts.Name or ""), Type = "Input", Element = row,
        Options = opts.Options, State = getSectionState(section),
        Set = function(v) value = v; input.Text = v end}
    attachRowBinds(row, nil, meta)
    if opts.Tooltip then attachTooltip(row, opts.Tooltip) end
    if opts.VisibleIf then registerVisibleIf(row, opts.VisibleIf, section) end
    return {Set = meta.Set, Get = function() return value end, _meta = meta,
        _rawName = opts.Name, _type = "Input"}
end

local function createDropdown(section, opts)
    local list = opts.List or {}
    local value = opts.Value or (list[1] or "")
    local open = false
    local row = new("Frame", {BorderSizePixel = 0, Size = UDim2.new(1,0,0,36)}, section.Content)
    themeBg(row, "Element"); regTransparency(row, "Element", 0); addCorner(row, UDim.new(0,8))
    addStroke(row, Theme.Outline, 1, 0.35)
    local nameLbl = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0,14,0,0),
        Size = UDim2.new(0.5,-10,1,0), Font = Config.CurrentFontFamily, Text = T(opts.Name or ""),
        TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left}, row)
    if opts.Name then nameLbl:SetAttribute("_tKey", opts.Name) end
    themeText(nameLbl, "Text")
    markSearch(row, T(opts.Name or ""), nameLbl)
    local vLbl = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0.5,0,0,0),
        Size = UDim2.new(0.5,-52,1,0), Font = Config.CurrentFontFamily, Text = T(tostring(value)),
        TextSize = 11, TextColor3 = Theme.Accent, TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd}, row)
    local arrowLbl = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(1,-36,0,0),
        Size = UDim2.new(0,22,1,0), Font = Config.CurrentFontFamily, Text = "v",
        TextSize = 11}, row)
    themeText(arrowLbl, "SubText")
    local click = new("TextButton", {BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0), Text = ""}, row)
    local itemH = 28
    local popupH = math.min(#list * (itemH+6) + 12, 220)
    local function buildPopup()
        local popup = new("ScrollingFrame", {BorderSizePixel = 0,
            Size = UDim2.new(0,200,0,popupH), CanvasSize = UDim2.new(0,0,0,0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3,
            Visible = false, ZIndex = Config.PopupZ, ClipsDescendants = true}, nil)
        themeBg(popup, "Panel"); popup.ScrollBarImageColor3 = Theme.Accent
        addCorner(popup, UDim.new(0,10)); addStroke(popup, Theme.Outline, 1, 0.1)
        new("UIListLayout", {Padding = UDim.new(0,3)}, popup); addPadding(popup, 6)
        for _, item in ipairs(list) do
            local ib = new("TextButton", {BorderSizePixel = 0,
                Size = UDim2.new(1,-8,0,itemH), Font = Config.CurrentFontFamily, Text = T(tostring(item)),
                TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
                AutoButtonColor = false, ZIndex = Config.PopupZ + 1}, popup)
            themeBg(ib, "Panel"); themeText(ib, "Text")
            addCorner(ib, UDim.new(0,6)); addPadding(ib, 8)
            ib.MouseButton1Click:Connect(function()
                value = item; vLbl.Text = T(tostring(item))
                if opts.Callback then pcall(opts.Callback, item) end
                if opts.Key then getSectionState(section)[opts.Key] = item; reevaluateVisibility() end
                closeTopPopup()
            end)
        end
        return popup
    end
    click.MouseButton1Click:Connect(function()
        if open then closeTopPopup(); return end
        local popup = buildPopup()
        local function pos()
            if not row or not row.Parent or not popup.Parent then return end
            local ap, as = row.AbsolutePosition, row.AbsoluteSize
            popup.Position = UDim2.fromOffset(ap.X, ap.Y + as.Y + 6)
            popup.Size = UDim2.new(0, math.max(as.X, 200), 0, popupH)
        end
        open = true
        pushPopup(popup, pos, function() open = false end)
    end)
    local bindId = opts.BindId or makeBindId("bind_dd")
    RegisterBind(bindId, T(opts.Name or ""), function() end, "Dropdown", value)
    if opts.Key then getSectionState(section)[opts.Key] = value end
    local meta = {Name = T(opts.Name or ""), Type = "Dropdown", Element = row, BindId = bindId,
        Options = opts.Options, State = getSectionState(section),
        Set = function(v) value = v; vLbl.Text = T(tostring(v)) end}
    attachRowBinds(row, bindId, meta)
    if opts.Tooltip then attachTooltip(row, opts.Tooltip) end
    if opts.VisibleIf then registerVisibleIf(row, opts.VisibleIf, section) end
    return {
        Set = meta.Set,
        Get = function() return value end,
        BindId = bindId, _meta = meta,
        _rawName = opts.Name, _type = "Dropdown",
        _setList = function(newList)
            for i = #list, 1, -1 do list[i] = nil end
            for _, v in ipairs(newList or {}) do list[#list+1] = v end
            popupH = math.min(#list * (itemH+6) + 12, 220)
        end,
        _setValue = function(v) value = v or ""; vLbl.Text = T(tostring(value)) end,
    }
end

local function createColorpicker(section, opts)
    local color = opts.Default or Color3.fromRGB(77, 107, 254)
    local alpha = opts.DefaultAlpha or 0
    local rainbowEnabled = opts.Rainbow or false
    local rainbowSpeed = opts.RainbowSpeed or 1
    local row = new("Frame", {BorderSizePixel = 0, Size = UDim2.new(1,0,0,36)}, section.Content)
    themeBg(row, "Element"); regTransparency(row, "Element", 0); addCorner(row, UDim.new(0,8))
    addStroke(row, Theme.Outline, 1, 0.35)
    local nameLbl = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0,14,0,0),
        Size = UDim2.new(1,-90,1,0), Font = Config.CurrentFontFamily, Text = T(opts.Name or ""),
        TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left}, row)
    if opts.Name then nameLbl:SetAttribute("_tKey", opts.Name) end
    themeText(nameLbl, "Text")
    markSearch(row, T(opts.Name or ""), nameLbl)
    local swatch = new("Frame", {BackgroundColor3 = color, BorderSizePixel = 0,
        Position = UDim2.new(1,-48,0.5,-11), Size = UDim2.new(0,36,0,22)}, row)
    addCorner(swatch, UDim.new(0,6)); addStroke(swatch, Theme.Outline, 1, 0.2)
    local click = new("TextButton", {BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0), Text = ""}, row)
    
    local activeCpApi = nil
    local cpElement = {
        Set = function(c, a, rbData) 
            color = c; if a then alpha = a end; swatch.BackgroundColor3 = c 
            if rbData then
                rainbowEnabled = rbData.rainbowEnabled
                rainbowSpeed = rbData.rainbowSpeed
            end
            if activeCpApi then activeCpApi.Set(c, a, rbData) end
        end, 
        Get = function() return color, alpha, {rainbowEnabled = rainbowEnabled, rainbowSpeed = rainbowSpeed} end, 
        _meta = {Name = T(opts.Name or ""), Type = "Colorpicker", Element = row,
            Options = opts.Options, State = getSectionState(section),
            Set = function(c, a, rbData) cpElement.Set(c, a, rbData) end
        },
        _rawName = opts.Name, _type = "Colorpicker"
    }
    
    local swatchRainbowCtrl = {
        active = rainbowEnabled, speed = rainbowSpeed, root = swatch,
        keepAlive = true,
        setFromRainbow = function(hv, frame)
            local c = Color3.fromHSV(hv, 1, 1)
            color = c
            swatch.BackgroundColor3 = c
            if activeCpApi then activeCpApi.Set(c, alpha, {rainbowEnabled = true, rainbowSpeed = rainbowSpeed}) end
            if frame and (frame % (Config.RainbowCallbackInterval or 4) == 0) then
                if opts.Callback then pcall(opts.Callback, c, alpha) end
            end
        end,
    }
    table.insert(RainbowControllers, swatchRainbowCtrl)
    
    click.MouseButton1Click:Connect(function()
        local sub = new("Frame", {BackgroundColor3 = Theme.Panel, BorderSizePixel = 0,
            Size = UDim2.new(0,300,0,400), Visible = true, ZIndex = Config.PopupZ + 20}, nil)
        addCorner(sub, UDim.new(0,10)); addStroke(sub, Theme.Outline, 1, 0.1)
        local subTitle = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0,16,0,10),
            Size = UDim2.new(1,-28,0,16), Font = Config.CurrentFontFamily, Text = T(opts.Name or ""),
            TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = Config.PopupZ + 21}, sub)
        themeText(subTitle, "Text")
        local cpHolder = new("Frame", {BackgroundTransparency = 1,
            Position = UDim2.new(0,20,0,32), Size = UDim2.new(1,-40,0,360),
            ZIndex = Config.PopupZ + 21}, sub)
            
        local _, cpApi = buildColorpickerUI(cpHolder, {
            Color = color, Alpha = alpha, Width = 260,
            Rainbow = rainbowEnabled, RainbowSpeed = rainbowSpeed,
            OnChange = function(c, a, rbData)
                color = c; if a then alpha = a end
                swatch.BackgroundColor3 = c
                if rbData then
                    rainbowEnabled = rbData.rainbowEnabled
                    rainbowSpeed = rbData.rainbowSpeed
                    swatchRainbowCtrl.active = rainbowEnabled
                    swatchRainbowCtrl.speed = rainbowSpeed
                end
                if opts.Callback then pcall(opts.Callback, c, a) end
            end,
            OnClose = function()
                if activeCpApi then activeCpApi.Destroy() end
                activeCpApi = nil
                closeTopPopup()
            end
        })
        activeCpApi = cpApi
        
        pushPopup(sub, function()
            if row and row.Parent and sub.Parent then
                local ap, as = row.AbsolutePosition, row.AbsoluteSize
                local vp = workspace.CurrentCamera.ViewportSize
                local x, y = ap.X + as.X + 8, ap.Y
                if x + 300 > vp.X then x = ap.X - 308 end
                if y + 400 > vp.Y then y = vp.Y - 400 - 8 end
                if y < 4 then y = 4 end
                sub.Position = UDim2.fromOffset(x, y)
            end
        end, function() 
            if activeCpApi then activeCpApi.Destroy() end
            activeCpApi = nil
        end)
    end)
    
    attachRowBinds(row, nil, cpElement._meta)
    if opts.Tooltip then attachTooltip(row, opts.Tooltip) end
    if opts.VisibleIf then registerVisibleIf(row, opts.VisibleIf, section) end
    return cpElement
end

local function createKeybind(section, opts)
    local value = opts.Value or Enum.KeyCode.F
    local modes = opts.Modes or {}
    local state = getSectionState(section)
    local stateId = opts.Key or opts.Name or "kb"
    if opts.Key then state[opts.Key] = value end
    local row = new("Frame", {BorderSizePixel = 0, Size = UDim2.new(1,0,0,36)}, section.Content)
    themeBg(row, "Element"); regTransparency(row, "Element", 0); addCorner(row, UDim.new(0,8))
    addStroke(row, Theme.Outline, 1, 0.35)
    local stateDot = new("Frame", {BackgroundColor3 = Theme.Muted, BorderSizePixel = 0,
        Position = UDim2.new(0,8,0.5,-4), Size = UDim2.new(0,8,0,8)}, row)
    addCorner(stateDot, UDim.new(1,0))
    local nameLbl = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0,24,0,0),
        Size = UDim2.new(1,-190,1,0), Font = Config.CurrentFontFamily, Text = T(opts.Name or ""),
        TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left}, row)
    if opts.Name then nameLbl:SetAttribute("_tKey", opts.Name) end
    themeText(nameLbl, "Text")
    markSearch(row, T(opts.Name or ""), nameLbl)
    local modeState = state["__mode_" .. tostring(stateId)] or "Toggle"
    state["__mode_" .. tostring(stateId)] = modeState
    local modeBtn = new("TextButton", {BorderSizePixel = 0,
        Position = UDim2.new(1,-164,0.5,-11), Size = UDim2.new(0,52,0,22),
        Font = Config.CurrentFontFamily, Text = MODE_SHORT[modeState] or modeState, TextSize = 10,
        AutoButtonColor = false}, row)
    themeBg(modeBtn, "ElementHover")
    modeBtn.TextColor3 = MODE_COLORS[modeState] or Theme.Text
    addCorner(modeBtn, UDim.new(0,6))
    local btn = new("TextButton", {BorderSizePixel = 0,
        Position = UDim2.new(1,-106,0.5,-11), Size = UDim2.new(0,94,0,22),
        Font = Config.CurrentFontFamily, Text = keyName(value), TextSize = 11, AutoButtonColor = false}, row)
    themeBg(btn, "ElementHover"); themeText(btn, "Text"); addCorner(btn, UDim.new(0,6))
    local bindId = opts.BindId or makeBindId("bind_kb")
    local bind = nil
    if not opts.NoBind then
        RegisterBind(bindId, T(opts.Name or ""), function()
            local mods = opts.Modes
            if not mods or #mods == 0 then
                if opts.Callback then pcall(opts.Callback, value) end
                return
            end
            handleKeybindPress(row, opts, state, bindId)
        end, "Keybind", opts.Value)
        bind = BindRegistry[bindId]
        if value then AddBindKey(bindId, value, modeState) end
    end
    btn.MouseButton1Click:Connect(function()
        btn.Text = "Press..."
        btn.TextColor3 = Theme.Warning
        bindListening = true
        local c
        c = UserInputService.InputBegan:Connect(function(inp, gpe)
            if gpe then return end
            if not isListenableInput(inp) then return end
            local nk = readInputKey(inp)
            value = nk
            if opts.Key then state[opts.Key] = nk end
            if bind then
                bind.keys = {}
                AddBindKey(bindId, nk, state["__mode_" .. tostring(stateId)] or "Toggle")
            end
            btn.Text = keyName(nk); btn.TextColor3 = Theme.Text
            bindListening = false; c:Disconnect()
            if opts.Callback then pcall(opts.Callback, nk) end
        end)
        _T(c)
        task.delay(8, function()
            if bindListening and c.Connected then
                c:Disconnect()
                bindListening = false
                if btn.Parent then
                    btn.Text = keyName(value); btn.TextColor3 = Theme.Text
                end
            end
        end)
    end)
    modeBtn.MouseButton1Click:Connect(function()
        local cur = state["__mode_" .. tostring(stateId)] or "Toggle"
        local nx = cur == "Toggle" and "Hold" or cur == "Hold" and "OnHoldDisable" or "Toggle"
        state["__mode_" .. tostring(stateId)] = nx
        modeBtn.Text = MODE_SHORT[nx] or nx
        modeBtn.TextColor3 = MODE_COLORS[nx] or Theme.Text
        if bind and #bind.keys > 0 then bind.keys[1].mode = nx end
    end)
    if bind then
        task.spawn(function()
            while row.Parent do
                local active = isBindActive(bind)
                tween(stateDot, {BackgroundColor3 = active and (MODE_COLORS[modeState] or Theme.Accent) or Theme.Muted})
                task.wait(0.15)
            end
        end)
    end
    local meta = {Name = T(opts.Name or ""), Type = "Keybind", Element = row, BindId = bindId,
        Options = opts.Options, State = state, Modes = modes, Default = opts.Value,
        Set = function(v)
            value = v
            btn.Text = keyName(v)
            if opts.Key then state[opts.Key] = v end
            if bind then
                bind.keys = {}
                if v then
                    AddBindKey(bindId, v, state["__mode_" .. tostring(stateId)] or "Toggle")
                end
            end
        end}
    attachRowBinds(row, bindId, meta)
    if opts.Tooltip then attachTooltip(row, opts.Tooltip) end
    if opts.VisibleIf then registerVisibleIf(row, opts.VisibleIf, section) end
    return {Set = meta.Set, Get = function() return value end, BindId = bindId,
        _meta = meta, _rawName = opts.Name, _type = "Keybind"}
end

-- ══════════════════════════════════════════════════════════════
-- SECTION
-- ══════════════════════════════════════════════════════════════
local function createSection(tab, opts)
    local holder = tab.ColumnLeft
    if opts.Side == "Right" then holder = tab.ColumnRight end
    local section = {Content = nil, Collapsed = false, Name = T(opts.Name or ""), Elements = {}, _tKey = opts.Name}
    local frame = new("Frame", {BorderSizePixel = 0,
        Size = UDim2.new(1,0,0,32), AutomaticSize = Enum.AutomaticSize.Y}, holder)
    themeBg(frame, "Section"); regTransparency(frame, "Section", 0)
    addCorner(frame, UDim.new(0,10)); addStroke(frame, Theme.Outline, 1, 0.35)
    frame:SetAttribute("SearchName", string.lower(T(opts.Name or "")))
    local header = new("TextButton", {BorderSizePixel = 0,
        Size = UDim2.new(1,0,0,28), Text = "", AutoButtonColor = false}, frame)
    themeBg(header, "Panel"); header.LayoutOrder = 0; addCorner(header, UDim.new(0,10))
    new("Frame", {BackgroundColor3 = Theme.Accent, BorderSizePixel = 0,
        Position = UDim2.new(0,10,0,0), Size = UDim2.new(0,3,0,14)}, header)
    local headerLbl = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0,20,0,2),
        Size = UDim2.new(1,-40,1,0), Font = Config.CurrentFontFamily, Text = T(opts.Name or ""),
        TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left}, header)
    if opts.Name then headerLbl:SetAttribute("_tKey", opts.Name) end
    themeText(headerLbl, "Text")
    local arrow = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(1,-24,0,0),
        Size = UDim2.new(0,16,1,0), Font = Config.CurrentFontFamily, Text = "v",
        TextSize = 11}, header)
    themeText(arrow, "Muted")
    local content = new("Frame", {BackgroundTransparency = 1,
        Size = UDim2.new(1,0,0,0), AutomaticSize = Enum.AutomaticSize.Y}, frame)
    content.LayoutOrder = 1
    new("UIListLayout", {Padding = UDim.new(0,6), SortOrder = Enum.SortOrder.LayoutOrder}, content)
    section.Content = content; section.Frame = frame; section.Header = header
    new("UIListLayout", {Padding = UDim.new(0,8), SortOrder = Enum.SortOrder.LayoutOrder}, frame)
    addPadding(frame, 10, 10)
    header.MouseButton1Click:Connect(function()
        section.Collapsed = not section.Collapsed
        content.Visible = not section.Collapsed
        arrow.Text = section.Collapsed and ">" or "v"
    end)
    table.insert(tab.Sections, section)
    local function track(i) table.insert(section.Elements, i); return i end
    function section:AddToggle(o) return track(createToggle(self, o)) end
    function section:AddSlider(o) return track(createSlider(self, o)) end
    function section:AddButton(o) return track(createButton(self, o)) end
    function section:AddLabel(o) return track(createLabel(self, o)) end
    function section:AddDropdown(o) return track(createDropdown(self, o)) end
    function section:AddColorpicker(o) return track(createColorpicker(self, o)) end
    function section:AddKeybind(o) return track(createKeybind(self, o)) end
    function section:AddDivider(o) return track(createDivider(self, o)) end
    function section:AddInput(o) return track(createInput(self, o)) end
    return section
end

-- ══════════════════════════════════════════════════════════════
-- TAB & SUB-TAB
-- ══════════════════════════════════════════════════════════════
local function createTab(window, opts)
    local tab = {Name = T(opts.Name or ""), Sections = {}, _nameKey = opts.Name, _icon = opts.Icon, SubTabs = {}}
    local btn = new("TextButton", {BorderSizePixel = 0, Size = UDim2.new(1,-12,0,32),
        Font = Config.CurrentFontFamily, Text = "  " .. (opts.Icon and opts.Icon .. "  " or "") .. T(opts.Name or ""),
        TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false}, window.SidebarList)
    addCorner(btn, UDim.new(0,6)); themeBg(btn, "Sidebar"); themeText(btn, "SubText")
    regTransparency(btn, "Tab", 0)
    local dot = new("Frame", {BorderSizePixel = 0,
        Position = UDim2.new(0,4,0.5,-8), Size = UDim2.new(0,3,0,16), Visible = false}, btn)
    themeBg(dot, "Accent"); addCorner(dot, UDim.new(1,0))
    local page = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0), Visible = false},
        window.PageHolder)
    
    local subTabBar = new("ScrollingFrame", {BackgroundTransparency = 1, BorderSizePixel = 0,
        Position = UDim2.new(0,0,0,0), Size = UDim2.new(1,0,0,32),
        CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.X,
        ScrollBarThickness = 0, Visible = false, ZIndex = 5}, page)
    new("UIListLayout", {Padding = UDim.new(0,6), FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center}, subTabBar)
    
    local subTabContent = new("Frame", {BackgroundTransparency = 1,
        Position = UDim2.new(0,0,0,32), Size = UDim2.new(1,0,1,-32), ZIndex = 4}, page)
    
    local defaultContent = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0), ZIndex = 4}, page)
    
    local sl = new("ScrollingFrame", {BackgroundTransparency = 1, BorderSizePixel = 0,
        Position = UDim2.new(0,0,0,0), Size = UDim2.new(0.5,-5,1,0),
        CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 0}, defaultContent)
    local sr = new("ScrollingFrame", {BackgroundTransparency = 1, BorderSizePixel = 0,
        Position = UDim2.new(0.5,5,0,0), Size = UDim2.new(0.5,-5,1,0),
        CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 0}, defaultContent)
    new("UIListLayout", {Padding = UDim.new(0,10)}, sl)
    new("UIListLayout", {Padding = UDim.new(0,10)}, sr)
    
    tab.Page, tab.ColumnLeft, tab.ColumnRight = page, sl, sr
    tab.Button, tab.AccentDot = btn, dot
    tab._refresh = function()
        if window.ActiveTab == tab then
            btn.BackgroundColor3 = Theme.Panel; btn.TextColor3 = Theme.Accent
            dot.BackgroundColor3 = Theme.Accent
        else
            btn.BackgroundColor3 = Theme.Sidebar; btn.TextColor3 = Theme.SubText
        end
    end
    tab._refreshLang = function()
        btn.Text = "  " .. (opts.Icon and opts.Icon .. "  " or "") .. T(opts.Name or "")
        tab.Name = T(opts.Name or "")
    end
    btn.MouseButton1Click:Connect(function() window:SelectTab(tab) end)
    
    local activeSubTab = nil
    function tab:CreateSubTab(o)
        o = o or {}
        if #self.SubTabs == 0 then
            defaultContent.Visible = false
            subTabBar.Visible = true
        end
        
        local subTabObj = {
            Name = T(o.Name or "SubTab"), _nameKey = o.Name, Tab = tab,
            Sections = {}, _icon = o.Icon, Button = nil, Page = nil
        }
        
        local sbBtn = new("TextButton", {BorderSizePixel = 0, Size = UDim2.new(0,0,0,26),
            AutomaticSize = Enum.AutomaticSize.X,
            Font = Config.CurrentFontFamily, Text = (o.Icon and o.Icon .. " " or "") .. T(o.Name or "SubTab"),
            TextSize = 11, AutoButtonColor = false, ZIndex = 6}, subTabBar)
        addCorner(sbBtn, UDim.new(0,6)); addPadding(sbBtn, 12, 0)
        themeBg(sbBtn, "Element"); themeText(sbBtn, "SubText")
        
        local sbPage = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0), Visible = false, ZIndex = 4}, subTabContent)
        
        local sl2 = new("ScrollingFrame", {BackgroundTransparency = 1, BorderSizePixel = 0,
            Position = UDim2.new(0,0,0,0), Size = UDim2.new(0.5,-5,1,0),
            CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 0}, sbPage)
        local sr2 = new("ScrollingFrame", {BackgroundTransparency = 1, BorderSizePixel = 0,
            Position = UDim2.new(0.5,5,0,0), Size = UDim2.new(0.5,-5,1,0),
            CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 0}, sbPage)
        new("UIListLayout", {Padding = UDim.new(0,10)}, sl2)
        new("UIListLayout", {Padding = UDim.new(0,10)}, sr2)
        
        subTabObj.ColumnLeft, subTabObj.ColumnRight = sl2, sr2
        subTabObj.Button, subTabObj.Page = sbBtn, sbPage
        
        subTabObj._refresh = function()
            if activeSubTab == subTabObj then
                sbBtn.BackgroundColor3 = Theme.Accent; sbBtn.TextColor3 = Theme.OnAccent
            else
                sbBtn.BackgroundColor3 = Theme.Element; sbBtn.TextColor3 = Theme.SubText
            end
        end
        
        sbBtn.MouseButton1Click:Connect(function()
            if activeSubTab == subTabObj then return end
            if activeSubTab then
                activeSubTab.Page.Visible = false
                activeSubTab._refresh()
            end
            activeSubTab = subTabObj
            activeSubTab.Page.Visible = true
            activeSubTab._refresh()
        end)
        
        table.insert(self.SubTabs, subTabObj)
        
        if #self.SubTabs == 1 then
            activeSubTab = subTabObj
            activeSubTab.Page.Visible = true
            activeSubTab._refresh()
        end
        
        function subTabObj:CreateSection(secOpts)
            return createSection(self, secOpts)
        end
        
        return subTabObj
    end
    
    function tab:CreateSection(o) return createSection(self, o) end
    return tab
end

-- ══════════════════════════════════════════════════════════════
-- WINDOW
-- ══════════════════════════════════════════════════════════════
local function createWindow(opts)
    local window
    local parent = getSafeParent()
    local gui = new("ScreenGui", {Name = "airhubUI_" .. tostring(math.random(1000,9999)),
        ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true}, parent)
    ensureOverlay(gui)

    -- ─── ИЗМЕНЕНИЕ 1: currentHomePos + getHiddenPos() ──────────────────
    local BASE_POS = UDim2.new(0.5, 0, 0.5, 0)  -- стартовая позиция (центр)
    local currentHomePos = BASE_POS              -- текущая "домашняя" позиция (обновляется при drag)
    local function getHiddenPos()
        return UDim2.new(
            currentHomePos.X.Scale, currentHomePos.X.Offset,
            currentHomePos.Y.Scale, currentHomePos.Y.Offset + 30
        )
    end

    local shadowFrame = new("Frame", {Name = "Shadow", BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5), Position = BASE_POS,
        Size = UDim2.new(0,Config.WindowWidth+20,0,Config.WindowHeight+20),
        BackgroundColor3 = Color3.fromRGB(0,0,0), BackgroundTransparency = 0.8,
        ZIndex = 0}, gui)
    addCorner(shadowFrame, UDim.new(0, 18))

    local main = new("Frame", {Name = "Main", BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5), Position = BASE_POS,
        Size = UDim2.new(0,Config.WindowWidth,0,Config.WindowHeight),
        ZIndex = 1, BackgroundTransparency = Config.MenuTransparency}, gui)
    themeBg(main, "Background"); regTransparency(main, "Menu", Config.MenuTransparency)
    addCorner(main, UDim.new(0, 14))
    addStroke(main, Theme.OutlineLight, 1, 0.25)
    addBrackets(main, 14, 2, Theme.Accent)

    local animScale = Instance.new("UIScale"); animScale.Scale = 1; animScale.Parent = main

    local titlebar = new("Frame", {BorderSizePixel = 0, Size = UDim2.new(1,0,0,40), ZIndex = 2,
        BackgroundTransparency = 1}, main)
    local titleLbl = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0,18,0,0),
        Size = UDim2.new(1,-330,1,0), Font = Config.CurrentFontFamily, Text = opts.Name or "airhubUI",
        TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3}, titlebar)
    themeText(titleLbl, "Text")
    local versionLbl = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0,18,0,22),
        Size = UDim2.new(1,-330,0,14), Font = Config.CurrentFontFamily, Text = "v" .. Config.Version,
        TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3}, titlebar)
    themeText(versionLbl, "Muted")
    new("Frame", {BackgroundColor3 = Theme.Outline, BorderSizePixel = 0,
        Position = UDim2.new(0,0,1,-1), Size = UDim2.new(1,0,0,1), ZIndex = 3}, titlebar)

    local searchFrame = new("Frame", {BorderSizePixel = 0,
        Position = UDim2.new(1, -250, 0.5, -11), Size = UDim2.new(0, 180, 0, 22),
        ZIndex = 3}, titlebar)
    themeBg(searchFrame, "ElementHover"); addCorner(searchFrame, UDim.new(0,6))
    local searchStroke = addStroke(searchFrame, Theme.Outline, 1, 0.4); themeStroke(searchStroke, "Outline")
    new("TextLabel", {BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(0, 12, 1, 0),
        Font = Config.CurrentFontFamily, Text = "/", TextSize = 11,
        TextColor3 = Theme.Muted, ZIndex = 4}, searchFrame)
    local searchBox = new("TextBox", {BackgroundTransparency = 1,
        Position = UDim2.new(0, 24, 0, 0), Size = UDim2.new(1, -50, 1, 0),
        Font = Config.CurrentFontFamily, Text = "", TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, ZIndex = 4}, searchFrame)
    tPlaceholder(searchBox, "ph_search")
    themeText(searchBox, "Text")
    local clearSearchBtn = new("TextButton", {BackgroundTransparency = 1,
        Position = UDim2.new(1, -22, 0, 0), Size = UDim2.new(0, 20, 1, 0),
        Font = Config.CurrentFontFamily, Text = "x", TextSize = 11, Visible = false,
        AutoButtonColor = false, ZIndex = 4}, searchFrame)
    themeText(clearSearchBtn, "Muted")
    searchBox.Focused:Connect(function() tween(searchStroke, {Color = Theme.Accent, Transparency = 0}) end)
    searchBox.FocusLost:Connect(function() tween(searchStroke, {Color = Theme.Outline, Transparency = 0.4}) end)

    local searchQuery = ""
    local function applySearch()
        local q = searchQuery
        local isActive = (q ~= "")
        if not window or not window.Tabs then return end
        for _, tab in ipairs(window.Tabs) do
            for _, section in ipairs(tab.Sections) do
                if section.Frame and section.Frame.Parent then
                    local sectionMatches = 0
                    for _, child in ipairs(section.Content:GetChildren()) do
                        if child:IsA("GuiObject") then
                            local nameLbl = RowNameLabels[child]
                            if not isActive then
                                child.Visible = true; sectionMatches = sectionMatches + 1
                                if nameLbl then highlightLabel(nameLbl, "") end
                            else
                                local sn = child:GetAttribute("SearchName")
                                if sn and string.find(sn, q, 1, true) then
                                    child.Visible = true; sectionMatches = sectionMatches + 1
                                    if nameLbl then highlightLabel(nameLbl, q) end
                                else
                                    child.Visible = false
                                    if nameLbl then highlightLabel(nameLbl, "") end
                                end
                            end
                        end
                    end
                    section.Frame.Visible = (not isActive) or sectionMatches > 0
                end
            end
            for _, subTab in ipairs(tab.SubTabs) do
                for _, section in ipairs(subTab.Sections) do
                    if section.Frame and section.Frame.Parent then
                        local sectionMatches = 0
                        for _, child in ipairs(section.Content:GetChildren()) do
                            if child:IsA("GuiObject") then
                                local nameLbl = RowNameLabels[child]
                                if not isActive then
                                    child.Visible = true; sectionMatches = sectionMatches + 1
                                    if nameLbl then highlightLabel(nameLbl, "") end
                                else
                                    local sn = child:GetAttribute("SearchName")
                                    if sn and string.find(sn, q, 1, true) then
                                        child.Visible = true; sectionMatches = sectionMatches + 1
                                        if nameLbl then highlightLabel(nameLbl, q) end
                                    else
                                        child.Visible = false
                                        if nameLbl then highlightLabel(nameLbl, "") end
                                    end
                                end
                            end
                        end
                        section.Frame.Visible = (not isActive) or sectionMatches > 0
                    end
                end
            end
        end
        if not isActive then reevaluateVisibility() end
    end
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        searchQuery = string.lower(searchBox.Text or "")
        clearSearchBtn.Visible = (searchQuery ~= "")
        applySearch()
    end)
    clearSearchBtn.MouseButton1Click:Connect(function()
        searchBox.Text = ""; searchBox:ReleaseFocus()
    end)

    local function mkBtn(text, offX, hov)
        local b = new("TextButton", {BorderSizePixel = 0,
            Position = UDim2.new(1,offX,0.5,-11), Size = UDim2.new(0,22,0,22),
            Font = Config.CurrentFontFamily, Text = text, TextSize = 11,
            AutoButtonColor = false, ZIndex = 3}, titlebar)
        themeBg(b, "ElementHover"); themeText(b, "SubText"); addCorner(b, UDim.new(0,6))
        return b
    end
    local btnClose = mkBtn("x", -32, Theme.Danger)
    local btnMin = mkBtn("-", -58, Theme.ElementHover)
    local minimized = false
    local restoreSize = UDim2.new(0,Config.WindowWidth,0,Config.WindowHeight)
    btnMin.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            restoreSize = main.Size
            tween(main, {Size = UDim2.new(0,main.AbsoluteSize.X,0,40)}, 0.15)
        else tween(main, {Size = restoreSize}, 0.15) end
    end)

    local sidebar = new("Frame", {BorderSizePixel = 0,
        Position = UDim2.new(0,0,0,40), Size = UDim2.new(0,168,1,-62), ZIndex = 2,
        BackgroundTransparency = 1}, main)
    themeBg(sidebar, "Sidebar"); regTransparency(sidebar, "Menu", 0)
    addCorner(sidebar, UDim.new(0,8))
    themeBg(new("Frame", {BorderSizePixel = 0, Position = UDim2.new(0,0,0,0),
        Size = UDim2.new(1,0,0,1), ZIndex = 3}, sidebar), "Outline")
    local sidebarScroll = new("ScrollingFrame", {BackgroundTransparency = 1, BorderSizePixel = 0,
        Position = UDim2.new(0,8,0,8), Size = UDim2.new(1,-16,1,-16),
        CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Accent, ZIndex = 5}, sidebar)
    new("UIListLayout", {Padding = UDim.new(0,4), SortOrder = Enum.SortOrder.LayoutOrder}, sidebarScroll)
    local pageHolder = new("Frame", {BackgroundTransparency = 1,
        Position = UDim2.new(0,168,0,40), Size = UDim2.new(1,-168,1,-62), ZIndex = 2}, main)
    addPadding(pageHolder, 12)
    local pageInner = new("Frame", {BackgroundTransparency = 1,
        Size = UDim2.new(1,0,1,0), ZIndex = 2}, pageHolder)
    local statusBar = new("Frame", {BorderSizePixel = 0,
        Position = UDim2.new(0,0,1,-22), Size = UDim2.new(1,0,0,22),
        ZIndex = 5, Visible = Config.StatusBar, BackgroundTransparency = 1}, main)
    new("Frame", {BackgroundColor3 = Theme.Outline, BorderSizePixel = 0,
        Position = UDim2.new(0,0,0,0), Size = UDim2.new(1,0,0,1), ZIndex = 6}, statusBar)
    local leftLbl = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0,12,0,0),
        Size = UDim2.new(0.4,-10,1,0), Font = Config.CurrentFontFamily, Text = "ready",
        TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6}, statusBar)
    themeText(leftLbl, "Accent")
    local midLbl = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0.4,0,0,0),
        Size = UDim2.new(0.3,0,1,0), Font = Config.CurrentFontFamily, Text = "players: 0",
        TextSize = 10, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 6}, statusBar)
    themeText(midLbl, "SubText")
    local rightLbl = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0.7,0,0,0),
        Size = UDim2.new(0.3,-10,1,0), Font = Config.CurrentFontFamily, Text = "fps: 0",
        TextSize = 10, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 6}, statusBar)
    themeText(rightLbl, "SubText")
    task.spawn(function()
        local startT = tick()
        while statusBar.Parent do
            local ping = getPing()
            rightLbl.Text = string.format("fps: %d  ping: %dms", currentFPS, ping)
            midLbl.Text = string.format("players: %d/%d", #Players:GetPlayers(), Players.MaxPlayers)
            local up = tick() - startT
            leftLbl.Text = string.format("%s  up: %02d:%02d", opts.Name or "airhubUI",
                math.floor(up/60), math.floor(up%60))
            task.wait(0.5)
        end
    end)
    local resizeHandle = new("TextButton", {BackgroundTransparency = 1,
        Position = UDim2.new(1,-18,1,-22-16), Size = UDim2.new(0,16,0,16), Text = "", ZIndex = 6}, main)
    for i = 1, 3 do
        new("Frame", {BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.4, BorderSizePixel = 0,
            Position = UDim2.new(0,4+(3-i)*3,1,-4-(i-1)*3), Size = UDim2.new(0,2,0,2), ZIndex = 7}, resizeHandle)
    end

    local function applyFontToAll()
        for _, d in ipairs(gui:GetDescendants()) do
            if d:IsA("TextLabel") or d:IsA("TextBox") or d:IsA("TextButton") then
                local base = d:GetAttribute("_baseTextSize")
                if not base then base = d.TextSize; d:SetAttribute("_baseTextSize", base) end
                d.Font = Config.CurrentFontFamily
                d.TextSize = math.clamp(math.floor(base * Config.CurrentFontScale + 0.5), 6, 48)
            end
        end
    end

    window = {GUI = gui, Main = main, TitleBar = titlebar, Sidebar = sidebar,
        SidebarList = sidebarScroll, PageHolder = pageInner, Overlay = Overlay,
        Tabs = {}, ActiveTab = nil, Name = opts.Name or "airhubUI", OnUnload = opts.OnUnload,
        Theme = Theme, Config = Config, _animScale = animScale,
        _isOpen = true,
        _hiding = false, _showing = false,
        _titleLbl = titleLbl, _statusBar = statusBar}

    -- ────────────────────────────────────────────────────────────
    -- FIXED Show/Hide/Toggle — сохраняет позицию перетаскивания
    -- ────────────────────────────────────────────────────────────
    local _lastToggleTime = 0
    local _toggleCooldown = 0.1

    -- ─── ИЗМЕНЕНИЕ 2: _forceHidden больше не сбрасывает Position ────────
    local function _forceHidden()
        gui.Enabled = false
        -- Позиция НЕ сбрасывается — окно остаётся там, где его закрыли.
        -- currentHomePos уже хранит правильное значение для будущего Show.
        main.BackgroundTransparency = Config.MenuTransparency
        shadowFrame.BackgroundTransparency = 0.8
        if animScale then animScale.Scale = 1 end
    end

    -- ─── ИЗМЕНЕНИЕ 3: Show анимирует из (currentHomePos + 30px) в currentHomePos
    function window:Show()
        if self._isOpen then return end
        self._isOpen = true
        self._hiding = false
        closeAllPopups()
        gui.Enabled = true
        local hiddenPos = getHiddenPos()
        main.Position = hiddenPos
        main.BackgroundTransparency = math.min(1, Config.MenuTransparency + 0.45)
        shadowFrame.Position = hiddenPos
        shadowFrame.BackgroundTransparency = 1
        if animScale then animScale.Scale = 0.88 end
        tween(main, {Position = currentHomePos, BackgroundTransparency = Config.MenuTransparency},
            Config.MenuAnim, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        tween(shadowFrame, {Position = currentHomePos, BackgroundTransparency = 0.8},
            Config.MenuAnim, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        if animScale then
            tween(animScale, {Scale = 1}, Config.MenuAnim, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        end
    end

    -- ─── ИЗМЕНЕНИЕ 4: Hide анимирует в (currentHomePos + 30px) вниз
    function window:Hide()
        if not self._isOpen then
            if gui.Enabled then _forceHidden() end
            return
        end
        self._isOpen = false
        self._hiding = true
        pcall(closeAllPopups)
        local animTime = Config.MenuCloseAnim
        local hiddenPos = getHiddenPos()
        tween(main, {Position = hiddenPos,
            BackgroundTransparency = math.min(1, Config.MenuTransparency + 0.45)},
            animTime, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        tween(shadowFrame, {Position = hiddenPos, BackgroundTransparency = 1},
            animTime, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        if animScale then
            tween(animScale, {Scale = 0.88}, animTime, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        end
        task.delay(animTime + 0.02, function()
            if not self._isOpen then
                _forceHidden()
            end
            self._hiding = false
        end)
        task.spawn(function()
            task.wait(animTime + 0.5)
            if not self._isOpen and gui.Enabled then
                _forceHidden()
                self._hiding = false
            end
        end)
    end

    function window:Toggle()
        local now = tick()
        if now - _lastToggleTime < _toggleCooldown then return end
        _lastToggleTime = now
        if self._isOpen then
            self:Hide()
        else
            self:Show()
        end
    end

    btnClose.MouseButton1Click:Connect(function()
        window:Hide()
    end)

    function window:SetLanguage(lang)
        if not L[lang] then return false end
        Config.Language = lang
        for _, d in ipairs(gui:GetDescendants()) do
            if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
                local k = d:GetAttribute("_tKey")
                if k then d.Text = T(k) end
                local pk = d:GetAttribute("_tPlaceholder")
                if pk then d.PlaceholderText = T(pk) end
            end
        end
        for _, tab in ipairs(self.Tabs) do
            if tab._refreshLang then tab._refreshLang() end
        end
        return true
    end

    function window:SelectTab(tab)
        if self.ActiveTab == tab then return end
        closeAllPopups()
        for _, t in ipairs(self.Tabs) do
            t.Page.Visible = false
            if t._refresh then t._refresh() end
            if t.AccentDot then t.AccentDot.Visible = false end
        end
        tab.Page.Visible = true
        if tab._refresh then tab._refresh() end
        if tab.AccentDot then tab.AccentDot.Visible = true end
        self.ActiveTab = tab
    end
    function window:AddTab(o)
        o = o or {}
        local t = createTab(self, o)
        self.Tabs[#self.Tabs+1] = t
        if #self.Tabs == 1 then self:SelectTab(t) end
        return t
    end

    function window:SetSearch(q) searchBox.Text = q or ""; searchBox:ReleaseFocus() end
    function window:SetTitle(text)
        if self._titleLbl then self._titleLbl.Text = text end
        self.Name = text
    end

    local BUILTIN_TABS = { tab_settings = true, tab_configs = true, tab_binds = true }

    local function serializeElemKey(v)
        if v == nil then return "" end
        if typeof(v) == "EnumItem" then return tostring(v) end
        if type(v) == "string" then return v end
        return tostring(v)
    end

    local function deserializeElemKey(s)
        if type(s) ~= "string" then return s end
        if s == "" or s == "nil" then return nil end
        local enumType, enumName = s:match("^Enum%.(%w+)%.(%w+)$")
        if enumType and enumName then
            local ok, val = pcall(function() return Enum[enumType][enumName] end)
            if ok and val then return val end
        end
        return s
    end

    local function isFiniteNum(n)
        return type(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge
    end

    function window:ExportSettings()
        local data = {Theme = {}, Config = {}}
        for k, v in pairs(Theme) do
            if typeof(v) == "Color3" then data.Theme[k] = {v.R, v.G, v.B} end
        end
        for k, v in pairs(Config) do
            if isFiniteNum(v) then data.Config[k] = v
            elseif type(v) == "string" or type(v) == "boolean" then data.Config[k] = v end
        end
        local elemsOk, elems = pcall(function()
            local elems = {}
            for _, tab in ipairs(self.Tabs) do
                local tabId = tab._nameKey or tab.Name
                if tabId and not BUILTIN_TABS[tabId] then
                    local tabData = {}
                    local function collectSections(tbl, sectionsList)
                        for _, section in ipairs(sectionsList) do
                            local secId = section._tKey or section.Name
                            if secId then
                                local secData = {}
                                for _, el in ipairs(section.Elements) do
                                    local elId = el._rawName
                                    local elType = (el._meta and el._meta.Type) or el._type
                                    if elId and el.Get and elType then
                                        if elType == "Colorpicker" then
                                            local ok, c, a, rbData = pcall(el.Get)
                                            if ok and typeof(c) == "Color3" then
                                                secData[elId] = {
                                                    r = c.R, g = c.G, b = c.B, alpha = isFiniteNum(a) and a or 0,
                                                    rainbowEnabled = rbData and rbData.rainbowEnabled or false,
                                                    rainbowSpeed = rbData and rbData.rainbowSpeed or 1
                                                }
                                            end
                                        elseif elType == "Keybind" then
                                            local ok, v = pcall(el.Get)
                                            if ok then secData[elId] = serializeElemKey(v) end
                                        elseif elType == "Button" then
                                        else
                                            local ok, v = pcall(el.Get)
                                            if ok then
                                                if type(v) == "boolean" or type(v) == "string" then
                                                    secData[elId] = v
                                                elseif isFiniteNum(v) then
                                                    secData[elId] = v
                                                end
                                            end
                                        end
                                    end
                                end
                                if next(secData) then tbl[secId] = secData end
                            end
                        end
                    end
                    collectSections(tabData, tab.Sections)
                    for _, subTab in ipairs(tab.SubTabs) do
                        local subId = "__sub_" .. (subTab._nameKey or subTab.Name)
                        local subData = {}
                        collectSections(subData, subTab.Sections)
                        if next(subData) then tabData[subId] = subData end
                    end
                    if next(tabData) then elems[tabId] = tabData end
                end
            end
            return elems
        end)
        if elemsOk and elems and next(elems) then
            data.Elements = elems
        elseif not elemsOk then
            warn("[airhubUI] Elements serialization failed: " .. tostring(elems))
        end
        local ok, str = pcall(function() return HttpService:JSONEncode(data) end)
        if not ok or type(str) ~= "string" then
            warn("[airhubUI] Export JSON encode failed: " .. tostring(str))
            return nil
        end
        return str
    end

    function window:ImportSettings(str)
        if not str or str == "" then return false, "empty" end
        local ok, data = pcall(function() return HttpService:JSONDecode(str) end)
        if not ok or type(data) ~= "table" then return false, "invalid JSON" end
        if data.Theme then
            for k, v in pairs(data.Theme) do
                if type(v) == "table" and #v == 3 then Theme[k] = Color3.new(v[1], v[2], v[3]) end
            end
            refreshTheme()
        end
        if data.Config then
            for k, v in pairs(data.Config) do
                if Config[k] ~= nil then Config[k] = v end
            end
            if Config.NotificationPosition then resetNotifHolder() end
            if statusBar and Config.StatusBar ~= nil then statusBar.Visible = Config.StatusBar end
            if L[Config.Language] then self:SetLanguage(Config.Language) end
            applyFontToAll()
        end
        if type(data.Elements) == "table" then
            local elemsOk, elemsErr = pcall(function()
                for _, tab in ipairs(self.Tabs) do
                    local tabId = tab._nameKey or tab.Name
                    if tabId and not BUILTIN_TABS[tabId] then
                        local tabData = data.Elements[tabId]
                        if type(tabData) == "table" then
                            local function applySections(tbl, sectionsList)
                                for _, section in ipairs(sectionsList) do
                                    local secId = section._tKey or section.Name
                                    local secData = secId and tbl[secId]
                                    if type(secData) == "table" then
                                        for _, el in ipairs(section.Elements) do
                                            local elId = el._rawName
                                            local elType = (el._meta and el._meta.Type) or el._type
                                            local savedVal = elId and secData[elId]
                                            if elId and el.Set and elType and savedVal ~= nil then
                                                if elType == "Colorpicker" then
                                                    if type(savedVal) == "table" and isFiniteNum(savedVal.r) then
                                                        local c = Color3.new(savedVal.r, savedVal.g, savedVal.b)
                                                        local rbData = {
                                                            rainbowEnabled = savedVal.rainbowEnabled or false,
                                                            rainbowSpeed = savedVal.rainbowSpeed or 1
                                                        }
                                                        pcall(el.Set, c, savedVal.alpha or 0, rbData)
                                                    end
                                                elseif elType == "Keybind" then
                                                    pcall(el.Set, deserializeElemKey(savedVal))
                                                elseif elType == "Button" then
                                                else
                                                    pcall(el.Set, savedVal)
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                            applySections(tabData, tab.Sections)
                            for _, subTab in ipairs(tab.SubTabs) do
                                local subId = "__sub_" .. (subTab._nameKey or subTab.Name)
                                local subData = tabData[subId]
                                if type(subData) == "table" then
                                    applySections(subData, subTab.Sections)
                                end
                            end
                        end
                    end
                end
            end)
            if not elemsOk then
                warn("[airhubUI] Elements import failed: " .. tostring(elemsErr))
            end
            pcall(reevaluateVisibility)
        end
        for _, t in ipairs(self.Tabs) do if t._refresh then t._refresh() end end
        return true
    end

    function window:GetUIState()
        local str = self:ExportSettings()
        if not str then return nil end
        local ok, data = pcall(function() return HttpService:JSONDecode(str) end)
        return ok and data or nil
    end

    function window:SetUIState(dataTable)
        if type(dataTable) ~= "table" then return false end
        local ok, str = pcall(function() return HttpService:JSONEncode(dataTable) end)
        if not ok then return false end
        return self:ImportSettings(str)
    end

    function window:SaveConfigToDisk(name)
        local str = self:ExportSettings()
        if not str then return false, "export failed" end
        return writeConfigFile(name, str)
    end
    function window:LoadConfigFromDisk(name)
        local str, err = readConfigFile(name)
        if not str then return false, err or "not found" end
        return self:ImportSettings(str)
    end
    function window:DeleteConfigFromDisk(name) return deleteConfigFile(name) end
    function window:ListDiskConfigs() return listDiskConfigs() end
    function window:IsFilesystemAvailable() return fsAvailable() end

    function window:ApplyFullTheme(preset)
        if type(preset) ~= "table" then return end
        local newFont = preset.Font
        local newScale = preset.FontSize
        for k, v in pairs(preset) do
            if k ~= "Font" and k ~= "FontSize" and Theme[k] ~= nil and typeof(v) == "Color3" then
                Theme[k] = v
            end
        end
        refreshTheme()
        for _, t in ipairs(self.Tabs) do if t._refresh then t._refresh() end end
        if newFont and FontCatalog[newFont] then
            Config.CurrentFontName = newFont
            Config.CurrentFontFamily = FontCatalog[newFont]
        end
        if newScale then Config.CurrentFontScale = tonumber(newScale) or 1 end
        applyFontToAll()
    end

    function window:Configure(cfg)
        cfg = cfg or {}
        local needRefresh = false
        local needFont = false
        for k, v in pairs(cfg) do
            if k == "CornerRadius" and type(v) == "number" then
                local delta = v - Config.BaseCornerRadius
                for _, d in ipairs(gui:GetDescendants()) do
                    if d:IsA("UICorner") then
                        local bs = d:GetAttribute("_baseRadius")
                        if bs and bs >= 0 then d.CornerRadius = UDim.new(0, math.max(0, bs + delta)) end
                    end
                end
            elseif k == "MenuTransparency" or k == "TabTransparency"
                or k == "SectionTransparency" or k == "ElementTransparency" then
                Config[k] = math.clamp(tonumber(v) or 0, 0, 1)
                applyTransparencyTo((k:gsub("Transparency","")))
            elseif k == "StatusBar" then
                Config.StatusBar = v and true or false
                if statusBar then statusBar.Visible = Config.StatusBar end
            elseif k == "SidebarWidth" and type(v) == "number" then
                local w = math.clamp(v, 100, 260)
                sidebar.Size = UDim2.new(0,w,1,-62)
                pageHolder.Position = UDim2.new(0,w,0,40)
                pageHolder.Size = UDim2.new(1,-w,1,-62)
            elseif k == "MenuAnimSpeed" and type(v) == "number" then
                Config.MenuAnim = math.clamp(v, 0.1, 1.0)
            elseif k == "MenuCloseAnimSpeed" and type(v) == "number" then
                Config.MenuCloseAnim = math.clamp(v, 0.1, 1.0)
            elseif k == "PopupAnimSpeed" and type(v) == "number" then
                Config.PopupAnim = math.clamp(v, 0.05, 0.5)
            elseif k == "NotificationDuration" and type(v) == "number" then
                Config.NotificationDuration = math.clamp(v, 0.5, 10)
            elseif k == "NotificationPosition" and type(v) == "string" then
                Config.NotificationPosition = v; resetNotifHolder()
            elseif k == "TooltipDelay" and type(v) == "number" then
                Config.TooltipDelay = math.clamp(v, 0, 1)
            elseif k == "WindowWidth" and type(v) == "number" then
                Config.WindowWidth = math.clamp(v, Config.MinWidth, 1400)
                if not minimized then 
                    main.Size = UDim2.new(0, Config.WindowWidth, 0, main.Size.Y.Offset) 
                    shadowFrame.Size = UDim2.new(0, Config.WindowWidth + 20, 0, shadowFrame.Size.Y.Offset)
                end
            elseif k == "WindowHeight" and type(v) == "number" then
                Config.WindowHeight = math.clamp(v, Config.MinHeight, 1000)
                if not minimized then 
                    main.Size = UDim2.new(0, main.Size.X.Offset, 0, Config.WindowHeight) 
                    shadowFrame.Size = UDim2.new(0, shadowFrame.Size.X.Offset, 0, Config.WindowHeight + 20)
                end
            elseif k == "FontFamily" and type(v) == "string" then
                if FontCatalog[v] then Config.CurrentFontFamily = FontCatalog[v]; Config.CurrentFontName = v; needFont = true end
            elseif k == "FontScale" and type(v) == "number" then
                Config.CurrentFontScale = math.clamp(v, 0.6, 2.0); needFont = true
            elseif Theme[k] ~= nil then
                Theme[k] = v; needRefresh = true
            end
        end
        if needRefresh then
            refreshTheme()
            for _, t in ipairs(self.Tabs) do if t._refresh then t._refresh() end end
        end
        if needFont then applyFontToAll() end
    end
    function window:SetTransparency(cat, v)
        v = math.clamp(tonumber(v) or 0, 0, 1)
        local key = cat .. "Transparency"
        if Config[key] ~= nil then Config[key] = v; applyTransparencyTo(cat) end
    end

    -- ─── ИЗМЕНЕНИЕ 5: drag-обработчик обновляет currentHomePos ──────────
    local drag, dStart, sPos, shadowPos
    titlebar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            drag = true; dStart = i.Position; sPos = main.Position; shadowPos = shadowFrame.Position; closeAllPopups()
        end
    end)
    _T(UserInputService.InputChanged:Connect(function(i)
        if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - dStart
            main.Position = UDim2.new(sPos.X.Scale, sPos.X.Offset + d.X, sPos.Y.Scale, sPos.Y.Offset + d.Y)
            shadowFrame.Position = UDim2.new(shadowPos.X.Scale, shadowPos.X.Offset + d.X, shadowPos.Y.Scale, shadowPos.Y.Offset + d.Y)
            -- Обновляем "домашнюю" позицию: при следующем Hide/Show будем использовать её
            currentHomePos = main.Position
        end
    end))
    _T(UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end end))

    local rz, rStart, rInit
    resizeHandle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            rz = true; rStart = i.Position; rInit = main.Size
        end
    end)
    _T(UserInputService.InputChanged:Connect(function(i)
        if rz and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - rStart
            local newW = math.max(Config.MinWidth, rInit.X.Offset + d.X)
            local newH = math.max(Config.MinHeight, rInit.Y.Offset + d.Y)
            main.Size = UDim2.new(0, newW, 0, newH)
            shadowFrame.Size = UDim2.new(0, newW + 20, 0, newH + 20)
        end
    end))
    _T(UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then rz = false end end))

    _T(UserInputService.InputBegan:Connect(function(i, gpe)
        if bindListening then return end
        if i.KeyCode == Enum.KeyCode.RightShift then
            window:Toggle()
        elseif i.KeyCode == Enum.KeyCode.Escape then
            if #PopupStack == 0 and window._isOpen then
                window:Hide()
            end
        end
    end))

    function window:Unload()
        if type(self.OnUnload) == "function" then pcall(self.OnUnload, self) end
        closeAllPopups()
        self._isOpen = false
        self._hiding = false
        self._showing = false
        for _, c in ipairs(AllConnections) do pcall(function() c:Disconnect() end) end
        AllConnections = {}
        for k in pairs(BindRegistry) do BindRegistry[k] = nil end
        BindOrder = {}
        RainbowControllers = {}
        pcall(function() gui:Destroy() end)
        NotificationHolder = nil; Overlay = nil; Tooltip = nil
    end
    function window:Destroy() self:Unload() end
    return window
end

-- ══════════════════════════════════════════════════════════════
-- LIB EXPORT
-- ══════════════════════════════════════════════════════════════
local airhubUILib = {
    CreateWindow = createWindow, Notify = Notify, Theme = Theme, Config = Config,
    ThemePresets = ThemePresets, FontCatalog = FontCatalog, T = T, L = L,
    BindRegistry = BindRegistry, BindOrder = BindOrder,
    AddBindKey = AddBindKey, RemoveBindKey = RemoveBindKey, ClearBind = ClearBind,
    CloseAllPopups = closeAllPopups, RefreshTheme = refreshTheme,
    GetFPS = function() return currentFPS end, GetPing = getPing,
    GetLanguage = function() return Config.Language end,
    ConfigFolder = CONFIG_FOLDER, ListDiskConfigs = listDiskConfigs,
    IsFilesystemAvailable = fsAvailable,
}

-- ══════════════════════════════════════════════════════════════
-- MAIN WINDOW
-- ══════════════════════════════════════════════════════════════
local Window = airhubUILib.CreateWindow({Name = "airhubUI"})
airhubUILib.Window = Window

-- ══════════════════════════════════════════════════════════════
-- SETTINGS TAB
-- ══════════════════════════════════════════════════════════════
local tabSettings = Window:AddTab({Name = "tab_settings", Icon = ">"})

local secGeneral = tabSettings:CreateSection({Name = "sec_general"})
local langLabelToCode = { ["English"] = "en", ["Русский"] = "ru" }
local codeToLangLabel = { en = "English", ru = "Русский" }

secGeneral:AddDropdown({
    Name = "lbl_language",
    Value = codeToLangLabel[Config.Language] or "English",
    List = { L.en.lang_en, L.ru.lang_ru },
    Callback = function(v)
        local code = langLabelToCode[v] or "en"
        Window:SetLanguage(code)
        Notify("airhubUI", T("n_lang_changed", L[code].lang_en), "success")
    end,
    Tooltip = "tt_language",
})

local secTheme = tabSettings:CreateSection({Name = "sec_theme"})
secTheme:AddDropdown({Name = "lbl_preset", Value = "airhubUI Light",
    List = (function()
        local t = {}
        for k in pairs(ThemePresets) do t[#t+1] = k end
        table.sort(t)
        return t
    end)(),
    Callback = function(v)
        local p = ThemePresets[v]
        if not p then return end
        Window:ApplyFullTheme(p)
        Notify("airhubUI", T("n_theme_applied", v), "success")
    end,
    Tooltip = "tt_preset"})

local secWindowSize = tabSettings:CreateSection({Name = "sec_window", Side = "Right"})
secWindowSize:AddInput({Name = "lbl_title", Placeholder = "ph_airhubui", Value = "airhubUI",
    Callback = function(v) Window:SetTitle(v or "airhubUI") end, Tooltip = "tt_title"})
secWindowSize:AddSlider({Name = "lbl_width", Value = 720, Min = 520, Max = 1200, Decimals = 0,
    Callback = function(v) Window:Configure({WindowWidth = v}) end, Tooltip = "tt_width"})
secWindowSize:AddSlider({Name = "lbl_height", Value = 500, Min = 380, Max = 900, Decimals = 0,
    Callback = function(v) Window:Configure({WindowHeight = v}) end, Tooltip = "tt_height"})
secWindowSize:AddSlider({Name = "lbl_sidebar_width", Value = 168, Min = 100, Max = 260,
    Callback = function(v) Window:Configure({SidebarWidth = v}) end, Tooltip = "tt_sidebar_width"})
secWindowSize:AddSlider({Name = "lbl_corner_radius", Value = 8, Min = 0, Max = 24,
    Callback = function(v) Window:Configure({CornerRadius = v}) end, Tooltip = "tt_corner_radius"})
secWindowSize:AddToggle({Name = "lbl_status_bar", Value = true,
    Callback = function(v) Window:Configure({StatusBar = v}) end, Tooltip = "tt_status_bar"})

local secFont = tabSettings:CreateSection({Name = "sec_font", Side = "Right"})
secFont:AddDropdown({Name = "lbl_font_family", Value = Config.CurrentFontName,
    List = (function()
        local t = {}
        for k in pairs(FontCatalog) do t[#t+1] = k end
        table.sort(t)
        return t
    end)(),
    Callback = function(v) Window:Configure({FontFamily = v}) end, Tooltip = "tt_font_family"})
secFont:AddSlider({Name = "lbl_font_size", Value = 1.0, Min = 0.6, Max = 1.8, Decimals = 2,
    Callback = function(v) Window:Configure({FontScale = v}) end, Tooltip = "tt_font_size"})

local secAnim = tabSettings:CreateSection({Name = "sec_anim"})
secAnim:AddSlider({Name = "lbl_menu_open", Value = Config.MenuAnim, Min = 0.1, Max = 1.0, Decimals = 2,
    Callback = function(v) Window:Configure({MenuAnimSpeed = v}) end, Tooltip = "tt_menu_open"})
secAnim:AddSlider({Name = "lbl_menu_close", Value = Config.MenuCloseAnim, Min = 0.1, Max = 1.0, Decimals = 2,
    Callback = function(v) Window:Configure({MenuCloseAnimSpeed = v}) end, Tooltip = "tt_menu_close"})
secAnim:AddSlider({Name = "lbl_popup_speed", Value = Config.PopupAnim, Min = 0.05, Max = 0.5, Decimals = 2,
    Callback = function(v) Window:Configure({PopupAnimSpeed = v}) end, Tooltip = "tt_popup_speed"})

local secWindowColors = tabSettings:CreateSection({Name = "sec_menu_colors", Side = "Right"})
secWindowColors:AddColorpicker({Name = "lbl_menu_bg", Default = Theme.Background,
    Callback = function(c) Window:Configure({Background = c}) end, Tooltip = "tt_menu_bg"})
secWindowColors:AddColorpicker({Name = "lbl_sidebar", Default = Theme.Sidebar,
    Callback = function(c) Window:Configure({Sidebar = c}) end, Tooltip = "tt_sidebar"})
secWindowColors:AddColorpicker({Name = "lbl_panel", Default = Theme.Panel,
    Callback = function(c) Window:Configure({Panel = c}) end, Tooltip = "tt_panel"})
secWindowColors:AddColorpicker({Name = "lbl_section_bg", Default = Theme.Section,
    Callback = function(c) Window:Configure({Section = c}) end, Tooltip = "tt_section_bg"})
secWindowColors:AddColorpicker({Name = "lbl_element", Default = Theme.Element,
    Callback = function(c) Window:Configure({Element = c}) end, Tooltip = "tt_element"})
secWindowColors:AddColorpicker({Name = "lbl_element_hover", Default = Theme.ElementHover,
    Callback = function(c) Window:Configure({ElementHover = c}) end, Tooltip = "tt_element_hover"})
secWindowColors:AddColorpicker({Name = "lbl_outline", Default = Theme.Outline,
    Callback = function(c) Window:Configure({Outline = c}) end, Tooltip = "tt_outline"})

local secText = tabSettings:CreateSection({Name = "sec_text_colors"})
secText:AddColorpicker({Name = "lbl_text", Default = Theme.Text,
    Callback = function(c) Window:Configure({Text = c}) end, Tooltip = "tt_text"})
secText:AddColorpicker({Name = "lbl_subtext", Default = Theme.SubText,
    Callback = function(c) Window:Configure({SubText = c}) end, Tooltip = "tt_subtext"})
secText:AddColorpicker({Name = "lbl_muted", Default = Theme.Muted,
    Callback = function(c) Window:Configure({Muted = c}) end, Tooltip = "tt_muted"})

local secAccent = tabSettings:CreateSection({Name = "sec_accent", Side = "Right"})
secAccent:AddColorpicker({Name = "lbl_accent", Default = Theme.Accent,
    Callback = function(c) Window:Configure({Accent = c}) end, Tooltip = "tt_accent"})
secAccent:AddColorpicker({Name = "lbl_accent2", Default = Theme.Accent2,
    Callback = function(c) Window:Configure({Accent2 = c}) end, Tooltip = "tt_accent2"})
secAccent:AddColorpicker({Name = "lbl_success", Default = Theme.Success,
    Callback = function(c) Window:Configure({Success = c}) end, Tooltip = "tt_success"})
secAccent:AddColorpicker({Name = "lbl_danger", Default = Theme.Danger,
    Callback = function(c) Window:Configure({Danger = c}) end, Tooltip = "tt_danger"})
secAccent:AddColorpicker({Name = "lbl_warning", Default = Theme.Warning,
    Callback = function(c) Window:Configure({Warning = c}) end, Tooltip = "tt_warning"})
secAccent:AddColorpicker({Name = "lbl_on_accent", Default = Theme.OnAccent,
    Callback = function(c) Window:Configure({OnAccent = c}) end, Tooltip = "tt_on_accent"})

local secTrans = tabSettings:CreateSection({Name = "sec_transparency"})
secTrans:AddSlider({Name = "lbl_transparency_menu", Value = Config.MenuTransparency, Min = 0, Max = 0.5, Decimals = 2,
    Callback = function(v) Window:SetTransparency("Menu", v) end, Tooltip = "tt_transparency_menu"})
secTrans:AddSlider({Name = "lbl_transparency_tabs", Value = 0, Min = 0, Max = 0.5, Decimals = 2,
    Callback = function(v) Window:SetTransparency("Tab", v) end, Tooltip = "tt_transparency_tabs"})
secTrans:AddSlider({Name = "lbl_transparency_sections", Value = 0, Min = 0, Max = 0.5, Decimals = 2,
    Callback = function(v) Window:SetTransparency("Section", v) end, Tooltip = "tt_transparency_sections"})
secTrans:AddSlider({Name = "lbl_transparency_elements", Value = 0, Min = 0, Max = 0.5, Decimals = 2,
    Callback = function(v) Window:SetTransparency("Element", v) end, Tooltip = "tt_transparency_elements"})

local secNotif = tabSettings:CreateSection({Name = "sec_notifications", Side = "Right"})
secNotif:AddSlider({Name = "lbl_duration", Value = Config.NotificationDuration, Min = 0.5, Max = 10, Decimals = 1,
    Callback = function(v) Window:Configure({NotificationDuration = v}) end, Tooltip = "tt_duration"})
secNotif:AddDropdown({Name = "lbl_position", Value = "top-right",
    List = {"top-right", "top-left", "bottom-right", "bottom-left"},
    Callback = function(v) Window:Configure({NotificationPosition = v}) end, Tooltip = "tt_position"})
secNotif:AddButton({Name = "btn_test_notif", Callback = function()
    Notify(T("n_test_notif_title"), T("n_test_notif_text"), "success", 2)
end, Tooltip = "tt_test_notif"})

local secTooltip = tabSettings:CreateSection({Name = "sec_tooltips"})
secTooltip:AddSlider({Name = "lbl_delay", Value = Config.TooltipDelay, Min = 0, Max = 1, Decimals = 2,
    Callback = function(v) Window:Configure({TooltipDelay = v}) end, Tooltip = "tt_delay"})

local secActions = tabSettings:CreateSection({Name = "sec_actions", Side = "Right"})
secActions:AddButton({Name = "btn_reset_light", Callback = function()
    Window:ApplyFullTheme(ThemePresets["airhubUI Light"])
    Notify("airhubUI", T("n_theme_reset_light"), "success")
end, Tooltip = "tt_reset_light"})
secActions:AddButton({Name = "btn_reset_dark", Callback = function()
    Window:ApplyFullTheme(ThemePresets["airhubUI Dark"])
    Notify("airhubUI", T("n_theme_reset_dark"), "success")
end, Tooltip = "tt_reset_dark"})
secActions:AddButton({Name = "btn_unload", Callback = function()
    Notify("airhubUI", T("n_unloading"), "warning", 1.5)
    task.wait(0.5)
    Window:Unload()
end, Tooltip = "tt_unload"})
secActions:AddButton({Name = "btn_reshow", Callback = function() Window:Show() end, Tooltip = "tt_reshow"})

-- ══════════════════════════════════════════════════════════════
-- CONFIGS TAB
-- ══════════════════════════════════════════════════════════════
local tabConfigs = Window:AddTab({Name = "tab_configs", Icon = ">"})

local secFileConfigs = tabConfigs:CreateSection({Name = "sec_file_configs"})
secFileConfigs:AddLabel({Text = T("lbl_folder_path", CONFIG_FOLDER, ROOT_PREFIX)})
secFileConfigs:AddLabel({
    Text = fsAvailable() and T("lbl_fs_available") or T("lbl_fs_unavailable"),
    Color = fsAvailable() and Theme.Success or Theme.Warning,
})

local fileNameRef = secFileConfigs:AddInput({
    Name = "lbl_config_name", Placeholder = "ph_my_config", Value = "",
    Tooltip = "tt_config_name",
})

local configsList = listDiskConfigs()
local configDropdownRef = secFileConfigs:AddDropdown({
    Name = "lbl_saved_configs",
    Value = (#configsList > 0) and configsList[1] or "",
    List = configsList,
    Tooltip = "tt_saved_configs",
})

local function refreshConfigDropdown()
    local list = listDiskConfigs()
    if configDropdownRef and configDropdownRef._setList then
        configDropdownRef._setList(list)
    end
    if configDropdownRef then
        configDropdownRef._setValue(#list > 0 and list[1] or "")
    end
end

secFileConfigs:AddDivider({Text = "lbl_actions"})

secFileConfigs:AddButton({Name = "btn_save_file", Callback = function()
    local name = fileNameRef:Get()
    if not name or name == "" then Notify("airhubUI", T("n_enter_name"), "warning"); return end
    if not fsAvailable() then
        local str = Window:ExportSettings()
        if str and trySetClipboard(str) then
            Notify("airhubUI", T("n_fs_unavail_clipboard"), "warning", 5)
        elseif str then
            print("[airhubUI Config] " .. str)
            Notify("airhubUI", T("n_fs_unavail_console"), "warning", 5)
        else
            Notify("airhubUI", T("n_save_failed", "export failed"), "error", 8)
        end
        return
    end
    local ok, err = Window:SaveConfigToDisk(name)
    if ok then
        Notify("airhubUI", T("n_saved_to", name), "success", 5)
        refreshConfigDropdown()
    else
        Notify("airhubUI", T("n_save_failed", tostring(err)), "error", 8)
    end
end, Tooltip = "tt_save_file"})

secFileConfigs:AddButton({Name = "btn_load_file", Callback = function()
    local name = configDropdownRef:Get() or fileNameRef:Get()
    if not name or name == "" then Notify("airhubUI", T("n_enter_name"), "warning"); return end
    if not fsAvailable() then
        local str = tryGetClipboard()
        if str and str ~= "" then
            local ok, err = Window:ImportSettings(str)
            if ok then Notify("airhubUI", T("n_loaded_clipboard"), "success")
            else Notify("airhubUI", T("n_invalid", tostring(err)), "error") end
        else Notify("airhubUI", T("n_clipboard_empty"), "error") end
        return
    end
    local ok, err = Window:LoadConfigFromDisk(name)
    if ok then Notify("airhubUI", T("n_loaded", name), "success")
    else Notify("airhubUI", T("n_load_failed", tostring(err)), "error", 8) end
end, Tooltip = "tt_load_file"})

secFileConfigs:AddButton({Name = "btn_delete_file", Callback = function()
    local name = configDropdownRef:Get() or fileNameRef:Get()
    if not name or name == "" then Notify("airhubUI", T("n_enter_name"), "warning"); return end
    if not canDelete() then Notify("airhubUI", T("n_delfile_missing"), "error"); return end
    local ok, err = Window:DeleteConfigFromDisk(name)
    if ok then
        Notify("airhubUI", T("n_deleted", name), "warning")
        refreshConfigDropdown()
    else
        Notify("airhubUI", T("n_delete_failed", tostring(err or "?")), "error", 8)
    end
end, Tooltip = "tt_delete_file"})

secFileConfigs:AddButton({Name = "btn_refresh_list", Callback = function()
    refreshConfigDropdown()
    Notify("airhubUI", T("n_list_refreshed"), "info", 1.5)
end, Tooltip = "tt_refresh_list"})

local secClipboard = tabConfigs:CreateSection({Name = "sec_clipboard", Side = "Right"})
secClipboard:AddLabel({Text = "lbl_clipboard_fallback_hint"})
secClipboard:AddButton({Name = "btn_copy_clipboard", Callback = function()
    local str = Window:ExportSettings()
    if not str then Notify("airhubUI", "Export failed", "error"); return end
    local ok = trySetClipboard(str)
    if ok then Notify("airhubUI", T("n_copied"), "success")
    else
        print("[airhubUI Config] " .. str)
        Notify("airhubUI", T("n_fs_unavail_console"), "warning")
    end
end, Tooltip = "tt_copy_clipboard"})
secClipboard:AddButton({Name = "btn_paste_clipboard", Callback = function()
    local str = tryGetClipboard()
    if not str or str == "" then Notify("airhubUI", T("n_clipboard_empty"), "error"); return end
    local ok, err = Window:ImportSettings(str)
    if ok then Notify("airhubUI", T("n_loaded_clipboard"), "success")
    else Notify("airhubUI", T("n_invalid", tostring(err)), "error") end
end, Tooltip = "tt_paste_clipboard"})

local secCustom = tabConfigs:CreateSection({Name = "sec_inmemory"})
secCustom:AddLabel({Text = "lbl_inmemory_hint"})
local presetNameRef = secCustom:AddInput({
    Name = "lbl_preset_name", Placeholder = "ph_my_preset", Value = "",
    Tooltip = "tt_preset_name"})
local customPresets = {}
secCustom:AddButton({Name = "btn_save_preset", Callback = function()
    local n = presetNameRef:Get()
    if not n or n == "" then Notify("airhubUI", T("n_enter_name"), "warning"); return end
    local str = Window:ExportSettings()
    if not str then Notify("airhubUI", "Export failed", "error"); return end
    customPresets[n] = str
    Notify("airhubUI", T("n_preset_saved", n), "success")
end, Tooltip = "tt_save_preset"})
secCustom:AddButton({Name = "btn_load_preset", Callback = function()
    local n = presetNameRef:Get()
    if not n or n == "" then Notify("airhubUI", T("n_enter_name"), "warning"); return end
    if not customPresets[n] then Notify("airhubUI", T("n_preset_not_found", n), "error"); return end
    local ok, err = Window:ImportSettings(customPresets[n])
    if ok then Notify("airhubUI", T("n_loaded", n), "success")
    else Notify("airhubUI", T("n_load_failed", tostring(err)), "error") end
end, Tooltip = "tt_load_preset"})
secCustom:AddButton({Name = "btn_delete_preset", Callback = function()
    local n = presetNameRef:Get()
    if not n or n == "" then Notify("airhubUI", T("n_enter_name"), "warning"); return end
    customPresets[n] = nil
    Notify("airhubUI", T("n_preset_deleted", n), "warning")
end, Tooltip = "tt_delete_preset"})

-- ══════════════════════════════════════════════════════════════
-- BINDS TAB
-- ══════════════════════════════════════════════════════════════
local tabBinds = Window:AddTab({Name = "tab_binds", Icon = ">"})
local secBindsList = tabBinds:CreateSection({Name = "sec_active_binds"})
secBindsList:AddLabel({Text = "lbl_binds_hint1"})
secBindsList:AddLabel({Text = "lbl_binds_hint2"})
secBindsList:AddLabel({Text = "lbl_binds_hint3", Color = Theme.Muted})
secBindsList:AddDivider({Text = "lbl_live_status"})

local lf = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1,0,0,0),
    AutomaticSize = Enum.AutomaticSize.Y}, secBindsList.Content)
new("UIListLayout", {Padding = UDim.new(0,4)}, lf)
local liveBindEntries = {}
local function refreshBinds()
    for _, c in ipairs(lf:GetChildren()) do
        if not c:IsA("UIListLayout") then c:Destroy() end
    end
    liveBindEntries = {}
    local any = false
    for _, id in ipairs(BindOrder) do
        local b = BindRegistry[id]
        if b and #b.keys > 0 then
            any = true
            local r = new("Frame", {BorderSizePixel = 0, Size = UDim2.new(1,0,0,34)}, lf)
            themeBg(r, "Element"); addCorner(r, UDim.new(0,8)); addStroke(r, Theme.Outline, 1, 0.35)
            local strip = new("Frame", {BackgroundColor3 = MODE_COLORS[b.keys[1].mode] or Theme.Accent,
                BorderSizePixel = 0, Position = UDim2.new(0,10,0.5,-8),
                Size = UDim2.new(0,3,0,16)}, r)
            addCorner(strip, UDim.new(1,0))
            local dot = new("Frame", {BackgroundColor3 = Theme.Muted, BorderSizePixel = 0,
                Position = UDim2.new(0,22,0.5,-5), Size = UDim2.new(0,10,0,10)}, r)
            addCorner(dot, UDim.new(1,0))
            local nameLbl = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0,42,0,0),
                Size = UDim2.new(0.5,-46,1,0), Font = Config.CurrentFontFamily, Text = b.name,
                TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd}, r)
            themeText(nameLbl, "Text")
            local statusLbl = new("TextLabel", {BackgroundTransparency = 1,
                Position = UDim2.new(1,-76,0,0), Size = UDim2.new(0,42,1,0),
                Font = Config.CurrentFontFamily, Text = "OFF", TextSize = 11,
                TextColor3 = Theme.Muted, TextXAlignment = Enum.TextXAlignment.Right}, r)
            local del = new("TextButton", {BackgroundColor3 = Theme.Danger, BackgroundTransparency = 0.85,
                BorderSizePixel = 0, Position = UDim2.new(1,-30,0.5,-10), Size = UDim2.new(0,20,0,20),
                Font = Config.CurrentFontFamily, Text = "x", TextColor3 = Theme.Danger,
                TextSize = 11, AutoButtonColor = false}, r)
            addCorner(del, UDim.new(0,6))
            del.MouseButton1Click:Connect(function() ClearBind(id); refreshBinds() end)
            liveBindEntries[id] = {row = r, dot = dot, statusLbl = statusLbl, bind = b}
        end
    end
    if not any then
        local empty = new("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(1,0,0,22),
            Font = Config.CurrentFontFamily, Text = T("lbl_binds_empty"),
            TextSize = 10, TextWrapped = true}, lf)
        themeText(empty, "Muted")
    end
end
secBindsList:AddButton({Name = "btn_binds_refresh", Callback = refreshBinds, Tooltip = "tt_binds_refresh"})
secBindsList:AddButton({Name = "btn_binds_clear", Callback = function()
    for _, id in ipairs(BindOrder) do
        if BindRegistry[id] then ClearBind(id) end
    end
    refreshBinds()
    Notify("airhubUI", T("n_binds_cleared"), "warning")
end, Tooltip = "tt_binds_clear"})
refreshBinds()

task.spawn(function()
    while true do
        for id, entry in pairs(liveBindEntries) do
            if entry.row and entry.row.Parent and entry.bind then
                local active = isBindActive(entry.bind)
                if entry.statusLbl and entry.statusLbl.Parent then
                    entry.statusLbl.Text = active and "ON" or "OFF"
                    entry.statusLbl.TextColor3 = active and Theme.Success or Theme.Muted
                end
                if entry.dot and entry.dot.Parent then
                    entry.dot.BackgroundColor3 = active and Theme.Success or Theme.Muted
                end
            else
                liveBindEntries[id] = nil
            end
        end
        task.wait(0.1)
    end
end)

-- ══════════════════════════════════════════════════════════════
-- EXPORT
-- ══════════════════════════════════════════════════════════════
getgenv().airhubUI = airhubUILib
getgenv().airhubUI_Window = Window

return airhubUILib
