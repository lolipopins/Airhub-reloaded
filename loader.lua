--// ============================================================================
--// AirHub — Fast Loader v3 (game-gated injection)
--// Параллельная загрузка всех файлов + строго-последовательное выполнение.
--//
--// Изменения vs v2:
--//   • Исправлены имена файлов: arsenal_extra_tab.lua / rivals_extra_tab.lua
--//   • Добавлен GAME_GATES: arsenal/rivals выполняются только в своих PlaceId
--//   • Остальные файлы грузятся и выполняются как раньше
--// ============================================================================

local BASE_URL = "https://raw.githubusercontent.com/lolipopins/Airhub-reloaded/main/src/"

local FILES = {
    "00_ui_lib.lua",
    "01_core.lua",
    "02_aimbot.lua",
    "03_antiaim.lua",
    "04_wallhack.lua",
    "05_movement.lua",
    "06_world.lua",
    "07_exploits.lua",
    "08_settings.lua",
    "arsenal_extra_tab.lua",
    "rivals_extra_tab.lua",
}

--// Какие файлы в каких играх разрешены.
--// Если файла нет в таблице — он выполняется везде.
local GAME_GATES = {
    ["arsenal_extra_tab.lua"] = { 286090429 }, -- Arsenal
    ["rivals_extra_tab.lua"]  = { 17625359962 }, -- Rivals
}

local LOCAL_DIRS = {
    "AirHub/src/",
    "airhub/src/",
    "src/",
    "",
}

local WAIT_AFTER_UI = true
local DELAY_BETWEEN = 0
local FETCH_TIMEOUT = 20

--// --- вспомогательное ---------------------------------------------------

local TASK = rawget(_G, "task")
if type(TASK) ~= "table" and type(getgenv) == "function" then
    local ok, env = pcall(getgenv)
    if ok and type(env) == "table" then TASK = rawget(env, "task") end
end

local spawnFn = (TASK and type(TASK.spawn) == "function" and TASK.spawn)
             or (type(rawget(_G, "spawn")) == "function" and rawget(_G, "spawn"))
             or function(f) f() end

local waitFn = (TASK and type(TASK.wait) == "function" and TASK.wait)
            or (type(rawget(_G, "wait")) == "function" and rawget(_G, "wait"))
            or function() end

local clockFn = (os and os.clock) or tick or function() return 0 end

local function log(msg, kind)
    local p = "[AirHub Loader] " .. tostring(msg)
    if kind == "err" then warn(p) else print(p) end
end

local function getExec(name)
    local f = rawget(_G, name)
    if type(f) == "function" then return f end
    if type(getgenv) == "function" then
        local ok, env = pcall(getgenv)
        if ok and type(env) == "table" then
            f = rawget(env, name)
            if type(f) == "function" then return f end
        end
    end
    return nil
end

local function httpGet(url)
    if type(rawget(_G, "HttpGet")) == "function" then
        local ok, r = pcall(rawget(_G, "HttpGet"), url)
        if ok and type(r) == "string" and #r > 0 then return r end
    end
    if game then
        if type(game.HttpGet) == "function" then
            local ok, r = pcall(game.HttpGet, game, url)
            if ok and type(r) == "string" and #r > 0 then return r end
        end
        if type(game.HttpGetAsync) == "function" then
            local ok, r = pcall(game.HttpGetAsync, game, url)
            if ok and type(r) == "string" and #r > 0 then return r end
        end
    end
    if type(request) == "function" then
        local ok, r = pcall(request, { Url = url, Method = "GET" })
        if ok and r and type(r.Body) == "string" and #r.Body > 0 then return r.Body end
    end
    if type(http_request) == "function" then
        local ok, r = pcall(http_request, { Url = url, Method = "GET" })
        if ok and r and type(r.Body) == "string" and #r.Body > 0 then return r.Body end
    end
    if type(syn) == "table" and type(syn.request) == "function" then
        local ok, r = pcall(syn.request, { Url = url, Method = "GET" })
        if ok and r and type(r.Body) == "string" and #r.Body > 0 then return r.Body end
    end
    return nil
end

local function sanitizeSource(src)
    if type(src) ~= "string" or #src == 0 then return nil, "empty source" end
    local trimmed = src:gsub("^%s+", "")
    local head = trimmed:sub(1, 200):lower()
    if head:find("^404: not found", 1, true)
        or head:find("^404 not found", 1, true)
        or head:find("^<!doctype html", 1, true)
        or head:find("^<html", 1, true)
        or head:find("\"message\":\"not found\"", 1, true)
        or head:find("this repository is empty", 1, true) then
        return nil, "HTTP 404 / not found"
    end
    local looksLikeLua = head:find("local ", 1, true)
        or head:find("--", 1, true)
        or head:find("getgenv", 1, true)
        or head:find("return", 1, true)
        or head:find("if ", 1, true)
    if not looksLikeLua then return nil, "not Lua" end
    return src
end

local function tryReadLocal(filename)
    local rf = getExec("readfile")
    if not rf then return nil end
    for _, dir in ipairs(LOCAL_DIRS) do
        local ok, content = pcall(rf, dir .. filename)
        if ok and type(content) == "string" and #content > 0 then
            return content, dir .. filename
        end
    end
    return nil
