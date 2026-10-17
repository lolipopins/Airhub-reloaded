--// AirHub - arsenal extra tab (hybrid: native tab + standalone fallback)
local H = getgenv().AirHub
if not H or not H._CoreLoaded then
    warn("[AirHub] arsenal extra tab: core not loaded")
    return
end
if H.Quotas and H.Quotas._Loaded then return end

local Util              = H.Util
local Players           = Util.Players
local RunService        = Util.RunService
local LocalPlayer       = Util.LocalPlayer
local ReplicatedStorage = Util.ReplicatedStorage
local Track             = Util.Track
local SanitizeColor     = Util.SanitizeColor
local UIS               = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")

H.Quotas = H.Quotas or {}
local Q = H.Quotas
Q._Loaded = true

Q.Settings = Q.Settings or {
    NameTagsEnabled        = false,
    NameTagsSize           = 9,
    NameTagsColor          = Color3.fromRGB(255, 255, 255),
    NameTagsTeamCheck      = true,
    NameTagsAliveCheck     = true,
    LimbHitboxEnabled      = false,
    LimbHitboxSize         = 13,
    LimbHitboxTransparency = 1,
    LimbHitboxTeamCheck    = true,
    InfAmmoEnabled         = false,
    FireRateEnabled        = false,
    FireRateValue          = 0.02,
    RecoilEnabled          = false,
}
Q.Internal = Q.Internal or {
    NameTags         = {},
    LimbOriginals    = {},
    LimbApplied      = {},
    Conns            = {},
    WeaponLoopActive = false,
    UI = {},
}
Q.Functions = Q.Functions or {}

--====================================================================
-- Helpers
--====================================================================
local function IsAlive(char)
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hum ~= nil and hum.Health > 0
end

local function IsEnemy(plr)
    if plr == LocalPlayer then return false end
    local lt = LocalPlayer.Team
    local tt = plr.Team
    if lt ~= nil and tt ~= nil and lt == tt then return false end
    return true
end

--====================================================================
-- Name Tags
--====================================================================
local function BuildNameTag(plr)
    if plr == LocalPlayer then return end
    local char = plr.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end
    local existing = Q.Internal.NameTags[plr]
    if existing ~= nil and existing.Parent ~= nil then return end

    local gui = Instance.new("BillboardGui")
    gui.Name           = "AirHub_Quotas_NameTag"
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.AlwaysOnTop    = true
    gui.LightInfluence = 1
    gui.Size           = UDim2.new(0, 300, 0, 30)
    gui.StudsOffset    = Vector3.new(0, 3, 0)
    gui.Parent         = head

    local label = Instance.new("TextLabel")
    label.Name                   = "NameLabel"
    label.BackgroundTransparency = 1
    label.Size                   = UDim2.new(1, 0, 1, 0)
    label.Font                   = Enum.Font.Ubuntu
    label.Text                   = plr.Name
    label.TextColor3             = Q.Settings.NameTagsColor
    label.TextSize               = Q.Settings.NameTagsSize
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
    label.TextTransparency       = 1
    label.Parent                 = gui

    Q.Internal.NameTags[plr] = gui
end

local function RemoveNameTag(plr)
    local gui = Q.Internal.NameTags[plr]
    if gui ~= nil and gui.Parent ~= nil then
        pcall(function() gui:Destroy() end)
    end
    Q.Internal.NameTags[plr] = nil
end

local function RefreshNameTagVisibility(plr)
    local gui = Q.Internal.NameTags[plr]
    if not gui or not gui.Parent then return end
    local label = gui:FindFirstChild("NameLabel")
    if not label then return end

    local visible = Q.Settings.NameTagsEnabled
    if visible and Q.Settings.NameTagsAliveCheck then
        visible = IsAlive(plr.Character)
    end
    if visible and Q.Settings.NameTagsTeamCheck then
        visible = IsEnemy(plr)
    end
    label.TextTransparency = visible and 0 or 1
    label.TextSize         = Q.Settings.NameTagsSize
    label.TextColor3       = Q.Settings.NameTagsColor
end

