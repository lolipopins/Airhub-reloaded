--=============================================================
-- airUI v1.3 — Fixed text theming everywhere + smooth open/close
--   * ALL text elements now properly themed (not just tabs)
--   * Smooth slide + scale + fade animation (no rotation artifacts)
--   * Search placeholder color updates with theme
--   * Popups properly animated
--=============================================================

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local CoreGui          = game:GetService("CoreGui")
local Stats            = game:GetService("Stats")
local LocalPlayer      = Players.LocalPlayer

-- ============================================================
-- FONT CATALOG
-- ============================================================
local FontCatalog = {
    ["Code"]             = Enum.Font.Code,
    ["Gotham"]           = Enum.Font.Gotham,
    ["GothamBold"]       = Enum.Font.GothamBold,
    ["GothamSemibold"]   = Enum.Font.GothamSemibold,
    ["Arial"]            = Enum.Font.Arial,
    ["ArialBold"]        = Enum.Font.ArialBold,
    ["SourceSans"]       = Enum.Font.SourceSans,
    ["SourceSansBold"]   = Enum.Font.SourceSansBold,
    ["SourceSansSemibold"]=Enum.Font.SourceSansSemibold,
    ["Roboto"]           = Enum.Font.Roboto,
    ["RobotoMono"]       = Enum.Font.RobotoMono,
    ["Ubuntu"]           = Enum.Font.Ubuntu,
    ["Fantasy"]          = Enum.Font.Fantasy,
    ["Antique"]          = Enum.Font.Antique,
    ["Arcade"]           = Enum.Font.Arcade,
    ["SciFi"]            = Enum.Font.SciFi,
    ["Bangers"]          = Enum.Font.Bangers,
    ["PatrickHand"]      = Enum.Font.PatrickHand,
}

-- ============================================================
-- THEME
-- ============================================================
local Theme = {
    Background   = Color3.fromRGB(245, 246, 249),
    BackgroundAlt= Color3.fromRGB(250, 251, 253),
    Sidebar      = Color3.fromRGB(240, 242, 246),
    Panel        = Color3.fromRGB(255, 255, 255),
    Section      = Color3.fromRGB(250, 251, 253),
    Element      = Color3.fromRGB(255, 255, 255),
    ElementHover = Color3.fromRGB(238, 241, 246),
    Accent       = Color3.fromRGB(77, 107, 254),
    AccentHover  = Color3.fromRGB(102, 128, 255),
    Accent2      = Color3.fromRGB(220, 90, 130),
    Cyan         = Color3.fromRGB(80, 180, 220),
    Green        = Color3.fromRGB(60, 200, 130),
    Text         = Color3.fromRGB(26, 29, 35),
    SubText      = Color3.fromRGB(107, 114, 128),
    Muted        = Color3.fromRGB(156, 163, 175),
    Outline      = Color3.fromRGB(226, 229, 235),
    OutlineLight = Color3.fromRGB(203, 208, 218),
    Danger       = Color3.fromRGB(220, 60, 90),
    Success      = Color3.fromRGB(60, 200, 130),
    Warning      = Color3.fromRGB(240, 180, 60),
    OnAccent     = Color3.fromRGB(255, 255, 255),
}

local ThemePresets = {
    ["airUI Light"] = {
        Background   = Color3.fromRGB(245, 246, 249),
        Sidebar      = Color3.fromRGB(240, 242, 246),
        Panel        = Color3.fromRGB(255, 255, 255),
        Section      = Color3.fromRGB(250, 251, 253),
        Element      = Color3.fromRGB(255, 255, 255),
        ElementHover = Color3.fromRGB(238, 241, 246),
        Accent       = Color3.fromRGB(77, 107, 254),
        Accent2      = Color3.fromRGB(220, 90, 130),
        Text         = Color3.fromRGB(26, 29, 35),
        SubText      = Color3.fromRGB(107, 114, 128),
        Muted        = Color3.fromRGB(156, 163, 175),
        Outline      = Color3.fromRGB(226, 229, 235),
        OnAccent     = Color3.fromRGB(255, 255, 255),
        Font         = "Code",
        FontSize     = 1.0,
    },
    ["airUI Dark"] = {
        Background   = Color3.fromRGB(14, 15, 19),
        Sidebar      = Color3.fromRGB(18, 19, 24),
        Panel        = Color3.fromRGB(22, 23, 29),
        Section      = Color3.fromRGB(25, 26, 33),
        Element      = Color3.fromRGB(30, 32, 40),
        ElementHover = Color3.fromRGB(38, 40, 50),
        Accent       = Color3.fromRGB(120, 150, 255),
        Accent2      = Color3.fromRGB(240, 120, 160),
        Text         = Color3.fromRGB(235, 238, 245),
        SubText      = Color3.fromRGB(160, 168, 184),
        Muted        = Color3.fromRGB(110, 118, 134),
        Outline      = Color3.fromRGB(48, 50, 60),
        OnAccent     = Color3.fromRGB(14, 15, 19),
        Font         = "Code",
        FontSize     = 1.0,
    },
    ["Smoke"] = {
        Background   = Color3.fromRGB(232, 234, 238),
        Sidebar      = Color3.fromRGB(222, 225, 230),
        Panel        = Color3.fromRGB(245, 247, 250),
        Section      = Color3.fromRGB(238, 240, 244),
        Element      = Color3.fromRGB(250, 251, 253),
        ElementHover = Color3.fromRGB(228, 231, 236),
        Accent       = Color3.fromRGB(90, 100, 120),
        Accent2      = Color3.fromRGB(160, 130, 180),
        Text         = Color3.fromRGB(35, 38, 44),
        SubText      = Color3.fromRGB(110, 116, 128),
        Muted        = Color3.fromRGB(160, 165, 175),
        Outline      = Color3.fromRGB(200, 205, 215),
        OnAccent     = Color3.fromRGB(245, 247, 250),
        Font         = "Gotham",
        FontSize     = 1.0,
    },
    ["Mint"] = {
        Background   = Color3.fromRGB(240, 250, 246),
        Sidebar      = Color3.fromRGB(228, 244, 238),
        Panel        = Color3.fromRGB(252, 255, 254),
        Section      = Color3.fromRGB(244, 252, 249),
        Element      = Color3.fromRGB(252, 255, 253),
        ElementHover = Color3.fromRGB(226, 244, 236),
        Accent       = Color3.fromRGB(60, 200, 130),
        Accent2      = Color3.fromRGB(80, 180, 220),
        Text         = Color3.fromRGB(20, 40, 32),
        SubText      = Color3.fromRGB(90, 120, 108),
        Muted        = Color3.fromRGB(150, 175, 165),
        Outline      = Color3.fromRGB(200, 224, 214),
        OnAccent     = Color3.fromRGB(255, 255, 255),
        Font         = "GothamSemibold",
        FontSize     = 1.0,
    },
    ["Rose"] = {
        Background   = Color3.fromRGB(252, 244, 246),
        Sidebar      = Color3.fromRGB(248, 232, 236),
        Panel        = Color3.fromRGB(255, 252, 253),
        Section      = Color3.fromRGB(252, 246, 248),
        Element      = Color3.fromRGB(255, 253, 254),
        ElementHover = Color3.fromRGB(246, 230, 235),
        Accent       = Color3.fromRGB(220, 90, 130),
        Accent2      = Color3.fromRGB(240, 120, 100),
        Text         = Color3.fromRGB(45, 22, 30),
        SubText      = Color3.fromRGB(130, 90, 105),
        Muted        = Color3.fromRGB(190, 150, 165),
        Outline      = Color3.fromRGB(232, 208, 216),
        OnAccent     = Color3.fromRGB(255, 255, 255),
        Font         = "GothamSemibold",
        FontSize     = 1.0,
    },
    ["Violet"] = {
        Background   = Color3.fromRGB(246, 244, 252),
        Sidebar      = Color3.fromRGB(238, 232, 250),
        Panel        = Color3.fromRGB(253, 252, 255),
        Section      = Color3.fromRGB(247, 244, 253),
        Element      = Color3.fromRGB(253, 252, 255),
        ElementHover = Color3.fromRGB(238, 232, 250),
        Accent       = Color3.fromRGB(140, 100, 220),
        Accent2      = Color3.fromRGB(220, 90, 160),
        Text         = Color3.fromRGB(32, 22, 45),
        SubText      = Color3.fromRGB(110, 90, 140),
        Muted        = Color3.fromRGB(175, 155, 200),
        Outline      = Color3.fromRGB(220, 210, 235),
        OnAccent     = Color3.fromRGB(255, 255, 255),
        Font         = "Gotham",
        FontSize     = 1.0,
    },
    ["Sky"] = {
        Background   = Color3.fromRGB(240, 246, 252),
        Sidebar      = Color3.fromRGB(228, 238, 248),
        Panel        = Color3.fromRGB(252, 254, 255),
        Section      = Color3.fromRGB(242, 248, 253),
        Element      = Color3.fromRGB(252, 254, 255),
        ElementHover = Color3.fromRGB(226, 238, 248),
        Accent       = Color3.fromRGB(80, 180, 220),
        Accent2      = Color3.fromRGB(77, 107, 254),
        Text         = Color3.fromRGB(20, 35, 50),
        SubText      = Color3.fromRGB(85, 115, 140),
        Muted        = Color3.fromRGB(150, 175, 195),
        Outline      = Color3.fromRGB(200, 218, 232),
        OnAccent     = Color3.fromRGB(255, 255, 255),
        Font         = "Gotham",
        FontSize     = 1.0,
    },
    ["Amber"] = {
        Background   = Color3.fromRGB(253, 248, 240),
        Sidebar      = Color3.fromRGB(250, 240, 224),
        Panel        = Color3.fromRGB(255, 253, 250),
        Section      = Color3.fromRGB(253, 249, 242),
        Element      = Color3.fromRGB(255, 254, 251),
        ElementHover = Color3.fromRGB(248, 238, 222),
        Accent       = Color3.fromRGB(240, 180, 60),
        Accent2      = Color3.fromRGB(240, 120, 100),
        Text         = Color3.fromRGB(45, 35, 20),
        SubText      = Color3.fromRGB(130, 110, 80),
        Muted        = Color3.fromRGB(185, 165, 135),
        Outline      = Color3.fromRGB(232, 220, 200),
        OnAccent     = Color3.fromRGB(45, 35, 20),
        Font         = "GothamSemibold",
        FontSize     = 1.0,
    },
    ["Cyber"] = {
        Background   = Color3.fromRGB(10, 12, 18),
        Sidebar      = Color3.fromRGB(14, 16, 24),
        Panel        = Color3.fromRGB(18, 20, 30),
        Section      = Color3.fromRGB(20, 22, 32),
        Element      = Color3.fromRGB(24, 27, 38),
        ElementHover = Color3.fromRGB(32, 36, 50),
        Accent       = Color3.fromRGB(0, 220, 255),
        Accent2      = Color3.fromRGB(255, 0, 170),
        Text         = Color3.fromRGB(220, 240, 255),
        SubText      = Color3.fromRGB(140, 160, 190),
        Muted        = Color3.fromRGB(90, 105, 135),
        Outline      = Color3.fromRGB(38, 44, 60),
        OnAccent     = Color3.fromRGB(10, 12, 18),
        Font         = "SciFi",
        FontSize     = 1.0,
    },
    ["Matrix"] = {
        Background   = Color3.fromRGB(8, 14, 10),
        Sidebar      = Color3.fromRGB(10, 18, 12),
        Panel        = Color3.fromRGB(12, 22, 15),
        Section      = Color3.fromRGB(14, 24, 17),
        Element      = Color3.fromRGB(18, 30, 22),
        ElementHover = Color3.fromRGB(24, 40, 30),
        Accent       = Color3.fromRGB(60, 255, 90),
        Accent2      = Color3.fromRGB(0, 220, 150),
        Text         = Color3.fromRGB(200, 255, 210),
        SubText      = Color3.fromRGB(120, 180, 130),
        Muted        = Color3.fromRGB(80, 130, 90),
        Outline      = Color3.fromRGB(30, 50, 35),
        OnAccent     = Color3.fromRGB(8, 14, 10),
        Font         = "Code",
        FontSize     = 1.0,
    },
    ["Nord"] = {
        Background   = Color3.fromRGB(46, 52, 64),
        Sidebar      = Color3.fromRGB(59, 66, 82),
        Panel        = Color3.fromRGB(67, 76, 94),
        Section      = Color3.fromRGB(59, 66, 82),
        Element      = Color3.fromRGB(76, 86, 106),
        ElementHover = Color3.fromRGB(86, 97, 118),
        Accent       = Color3.fromRGB(136, 192, 208),
        Accent2      = Color3.fromRGB(180, 142, 173),
        Text         = Color3.fromRGB(236, 239, 244),
        SubText      = Color3.fromRGB(216, 222, 233),
        Muted        = Color3.fromRGB(180, 190, 205),
        Outline      = Color3.fromRGB(76, 86, 106),
        OnAccent     = Color3.fromRGB(46, 52, 64),
        Font         = "SourceSansSemibold",
        FontSize     = 1.0,
    },
    ["Dracula"] = {
        Background   = Color3.fromRGB(40, 42, 54),
        Sidebar      = Color3.fromRGB(48, 50, 63),
        Panel        = Color3.fromRGB(56, 58, 74),
        Section      = Color3.fromRGB(50, 52, 66),
        Element      = Color3.fromRGB(68, 71, 90),
        ElementHover = Color3.fromRGB(80, 83, 105),
        Accent       = Color3.fromRGB(189, 147, 249),
        Accent2      = Color3.fromRGB(255, 121, 198),
        Text         = Color3.fromRGB(248, 248, 242),
        SubText      = Color3.fromRGB(210, 210, 220),
        Muted        = Color3.fromRGB(160, 162, 180),
        Outline      = Color3.fromRGB(68, 71, 90),
        OnAccent     = Color3.fromRGB(40, 42, 54),
        Font         = "GothamSemibold",
        FontSize     = 1.0,
    },
}