end

local function compile(src, name)
    local ls = getExec("loadstring")
    if ls then
        local ok, chunk = pcall(ls, src, "@" .. name)
        if ok then return chunk end
        return nil, chunk
    end
    if type(load) == "function" then
        local ok, chunk = pcall(load, src, "@" .. name)
        if ok then return chunk end
        return nil, chunk
    end
    return nil, "loadstring/load unavailable"
end

local function fetchOne(filename)
    local src, localPath = tryReadLocal(filename)
    if src then return src, "LOCAL:" .. localPath end

    local url = BASE_URL .. filename
    local remote = httpGet(url)
    if not remote then return nil, "no source (local + HTTP failed)" end

    local clean, err = sanitizeSource(remote)
    if not clean then return nil, "bad source: " .. tostring(err) end
    return clean, "HTTP"
end

--// --- gate --------------------------------------------------------------

local function isAllowed(filename)
    local allowed = GAME_GATES[filename]
    if not allowed then return true end -- нет ограничений
    local placeId = game and game.PlaceId
    if not placeId then
        log("cannot read game.PlaceId — skipping gated file: " .. filename, "err")
        return false
    end
    for _, id in ipairs(allowed) do
        if placeId == id then return true end
    end
    return false
end

--// --- main -------------------------------------------------------------

local function run()
    local t0 = clockFn()
    log("===============================================")
    log("AirHub fast loader v3 — " .. #FILES .. " files (parallel fetch)")
    log("PlaceId: " .. tostring(game and game.PlaceId or "unknown"))
    log("===============================================")

    -- 1) Параллельный fetch (качаем всё, даже gated — чтобы не усложнять)
    local sources = {}
    local done = {}

    for i, fname in ipairs(FILES) do
        spawnFn(function()
            local src, label = fetchOne(fname)
            sources[i] = { src = src, label = label }
            done[i] = true
        end)
    end

    local waitStart = clockFn()
    while clockFn() - waitStart < FETCH_TIMEOUT do
        local all = true
        for i = 1, #FILES do
            if not done[i] then all = false break end
        end
        if all then break end
        waitFn(0.01)
    end

    local fetchTime = clockFn() - t0

    -- 1.5) retry для тех, что не пришли параллельно
    local retried = 0
    for i, fname in ipairs(FILES) do
        local e = sources[i]
        if not e or not e.src then
            retried = retried + 1
            local src, label = fetchOne(fname)
            sources[i] = { src = src, label = label }
        end
    end
    if retried > 0 then
        log("Retried sequentially: " .. retried .. " file(s)")
    end

    -- 2) Последовательное выполнение с учётом gate
    local loaded, failed, skipped = 0, 0, 0
    local failed_files = {}

    for i, fname in ipairs(FILES) do
        if not isAllowed(fname) then
            skipped = skipped + 1
            log(string.format("[%02d/%02d] SKIP %-28s -> not allowed for PlaceId", i, #FILES, fname))
        else
            local entry = sources[i]
            if not entry or not entry.src then
                failed = failed + 1
                local err = (entry and entry.label) or "fetch failed / timeout"
                table.insert(failed_files, { name = fname, err = err })
                log(string.format("[%02d/%02d] FAIL %-28s -> %s", i, #FILES, fname, err), "err")
            else
                local chunk, cerr = compile(entry.src, fname)
                if not chunk then
                    failed = failed + 1
                    local err = "compile: " .. tostring(cerr)
                    table.insert(failed_files, { name = fname, err = err })
                    log(string.format("[%02d/%02d] FAIL %-28s -> %s", i, #FILES, fname, err), "err")
                else
                    local ok, rerr = pcall(chunk)
                    if not ok then
                        failed = failed + 1
                        local err = "runtime: " .. tostring(rerr)
                        table.insert(failed_files, { name = fname, err = err })
                        log(string.format("[%02d/%02d] FAIL %-28s -> %s", i, #FILES, fname, err), "err")
                    else
                        loaded = loaded + 1
                        log(string.format("[%02d/%02d] OK   %-28s <- %s", i, #FILES, fname, entry.label))
                    end
                end
            end
        end

        if i == 1 and WAIT_AFTER_UI then
            waitFn()
        elseif i < #FILES and DELAY_BETWEEN > 0 then
            waitFn(DELAY_BETWEEN)
        end
    end

    local totalTime = clockFn() - t0

    log("===============================================")
    log(string.format(
        "Loaded: %d/%d | Skipped: %d | Failed: %d | fetch: %.2fs | total: %.2fs",
        loaded, #FILES, skipped, failed, fetchTime, totalTime
    ))
    if failed > 0 then
        log("Failed files:", "err")
        for _, e in ipairs(failed_files) do
            log("  • " .. e.name .. " — " .. tostring(e.err), "err")
        end
    end
    if loaded == #FILES then
        log("AirHub fully loaded. RightShift to toggle menu.")
    elseif loaded > 0 then
        log("AirHub loaded for this game (some tabs skipped).")
    else
        log("AirHub NOT loaded — check BASE_URL / HTTP method / PlaceId.", "err")
    end
    log("===============================================")
end

pcall(run)