local function StartNameTags()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then BuildNameTag(plr) end
    end
    if Q.Internal.Conns.nameTagStep == nil then
        Q.Internal.Conns.nameTagStep = RunService.RenderStepped:Connect(function()
            if H.ShuttingDown then return end
            if not Q.Settings.NameTagsEnabled then return end
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    local head = plr.Character:FindFirstChild("Head")
                    if head then
                        local gui = Q.Internal.NameTags[plr]
                        if gui == nil or gui.Parent == nil then BuildNameTag(plr) end
                        RefreshNameTagVisibility(plr)
                    end
                end
            end
        end)
    end
end

local function StopNameTags()
    for plr in pairs(Q.Internal.NameTags) do
        RemoveNameTag(plr)
    end
    if Q.Internal.Conns.nameTagStep ~= nil then
        pcall(function() Q.Internal.Conns.nameTagStep:Disconnect() end)
        Q.Internal.Conns.nameTagStep = nil
    end
end

--====================================================================
-- Limb Hitbox
--====================================================================
local LIMB_PARTS = { "RightUpperLeg", "LeftUpperLeg", "HeadHB", "Head", "HumanoidRootPart" }
local RestoreLimbHitboxForPlayer

local function ApplyLimbHitboxForPlayer(plr)
    if plr == LocalPlayer then return end
    if Q.Settings.LimbHitboxTeamCheck and not IsEnemy(plr) then
        if RestoreLimbHitboxForPlayer ~= nil then RestoreLimbHitboxForPlayer(plr) end
        return
    end
    local char = plr.Character
    if not char then return end

    local size = Vector3.new(Q.Settings.LimbHitboxSize, Q.Settings.LimbHitboxSize, Q.Settings.LimbHitboxSize)
    local parts = {}
    for _, name in ipairs(LIMB_PARTS) do
        local p = char:FindFirstChild(name)
        if p ~= nil and p:IsA("BasePart") then
            if Q.Internal.LimbOriginals[p] == nil then
                Q.Internal.LimbOriginals[p] = { Size = p.Size, CanCollide = p.CanCollide, Transparency = p.Transparency }
            end
            pcall(function()
                p.CanCollide = false
                p.Transparency = Q.Settings.LimbHitboxTransparency
                p.Size = size
            end)
            parts[#parts + 1] = p
        end
    end
    Q.Internal.LimbApplied[plr] = parts
end

RestoreLimbHitboxForPlayer = function(plr)
    local parts = Q.Internal.LimbApplied[plr]
    if parts == nil then return end
    for _, p in ipairs(parts) do
        local orig = Q.Internal.LimbOriginals[p]
        if orig ~= nil and p.Parent ~= nil then
            pcall(function()
                p.Size = orig.Size
                p.CanCollide = orig.CanCollide
                p.Transparency = orig.Transparency
            end)
        end
        Q.Internal.LimbOriginals[p] = nil
    end
    Q.Internal.LimbApplied[plr] = nil
end

local function StartLimbHitbox()
    for _, plr in ipairs(Players:GetPlayers()) do ApplyLimbHitboxForPlayer(plr) end
    if Q.Internal.Conns.limbStep == nil then
        Q.Internal.Conns.limbStep = RunService.Heartbeat:Connect(function()
            if H.ShuttingDown then return end
            if not Q.Settings.LimbHitboxEnabled then return end
            local size = Vector3.new(Q.Settings.LimbHitboxSize, Q.Settings.LimbHitboxSize, Q.Settings.LimbHitboxSize)
            for plr, parts in pairs(Q.Internal.LimbApplied) do
                if plr.Parent == nil or plr.Character == nil then
                    RestoreLimbHitboxForPlayer(plr)
                else
                    for _, p in ipairs(parts) do
                        if p.Parent ~= nil and p.Size ~= size then
                            pcall(function()
                                p.Size = size
                                p.CanCollide = false
                                p.Transparency = Q.Settings.LimbHitboxTransparency
                            end)
                        end
                    end
                end
            end
        end)
    end
end

local function StopLimbHitbox()
    for plr in pairs(Q.Internal.LimbApplied) do RestoreLimbHitboxForPlayer(plr) end
    if Q.Internal.Conns.limbStep ~= nil then
        pcall(function() Q.Internal.Conns.limbStep:Disconnect() end)
        Q.Internal.Conns.limbStep = nil
    end
end

--====================================================================
-- Weapon Mods
--====================================================================
local function ApplyWeaponMods()
    pcall(function()
        if Q.Settings.InfAmmoEnabled then
            local pg = LocalPlayer:FindFirstChild("PlayerGui")
            local gui = pg and pg:FindFirstChild("GUI")
            local client = gui and gui:FindFirstChild("Client")
            local vars = client and client:FindFirstChild("Variables")
            if vars then
                local a1 = vars:FindFirstChild("ammocount")
                local a2 = vars:FindFirstChild("ammocount2")
                if a1 then a1.Value = 999 end
                if a2 then a2.Value = 999 end
            end
        end
        if Q.Settings.FireRateEnabled or Q.Settings.RecoilEnabled then
            local weapons = ReplicatedStorage:FindFirstChild("Weapons")
            if weapons then
                for _, v in ipairs(weapons:GetDescendants()) do
                    if Q.Settings.FireRateEnabled then
                        if v.Name == "Auto" then pcall(function() v.Value = true end) end
                        if v.Name == "FireRate" then pcall(function() v.Value = Q.Settings.FireRateValue end) end
                    end
                    if Q.Settings.RecoilEnabled then
                        if v.Name == "RecoilControl" then pcall(function() v.Value = 0 end) end
                        if v.Name == "MaxSpread" then pcall(function() v.Value = 0 end) end
                    end
                end
            end
        end
    end)
end

local function StartWeaponMods()
    if Q.Internal.WeaponLoopActive then return end
    Q.Internal.WeaponLoopActive = true
    task.spawn(function()
        while Q.Internal.WeaponLoopActive and not H.ShuttingDown do
            if Q.Settings.InfAmmoEnabled or Q.Settings.FireRateEnabled or Q.Settings.RecoilEnabled then
                ApplyWeaponMods()
            end
            task.wait(0.2)
        end
    end)
end

local function StopWeaponMods()
    Q.Internal.WeaponLoopActive = false
end

--====================================================================
-- Player events
--====================================================================
Track(Players.PlayerAdded:Connect(function(plr)
    if Q.Settings.NameTagsEnabled then
        task.wait(0.5)
        if H.ShuttingDown then return end
        BuildNameTag(plr)
    end
end))

Track(Players.PlayerRemoving:Connect(function(plr)
    RemoveNameTag(plr)
    RestoreLimbHitboxForPlayer(plr)
end))

Track(LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if H.ShuttingDown then return end
    if Q.Settings.NameTagsEnabled then
        for plr in pairs(Q.Internal.NameTags) do
            if plr ~= LocalPlayer then BuildNameTag(plr) end
        end
    end
end))