local Config = {
    WindowWidth = 720, WindowHeight = 500,
    MinWidth = 520, MinHeight = 380,
    ToggleKey = Enum.KeyCode.RightShift,
    AnimSpeed = 0.15,
    MenuAnim = 0.32,
    MenuCloseAnim = 0.20,
    PopupAnim = 0.18,
    CornerRadius = UDim.new(0, 8),
    BaseCornerRadius = 8,
    CurrentFontFamily = Enum.Font.Code,
    CurrentFontName = "Code",
    CurrentFontScale = 1.0,
    PopupZ = 5000, OverlayZ = 4000, NotifyZ = 6000, TooltipZ = 7000,
    StatusBar = true,
    MenuTransparency = 0.06, TabTransparency = 0, SectionTransparency = 0, ElementTransparency = 0,
    Version = "1.3",
}

local WHEEL_UP, WHEEL_DOWN = "WheelUp", "WheelDown"

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
        if k == WHEEL_UP then return "WU" end
        if k == WHEEL_DOWN then return "WD" end
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
        return inp.Position.Z > 0 and WHEEL_UP or WHEEL_DOWN
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
    size = size or 12
    thick = thick or 2
    color = color or Theme.Accent
    local function bracket(xS, xO, yS, yO, w, h, ax, ay)
        new("Frame", {BackgroundColor3 = color, BackgroundTransparency = 0.15, BorderSizePixel = 0,
            AnchorPoint = Vector2.new(ax, ay), Position = UDim2.new(xS, xO, yS, yO),
            Size = UDim2.new(0, w, 0, h), ZIndex = (parent.ZIndex or 1) + 1}, parent)
    end
    bracket(0,0,0,0,size,thick,0,0)
    bracket(0,0,0,0,thick,size,0,0)
    bracket(1,0,0,0,size,thick,1,0)
    bracket(1,0,0,0,thick,size,1,0)
    bracket(0,0,1,0,size,thick,0,1)
    bracket(0,0,1,0,thick,size,0,1)
    bracket(1,0,1,0,size,thick,1,1)
    bracket(1,0,1,0,thick,size,1,1)
end

local MODE_COLORS = {
    Toggle = Color3.fromRGB(60, 200, 130),
    Hold = Color3.fromRGB(240, 180, 60),
    OnHoldDisable = Color3.fromRGB(220, 60, 90),
}
local MODE_SHORT = { Toggle = "TGL", Hold = "HLD", OnHoldDisable = "OHD" }

-- ============================================================
-- SEARCH HIGHLIGHT
-- ============================================================
local HIGHLIGHT_COLOR = "rgb(77, 107, 254)"

local function highlightLabel(lbl, query)
    if not lbl or not lbl.Parent then return end
    local orig = lbl:GetAttribute("_hlOrig")
    if orig == nil then
        orig = lbl.Text
        lbl:SetAttribute("_hlOrig", orig)
    end
    if not query or query == "" then
        lbl.RichText = false
        lbl.Text = orig
        return
    end
    local lower = string.lower(orig)
    local qlen = #query
    if qlen == 0 or not string.find(lower, query, 1, true) then
        lbl.RichText = false
        lbl.Text = orig
        return
    end
    local parts = {}
    local i = 1
    while i <= #orig do
        local s = string.find(lower, query, i, true)
        if not s then
            table.insert(parts, orig:sub(i))
            break
        end
        local e = s + qlen - 1
        if s > i then table.insert(parts, orig:sub(i, s - 1)) end
        table.insert(parts, '<font color="' .. HIGHLIGHT_COLOR .. '"><b>' ..
                     orig:sub(s, e) .. '</b></font>')
        i = e + 1
    end
    lbl.RichText = true
    lbl.Text = table.concat(parts)
end

local function markSearch(row, name, nameLabel)
    row:SetAttribute("SearchName", string.lower(name or ""))
    if nameLabel then RowNameLabels[row] = nameLabel end
end

-- ============================================================
-- BIND SYSTEM
-- ============================================================
local function matchesKey(stored, input)
    if not stored then return false end
    if stored == WHEEL_UP or stored == WHEEL_DOWN then
        return input.UserInputType == Enum.UserInputType.MouseWheel and stored == readInputKey(input)
    end
    return stored == input.KeyCode or stored == input.UserInputType
end

local function findActiveKey(bind)
    for _, e in ipairs(bind.keys) do
        if e.mode == "Hold" and e.held then return e, true end
    end
    for _, e in ipairs(bind.keys) do
        if e.mode == "Toggle" and e.toggled then return e, true end
    end
    for _, e in ipairs(bind.keys) do
        if e.mode == "OnHoldDisable" and e.held then return e, false end
    end
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

local function AddBindKey(bindId, key, mode, value)
    local b = BindRegistry[bindId]; if not b then return end
    local e = {key = key, mode = mode or "Toggle", value = value, held = false, toggled = false}
    table.insert(b.keys, e); fireBind(b); return e
end

local function RemoveBindKey(bindId, idx, silent)
    local b = BindRegistry[bindId]; if not b then return end
    table.remove(b.keys, idx); fireBind(b, silent)
end

local function ClearBind(id, silent)
    local b = BindRegistry[id]; if not b then return end
    b.keys = {}; fireBind(b, silent)
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

-- ============================================================
-- RAINBOW LOOP
-- ============================================================
local rainbowTime = 0
_T(RunService.RenderStepped:Connect(function(dt)
    if #RainbowControllers == 0 then return end
    rainbowTime = (rainbowTime + dt * 0.20) % 1
    for i = #RainbowControllers, 1, -1 do
        local c = RainbowControllers[i]
        if not c then
            table.remove(RainbowControllers, i)
        elseif not c.root or not c.root.Parent then
            if not c.keepAlive then
                table.remove(RainbowControllers, i)
            end
        elseif c.active and type(c.setFromRainbow) == "function" then
            pcall(c.setFromRainbow, (rainbowTime * (c.speed or 1)) % 1)
        end
    end
end))

-- ============================================================
-- NOTIFICATIONS
-- ============================================================
local NotificationHolder
local function ensureNotifHolder(parent)
    if NotificationHolder and NotificationHolder.Parent then return NotificationHolder end
    NotificationHolder = new("Frame", {Name = "airUINotifications", BackgroundTransparency = 1,
        Position = UDim2.new(1,-16,0,16), Size = UDim2.new(0,320,1,-32),
        AnchorPoint = Vector2.new(1,0), ZIndex = Config.NotifyZ}, parent)
    new("UIListLayout", {Padding = UDim.new(0,8), SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Right}, NotificationHolder)
    return NotificationHolder
end

local function Notify(title, text, kind, duration)
    local holder = ensureNotifHolder(NotificationHolder and NotificationHolder.Parent or getSafeParent())
    duration = duration or 3
    local accent, icon = Theme.Accent, "i"
    if kind == "success" then accent, icon = Theme.Success, "+"
    elseif kind == "error" then accent, icon = Theme.Danger, "x"
    elseif kind == "warning" then accent, icon = Theme.Warning, "!" end
    local n = new("Frame", {Name = "Notification", BorderSizePixel = 0,
        Size = UDim2.new(1,0,0,62), Position = UDim2.new(1,24,0,0), ZIndex = Config.NotifyZ + 1}, holder)
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
            tween(n, {Position = UDim2.new(1,24,0,0)})
            task.wait(Config.AnimSpeed)
            if n then n:Destroy() end
        end
    end)
end

-- ============================================================
-- OVERLAY + POPUP STACK
-- ============================================================
local Overlay
local function ensureOverlay(gui)
    if Overlay and Overlay.Parent == gui then return Overlay end
    if Overlay and Overlay.Parent then Overlay:Destroy() end
    Overlay = new("Frame", {Name = "airUIOverlay", BackgroundTransparency = 1,
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
    if not us then
        us = Instance.new("UIScale"); us.Parent = frame
    end
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
        if top.us and top.us.Parent then
            tween(top.us, {Scale = 0.92}, Config.PopupAnim * 0.6)
        end
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

-- ============================================================
-- TOOLTIP
-- ============================================================
local Tooltip
local function ensureTooltip()
    if Tooltip and Tooltip.Parent then return Tooltip end
    if not Overlay or not Overlay.Parent then return nil end
    Tooltip = new("Frame", {Name = "airUITooltip", BorderSizePixel = 0,
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
    t:FindFirstChild("Text").Text = text; t.Visible = true
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
    local function enter() hideToken = hideToken + 1; pcall(showTooltip, frame, text) end
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

-- ============================================================
-- COLORPICKER UI
-- ============================================================
local function buildColorpickerUI(parent, opts)
    opts = opts or {}
    local color = opts.Color or Color3.fromRGB(77, 107, 254)
    local alpha = opts.Alpha or 0
    local h, s, v = Color3.toHSV(color)
    local rainbowEnabled = opts.Rainbow or false
    local rainbowSpeed = opts.RainbowSpeed or 1
    local onChange = opts.OnChange or function() end
    local W = opts.Width or 240
    local root = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(0,W,0,300)}, parent)
    local sv = new("Frame", {BackgroundColor3 = Color3.fromHSV(h,1,1), BorderSizePixel = 0,
        Position = UDim2.new(0,0,0,0), Size = UDim2.new(1,0,0,110), ClipsDescendants = true,
        ZIndex = (parent.ZIndex or 1) + 10}, root)
    addCorner(sv, UDim.new(0,6))
    new("ImageLabel", {BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0),
        Image = "rbxassetid://4155801252", ZIndex = (parent.ZIndex or 1) + 11}, sv)
    local satO = new("Frame", {BackgroundColor3 = Color3.fromRGB(255,255,255),
        BackgroundTransparency = 1-s, BorderSizePixel = 0, Size = UDim2.new(1,0,1,0),
        ZIndex = (parent.ZIndex or 1) + 12}, sv)
    local valO = new("Frame", {BackgroundColor3 = Color3.fromRGB(0,0,0),
        BackgroundTransparency = 1-v, BorderSizePixel = 0, Size = UDim2.new(1,0,1,0),
        ZIndex = (parent.ZIndex or 1) + 13}, sv)
    local hue = new("Frame", {BackgroundColor3 = Color3.fromRGB(255,255,255), BorderSizePixel = 0,
        Position = UDim2.new(0,0,0,118), Size = UDim2.new(1,0,0,12),
        ZIndex = (parent.ZIndex or 1) + 10}, root)
    addCorner(hue, UDim.new(1,0))
    new("UIGradient", {Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)),
        ColorSequenceKeypoint.new(1/6, Color3.fromRGB(255,255,0)),
        ColorSequenceKeypoint.new(2/6, Color3.fromRGB(0,255,0)),
        ColorSequenceKeypoint.new(3/6, Color3.fromRGB(0,255,255)),
        ColorSequenceKeypoint.new(4/6, Color3.fromRGB(0,0,255)),
        ColorSequenceKeypoint.new(5/6, Color3.fromRGB(255,0,255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255,0,0))}}, hue)
    local alphaBg = new("Frame", {BackgroundColor3 = Color3.fromRGB(230,232,238), BorderSizePixel = 0,
        Position = UDim2.new(0,0,0,138), Size = UDim2.new(1,0,0,12),
        ClipsDescendants = true, ZIndex = (parent.ZIndex or 1) + 10}, root)
    addCorner(alphaBg, UDim.new(1,0))
    for i = 0, 10 do
        new("Frame", {BackgroundColor3 = Color3.fromRGB(180,184,192), BorderSizePixel = 0,
            Position = UDim2.new(i/10,0,0,0), Size = UDim2.new(0.05,0,0.5,0),
            ZIndex = (parent.ZIndex or 1) + 11}, alphaBg)
        new("Frame", {BackgroundColor3 = Color3.fromRGB(180,184,192), BorderSizePixel = 0,
            Position = UDim2.new((i+0.5)/10,0,0.5,0), Size = UDim2.new(0.05,0,0.5,0),
            ZIndex = (parent.ZIndex or 1) + 11}, alphaBg)
    end
    local alphaFill = new("Frame", {BackgroundColor3 = color, BorderSizePixel = 0,
        Size = UDim2.new(1,0,1,0), ZIndex = (parent.ZIndex or 1) + 12}, alphaBg)
    local alphaGrad = new("UIGradient", {Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, alpha), NumberSequenceKeypoint.new(1, 0)}),
        Rotation = 0}, alphaFill)
    local alphaKnob = new("Frame", {BackgroundColor3 = Color3.fromRGB(255,255,255), BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new(1-alpha,0,0.5,0),
        Size = UDim2.new(0,14,0,14), ZIndex = (parent.ZIndex or 1) + 13}, alphaBg)
    addCorner(alphaKnob, UDim.new(1,0)); addStroke(alphaKnob, Theme.Accent, 2)
    local hex = new("TextBox", {BorderSizePixel = 0, Position = UDim2.new(0,0,0,160),
        Size = UDim2.new(1,0,0,24), Font = Config.CurrentFontFamily, Text = "", TextSize = 11,
        ClearTextOnFocus = false, ZIndex = (parent.ZIndex or 1) + 10}, root)
    themeBg(hex, "ElementHover"); themeText(hex, "Text")
    addCorner(hex, UDim.new(0,6)); addPadding(hex, 8)
    local rbRow = new("Frame", {BorderSizePixel = 0, Position = UDim2.new(0,0,0,192),
        Size = UDim2.new(1,0,0,28), ZIndex = (parent.ZIndex or 1) + 10}, root)
    themeBg(rbRow, "ElementHover"); addCorner(rbRow, UDim.new(0,6))
    local rbLabel = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0,10,0,0),
        Size = UDim2.new(0.7,-10,1,0), Font = Config.CurrentFontFamily, Text = "Rainbow",
        TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = (parent.ZIndex or 1) + 11}, rbRow)
    themeText(rbLabel, "Text")
    local rbSw = new("Frame", {BackgroundColor3 = rainbowEnabled and Theme.Accent or Color3.fromRGB(214, 218, 226),
        BorderSizePixel = 0, Position = UDim2.new(1,-38,0.5,-8), Size = UDim2.new(0,30,0,16),
        ZIndex = (parent.ZIndex or 1) + 11}, rbRow)
    addCorner(rbSw, UDim.new(1,0))
    local rbKnob = new("Frame", {BackgroundColor3 = Color3.fromRGB(255,255,255), BorderSizePixel = 0,
        Position = rainbowEnabled and UDim2.new(1,-14,0,2) or UDim2.new(0,2,0,2),
        Size = UDim2.new(0,12,0,12), ZIndex = (parent.ZIndex or 1) + 12}, rbSw)
    addCorner(rbKnob, UDim.new(1,0))
    local rbToggle = new("TextButton", {BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0),
        Text = "", ZIndex = (parent.ZIndex or 1) + 13}, rbRow)
    local rainbowCtrl = {
        active = rainbowEnabled,
        speed = rainbowSpeed,
        root = root,
        keepAlive = opts.KeepAlive or false,
        setFromRainbow = function(hv)
            h = hv; s = 1; v = 1
            color = Color3.fromHSV(h, s, v)
            if sv and sv.Parent then sv.BackgroundColor3 = Color3.fromHSV(h,1,1) end
            if satO and satO.Parent then satO.BackgroundTransparency = 0 end
            if valO and valO.Parent then valO.BackgroundTransparency = 0 end
            if alphaFill and alphaFill.Parent then alphaFill.BackgroundColor3 = color end
            if hex and hex.Parent then
                hex.Text = string.format("#%02X%02X%02X",
                    math.floor(color.R*255+0.5), math.floor(color.G*255+0.5), math.floor(color.B*255+0.5))
            end
            pcall(onChange, color, alpha, {rainbowEnabled = true, rainbowSpeed = rainbowSpeed})
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
        if alphaFill and alphaFill.Parent then alphaFill.BackgroundColor3 = color end
        if hex and hex.Parent then hex.Text = hexStr(color) end
    end
    applyMain()
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
    local svDrag, hueDrag, alphaDrag = false, false, false
    local function disableRainbow()
        if rainbowEnabled then
            rainbowEnabled = false
            rainbowCtrl.active = false
            tween(rbSw, {BackgroundColor3 = Color3.fromRGB(214, 218, 226)})
            tween(rbKnob, {Position = UDim2.new(0,2,0,2)})
            pcall(onChange, color, alpha, {rainbowEnabled = false, rainbowSpeed = rainbowSpeed})
        end
    end
    sv.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            svDrag = true; disableRainbow()
            local rx = math.clamp((i.Position.X - sv.AbsolutePosition.X) / sv.AbsoluteSize.X, 0, 1)
            local ry = math.clamp((i.Position.Y - sv.AbsolutePosition.Y) / sv.AbsoluteSize.Y, 0, 1)
            s, v = rx, 1 - ry; applyMain()
            pcall(onChange, color, alpha, {rainbowEnabled = false, rainbowSpeed = rainbowSpeed})
        end
    end)
    hue.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            hueDrag = true; disableRainbow()
            h = math.clamp((i.Position.X - hue.AbsolutePosition.X) / hue.AbsoluteSize.X, 0, 1)
            applyMain(); pcall(onChange, color, alpha, {rainbowEnabled = false, rainbowSpeed = rainbowSpeed})
        end
    end)
    alphaBg.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            alphaDrag = true
            local rel = math.clamp((i.Position.X - alphaBg.AbsolutePosition.X) / alphaBg.AbsoluteSize.X, 0, 1)
            alpha = 1 - rel
            alphaKnob.Position = UDim2.new(rel, 0, 0.5, 0)
            if alphaGrad then
                alphaGrad.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, alpha), NumberSequenceKeypoint.new(1, 0)})
            end
            pcall(onChange, color, alpha, {rainbowEnabled = rainbowEnabled, rainbowSpeed = rainbowSpeed})
        end
    end)
    _T(UserInputService.InputChanged:Connect(function(i)
        if i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        if svDrag then
            local rx = math.clamp((i.Position.X - sv.AbsolutePosition.X) / sv.AbsoluteSize.X, 0, 1)
            local ry = math.clamp((i.Position.Y - sv.AbsolutePosition.Y) / sv.AbsoluteSize.Y, 0, 1)
            s, v = rx, 1 - ry; applyMain()
            pcall(onChange, color, alpha, {rainbowEnabled = false, rainbowSpeed = rainbowSpeed})
        end
        if hueDrag then
            h = math.clamp((i.Position.X - hue.AbsolutePosition.X) / hue.AbsoluteSize.X, 0, 1)
            applyMain(); pcall(onChange, color, alpha, {rainbowEnabled = false, rainbowSpeed = rainbowSpeed})
        end
        if alphaDrag then
            local rel = math.clamp((i.Position.X - alphaBg.AbsolutePosition.X) / alphaBg.AbsoluteSize.X, 0, 1)
            alpha = 1 - rel
            alphaKnob.Position = UDim2.new(rel, 0, 0.5, 0)
            if alphaGrad then
                alphaGrad.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, alpha), NumberSequenceKeypoint.new(1, 0)})
            end
            pcall(onChange, color, alpha, {rainbowEnabled = rainbowEnabled, rainbowSpeed = rainbowSpeed})
        end
    end))
    _T(UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            svDrag, hueDrag, alphaDrag = false, false, false
        end
    end))
    hex.FocusLost:Connect(function()
        local txt = hex.Text:gsub("#","")
        local r = tonumber(txt:sub(1,2),16)
        local g = tonumber(txt:sub(3,4),16)
        local b = tonumber(txt:sub(5,6),16)
        if r and g and b then
            disableRainbow()
            color = Color3.fromRGB(r,g,b); h, s, v = Color3.toHSV(color)
            applyMain(); pcall(onChange, color, alpha, {rainbowEnabled = false, rainbowSpeed = rainbowSpeed})
        else hex.Text = hexStr(color) end
    end)
    return root, {
        Get = function() return color, alpha end,
        Set = function(c, a) 
            color = c; if a then alpha = a end
            h, s, v = Color3.toHSV(c); applyMain()
        end,
        GetRainbow = function() return rainbowEnabled, rainbowSpeed end,
        Destroy = function() 
            rainbowCtrl.active = false
            rainbowCtrl.keepAlive = false
        end,
    }
end