--====================================================================
-- Standalone fallback UI
--====================================================================
local COLORS = {
    bg      = Color3.fromRGB(20, 21, 28),
    panel   = Color3.fromRGB(30, 32, 42),
    control = Color3.fromRGB(44, 46, 58),
    accent  = Color3.fromRGB(90, 140, 255),
    text    = Color3.fromRGB(235, 238, 248),
    sub     = Color3.fromRGB(160, 163, 178),
    border  = Color3.fromRGB(52, 54, 68),
}

local PRESET_COLORS = {
    { name = "White",   color = Color3.fromRGB(255, 255, 255) },
    { name = "Red",     color = Color3.fromRGB(255,  80,  80) },
    { name = "Green",   color = Color3.fromRGB( 80, 255, 120) },
    { name = "Blue",    color = Color3.fromRGB( 90, 140, 255) },
    { name = "Yellow",  color = Color3.fromRGB(255, 230,  80) },
    { name = "Cyan",    color = Color3.fromRGB( 80, 220, 255) },
    { name = "Magenta", color = Color3.fromRGB(255,  90, 210) },
    { name = "Black",   color = Color3.fromRGB( 20,  20,  20) },
}

local function make(inst, props, parent)
    local o = Instance.new(inst)
    for k, v in pairs(props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local function corner(p, r)
    return make("UICorner", { CornerRadius = UDim.new(0, r or 8) }, p)
end

local function stroke(p, c, t, tr)
    return make("UIStroke", {
        Color = c or COLORS.border, Thickness = t or 1,
        Transparency = tr or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, p)
end

local function BuildStandaloneUI()
    if getgenv()._AirHub_Arsenal_GUI and getgenv()._AirHub_Arsenal_GUI.Parent then
        return getgenv()._AirHub_Arsenal_GUI
    end

    local sg = make("ScreenGui", {
        Name = "AirHub_Arsenal_Standalone",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
    })
    pcall(function() sg.Parent = game:GetService("CoreGui") end)
    if not sg.Parent then
        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if pg then sg.Parent = pg end
    end
    if not sg.Parent then
        warn("[AirHub] arsenal extra tab: cannot parent ScreenGui")
        return nil
    end
    getgenv()._AirHub_Arsenal_GUI = sg

    -- Open button
    local openBtn = make("TextButton", {
        Name = "OpenButton",
        Size = UDim2.new(0, 130, 0, 32),
        Position = UDim2.new(0, 20, 0, 20),
        BackgroundColor3 = COLORS.accent,
        Text = "Arsenal",
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = COLORS.text,
        AutoButtonColor = false,
        Visible = false,
        Parent = sg,
    })
    corner(openBtn, 8)

    -- Window
    local win = make("Frame", {
        Name = "Window",
        Size = UDim2.new(0, 380, 0, 520),
        Position = UDim2.new(0.5, -190, 0.5, -260),
        BackgroundColor3 = COLORS.bg,
        BorderSizePixel = 0,
        Visible = false,
        Parent = sg,
    })
    corner(win, 12)
    stroke(win, COLORS.border, 1)

    -- Header
    local header = make("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = COLORS.panel,
        BorderSizePixel = 0,
        Parent = win,
    })
    corner(header, 12)
    make("Frame", {
        Size = UDim2.new(1, 0, 0, 12),
        Position = UDim2.new(0, 0, 1, -12),
        BackgroundColor3 = COLORS.panel,
        BorderSizePixel = 0,
        Parent = header,
    })
    make("TextLabel", {
        Text = "Arsenal — AirHub",
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextColor3 = COLORS.text,
        BackgroundTransparency = 1,
        Size = UDim2.new(0.7, 0, 1, 0),
        Position = UDim2.new(0, 14, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header,
    })
    local closeBtn = make("TextButton", {
        Text = "×",
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextColor3 = COLORS.sub,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 32, 0, 32),
        Position = UDim2.new(1, -36, 0.5, -16),
        AutoButtonColor = false,
        Parent = header,
    })

    -- Scroll content
    local scroll = make("ScrollingFrame", {
        Name = "Scroll",
        Size = UDim2.new(1, -20, 1, -56),
        Position = UDim2.new(0, 10, 0, 48),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = COLORS.border,
        Parent = win,
    })
    make("UIListLayout", {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = scroll,
    })

    -- Toggle helper
    local function AddSection(parent, title, order)
        local sec = make("Frame", {
            BackgroundColor3 = COLORS.panel,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = order or 0,
            Parent = parent,
        })
        corner(sec, 10)
        stroke(sec, COLORS.border, 1)
        local pad = make("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -20, 0, 0),
            Position = UDim2.new(0, 10, 0, 8),
            AutomaticSize = Enum.AutomaticSize.Y,
            Parent = sec,
        })
        make("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = pad,
        })
        make("TextLabel", {
            Text = title,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextColor3 = COLORS.text,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 20),
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 0,
            Parent = pad,
        })
        return pad
    end

    local orderCounter = 0
    local function nextOrder()
        orderCounter = orderCounter + 1
        return orderCounter
    end

    local function AddToggle(parent, name, initial, cb)
        local row = make("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 30),
            LayoutOrder = nextOrder(),
            Parent = parent,
        })
        make("TextLabel", {
            Text = name,
            Font = Enum.Font.GothamMedium,
            TextSize = 13,
            TextColor3 = COLORS.text,
            BackgroundTransparency = 1,
            Size = UDim2.new(0.7, 0, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = row,
        })
        local track = make("Frame", {
            BackgroundColor3 = initial and COLORS.accent or COLORS.control,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 40, 0, 20),
            Position = UDim2.new(1, -40, 0.5, -10),
            Parent = row,
        })
        corner(track, 10)
        local knob = make("Frame", {
            BackgroundColor3 = COLORS.text,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 16, 0, 16),
            Position = initial and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
            Parent = track,
        })
        corner(knob, 8)
        local btn = make("TextButton", {
            Text = "",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Parent = track,
        })
        local state = { value = initial and true or false }
        local function setValue(v, fire)
            state.value = v and true or false
            track.BackgroundColor3 = state.value and COLORS.accent or COLORS.control
            knob.Position = state.value and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
            if fire and cb then cb(state.value) end
        end
        btn.MouseButton1Click:Connect(function() setValue(not state.value, true) end)
        return { Set = function(self, v) setValue(v, true) end, Value = state }
    end

    local function AddSlider(parent, name, initial, min, max, decimals, cb)
        local row = make("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 42),
            LayoutOrder = nextOrder(),
            Parent = parent,
        })
        make("TextLabel", {
            Text = name,
            Font = Enum.Font.GothamMedium,
            TextSize = 13,
            TextColor3 = COLORS.text,
            BackgroundTransparency = 1,
            Size = UDim2.new(0.7, 0, 0, 18),
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = row,
        })
        local valLbl = make("TextLabel", {
            Text = "",
            Font = Enum.Font.GothamMedium,
            TextSize = 12,
            TextColor3 = COLORS.accent,
            BackgroundTransparency = 1,
            Size = UDim2.new(0.3, 0, 0, 18),
            Position = UDim2.new(0.7, 0, 0, 0),
            TextXAlignment = Enum.TextXAlignment.Right,
            Parent = row,
        })
        local track = make("Frame", {
            BackgroundColor3 = COLORS.control,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 6),
            Position = UDim2.new(0, 0, 0, 28),
            Parent = row,
        })
        corner(track, 3)
        local fill = make("Frame", {
            BackgroundColor3 = COLORS.accent,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 0, 1, 0),
            Parent = track,
        })
        corner(fill, 3)
        local knob = make("Frame", {
            BackgroundColor3 = COLORS.text,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 12, 0, 12),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0, 0, 0.5, 0),
            Parent = track,
        })
        corner(knob, 6)
        local hit = make("TextButton", {
            Text = "",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 20),
            Position = UDim2.new(0, 0, 0.5, -10),
            Parent = track,
        })
        local state = { value = initial }
        local function fmt(v)
            if decimals <= 0 then return tostring(math.floor(v + 0.5)) end
            return string.format("%." .. decimals .. "f", v)
        end
        local function setVisual(v)
            local alpha = (max > min) and ((v - min) / (max - min)) or 0
            alpha = math.clamp(alpha, 0, 1)
            fill.Size = UDim2.new(alpha, 0, 1, 0)
            knob.Position = UDim2.new(alpha, 0, 0.5, 0)
            valLbl.Text = fmt(v)
        end
        local function set(v, fire)
            v = math.clamp(tonumber(v) or min, min, max)
            if decimals <= 0 then v = math.floor(v + 0.5) end
            state.value = v
            setVisual(v)
            if fire and cb then cb(v) end
        end
        set(initial, false)
        local dragging = false
        local function fromInput(inp)
            local p = track.AbsolutePosition
            local s = track.AbsoluteSize
            if s.X <= 0 then return end
            local a = math.clamp((inp.Position.X - p.X) / s.X, 0, 1)
            set(min + (max - min) * a, true)
        end
        hit.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                dragging = true; fromInput(inp)
            end
        end)
        hit.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        UIS.InputChanged:Connect(function(inp)
            if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
                fromInput(inp)
            end
        end)
        return { Set = function(self, v) set(v, true) end, Value = state }
    end

    local function AddColorPicker(parent, name, initial, cb)
        local row = make("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 30),
            LayoutOrder = nextOrder(),
            Parent = parent,
        })
        make("TextLabel", {
            Text = name,
            Font = Enum.Font.GothamMedium,
            TextSize = 13,
            TextColor3 = COLORS.text,
            BackgroundTransparency = 1,
            Size = UDim2.new(0.6, 0, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = row,
        })
        local swatch = make("TextButton", {
            Text = "",
            BackgroundColor3 = initial,
            Size = UDim2.new(0, 60, 0, 22),
            Position = UDim2.new(1, -60, 0.5, -11),
            AutoButtonColor = false,
            Parent = row,
        })
        corner(swatch, 6)
        stroke(swatch, COLORS.border, 1, 0.4)

        local popup
        local function closePopup() if popup then popup:Destroy(); popup = nil end end
        local function buildPopup()
            closePopup()
            local wPx, hPx = 200, 24 * #PRESET_COLORS + 8
            local px = swatch.AbsolutePosition.X
            local py = swatch.AbsolutePosition.Y + swatch.AbsoluteSize.Y + 4
            local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(800, 600)
            if px + wPx > vp.X then px = vp.X - wPx - 8 end
            if py + hPx > vp.Y then py = swatch.AbsolutePosition.Y - hPx - 4 end
            popup = make("Frame", {
                BackgroundColor3 = COLORS.panel,
                BorderSizePixel = 0,
                Size = UDim2.new(0, wPx, 0, hPx),
                Position = UDim2.new(0, px, 0, py),
                ZIndex = 20,
                Parent = sg,
            })
            corner(popup, 8)
            stroke(popup, COLORS.border, 1, 0.2)
            make("UIListLayout", {
                Padding = UDim.new(0, 2),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = popup,
            })
            make("UIPadding", {
                PaddingTop = UDim.new(0, 4),
                PaddingLeft = UDim.new(0, 4),
                PaddingRight = UDim.new(0, 4),
                PaddingBottom = UDim.new(0, 4),
                Parent = popup,
            })
            for i, opt in ipairs(PRESET_COLORS) do
                local ob = make("TextButton", {
                    Text = "  " .. opt.name,
                    Font = Enum.Font.Gotham,
                    TextSize = 12,
                    TextColor3 = COLORS.text,
                    BackgroundColor3 = opt.color,
                    BackgroundTransparency = 0.5,
                    Size = UDim2.new(1, 0, 0, 22),
                    AutoButtonColor = false,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    LayoutOrder = i,
                    Parent = popup,
                })
                corner(ob, 4)
                ob.MouseButton1Click:Connect(function()
                    swatch.BackgroundColor3 = opt.color
                    if cb then cb(opt.color) end
                    closePopup()
                end)
            end
            task.delay(0.05, function()
                local conn
                conn = UIS.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                        if popup and popup.Parent then
                            local mp = inp.Position
                            local p = popup.AbsolutePosition
                            local s = popup.AbsoluteSize
                            if not (mp.X >= p.X and mp.X <= p.X + s.X and mp.Y >= p.Y and mp.Y <= p.Y + s.Y) then
                                closePopup()
                            end
                        end
                        if conn then conn:Disconnect() end
                    end
                end)
            end)
        end
        swatch.MouseButton1Click:Connect(function()
            if popup then closePopup() else buildPopup() end
        end)
        return {
            Set = function(self, c)
                if typeof(c) == "Color3" then
                    swatch.BackgroundColor3 = c
                    if cb then cb(c) end
                end
            end,
        }
    end

    -- Build sections
    local secNT = AddSection(scroll, "Name Tags", 1)
    AddToggle(secNT, "Enabled", Q.Settings.NameTagsEnabled, function(v)
        Q.Settings.NameTagsEnabled = v
        if v then StartNameTags() else StopNameTags() end
    end)
    AddSlider(secNT, "Text Size", Q.Settings.NameTagsSize, 6, 24, 0, function(v)
        Q.Settings.NameTagsSize = v
    end)
    AddColorPicker(secNT, "Text Color", Q.Settings.NameTagsColor, function(c)
        Q.Settings.NameTagsColor = SanitizeColor(c)
    end)
    AddToggle(secNT, "Team Check", Q.Settings.NameTagsTeamCheck, function(v)
        Q.Settings.NameTagsTeamCheck = v
    end)
    AddToggle(secNT, "Alive Check", Q.Settings.NameTagsAliveCheck, function(v)
        Q.Settings.NameTagsAliveCheck = v
    end)

    local secLH = AddSection(scroll, "Limb Hitbox (OP Silent Aim)", 2)
    AddToggle(secLH, "Enabled", Q.Settings.LimbHitboxEnabled, function(v)
        Q.Settings.LimbHitboxEnabled = v
        if v then StartLimbHitbox() else StopLimbHitbox() end
    end)
    AddSlider(secLH, "Hitbox Size", Q.Settings.LimbHitboxSize, 5, 30, 0, function(v)
        Q.Settings.LimbHitboxSize = v
        if Q.Settings.LimbHitboxEnabled then StopLimbHitbox(); StartLimbHitbox() end
    end)
    AddSlider(secLH, "Transparency", Q.Settings.LimbHitboxTransparency, 0, 1, 2, function(v)
        Q.Settings.LimbHitboxTransparency = v
    end)
    AddToggle(secLH, "Team Check", Q.Settings.LimbHitboxTeamCheck, function(v)
        Q.Settings.LimbHitboxTeamCheck = v
        if Q.Settings.LimbHitboxEnabled then StopLimbHitbox(); StartLimbHitbox() end
    end)

    local secWM = AddSection(scroll, "Weapon Mods", 3)
    AddToggle(secWM, "Infinite Ammo", Q.Settings.InfAmmoEnabled, function(v)
        Q.Settings.InfAmmoEnabled = v
        if v then StartWeaponMods() end
    end)
    AddToggle(secWM, "Fire Rate Mod", Q.Settings.FireRateEnabled, function(v)
        Q.Settings.FireRateEnabled = v
        if v then StartWeaponMods() end
    end)
    AddSlider(secWM, "Fire Rate Value", Q.Settings.FireRateValue, 0.01, 0.5, 3, function(v)
        Q.Settings.FireRateValue = v
    end)
    AddToggle(secWM, "Recoil Mod", Q.Settings.RecoilEnabled, function(v)
        Q.Settings.RecoilEnabled = v
        if v then StartWeaponMods() end
    end)

    -- Drag window
    local dragging, dragStart, startPos
    header.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = inp.Position
            startPos = win.Position
        end
    end)
    header.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            local d = inp.Position - dragStart
            win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)

    closeBtn.MouseButton1Click:Connect(function()
        win.Visible = false
        openBtn.Visible = true
    end)
    openBtn.MouseButton1Click:Connect(function()
        win.Visible = true
        openBtn.Visible = false
    end)

    -- Key toggle (RightAlt)
    UIS.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.KeyCode == Enum.KeyCode.RightAlt then
            if win.Visible then win.Visible = false; openBtn.Visible = true
            else win.Visible = true; openBtn.Visible = false end
        end
    end)

    win.Visible = true
    openBtn.Visible = false
    return sg
end

--====================================================================
-- Main UI dispatcher
--====================================================================
local function FillAirHubTab()
    local MainFrame = H._UI and H._UI.MainFrame
    if not MainFrame then return false end
    local tab = MainFrame:CreateTab({ Name = "arsenal" })

    local secNT = tab:CreateSection({ Name = "Name Tags" })
    secNT:AddToggle({ Name = "Enabled", Value = Q.Settings.NameTagsEnabled,
        Callback = function(v) Q.Settings.NameTagsEnabled = v
            if v then StartNameTags() else StopNameTags() end end })
    secNT:AddSlider({ Name = "Text Size", Value = Q.Settings.NameTagsSize, Min = 6, Max = 24,
        Callback = function(v) Q.Settings.NameTagsSize = v end })
    secNT:AddColorpicker({ Name = "Text Color", Value = Q.Settings.NameTagsColor,
        Callback = function(c) Q.Settings.NameTagsColor = SanitizeColor(c) end })
    secNT:AddToggle({ Name = "Team Check", Value = Q.Settings.NameTagsTeamCheck,
        Callback = function(v) Q.Settings.NameTagsTeamCheck = v end })
    secNT:AddToggle({ Name = "Alive Check", Value = Q.Settings.NameTagsAliveCheck,
        Callback = function(v) Q.Settings.NameTagsAliveCheck = v end })

    local secLH = tab:CreateSection({ Name = "Limb Hitbox (OP Silent Aim)", Side = "Right" })
    secLH:AddToggle({ Name = "Enabled", Value = Q.Settings.LimbHitboxEnabled,
        Callback = function(v) Q.Settings.LimbHitboxEnabled = v
            if v then StartLimbHitbox() else StopLimbHitbox() end end })
    secLH:AddSlider({ Name = "Hitbox Size", Value = Q.Settings.LimbHitboxSize, Min = 5, Max = 30,
        Callback = function(v)
            Q.Settings.LimbHitboxSize = v
            if Q.Settings.LimbHitboxEnabled then StopLimbHitbox(); StartLimbHitbox() end
        end })
    secLH:AddSlider({ Name = "Transparency", Value = Q.Settings.LimbHitboxTransparency, Min = 0, Max = 1, Decimals = 2,
        Callback = function(v) Q.Settings.LimbHitboxTransparency = v end })
    secLH:AddToggle({ Name = "Team Check", Value = Q.Settings.LimbHitboxTeamCheck,
        Callback = function(v) Q.Settings.LimbHitboxTeamCheck = v
            if Q.Settings.LimbHitboxEnabled then StopLimbHitbox(); StartLimbHitbox() end end })

    local secWM = tab:CreateSection({ Name = "Weapon Mods" })
    secWM:AddToggle({ Name = "Infinite Ammo", Value = Q.Settings.InfAmmoEnabled,
        Callback = function(v) Q.Settings.InfAmmoEnabled = v
            if v then StartWeaponMods() end end })
    secWM:AddToggle({ Name = "Fire Rate Mod", Value = Q.Settings.FireRateEnabled,
        Callback = function(v) Q.Settings.FireRateEnabled = v
            if v then StartWeaponMods() end end })
    secWM:AddSlider({ Name = "Fire Rate Value", Value = Q.Settings.FireRateValue, Min = 0.01, Max = 0.5, Decimals = 3,
        Callback = function(v) Q.Settings.FireRateValue = v end })
    secWM:AddToggle({ Name = "Recoil Mod", Value = Q.Settings.RecoilEnabled,
        Callback = function(v) Q.Settings.RecoilEnabled = v
            if v then StartWeaponMods() end end })

    return true