-- ============================================================
-- KEYBIND MODE PICKER
-- ============================================================
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
        Notify("Keybind", (opt.Name or "?") .. ": " .. modes[1] .. " " .. (cur and "ON" or "OFF"), "info", 1.2)
        return
    end
    if openPickerMenu then
        openPickerMenu(anchor, opt, state, modes, id)
    end
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
        Text = (opt.Name or "Keybind"), TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = Config.PopupZ + 81}, popup)
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
        ib.MouseEnter:Connect(function()
            if item ~= active then tween(ib, {BackgroundColor3 = Theme.Element}) end end)
        ib.MouseLeave:Connect(function()
            if item ~= active then tween(ib, {BackgroundColor3 = Theme.ElementHover}) end end)
        ib.MouseButton1Click:Connect(function()
            state["__kbActive_" .. tostring(id)] = item
            if opt.Callback then pcall(opt.Callback, item, state) end
            Notify("Keybind", (opt.Name or "?") .. " → " .. tostring(item), "info", 1.2)
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

-- ============================================================
-- BIND POPUP
-- ============================================================
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
    local typeLbl = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0,20,0,28),
        Size = UDim2.new(1,-30,0,12), Font = Config.CurrentFontFamily,
        Text = "MMB opens | type: " .. (bind.type or "?"),
        TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = Config.PopupZ + 51}, popup)
    themeText(typeLbl, "SubText")
    local hintLbl = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0,20,0,44),
        Size = UDim2.new(1,-30,0,12), Font = Config.CurrentFontFamily,
        Text = "TGL=Toggle  HLD=Hold  OHD=OnHoldDisable",
        TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = Config.PopupZ + 51}, popup)
    themeText(hintLbl, "Muted")
    local listScroll = new("ScrollingFrame", {BackgroundTransparency = 1, BorderSizePixel = 0,
        Position = UDim2.new(0,10,0,62), Size = UDim2.new(1,-20,0,popupH - 152),
        CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3, ZIndex = Config.PopupZ + 51}, popup)
    listScroll.ScrollBarImageColor3 = Theme.Accent
    new("UIListLayout", {Padding = UDim.new(0,6), SortOrder = Enum.SortOrder.LayoutOrder}, listScroll)
    local function valueToText(v, default)
        if v ~= nil then return tostring(v) end
        if default ~= nil then return tostring(default) end
        return ""
    end
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
                    kb.Text = keyName(nk)
                    kb.TextColor3 = Theme.Text
                    bindListening = false; c:Disconnect(); fireBind(bind)
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
                fireBind(bind)
            end)
            local del = new("TextButton", {BackgroundColor3 = Theme.Danger, BackgroundTransparency = 0.7,
                BorderSizePixel = 0, Position = UDim2.new(1,-36,0,7), Size = UDim2.new(0,28,0,22),
                Font = Config.CurrentFontFamily, Text = "x", TextColor3 = Theme.Danger, TextSize = 12,
                AutoButtonColor = false, ZIndex = Config.PopupZ + 53}, r)
            addCorner(del, UDim.new(0,4))
            del.MouseEnter:Connect(function() tween(del, {BackgroundTransparency = 0, TextColor3 = Theme.OnAccent}) end)
            del.MouseLeave:Connect(function() tween(del, {BackgroundTransparency = 0.7, TextColor3 = Theme.Danger}) end)
            del.MouseButton1Click:Connect(function() RemoveBindKey(bindId, i, true); refresh() end)
            if hasValue then
                local vl = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0,10,0,38),
                    Size = UDim2.new(0,50,0,20), Font = Config.CurrentFontFamily, Text = "Value",
                    TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = Config.PopupZ + 53}, r)
                themeText(vl, "SubText")
                local vb = new("TextBox", {BorderSizePixel = 0,
                    Position = UDim2.new(0,62,0,38), Size = UDim2.new(1,-72,0,20),
                    Font = Config.CurrentFontFamily, Text = valueToText(e.value, bind.default),
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
        if #bind.keys == 0 then
            local empty = new("TextLabel", {BackgroundTransparency = 1,
                Size = UDim2.new(1,0,0,24), Font = Config.CurrentFontFamily,
                Text = "No keys bound. Press + Add Key.",
                TextSize = 10, TextWrapped = true, LayoutOrder = 999,
                ZIndex = Config.PopupZ + 52}, listScroll)
            themeText(empty, "Muted")
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
    clearBtn.MouseEnter:Connect(function() tween(clearBtn, {BackgroundTransparency = 0, TextColor3 = Theme.OnAccent}) end)
    clearBtn.MouseLeave:Connect(function() tween(clearBtn, {BackgroundTransparency = 0.85, TextColor3 = Theme.Danger}) end)
    clearBtn.MouseButton1Click:Connect(function() ClearBind(bindId, true); refresh() end)
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

-- ============================================================
-- BIND INPUT
-- ============================================================
local lastOpenTime = 0
local OPEN_THROTTLE = 0.15
local function canOpenBind()
    local now = tick()
    if now - lastOpenTime < OPEN_THROTTLE then return false end
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
    local function rmbHandler(input)
        if bindListening then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton2 then return end
        if not canOpenBind() then return end
        openOptionsMenu(row, meta)
    end
    row.InputBegan:Connect(rmbHandler)
    for _, d in ipairs(row:GetDescendants()) do
        if d:IsA("GuiObject") then d.InputBegan:Connect(rmbHandler) end
    end
end

local function attachRowBinds(row, bindId, meta)
    local hasOptions = meta and meta.Options and #meta.Options > 0
    attachRowRMB(row, meta, hasOptions)
    attachRowMMB(row, bindId)
end

-- ============================================================
-- OPTIONS POPUP
-- ============================================================
function openOptionsMenu(anchor, meta)
    if not meta then return end
    local opts = meta.Options
    local state = meta.State or {}
    for _, opt in ipairs(opts or {}) do
        if opt.Key and state[opt.Key] == nil then state[opt.Key] = opt.Default end
    end
    local POPUP_W = 360
    local popup = new("Frame", {Name = "OptionsPopup", BorderSizePixel = 0,
        Size = UDim2.new(0,POPUP_W,0,200), Visible = false, ZIndex = Config.PopupZ}, nil)
    themeBg(popup, "Panel"); addCorner(popup, UDim.new(0,10))
    addStroke(popup, Theme.Outline, 1, 0.1)
    new("Frame", {BackgroundColor3 = Theme.Accent2, BorderSizePixel = 0,
        Size = UDim2.new(0,3,0,180), Position = UDim2.new(0,8,0,10),
        ZIndex = Config.PopupZ + 1}, popup)
    local hdr = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0,20,0,10),
        Size = UDim2.new(1,-30,0,16), Font = Config.CurrentFontFamily,
        Text = (meta.Name or "Options") .. " — Advanced", TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = Config.PopupZ + 1}, popup)
    themeText(hdr, "Text")
    local subHdr = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0,20,0,28),
        Size = UDim2.new(1,-30,0,12), Font = Config.CurrentFontFamily,
        Text = "MMB on row = bind | " .. (meta.Type or "?"),
        TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = Config.PopupZ + 1}, popup)
    themeText(subHdr, "SubText")
    local inner = new("Frame", {BackgroundTransparency = 1,
        Position = UDim2.new(0,10,0,48), Size = UDim2.new(1,-20,0,100), ZIndex = Config.PopupZ + 1}, popup)
    new("UIListLayout", {Padding = UDim.new(0,6), SortOrder = Enum.SortOrder.LayoutOrder}, inner)
    local rebuild

    local function optBindId(opt, suffix)
        local base = "opt_" .. tostring(meta.Name or "x") .. "_" .. tostring(opt.Key or opt.Name or "y")
        if suffix then base = base .. "_" .. suffix end
        return base
    end
    local function attachOptionBindInputs(row, bindId)
        if not bindId then return end
        attachRowMMB(row, bindId)
    end

    local function createControlRow(parent, opt, layoutOrder, st)
        local rowH = 34
        if opt.Type == "Divider" or opt.Type == "Label" then rowH = 22
        elseif opt.Type == "Slider" then rowH = 42 end
        local row = new("Frame", {BorderSizePixel = 0,
            Size = UDim2.new(1,0,0,rowH), LayoutOrder = layoutOrder,
            BackgroundTransparency = (opt.Type == "Divider" or opt.Type == "Label") and 1 or 0,
            ZIndex = Config.PopupZ + 2}, parent)
        if opt.Type ~= "Divider" and opt.Type ~= "Label" then
            themeBg(row, "ElementHover"); addCorner(row, UDim.new(0,6))
        end
        if opt.Type == "Divider" then
            local lbl = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0,0,0,0),
                Size = UDim2.new(1,0,1,-4), Font = Config.CurrentFontFamily, Text = opt.Text or "",
                TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = Config.PopupZ + 3}, row)
            themeText(lbl, "Muted")
            new("Frame", {BorderSizePixel = 0, Position = UDim2.new(0,0,1,-2),
                Size = UDim2.new(1,0,0,1), BackgroundColor3 = Theme.Outline, ZIndex = Config.PopupZ + 3}, row)
            return row
        elseif opt.Type == "Label" then
            local lbl = new("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0),
                Font = Config.CurrentFontFamily, Text = opt.Text or "", TextSize = 10, TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left, ZIndex = Config.PopupZ + 3}, row)
            themeText(lbl, "SubText")
            return row
        elseif opt.Type == "Toggle" then
            local bindId = optBindId(opt, "tgl")
            local nameLbl = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0,12,0,0),
                Size = UDim2.new(1,-60,1,0), Font = Config.CurrentFontFamily, Text = opt.Name or "Toggle",
                TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = Config.PopupZ + 3}, row)
            themeText(nameLbl, "Text")
            local value = st[opt.Key] and true or false
            local sw = new("Frame", {BackgroundColor3 = value and Theme.Accent or Color3.fromRGB(214, 218, 226),
                BorderSizePixel = 0, Position = UDim2.new(1,-46,0.5,-8),
                Size = UDim2.new(0,36,0,16), ZIndex = Config.PopupZ + 3}, row)
            addCorner(sw, UDim.new(1,0))
            local knob = new("Frame", {BackgroundColor3 = Color3.fromRGB(255,255,255), BorderSizePixel = 0,
                Position = value and UDim2.new(1,-18,0,2) or UDim2.new(0,2,0,2),
                Size = UDim2.new(0,12,0,12), ZIndex = Config.PopupZ + 4}, sw)
            addCorner(knob, UDim.new(1,0))
            local click = new("TextButton", {BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0),
                Text = "", ZIndex = Config.PopupZ + 6}, row)
            click.MouseButton1Click:Connect(function()
                local nv = not (st[opt.Key] and true or false)
                st[opt.Key] = nv
                if opt.Callback then pcall(opt.Callback, nv, st) end
                rebuild()
            end)
            RegisterBind(bindId, opt.Name or "Toggle", function(ov)
                local nv
                if ov ~= nil then nv = ov and true or false
                else nv = not (st[opt.Key] and true or false) end
                st[opt.Key] = nv
                if opt.Callback then pcall(opt.Callback, nv, st) end
                rebuild()
            end, "Toggle", st[opt.Key])
            attachOptionBindInputs(row, bindId)
            return row
        elseif opt.Type == "Slider" then
            local bindId = optBindId(opt, "sld")
            local value = st[opt.Key] or opt.Min or 0
            local min, max = opt.Min or 0, opt.Max or 100
            local dec = opt.Decimals or 0
            local nameLbl = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0,12,0,3),
                Size = UDim2.new(1,-80,0,14), Font = Config.CurrentFontFamily, Text = opt.Name or "Slider",
                TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = Config.PopupZ + 3}, row)
            themeText(nameLbl, "Text")
            local vLbl = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(1,-80,0,3),
                Size = UDim2.new(0,60,0,14), Font = Config.CurrentFontFamily, Text = tostring(value),
                TextSize = 11, TextColor3 = Theme.Accent,
                TextXAlignment = Enum.TextXAlignment.Right, ZIndex = Config.PopupZ + 3}, row)
            local track = new("Frame", {BorderSizePixel = 0, Position = UDim2.new(0,12,1,-16),
                Size = UDim2.new(1,-34,0,5), ZIndex = Config.PopupZ + 3}, row)
            themeBg(track, "Panel"); addCorner(track, UDim.new(1,0))
            local fill = new("Frame", {BorderSizePixel = 0,
                Size = UDim2.new(math.clamp((value-min)/(max-min), 0, 1),0,1,0),
                ZIndex = Config.PopupZ + 4}, track)
            themeBg(fill, "Accent"); addCorner(fill, UDim.new(1,0))
            local knob = new("Frame", {BackgroundColor3 = Color3.fromRGB(255,255,255), BorderSizePixel = 0,
                AnchorPoint = Vector2.new(0.5,0.5),
                Position = UDim2.new(math.clamp((value-min)/(max-min), 0, 1),0,0.5,0),
                Size = UDim2.new(0,14,0,14), ZIndex = Config.PopupZ + 5}, track)
            addCorner(knob, UDim.new(1,0)); addStroke(knob, Theme.Accent, 2)
            local function rnd(n) local m = 10^dec; return math.floor(n*m+0.5)/m end
            local function apply(x)
                local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                local nv = rnd(min + (max-min)*rel)
                st[opt.Key] = nv; vLbl.Text = tostring(nv)
                fill.Size = UDim2.new(rel, 0, 1, 0)
                knob.Position = UDim2.new(rel, 0, 0.5, 0)
                if opt.Callback then pcall(opt.Callback, nv, st) end
            end
            local drag = false
            track.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then
                    drag = true; apply(i.Position.X)
                end
            end)
            _T(UserInputService.InputChanged:Connect(function(i)
                if drag and i.UserInputType == Enum.UserInputType.MouseMovement then apply(i.Position.X) end
            end))
            _T(UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
            end))
            RegisterBind(bindId, opt.Name or "Slider", function(ov)
                if ov ~= nil then
                    local n = tonumber(ov)
                    if n then
                        st[opt.Key] = math.clamp(n, min, max)
                        if opt.Callback then pcall(opt.Callback, st[opt.Key], st) end
                        rebuild()
                    end
                end
            end, "Slider", st[opt.Key] or min)
            attachOptionBindInputs(row, bindId)
            return row
        elseif opt.Type == "Colorpicker" then
            local bindId = optBindId(opt, "cp")
            local value = st[opt.Key] or Color3.fromRGB(77, 107, 254)
            local alphaV = st["__alpha_" .. tostring(opt.Key)] or 0
            local nameLbl = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0,12,0,0),
                Size = UDim2.new(1,-90,1,0), Font = Config.CurrentFontFamily, Text = opt.Name or "Color",
                TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = Config.PopupZ + 3}, row)
            themeText(nameLbl, "Text")
            local sw = new("Frame", {BackgroundColor3 = value, BorderSizePixel = 0,
                Position = UDim2.new(1,-52,0.5,-11), Size = UDim2.new(0,42,0,22),
                ZIndex = Config.PopupZ + 3}, row)
            addCorner(sw, UDim.new(0,6)); addStroke(sw, Theme.Outline, 1, 0.2)
            local click = new("TextButton", {BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0),
                Text = "", ZIndex = Config.PopupZ + 6}, row)
            click.MouseButton1Click:Connect(function()
                local sub = new("Frame", {BackgroundColor3 = Theme.Panel, BorderSizePixel = 0,
                    Size = UDim2.new(0,280,0,300), Visible = true, ZIndex = Config.PopupZ + 20}, nil)
                addCorner(sub, UDim.new(0,10)); addStroke(sub, Theme.Outline, 1, 0.1)
                local subTitle = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0,16,0,10),
                    Size = UDim2.new(1,-28,0,16), Font = Config.CurrentFontFamily, Text = opt.Name or "Color",
                    TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = Config.PopupZ + 21}, sub)
                themeText(subTitle, "Text")
                local cpHolder = new("Frame", {BackgroundTransparency = 1,
                    Position = UDim2.new(0,20,0,32), Size = UDim2.new(1,-40,0,240),
                    ZIndex = Config.PopupZ + 21}, sub)
                local cpApi = buildColorpickerUI(cpHolder, {
                    Color = value, Alpha = alphaV, Width = 240,
                    OnChange = function(c, a)
                        st[opt.Key] = c; st["__alpha_" .. tostring(opt.Key)] = a
                        sw.BackgroundColor3 = c
                        if opt.Callback then pcall(opt.Callback, c, a) end
                    end,
                })
                local closeSub = new("TextButton", {BorderSizePixel = 0,
                    Position = UDim2.new(0,16,1,-38), Size = UDim2.new(1,-32,0,28),
                    Font = Config.CurrentFontFamily, Text = "Close", TextSize = 11, AutoButtonColor = false,
                    ZIndex = Config.PopupZ + 21}, sub)
                themeBg(closeSub, "Accent"); closeSub.TextColor3 = Theme.OnAccent
                addCorner(closeSub, UDim.new(0,6))
                closeSub.MouseButton1Click:Connect(function()
                    if cpApi and cpApi.Destroy then cpApi.Destroy() end
                    closeTopPopup()
                end)
                pushPopup(sub, function()
                    if row and row.Parent and sub.Parent then
                        local ap, as = row.AbsolutePosition, row.AbsoluteSize
                        local vp = workspace.CurrentCamera.ViewportSize
                        local x, y = ap.X + as.X + 8, ap.Y
                        if x + 280 > vp.X then x = ap.X - 288 end
                        if y + 300 > vp.Y then y = vp.Y - 300 - 8 end
                        if y < 4 then y = 4 end
                        sub.Position = UDim2.fromOffset(x, y)
                    end
                end, function() end)
            end)
            RegisterBind(bindId, opt.Name or "Color", function() end, "Colorpicker", true)
            attachOptionBindInputs(row, bindId)
            return row
        end
        return row
    end

    rebuild = function()
        for _, c in ipairs(inner:GetChildren()) do
            if not c:IsA("UIListLayout") then c:Destroy() end
        end
        if not opts or #opts == 0 then
            local empty = new("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(1,0,0,24),
                Font = Config.CurrentFontFamily, Text = "No advanced options.",
                TextSize = 10, LayoutOrder = 1, ZIndex = Config.PopupZ + 2}, inner)
            themeText(empty, "Muted")
        end
        local order = 0
        for _, opt in ipairs(opts or {}) do
            local visible = true
            if opt.VisibleIf then
                local ok, v = pcall(opt.VisibleIf, state)
                visible = ok and (v and true or false) or false
            end
            if visible then
                order = order + 1
                createControlRow(inner, opt, order, state)
            end
        end
        task.defer(function()
            local layout = inner:FindFirstChildOfClass("UIListLayout")
            local contentH = layout and layout.AbsoluteContentSize.Y or 0
            local totalH = math.clamp(48 + contentH + 48, 140, 560)
            popup.Size = UDim2.new(0,POPUP_W,0,totalH)
            inner.Size = UDim2.new(1,-20,0,contentH)
        end)
        reevaluateVisibility()
    end
    local closeBtn = new("TextButton", {BorderSizePixel = 0,
        Position = UDim2.new(0,10,1,-38), Size = UDim2.new(1,-20,0,28),
        Font = Config.CurrentFontFamily, Text = "Close", TextSize = 11,
        AutoButtonColor = false, ZIndex = Config.PopupZ + 2}, popup)
    themeBg(closeBtn, "ElementHover"); themeText(closeBtn, "Text")
    addCorner(closeBtn, UDim.new(0,6))
    closeBtn.MouseButton1Click:Connect(function() closeTopPopup() end)
    rebuild()
    pushPopup(popup, function()
        if not anchor or not anchor.Parent then return end
        local ap, as = anchor.AbsolutePosition, anchor.AbsoluteSize
        local vp = workspace.CurrentCamera.ViewportSize
        local x, y = ap.X + as.X + 8, ap.Y
        if x + POPUP_W > vp.X then x = ap.X - POPUP_W - 8 end
        if y + popup.AbsoluteSize.Y > vp.Y then y = vp.Y - popup.AbsoluteSize.Y - 8 end
        if y < 4 then y = 4 end
        popup.Position = UDim2.fromOffset(x, y)
    end, function() end)
end

-- ============================================================
-- HELPERS
-- ============================================================
local function registerVisibleIf(element, predicate, section)
    local st = getSectionState(section)
    watchVisibility(element, predicate, st)
end
local function makeBindId(prefix)
    return (prefix or "bind") .. "_" .. tostring(os.clock()) .. "_" .. tostring(math.random(1,99999))
end

-- ============================================================
-- COMPONENTS
-- ============================================================
local function createToggle(section, opts)
    local userState = opts.Value or false
    local eff = userState
    local row = new("Frame", {BorderSizePixel = 0, Size = UDim2.new(1,0,0,36)}, section.Content)
    themeBg(row, "Element"); regTransparency(row, "Element", 0); addCorner(row, UDim.new(0,8))
    addStroke(row, Theme.Outline, 1, 0.35)
    local accentStrip = new("Frame", {BackgroundColor3 = Theme.Muted, BorderSizePixel = 0,
        Position = UDim2.new(0,0,0.25,0), Size = UDim2.new(0,2,0.5,0), BackgroundTransparency = 0.7}, row)
    addCorner(accentStrip, UDim.new(1,0))
    local nameLbl = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0,14,0,0),
        Size = UDim2.new(1,-100,1,0), Font = Config.CurrentFontFamily, Text = opts.Name or "Toggle",
        TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left}, row)
    themeText(nameLbl, "Text")
    markSearch(row, opts.Name or "Toggle", nameLbl)
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
    local dot = new("Frame", {BackgroundColor3 = Theme.Accent2, BorderSizePixel = 0,
        Position = UDim2.new(1,-54,0.5,-3), Size = UDim2.new(0,6,0,6), Visible = false}, row)
    addCorner(dot, UDim.new(1,0))
    local function setVis(v)
        tween(sw, {BackgroundColor3 = v and Theme.Accent or Color3.fromRGB(214, 218, 226)})
        tween(knob, {Position = v and UDim2.new(1,-18,0,2) or UDim2.new(0,2,0,2)})
        tween(accentStrip, {BackgroundColor3 = v and Theme.Accent or Theme.Muted, BackgroundTransparency = v and 0 or 0.7})
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
    local bind = RegisterBind(bindId, opts.Name or "Toggle",
        function(ov) setEff(ov ~= nil and (ov and true or false) or userState, true) end,
        "Toggle", true)
    task.spawn(function() while row.Parent do dot.Visible = #bind.keys > 0; task.wait(0.3) end end)
    if opts.Key then getSectionState(section)[opts.Key] = eff end
    local meta = {Name = opts.Name or "Toggle", Type = "Toggle", Element = row, BindId = bindId,
        Options = opts.Options, State = getSectionState(section),
        Set = function(v) userState = v; setEff(v, false) end}
    attachRowBinds(row, bindId, meta)
    if opts.Tooltip then attachTooltip(row, opts.Tooltip) end
    if opts.VisibleIf then registerVisibleIf(row, opts.VisibleIf, section) end
    return {Set = meta.Set, Get = function() return eff end, BindId = bindId, _meta = meta}
end

local function createSlider(section, opts)
    local min, max = opts.Min or 0, opts.Max or 100
    local dec = opts.Decimals or 0
    local userV = opts.Value or min
    local effV = userV
    local row = new("Frame", {BorderSizePixel = 0, Size = UDim2.new(1,0,0,52)}, section.Content)
    themeBg(row, "Element"); regTransparency(row, "Element", 0); addCorner(row, UDim.new(0,8))
    addStroke(row, Theme.Outline, 1, 0.35)
    local accentStrip = new("Frame", {BackgroundColor3 = Theme.Accent, BorderSizePixel = 0,
        Position = UDim2.new(0,0,0.25,0), Size = UDim2.new(0,2,0.5,0)}, row)
    addCorner(accentStrip, UDim.new(1,0))
    local nameLbl = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0,14,0,6),
        Size = UDim2.new(1,-90,0,16), Font = Config.CurrentFontFamily, Text = opts.Name or "Slider",
        TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left}, row)
    themeText(nameLbl, "Text")
    markSearch(row, opts.Name or "Slider", nameLbl)
    local vLbl = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(1,-80,0,6),
        Size = UDim2.new(0,68,0,16), Font = Config.CurrentFontFamily, Text = tostring(effV), TextSize = 11,
        TextColor3 = Theme.Accent, TextXAlignment = Enum.TextXAlignment.Right}, row)
    local dot = new("Frame", {BackgroundColor3 = Theme.Accent2, BorderSizePixel = 0,
        Position = UDim2.new(1,-88,0.5,-3), Size = UDim2.new(0,6,0,6), Visible = false}, row)
    addCorner(dot, UDim.new(1,0))
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
    local function setFromX(x)
        local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        userV = rnd(min + (max-min)*rel); setEff(userV, true)
    end
    local drag = false
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
           or i.UserInputType == Enum.UserInputType.Touch then drag = true; setFromX(i.Position.X) end
    end)
    _T(UserInputService.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement
            or i.UserInputType == Enum.UserInputType.Touch) then setFromX(i.Position.X) end end))
    _T(UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
           or i.UserInputType == Enum.UserInputType.Touch then drag = false end end))
    local bindId = opts.BindId or makeBindId("bind_sld")
    local bind = RegisterBind(bindId, opts.Name or "Slider",
        function(ov)
            if ov ~= nil then local v = tonumber(ov); if v then setEff(v, true) end
            else setEff(userV, true) end
        end, "Slider", (min+max)/2)
    task.spawn(function() while row.Parent do dot.Visible = #bind.keys > 0; task.wait(0.3) end end)
    if opts.Key then getSectionState(section)[opts.Key] = effV end
    local meta = {Name = opts.Name or "Slider", Type = "Slider", Element = row, BindId = bindId,
        Options = opts.Options, State = getSectionState(section),
        Set = function(v) userV = math.clamp(v, min, max); setEff(userV, false) end}
    attachRowBinds(row, bindId, meta)
    if opts.Tooltip then attachTooltip(row, opts.Tooltip) end
    if opts.VisibleIf then registerVisibleIf(row, opts.VisibleIf, section) end
    return {Set = meta.Set, Get = function() return effV end, BindId = bindId, _meta = meta}
end

local function createButton(section, opts)
    local btn = new("TextButton", {BorderSizePixel = 0, Size = UDim2.new(1,0,0,36),
        Font = Config.CurrentFontFamily, Text = opts.Name or "Button", TextSize = 12, AutoButtonColor = false}, section.Content)
    themeBg(btn, "Element"); regTransparency(btn, "Element", 0); themeText(btn, "Text")
    addStroke(btn, Theme.Outline, 1, 0.35); addCorner(btn, UDim.new(0,8))
    markSearch(btn, opts.Name or "Button", btn)
    btn.MouseEnter:Connect(function() tween(btn, {BackgroundColor3 = Theme.Accent, TextColor3 = Theme.OnAccent}) end)
    btn.MouseLeave:Connect(function() tween(btn, {BackgroundColor3 = Theme.Element, TextColor3 = Theme.Text}) end)
    btn.MouseButton1Click:Connect(function() if opts.Callback then pcall(opts.Callback) end end)
    local bindId = opts.BindId or makeBindId("bind_btn")
    local bind = RegisterBind(bindId, opts.Name or "Button",
        function(ov) if ov ~= false then if opts.Callback then pcall(opts.Callback) end end end, "Button", true)
    local dot = new("Frame", {BackgroundColor3 = Theme.Accent2, BorderSizePixel = 0,
        Position = UDim2.new(1,-10,0.5,-3), Size = UDim2.new(0,6,0,6), Visible = false}, btn)
    addCorner(dot, UDim.new(1,0))
    task.spawn(function() while btn.Parent do dot.Visible = #bind.keys > 0; task.wait(0.3) end end)
    local meta = {Name = opts.Name or "Button", Type = "Button", Element = btn, BindId = bindId,
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
        Font = Config.CurrentFontFamily, Text = text, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true}, section.Content)
    -- Only register with theme if no explicit custom color was passed
    if opts.Color then
        lbl.TextColor3 = opts.Color
    else
        themeText(lbl, "SubText")
    end
    markSearch(lbl, text, lbl)
    if opts.VisibleIf then registerVisibleIf(lbl, opts.VisibleIf, section) end
    return lbl
end

local function createDivider(section, opts)
    local h = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1,0,0,22)}, section.Content)
    local lbl = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0,0,0,0),
        Size = UDim2.new(1,0,1,-4), Font = Config.CurrentFontFamily, Text = opts.Text or "",
        TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left}, h)
    if opts.Color then lbl.TextColor3 = opts.Color else themeText(lbl, "Muted") end
    markSearch(h, opts.Text or "", lbl)
    new("Frame", {BorderSizePixel = 0, Position = UDim2.new(0,0,1,-2),
        Size = UDim2.new(1,0,0,1)}, h).BackgroundColor3 = Theme.Outline
    if opts.VisibleIf then registerVisibleIf(h, opts.VisibleIf, section) end
    return h
end