end

-- Try to add to AirHub UI for 10 seconds; if it never shows up, use standalone.
task.spawn(function()
    local deadline = tick() + 10
    while tick() < deadline do
        if H.ShuttingDown then return end
        if H._UI and H._UI.MainFrame then
            local ok, err = pcall(FillAirHubTab)
            if ok then
                print("[AirHub] arsenal extra tab: added to AirHub UI")
                return
            else
                warn("[AirHub] arsenal extra tab: FillAirHubTab failed: " .. tostring(err))
            end
        end
        task.wait(0.5)
    end

    -- Fallback: standalone UI
    print("[AirHub] arsenal extra tab: AirHub UI not ready, spawning standalone UI (RightAlt to toggle)")
    local ok, err = pcall(BuildStandaloneUI)
    if not ok then
        warn("[AirHub] arsenal extra tab: standalone UI failed: " .. tostring(err))
    end
end)

--====================================================================
-- Public cleanup
--====================================================================
Q.Functions.StopAll = function()
    Q.Settings.NameTagsEnabled   = false
    Q.Settings.LimbHitboxEnabled = false
    Q.Settings.InfAmmoEnabled    = false
    Q.Settings.FireRateEnabled   = false
    Q.Settings.RecoilEnabled     = false
    StopNameTags()
    StopLimbHitbox()
    StopWeaponMods()
    local sg = getgenv()._AirHub_Arsenal_GUI
    if sg and sg.Parent then pcall(function() sg:Destroy() end) end
    getgenv()._AirHub_Arsenal_GUI = nil
end