local function createKeybind(section, opts)
    local value = opts.Value or Enum.KeyCode.F
    if typeof(value) == "Enum" then value = Enum.KeyCode.F end
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
        Size = UDim2.new(1,-190,1,0), Font = Config.CurrentFontFamily, Text = opts.Name or "Keybind",
        TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left}, row)
    themeText(nameLbl, "Text")
    markSearch(row, opts.Name or "Keybind", nameLbl)

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

    if #modes > 0 then
        local modeCount = new("TextLabel", {BackgroundTransparency = 1,
            Position = UDim2.new(1,-186,0.5,-8), Size = UDim2.new(0,22,0,16),
            Font = Config.CurrentFontFamily, Text = tostring(#modes) .. "m",
            TextSize = 9, TextColor3 = Theme.Accent2,
            TextXAlignment = Enum.TextXAlignment.Right}, row)
    end

    local bindId = opts.BindId or makeBindId("bind_kb")
    local bind = nil
    if not opts.NoBind then
        RegisterBind(bindId, opts.Name or "Keybind", function()
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
                    btn.Text = keyName(value)
                    btn.TextColor3 = Theme.Text
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
        fireBind(bind)
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

    local meta = {Name = opts.Name or "Keybind", Type = "Keybind", Element = row, BindId = bindId,
        Options = opts.Options, State = state, Modes = modes, Default = opts.Value,
        Set = function(v) value = v; btn.Text = keyName(v) end}
    attachRowBinds(row, bindId, meta)
    if opts.Tooltip then attachTooltip(row, opts.Tooltip) end
    if opts.VisibleIf then registerVisibleIf(row, opts.VisibleIf, section) end
    return {Set = meta.Set, Get = function() return value end, BindId = bindId, _meta = meta}
end

local function createDropdown(section, opts)
    local list = opts.List or {}
    local value = opts.Value or (list[1] or "")
    local open = false
    local row = new("Frame", {BorderSizePixel = 0, Size = UDim2.new(1,0,0,36)}, section.Content)
    themeBg(row, "Element"); regTransparency(row, "Element", 0); addCorner(row, UDim.new(0,8))
    addStroke(row, Theme.Outline, 1, 0.35)
    local nameLbl = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0,14,0,0),
        Size = UDim2.new(0.5,-10,1,0), Font = Config.CurrentFontFamily, Text = opts.Name or "Dropdown",
        TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left}, row)
    themeText(nameLbl, "Text")
    markSearch(row, opts.Name or "Dropdown", nameLbl)
    local vLbl = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0.5,0,0,0),
        Size = UDim2.new(0.5,-52,1,0), Font = Config.CurrentFontFamily, Text = tostring(value),
        TextSize = 11, TextColor3 = Theme.Accent, TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd}, row)
    local arrowLbl = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(1,-36,0,0),
        Size = UDim2.new(0,22,1,0), Font = Config.CurrentFontFamily, Text = "v",
        TextSize = 11}, row)
    themeText(arrowLbl, "SubText")
    local dot = new("Frame", {BackgroundColor3 = Theme.Accent2, BorderSizePixel = 0,
        Position = UDim2.new(1,-52,0.5,-3), Size = UDim2.new(0,6,0,6), Visible = false}, row)
    addCorner(dot, UDim.new(1,0))
    local click = new("TextButton", {BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0), Text = ""}, row)
    local itemH = 28
    local popupH = math.min(#list * (itemH+6) + 12, 220)

    local function buildDropdownPopup()
        local popup = new("ScrollingFrame", {BorderSizePixel = 0,
            Size = UDim2.new(0,200,0,popupH), CanvasSize = UDim2.new(0,0,0,0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3,
            Visible = false, ZIndex = Config.PopupZ, ClipsDescendants = true}, nil)
        themeBg(popup, "Panel"); popup.ScrollBarImageColor3 = Theme.Accent
        addCorner(popup, UDim.new(0,10)); addStroke(popup, Theme.Outline, 1, 0.1)
        new("UIListLayout", {Padding = UDim.new(0,3)}, popup); addPadding(popup, 6)
        for _, item in ipairs(list) do
            local ib = new("TextButton", {BorderSizePixel = 0,
                Size = UDim2.new(1,-8,0,itemH), Font = Config.CurrentFontFamily, Text = item,
                TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
                AutoButtonColor = false, ZIndex = Config.PopupZ + 1}, popup)
            themeBg(ib, "Panel"); themeText(ib, "Text")
            addCorner(ib, UDim.new(0,6)); addPadding(ib, 8)
            ib.MouseEnter:Connect(function()
                tween(ib, {BackgroundColor3 = Theme.ElementHover, TextColor3 = Theme.Accent}) end)
            ib.MouseLeave:Connect(function()
                tween(ib, {BackgroundColor3 = Theme.Panel, TextColor3 = Theme.Text}) end)
            ib.MouseButton1Click:Connect(function()
                value = item; vLbl.Text = item
                if opts.Callback then pcall(opts.Callback, value) end
                if opts.Key then getSectionState(section)[opts.Key] = value; reevaluateVisibility() end
                closeTopPopup()
            end)
        end
        return popup
    end

    click.MouseButton1Click:Connect(function()
        if open then closeTopPopup(); return end
        local popup = buildDropdownPopup()
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
    local bind = RegisterBind(bindId, opts.Name or "Dropdown",
        function(ov)
            if ov ~= nil and tostring(ov) ~= "" then
                local sv = tostring(ov)
                for _, it in ipairs(list) do
                    if it == sv then value = it; vLbl.Text = it
                        if opts.Callback then pcall(opts.Callback, value) end
                        return end
                end
            end
            if #list == 0 then return end
            local cur = value or list[1]; local idx = 1
            for i, v2 in ipairs(list) do if v2 == cur then idx = i; break end end
            idx = (idx % #list) + 1
            value = list[idx]; vLbl.Text = value
            if opts.Callback then pcall(opts.Callback, value) end
        end, "Dropdown", value)
    task.spawn(function() while row.Parent do
        local b = BindRegistry[bindId]; dot.Visible = b and #b.keys > 0 or false; task.wait(0.3) end end)
    if opts.Key then getSectionState(section)[opts.Key] = value end
    local meta = {Name = opts.Name or "Dropdown", Type = "Dropdown", Element = row, BindId = bindId,
        Options = opts.Options, State = getSectionState(section),
        Set = function(v) value = v; vLbl.Text = v end}
    attachRowBinds(row, bindId, meta)
    if opts.Tooltip then attachTooltip(row, opts.Tooltip) end
    if opts.VisibleIf then registerVisibleIf(row, opts.VisibleIf, section) end
    return {Set = meta.Set, Get = function() return value end, BindId = bindId, _meta = meta}
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
        Size = UDim2.new(1,-90,1,0), Font = Config.CurrentFontFamily, Text = opts.Name or "Color",
        TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left}, row)
    themeText(nameLbl, "Text")
    markSearch(row, opts.Name or "Color", nameLbl)
    local swatch = new("Frame", {BackgroundColor3 = color, BorderSizePixel = 0,
        Position = UDim2.new(1,-48,0.5,-11), Size = UDim2.new(0,36,0,22)}, row)
    addCorner(swatch, UDim.new(0,6)); addStroke(swatch, Theme.Outline, 1, 0.2)
    local click = new("TextButton", {BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0), Text = ""}, row)
    local popupH = 300
    local cachedPopup = nil
    local cachedAPI = nil

    local function buildPopup()
        local popup = new("Frame", {BorderSizePixel = 0,
            Size = UDim2.new(0,280,0,popupH), Visible = false, ZIndex = Config.PopupZ}, nil)
        themeBg(popup, "Panel"); addCorner(popup, UDim.new(0,10))
        addStroke(popup, Theme.Outline, 1, 0.1)
        local subTitle = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0,16,0,10),
            Size = UDim2.new(1,-28,0,16), Font = Config.CurrentFontFamily, Text = opts.Name or "Color",
            TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = Config.PopupZ + 1}, popup)
        themeText(subTitle, "Text")
        local holder = new("Frame", {BackgroundTransparency = 1,
            Position = UDim2.new(0,20,0,32), Size = UDim2.new(1,-40,0,240),
            ZIndex = Config.PopupZ + 1}, popup)
        local _, api = buildColorpickerUI(holder, {
            Color = color, Alpha = alpha,
            Rainbow = rainbowEnabled, RainbowSpeed = rainbowSpeed,
            KeepAlive = true,
            Width = 240,
            OnChange = function(c, a, meta)
                color = c
                if a then alpha = a end
                swatch.BackgroundColor3 = c
                if meta then
                    if meta.rainbowEnabled ~= nil then rainbowEnabled = meta.rainbowEnabled end
                    if meta.rainbowSpeed then rainbowSpeed = meta.rainbowSpeed end
                end
                if opts.Callback then pcall(opts.Callback, c, a) end
            end,
        })
        local closeBtn = new("TextButton", {BorderSizePixel = 0,
            Position = UDim2.new(0,16,1,-38), Size = UDim2.new(1,-32,0,28),
            Font = Config.CurrentFontFamily, Text = "Close", TextSize = 11, AutoButtonColor = false,
            ZIndex = Config.PopupZ + 1}, popup)
        themeBg(closeBtn, "Accent"); closeBtn.TextColor3 = Theme.OnAccent
        addCorner(closeBtn, UDim.new(0,6))
        closeBtn.MouseButton1Click:Connect(function()
            closeTopPopup()
        end)
        return popup, api
    end

    click.MouseButton1Click:Connect(function()
        if not cachedPopup or not cachedPopup.Parent then
            cachedPopup, cachedAPI = buildPopup()
        end
        pushPopup(cachedPopup, function()
            if not row or not row.Parent or not cachedPopup.Parent then return end
            local ap, as = row.AbsolutePosition, row.AbsoluteSize
            local x, y = ap.X + as.X + 8, ap.Y
            local vp = workspace.CurrentCamera.ViewportSize
            if x + 280 > vp.X then x = ap.X - 288 end
            if y + popupH > vp.Y then y = vp.Y - popupH - 8 end
            if y < 4 then y = 4 end
            cachedPopup.Position = UDim2.fromOffset(x, y)
        end, nil, {keepAlive = true})
    end)

    local meta = {Name = opts.Name or "Color", Type = "Colorpicker", Element = row,
        Options = opts.Options, State = getSectionState(section),
        Set = function(c, a)
            color = c; if a then alpha = a end
            swatch.BackgroundColor3 = c
            if cachedAPI and cachedAPI.Set then
                pcall(function() cachedAPI.Set(c, a) end)
            end
        end}
    attachRowBinds(row, nil, meta)
    if opts.Tooltip then attachTooltip(row, opts.Tooltip) end
    if opts.VisibleIf then registerVisibleIf(row, opts.VisibleIf, section) end
    return {Set = meta.Set, Get = function() return color, alpha end, _meta = meta}
end

local function createBanner(section, opts)
    local holder = new("Frame", {BorderSizePixel = 0,
        Size = UDim2.new(1,0,0,opts.Height or 90), ClipsDescendants = true}, section.Content)
    themeBg(holder, "ElementHover"); addCorner(holder, UDim.new(0,8)); addStroke(holder, Theme.Outline, 1, 0.3)
    markSearch(holder, opts.Title or "banner")
    new("ImageLabel", {BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0),
        Image = opts.Image or "rbxassetid://0", ScaleType = Enum.ScaleType.Crop}, holder)
    if opts.Title then
        local titleLbl = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0,12,1,-28),
            Size = UDim2.new(1,-24,0,20), Font = Config.CurrentFontFamily, Text = opts.Title,
            TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
            TextStrokeTransparency = 0.4}, holder)
        themeText(titleLbl, "Text")
    end
    if opts.VisibleIf then registerVisibleIf(holder, opts.VisibleIf, section) end
    return holder
end

-- ============================================================
-- SECTION
-- ============================================================
local function createSection(tab, opts)
    local holder = tab.ColumnLeft
    if opts.Side == "Right" then holder = tab.ColumnRight end
    local section = {Content = nil, Collapsed = false, Name = opts.Name or "Section", Elements = {}}
    local frame = new("Frame", {BorderSizePixel = 0,
        Size = UDim2.new(1,0,0,32), AutomaticSize = Enum.AutomaticSize.Y}, holder)
    themeBg(frame, "Section"); regTransparency(frame, "Section", 0)
    addCorner(frame, UDim.new(0,10)); addStroke(frame, Theme.Outline, 1, 0.35)
    frame:SetAttribute("SearchName", string.lower(section.Name))
    local header = new("TextButton", {BorderSizePixel = 0,
        Size = UDim2.new(1,0,0,28), Text = "", AutoButtonColor = false}, frame)
    themeBg(header, "Panel"); header.LayoutOrder = 0; addCorner(header, UDim.new(0,10))
    new("Frame", {BackgroundColor3 = Theme.Accent, BorderSizePixel = 0,
        Position = UDim2.new(0,10,0,0), Size = UDim2.new(0,3,0,14)}, header)
    local headerLbl = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0,20,0,2),
        Size = UDim2.new(1,-40,1,0), Font = Config.CurrentFontFamily, Text = section.Name,
        TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left}, header)
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
    function section:AddKeybind(o) return track(createKeybind(self, o)) end
    function section:AddDropdown(o) return track(createDropdown(self, o)) end
    function section:AddColorpicker(o) return track(createColorpicker(self, o)) end
    function section:AddDivider(o) return track(createDivider(self, o)) end
    function section:AddBanner(o) return track(createBanner(self, o)) end
    return section
end

-- ============================================================
-- TAB
-- ============================================================
local function createTab(window, opts)
    local tab = {Name = opts.Name or "Tab", Sections = {}}
    local btn = new("TextButton", {BorderSizePixel = 0, Size = UDim2.new(1,-12,0,32),
        Font = Config.CurrentFontFamily, Text = "  " .. (opts.Icon and opts.Icon .. "  " or "") .. tab.Name,
        TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false}, window.SidebarList)
    addCorner(btn, UDim.new(0,6)); themeBg(btn, "Sidebar"); themeText(btn, "SubText")
    regTransparency(btn, "Tab", 0)
    local dot = new("Frame", {BorderSizePixel = 0,
        Position = UDim2.new(0,4,0.5,-8), Size = UDim2.new(0,3,0,16), Visible = false}, btn)
    themeBg(dot, "Accent"); addCorner(dot, UDim.new(1,0))
    local badge = new("TextLabel", {BackgroundColor3 = Theme.Accent2, BorderSizePixel = 0,
        Position = UDim2.new(1,-24,0.5,-8), Size = UDim2.new(0,16,0,16),
        Font = Config.CurrentFontFamily, Text = "0", TextSize = 8,
        TextColor3 = Theme.OnAccent, Visible = false, ZIndex = 4}, btn)
    addCorner(badge, UDim.new(1,0))
    local page = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0), Visible = false},
        window.PageHolder)
    local sl = new("ScrollingFrame", {BackgroundTransparency = 1, BorderSizePixel = 0,
        Position = UDim2.new(0,0,0,0), Size = UDim2.new(0.5,-5,1,0),
        CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 0}, page)
    local sr = new("ScrollingFrame", {BackgroundTransparency = 1, BorderSizePixel = 0,
        Position = UDim2.new(0.5,5,0,0), Size = UDim2.new(0.5,-5,1,0),
        CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 0}, page)
    new("UIListLayout", {Padding = UDim.new(0,10)}, sl)
    new("UIListLayout", {Padding = UDim.new(0,10)}, sr)
    tab.Page, tab.ColumnLeft, tab.ColumnRight = page, sl, sr
    tab.Button, tab.AccentDot, tab.MatchBadge = btn, dot, badge
    tab._refresh = function()
        if window.ActiveTab == tab then
            btn.BackgroundColor3 = Theme.Panel; btn.TextColor3 = Theme.Accent
            dot.BackgroundColor3 = Theme.Accent
        else
            btn.BackgroundColor3 = Theme.Sidebar; btn.TextColor3 = Theme.SubText
        end
    end
    btn.MouseButton1Click:Connect(function() window:SelectTab(tab) end)
    btn.MouseEnter:Connect(function()
        if window.ActiveTab ~= tab then tween(btn, {BackgroundColor3 = Theme.ElementHover, TextColor3 = Theme.Text}) end end)
    btn.MouseLeave:Connect(function()
        if window.ActiveTab ~= tab then tween(btn, {BackgroundColor3 = Theme.Sidebar, TextColor3 = Theme.SubText}) end end)
    function tab:CreateSection(o) return createSection(self, o) end
    return tab
end

-- ============================================================
-- WINDOW
-- ============================================================
local function createWindow(opts)
    local window
    local parent = getSafeParent()
    local gui = new("ScreenGui", {Name = "airUI_" .. tostring(math.random(1000,9999)),
        ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true}, parent)
    ensureOverlay(gui)

    local BASE_POS = UDim2.new(0.5, 0, 0.5, 0)
    local HIDDEN_POS = UDim2.new(0.5, 0, 0.5, 30)

    local main = new("Frame", {Name = "Main", BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = BASE_POS,
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
        Size = UDim2.new(1,-330,1,0), Font = Config.CurrentFontFamily, Text = opts.Name or "airUI",
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
    local searchIcon = new("TextLabel", {BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(0, 12, 1, 0),
        Font = Config.CurrentFontFamily, Text = "/", TextSize = 11, ZIndex = 4}, searchFrame)
    themeText(searchIcon, "Muted")
    local searchBox = new("TextBox", {BackgroundTransparency = 1,
        Position = UDim2.new(0, 24, 0, 0), Size = UDim2.new(1, -50, 1, 0),
        Font = Config.CurrentFontFamily, Text = "", PlaceholderText = "Search...",
        TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, ZIndex = 4}, searchFrame)
    themeText(searchBox, "Text")
    -- Register placeholder color to update with theme
    searchBox:SetAttribute("_themePlaceholder", "Muted")
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
            local tabMatches = 0
            for _, section in ipairs(tab.Sections) do
                if section.Frame and section.Frame.Parent then
                    local sectionMatches = 0
                    for _, child in ipairs(section.Content:GetChildren()) do
                        if child:IsA("GuiObject") then
                            local nameLbl = RowNameLabels[child]
                            if not isActive then
                                child.Visible = true
                                sectionMatches = sectionMatches + 1
                                if nameLbl then highlightLabel(nameLbl, "") end
                            else
                                local sn = child:GetAttribute("SearchName")
                                if sn and string.find(sn, q, 1, true) then
                                    child.Visible = true
                                    sectionMatches = sectionMatches + 1
                                    if nameLbl then highlightLabel(nameLbl, q) end
                                else
                                    child.Visible = false
                                    if nameLbl then highlightLabel(nameLbl, "") end
                                end
                            end
                        end
                    end
                    if not isActive then
                        section.Frame.Visible = true
                    else
                        section.Frame.Visible = sectionMatches > 0
                    end
                    tabMatches = tabMatches + sectionMatches
                end
            end
            if tab.MatchBadge then
                if isActive and tabMatches > 0 then
                    tab.MatchBadge.Visible = true
                    tab.MatchBadge.Text = tostring(tabMatches)
                else
                    tab.MatchBadge.Visible = false
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
        searchBox.Text = ""
        searchBox:ReleaseFocus()
    end)

    local function mkBtn(text, offX, hov)
        local b = new("TextButton", {BorderSizePixel = 0,
            Position = UDim2.new(1,offX,0.5,-11), Size = UDim2.new(0,22,0,22),
            Font = Config.CurrentFontFamily, Text = text, TextSize = 11,
            AutoButtonColor = false, ZIndex = 3}, titlebar)
        themeBg(b, "ElementHover"); themeText(b, "SubText"); addCorner(b, UDim.new(0,6))
        b.MouseEnter:Connect(function()
            tween(b, {BackgroundColor3 = hov or Theme.Element, TextColor3 = Theme.Text}) end)
        b.MouseLeave:Connect(function()
            tween(b, {BackgroundColor3 = Theme.ElementHover, TextColor3 = Theme.SubText}) end)
        return b
    end
    local btnClose = mkBtn("x", -32, Theme.Danger)
    local btnMin = mkBtn("-", -58, Theme.ElementHover)
    btnClose.MouseButton1Click:Connect(function() gui.Enabled = false end)
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
    addCorner(statusBar, UDim.new(0,8))
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
            local ok, fps = pcall(function() return math.floor(Stats.FrameRate:GetValue()) end)
            local okP, ping = pcall(function()
                return math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
            rightLbl.Text = string.format("fps: %d  ping: %dms", ok and fps or 0, okP and ping or 0)
            midLbl.Text = string.format("players: %d/%d", #Players:GetPlayers(), Players.MaxPlayers)
            local up = tick() - startT
            leftLbl.Text = string.format("%s  up: %02d:%02d", opts.Name or "airUI",
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

    window = {GUI = gui, Main = main, TitleBar = titlebar, Sidebar = sidebar,
        SidebarList = sidebarScroll, PageHolder = pageInner, Overlay = Overlay,
        Tabs = {}, ActiveTab = nil, Name = opts.Name or "airUI", OnUnload = opts.OnUnload,
        Theme = Theme, Config = Config, _animScale = animScale,
        _hiding = false, _showing = false}

    function window:SelectTab(tab)
        if self.ActiveTab == tab then return end
        closeAllPopups()
        for _, t in ipairs(self.Tabs) do
            t.Page.Visible = false
            if t._refresh then t._refresh() end
            tween(t.Button, {BackgroundColor3 = Theme.Sidebar, TextColor3 = Theme.SubText})
            if t.AccentDot then t.AccentDot.Visible = false end
        end
        tab.Page.Visible = true
        tween(tab.Button, {BackgroundColor3 = Theme.Panel, TextColor3 = Theme.Accent})
        if tab.AccentDot then
            tab.AccentDot.Visible = true
            tab.AccentDot.BackgroundColor3 = Theme.Accent
        end
        self.ActiveTab = tab
    end
    function window:AddTab(o)
        o = o or {}
        local t = createTab(self, o)
        self.Tabs[#self.Tabs+1] = t
        if #self.Tabs == 1 then self:SelectTab(t) end
        return t
    end
    function window:RemoveTab(t)
        local idx
        for i, tt in ipairs(self.Tabs) do if tt == t or tt.Name == t then idx = i; break end end
        if not idx then return false end
        local tt = self.Tabs[idx]
        table.remove(self.Tabs, idx)
        if tt.Button then tt.Button:Destroy() end
        if tt.Page then tt.Page:Destroy() end
        if self.ActiveTab == tt then
            self.ActiveTab = nil
            if self.Tabs[1] then self:SelectTab(self.Tabs[1]) end
        end
        return true
    end

    -- ============================================================
    -- SMOOTH OPEN / CLOSE ANIMATION
    -- Slide (Position) + Scale (UIScale) + Fade (Transparency)
    -- No rotation, no artifacts.
    -- ============================================================
    function window:Show()
        if self._showing then return end
        self._hiding = false
        self._showing = true
        closeAllPopups()
        gui.Enabled = true

        -- Prepare start state
        main.Position = HIDDEN_POS
        main.BackgroundTransparency = math.min(1, Config.MenuTransparency + 0.45)
        if animScale then animScale.Scale = 0.88 end

        tween(main, {
            Position = BASE_POS,
            BackgroundTransparency = Config.MenuTransparency
        }, Config.MenuAnim, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        if animScale then
            tween(animScale, {Scale = 1}, Config.MenuAnim, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        end

        task.delay(Config.MenuAnim, function()
            self._showing = false
        end)
    end

    function window:Hide()
        if not gui.Enabled or self._hiding then return end
        self._hiding = true
        closeAllPopups()

        tween(main, {
            Position = HIDDEN_POS,
            BackgroundTransparency = math.min(1, Config.MenuTransparency + 0.45)
        }, Config.MenuCloseAnim, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        if animScale then
            tween(animScale, {Scale = 0.88}, Config.MenuCloseAnim, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        end

        task.delay(Config.MenuCloseAnim + 0.02, function()
            if self._hiding then
                gui.Enabled = false
                main.Position = BASE_POS
                main.BackgroundTransparency = Config.MenuTransparency
                if animScale then animScale.Scale = 1 end
                self._hiding = false
                self._showing = false
            end
        end)
    end

    function window:Toggle()
        if gui.Enabled and not self._hiding then
            self:Hide()
        else
            self:Show()
        end
    end
    function window:SetSearch(q)
        searchBox.Text = q or ""
        searchBox:ReleaseFocus()
    end
    function window:GetSearch() return searchQuery end

    -- ============================================================
    -- APPLY FONT to all text descendants
    -- ============================================================
    local function applyFontToAll(fontFamily, fontScale)
        for _, d in ipairs(gui:GetDescendants()) do
            if d:IsA("TextLabel") or d:IsA("TextBox") or d:IsA("TextButton") then
                local base = d:GetAttribute("_baseTextSize")
                if not base then
                    base = d.TextSize
                    d:SetAttribute("_baseTextSize", base)
                end
                if fontFamily then d.Font = fontFamily end
                if fontScale then
                    d.TextSize = math.clamp(math.floor(base * fontScale + 0.5), 6, 48)
                end
            end
        end
    end

    -- ============================================================
    -- CORNER RADIUS — delta-based
    -- ============================================================
    local function applyCornerDelta(targetVal)
        local delta = targetVal - Config.BaseCornerRadius
        for _, d in ipairs(gui:GetDescendants()) do
            if d:IsA("UICorner") then
                local baseScale = d:GetAttribute("_baseScale")
                local baseOff = d:GetAttribute("_baseRadius")
                if baseScale == nil then
                    local cur = d.CornerRadius
                    if typeof(cur) == "UDim2" then cur = UDim.new(cur.X.Scale, cur.X.Offset) end
                    baseScale = cur.Scale
                    baseOff = cur.Offset
                    d:SetAttribute("_baseScale", baseScale)
                    d:SetAttribute("_baseRadius", baseOff)
                end
                if baseScale and baseScale > 0 then
                    -- pill/circle — don't touch
                else
                    local newOff = math.max(0, baseOff + delta)
                    d.CornerRadius = UDim.new(0, newOff)
                end
            end
        end
    end

    -- ============================================================
    -- APPLY FULL THEME (colors + font)
    -- ============================================================
    function window:ApplyFullTheme(preset)
        if type(preset) ~= "table" then return end
        local newFont = preset.Font
        local newScale = preset.FontSize
        for k, v in pairs(preset) do
            if k == "Font" or k == "FontSize" then
                -- handled below
            elseif Theme[k] ~= nil and typeof(v) == "Color3" then
                Theme[k] = v
            end
        end
        refreshTheme()
        for _, t in ipairs(self.Tabs) do if t._refresh then t._refresh() end end
        if newFont then
            local fam = FontCatalog[newFont]
            if fam then
                Config.CurrentFontName = newFont
                Config.CurrentFontFamily = fam
            end
        end
        if newScale then Config.CurrentFontScale = tonumber(newScale) or 1 end
        applyFontToAll(Config.CurrentFontFamily, Config.CurrentFontScale)
    end

    function window:Configure(cfg)
        cfg = cfg or {}
        local needRefresh = false
        local needFontApply = false
        for k, v in pairs(cfg) do
            if k == "CornerRadius" and type(v) == "number" then
                Config.CornerRadius = UDim.new(0, v)
                applyCornerDelta(v)
            elseif k == "FontFamily" and type(v) == "string" then
                local fam = FontCatalog[v]
                if fam then
                    Config.CurrentFontName = v
                    Config.CurrentFontFamily = fam
                    needFontApply = true
                end
            elseif k == "FontScale" and type(v) == "number" then
                Config.CurrentFontScale = math.clamp(v, 0.6, 2.0)
                needFontApply = true
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
            elseif Theme[k] ~= nil then
                Theme[k] = v; needRefresh = true
            end
        end
        if needRefresh then
            refreshTheme()
            for _, t in ipairs(self.Tabs) do if t._refresh then t._refresh() end end
        end
        if needFontApply then
            applyFontToAll(Config.CurrentFontFamily, Config.CurrentFontScale)
        end
    end
    function window:SetTransparency(cat, v)
        v = math.clamp(tonumber(v) or 0, 0, 1)
        local key = cat .. "Transparency"
        if Config[key] ~= nil then Config[key] = v; applyTransparencyTo(cat) end
    end

    local drag, dStart, sPos
    titlebar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            drag = true; dStart = i.Position; sPos = main.Position; closeAllPopups()
        end
    end)
    _T(UserInputService.InputChanged:Connect(function(i)
        if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - dStart
            main.Position = UDim2.new(sPos.X.Scale, sPos.X.Offset + d.X, sPos.Y.Scale, sPos.Y.Offset + d.Y)
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
            main.Size = UDim2.new(0, math.max(Config.MinWidth, rInit.X.Offset + d.X),
                0, math.max(Config.MinHeight, rInit.Y.Offset + d.Y))
        end
    end))
    _T(UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then rz = false end end))

    _T(UserInputService.InputBegan:Connect(function(i, gpe)
        if gpe then return end
        if bindListening then return end
        if i.KeyCode == Enum.KeyCode.RightShift then window:Toggle() end
    end))

    function window:Unload()
        if type(self.OnUnload) == "function" then pcall(self.OnUnload, self) end
        closeAllPopups()
        for _, c in ipairs(AllConnections) do pcall(function() c:Disconnect() end) end
        AllConnections = {}
        for k in pairs(BindRegistry) do BindRegistry[k] = nil end
        BindOrder = {}
        RainbowControllers = {}
        pcall(function() gui:Destroy() end)
        NotificationHolder = nil; Overlay = nil; Tooltip = nil
        if getgenv().airUI_Window == window then getgenv().airUI_Window = nil end
        if getgenv().airUI then getgenv().airUI = nil end
        print("[airUI] Unloaded.")
    end
    function window:Destroy() self:Unload() end
    return window
end

local airUILib = {
    CreateWindow = createWindow, Notify = Notify, Theme = Theme, Config = Config,
    ThemePresets = ThemePresets, FontCatalog = FontCatalog,
    BindRegistry = BindRegistry, BindOrder = BindOrder,
    AddBindKey = AddBindKey, RemoveBindKey = RemoveBindKey, ClearBind = ClearBind,
    CloseAllPopups = closeAllPopups, RefreshTheme = refreshTheme,
}

function airUILib.LoadTab(code)
    if type(code) ~= "string" then return false, "code must be string" end
    local fn, err = loadstring(code)
    if not fn then
        warn("[airUI.LoadTab] syntax error: " .. tostring(err))
        return false, err
    end
    local ok, result = pcall(fn)
    if not ok then
        warn("[airUI.LoadTab] runtime error: " .. tostring(result))
        return false, result
    end
    return true, result
end

function airUILib.LoadTabFromURL(url)
    if type(url) ~= "string" then return false, "url must be string" end
    local ok, code = pcall(function() return game:HttpGet(url) end)
    if not ok or not code then
        warn("[airUI.LoadTabFromURL] fetch failed: " .. tostring(code))
        return false, code
    end
    return airUILib.LoadTab(code)
end

-- ============================================================
-- MAIN WINDOW
-- ============================================================
local Window = airUILib.CreateWindow({Name = "airUI"})
airUILib.Window = Window

-- ============================================================
-- SETTINGS TAB
-- ============================================================
local tabSettings = Window:AddTab({Name = "Settings", Icon = ">"})

local secTheme = tabSettings:CreateSection({Name = "Theme Presets"})
secTheme:AddDropdown({Name = "Preset", Value = "airUI Light",
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
        Notify("Theme", "Applied: " .. v, "success")
    end,
    Tooltip = "Меняет ВСЕ цвета + шрифт + размер текста"})

local secFont = tabSettings:CreateSection({Name = "Font", Side = "Right"})
secFont:AddDropdown({Name = "Font Family", Value = Config.CurrentFontName,
    List = (function()
        local t = {}
        for k in pairs(FontCatalog) do t[#t+1] = k end
        table.sort(t)
        return t
    end)(),
    Callback = function(v)
        Window:Configure({FontFamily = v})
        Notify("Font", "Applied: " .. v, "success")
    end,
    Tooltip = "Меняет шрифт всего меню"})
secFont:AddSlider({Name = "Font Size", Value = 1.0, Min = 0.6, Max = 1.8, Decimals = 2,
    Callback = function(v) Window:Configure({FontScale = v}) end,
    Tooltip = "Множитель размера текста (0.6x – 1.8x)"})

local secWindow = tabSettings:CreateSection({Name = "Menu Colors", Side = "Right"})
secWindow:AddColorpicker({Name = "Menu Background", Default = Theme.Background,
    Callback = function(c) Window:Configure({Background = c}) end})
secWindow:AddColorpicker({Name = "Sidebar", Default = Theme.Sidebar,
    Callback = function(c) Window:Configure({Sidebar = c}) end})
secWindow:AddColorpicker({Name = "Panel", Default = Theme.Panel,
    Callback = function(c) Window:Configure({Panel = c}) end})
secWindow:AddColorpicker({Name = "Section Background", Default = Theme.Section,
    Callback = function(c) Window:Configure({Section = c}) end})
secWindow:AddColorpicker({Name = "Element", Default = Theme.Element,
    Callback = function(c) Window:Configure({Element = c}) end})
secWindow:AddColorpicker({Name = "Element Hover", Default = Theme.ElementHover,
    Callback = function(c) Window:Configure({ElementHover = c}) end})
secWindow:AddColorpicker({Name = "Outline / Border", Default = Theme.Outline,
    Callback = function(c) Window:Configure({Outline = c}) end})

local secText = tabSettings:CreateSection({Name = "Text Colors"})
secText:AddColorpicker({Name = "Text", Default = Theme.Text,
    Callback = function(c) Window:Configure({Text = c}) end})
secText:AddColorpicker({Name = "SubText", Default = Theme.SubText,
    Callback = function(c) Window:Configure({SubText = c}) end})
secText:AddColorpicker({Name = "Muted", Default = Theme.Muted,
    Callback = function(c) Window:Configure({Muted = c}) end})

local secAccent = tabSettings:CreateSection({Name = "Accent Colors", Side = "Right"})
secAccent:AddColorpicker({Name = "Accent", Default = Theme.Accent,
    Callback = function(c) Window:Configure({Accent = c}) end,
    Tooltip = "Включи Rainbow — переливается"})
secAccent:AddColorpicker({Name = "Accent 2", Default = Theme.Accent2,
    Callback = function(c) Window:Configure({Accent2 = c}) end})
secAccent:AddColorpicker({Name = "Success", Default = Theme.Success,
    Callback = function(c) Window:Configure({Success = c}) end})
secAccent:AddColorpicker({Name = "Danger", Default = Theme.Danger,
    Callback = function(c) Window:Configure({Danger = c}) end})
secAccent:AddColorpicker({Name = "Warning", Default = Theme.Warning,
    Callback = function(c) Window:Configure({Warning = c}) end})
secAccent:AddColorpicker({Name = "On Accent", Default = Theme.OnAccent,
    Callback = function(c) Window:Configure({OnAccent = c}) end})

local secTrans = tabSettings:CreateSection({Name = "Transparency"})
secTrans:AddSlider({Name = "Menu", Value = Config.MenuTransparency, Min = 0, Max = 0.5, Decimals = 2,
    Callback = function(v) Window:SetTransparency("Menu", v) end})
secTrans:AddSlider({Name = "Tabs", Value = 0, Min = 0, Max = 0.5, Decimals = 2,
    Callback = function(v) Window:SetTransparency("Tab", v) end})
secTrans:AddSlider({Name = "Sections", Value = 0, Min = 0, Max = 0.5, Decimals = 2,
    Callback = function(v) Window:SetTransparency("Section", v) end})
secTrans:AddSlider({Name = "Elements", Value = 0, Min = 0, Max = 0.5, Decimals = 2,
    Callback = function(v) Window:SetTransparency("Element", v) end})

local secMenu = tabSettings:CreateSection({Name = "Menu", Side = "Right"})
secMenu:AddLabel({Text = "Toggle Key: RightShift (фиксировано)"})
secMenu:AddSlider({Name = "Sidebar Width", Value = 168, Min = 100, Max = 260,
    Callback = function(v) Window:Configure({SidebarWidth = v}) end})
secMenu:AddSlider({Name = "Corner Radius", Value = 8, Min = 0, Max = 24,
    Callback = function(v) Window:Configure({CornerRadius = v}) end,
    Tooltip = "Можно уменьшать и увеличивать"})
secMenu:AddToggle({Name = "Status Bar", Value = true,
    Callback = function(v) Window:Configure({StatusBar = v}) end})

local secActions = tabSettings:CreateSection({Name = "Actions"})
secActions:AddButton({Name = "Reset to airUI Light", Callback = function()
    Window:ApplyFullTheme(ThemePresets["airUI Light"])
    Notify("Theme", "Reset to airUI Light", "success")
end})
secActions:AddButton({Name = "Reset to airUI Dark", Callback = function()
    Window:ApplyFullTheme(ThemePresets["airUI Dark"])
    Notify("Theme", "Reset to airUI Dark", "success")
end})
secActions:AddButton({Name = "Unload Menu", Callback = function()
    Notify("airUI", "Unloading...", "warning", 1.5)
    task.wait(0.5)
    Window:Unload()
end})
secActions:AddButton({Name = "Re-show Window", Callback = function() Window:Show() end})
secActions:AddButton({Name = "Clear Search", Callback = function() Window:SetSearch("") end})

-- ============================================================
-- BINDS TAB
-- ============================================================
local tabBinds = Window:AddTab({Name = "Binds", Icon = ">"})
local secBindsList = tabBinds:CreateSection({Name = "Active Binds"})
secBindsList:AddLabel({Text = "MMB (клик колесом) на любую строку — открыть меню биндов."})
secBindsList:AddLabel({Text = "Кейбинды работают через свою клавишу, независимо от меню."})
secBindsList:AddDivider({Text = "LIVE STATUS"})

local lf = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1,0,0,0),
    AutomaticSize = Enum.AutomaticSize.Y}, secBindsList.Content)
new("UIListLayout", {Padding = UDim.new(0,4)}, lf)

local liveBindEntries = {}

local refreshingBinds = false
local function refreshBinds()
    if refreshingBinds then return end
    refreshingBinds = true
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
            r:SetAttribute("SearchName", string.lower(b.name or ""))

            local firstMode = b.keys[1].mode
            local strip = new("Frame", {BackgroundColor3 = MODE_COLORS[firstMode] or Theme.Accent,
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

            local ks = ""
            for i, e in ipairs(b.keys) do
                ks = ks .. (i>1 and "  " or "") .. keyName(e.key) .. " [" .. (MODE_SHORT[e.mode] or "?") .. "]"
            end
            local keysLbl = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0.5,0,0,0),
                Size = UDim2.new(0.3,-10,1,0), Font = Config.CurrentFontFamily, Text = ks,
                TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd}, r)
            themeText(keysLbl, "SubText")

            local statusLbl = new("TextLabel", {BackgroundTransparency = 1,
                Position = UDim2.new(1,-76,0,0), Size = UDim2.new(0,42,1,0),
                Font = Config.CurrentFontFamily, Text = "OFF", TextSize = 11,
                TextColor3 = Theme.Muted, TextXAlignment = Enum.TextXAlignment.Right}, r)

            local del = new("TextButton", {BackgroundColor3 = Theme.Danger, BackgroundTransparency = 0.85,
                BorderSizePixel = 0, Position = UDim2.new(1,-30,0.5,-10), Size = UDim2.new(0,20,0,20),
                Font = Config.CurrentFontFamily, Text = "x", TextColor3 = Theme.Danger,
                TextSize = 11, AutoButtonColor = false}, r)
            addCorner(del, UDim.new(0,6))
            del.MouseEnter:Connect(function() tween(del, {BackgroundTransparency = 0, TextColor3 = Theme.OnAccent}) end)
            del.MouseLeave:Connect(function() tween(del, {BackgroundTransparency = 0.85, TextColor3 = Theme.Danger}) end)
            del.MouseButton1Click:Connect(function()
                ClearBind(id, true); refreshBinds()
            end)

            liveBindEntries[id] = {row = r, dot = dot, statusLbl = statusLbl, bind = b, strip = strip}
        end
    end
    if not any then
        local empty = new("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(1,0,0,22),
            Font = Config.CurrentFontFamily, Text = "Пусто. Наведи MMB на любой компонент.",
            TextSize = 10, TextWrapped = true}, lf)
        themeText(empty, "Muted")
    end
    refreshingBinds = false
end

secBindsList:AddButton({Name = "Refresh", Callback = refreshBinds})
secBindsList:AddButton({Name = "Clear All (Reset)", Callback = function()
    for _, id in ipairs(BindOrder) do
        if BindRegistry[id] then ClearBind(id, true) end
    end
    refreshBinds()
    Notify("Binds", "All binds cleared", "warning")
end})
refreshBinds()

-- ============================================================
-- LIVE STATE UPDATER
-- ============================================================
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

getgenv().airUI = airUILib
getgenv().airUI_Window = Window

return airUILib
