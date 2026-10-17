--// AirHub - 04_wallhack.lua v2 (merged with ServerPosition)
--// FIXED: colorpicker Default, china hat retry, glow adornee, sanitize nil,
--//        torso parts, box clipping, team gate, SelfESP.Enabled sync,
--//        SetSelfESPChamsEnabled/ChinaHatEnabled consistency, reset UI sync
--// NEW: Texture Chams, Wireframe Chams, Tracers, Name Tags, Health Bars,
--//      Distance Indicators, more ChinaHat options, RU + tooltips
--// UI: airhubUI Visuals tab.

local H = getgenv().AirHub
if not H or not H._CoreLoaded then warn("[AirHub] 04_wallhack: core not loaded") return end
if H.WallHack and H.WallHack._Loaded then return end

-- ============================================================================
-- PART 1 — SCHEMA
-- ============================================================================
H.WallHack = H.WallHack or {}
local WallHack = H.WallHack
WallHack._Loaded = true

WallHack.Settings = WallHack.Settings or {
    Enabled = false, TeamCheck = false, AliveCheck = true,
}
WallHack.Visuals = WallHack.Visuals or {}

WallHack.Visuals.BoxSettings = WallHack.Visuals.BoxSettings or {
    Enabled = true, Type = 1,
    Color = Color3.fromRGB(255, 255, 255),
    TargetColor = Color3.fromRGB(255, 0, 0),
    Transparency = 0.7, Thickness = 1, Filled = false, Increase = 1,
}
WallHack.Visuals.GlowSettings = WallHack.Visuals.GlowSettings or {
    Enabled = true, Color = Color3.fromRGB(0, 255, 255),
    Transparency = 0.5, Mode = "Outline",
}
WallHack.Visuals.HUDSettings = WallHack.Visuals.HUDSettings or {
    Enabled = false, Position = "TopLeft",
    ShowPlayers = true, ShowFPS = true, ShowPing = true, ShowSession = true,
    AccentColor = Color3.fromRGB(90, 140, 255),
    BackColor   = Color3.fromRGB(20, 20, 26),
    TextColor   = Color3.fromRGB(240, 240, 245),
    MutedColor  = Color3.fromRGB(150, 150, 165),
    BackTransparency = 0.15,
}
WallHack.Visuals.TracerSettings = WallHack.Visuals.TracerSettings or {
    Enabled = false, Color = Color3.fromRGB(255, 100, 100),
    Transparency = 0.5, Thickness = 1, Origin = "Bottom", -- Bottom | Mouse | Top
}
WallHack.Visuals.NameSettings = WallHack.Visuals.NameSettings or {
    Enabled = false, Color = Color3.fromRGB(255, 255, 255),
    Size = 14, ShowDistance = true, ShowHealth = true,
}
WallHack.Visuals.SelfESP = WallHack.Visuals.SelfESP or {
    Enabled = false,
    Chams = {
        Enabled = false, Mode = "Both",   -- Fill | Outline | Both | Texture | Wireframe
        FillColor = Color3.fromRGB(90, 140, 255), FillTransparency = 0.4,
        OutlineColor = Color3.fromRGB(255, 255, 255), OutlineTransparency = 0.0,
        AlwaysOnTop = true,
        TextureId = "rbxassetid://0",
        TextureTransparency = 0.3,
        TextureFaces = "Front", -- Front | AllFaces
    },
    ChinaHat = {
        Enabled = false,
        Color   = Color3.fromRGB(255, 60, 60),
        Material = "Neon",
        Size = 4, OffsetY = 1.8, Transparency = 0, Rotation = 0,
        UseMesh = true,
        AutoRotate = false, RotateSpeed = 90,
        Rainbow = false, RainbowSpeed = 0.5,
    },
}
WallHack.Internal = WallHack.Internal or {
    HUD = {
        Elements = {}, Conn = nil, Frames = 0,
        LastSample = os.clock(), CurrentFps = 0,
        SessionStart = os.clock(), Visible = false,
        W = 230, H = 84,
    },
    SelfESP = {
        Highlight = nil, TextureDecals = {},
        HatPart = nil, HatHead = nil,
        HatConn = nil, CharConn = nil, HatFolder = nil,
        ResolvedMaterial = Enum.Material.Neon,
        LastSchemaMaterial = nil, LastAppliedMaterial = nil,
        LastTextureId = nil, LastTextureMode = nil,
    },
}
WallHack.WrappedPlayers = WallHack.WrappedPlayers or {}
WallHack.Functions      = WallHack.Functions      or {}

-- ============================================================================
-- PART 2 — INIT
-- ============================================================================
local okInit, errInit = pcall(function()

    local Util = H.Util
    if not Util then error("H.Util missing") end

    local Players       = Util.Players
    local RunService    = Util.RunService
    local LocalPlayer   = Util.LocalPlayer
    local SanitizeColor = Util.SanitizeColor or function(c) return c end

    local function SafeColor(c, fallback)
        local safe = SanitizeColor(c)
        if typeof(safe) ~= "Color3" then
            return fallback or Color3.fromRGB(255, 255, 255)
        end
        return safe
    end

    local function IsEnemyByAimbot(plr)
        if not plr or plr == LocalPlayer then return false end
        local A = H.Aimbot
        if not A or not A.Settings or not A.Settings.TeamCheck then return true end
        local tc = A.Settings.TeamCheck
        if not tc.Enabled then return true end
        local lt, tt = LocalPlayer.Team, plr.Team
        local mode = tc.Mode or "Enemies"
        if mode == "All" then return true end
        if mode == "Enemies" then
            if lt and tt and lt == tt then return false end
            if (not lt or not tt) and not tc.TreatNeutralAsEnemy then return false end
            return true
        elseif mode == "Allies" then
            return (lt ~= nil and tt ~= nil and lt == tt)
        elseif mode == "IgnoreNeutrals" then
            if not lt or not tt then return false end
            return lt ~= tt
        end
        return true
    end

    local VALID_PART_MATERIALS = {
        "Plastic", "SmoothPlastic", "Neon", "Wood", "WoodPlanks",
        "Marble", "Slate", "Concrete", "Granite", "Brick",
        "Pebble", "Cobblestone", "Rock", "Sandstone", "Basalt",
        "Limestone", "Pavement", "Asphalt", "Salt", "Mud", "Ground",
        "Sand", "Fabric", "Grass", "Snow", "Glacier", "Ice",
        "Metal", "CorrodedMetal", "DiamondPlate", "Foil",
        "Glass", "ForceField",
    }
    local MATERIAL_SET = {}
    for _, n in ipairs(VALID_PART_MATERIALS) do MATERIAL_SET[n] = true end

    local MATERIAL_LOOKUP = {}
    do
        local ok, items = pcall(function() return Enum.Material:GetEnumItems() end)
        if ok and items then
            for _, item in ipairs(items) do
                MATERIAL_LOOKUP[item.Name:lower()] = item.Name
            end
        end
        for _, name in ipairs(VALID_PART_MATERIALS) do
            if not MATERIAL_LOOKUP[name:lower()] then
                MATERIAL_LOOKUP[name:lower()] = name
            end
        end
    end

    local function resolveMaterial(name)
        if typeof(name) == "EnumItem" then
            if name.EnumType == Enum.Material then return name end
            name = tostring(name)
        end
        if type(name) ~= "string" or name == "" then return Enum.Material.Neon end
        local ok, m = pcall(function() return Enum.Material[name] end)
        if ok and m then return m end
        local canonical = MATERIAL_LOOKUP[name:lower()]
        if canonical then
            local ok2, m2 = pcall(function() return Enum.Material[canonical] end)
            if ok2 and m2 then return m2 end
        end
        return Enum.Material.Neon
    end

    local function stripMaterialOverrides(part)
        if not part then return end
        local mv = part:FindFirstChildOfClass("MaterialVariant")
        if mv then pcall(function() mv:Destroy() end) end
        local sa = part:FindFirstChildOfClass("SurfaceAppearance")
        if sa then pcall(function() sa:Destroy() end) end
    end

    -- FIX: ensure mesh doesn't override material appearance
    local function ensureMeshNeutral(part)
        if not part then return end
        local mesh = part:FindFirstChildOfClass("SpecialMesh")
        if mesh then
            pcall(function()
                mesh.TextureId = ""
                mesh.VertexColor = Vector3.new(1, 1, 1)
            end)
        end
    end

    local function applyMaterialToPart(part, materialEnum)
        if not part or not part.Parent then return end
        if not materialEnum or typeof(materialEnum) ~= "EnumItem" then return end
        if materialEnum.EnumType ~= Enum.Material then return end
        stripMaterialOverrides(part)
        ensureMeshNeutral(part)
        if part.Material ~= materialEnum then
            pcall(function() part.Material = materialEnum end)
        end
    end

    local function setChinaHatMaterialInternal(name, silent)
        local resolved = resolveMaterial(name)
        local nameStr  = resolved.Name
        if not MATERIAL_SET[nameStr] then
            resolved = Enum.Material.Neon
            if not silent then
                warn(string.format(
                    "[AirHub][ChinaHat] invalid Material '%s' → Neon.", tostring(name)))
            end
        end
        WallHack.Visuals.SelfESP.ChinaHat.Material = resolved.Name
        WallHack.Internal.SelfESP.ResolvedMaterial = resolved
        local Se = WallHack.Internal.SelfESP
        if Se.HatPart then
            applyMaterialToPart(Se.HatPart, resolved)
            Se.LastAppliedMaterial = resolved
        end
        return resolved
    end

    local function getPingMs()
        local ok, raw = pcall(function() return LocalPlayer:GetNetworkPing() end)
        if not ok or type(raw) ~= "number" then return 0 end
        if raw < 10 then return math.floor(raw * 1000 + 0.5) end
        return math.floor(raw + 0.5)
    end

    -- ========================================================================
    -- HUD
    -- ========================================================================
    local function hudNewText(size, font)
        local t = Drawing.new("Text")
        t.Font = font or 2; t.Size = size or 14
        t.Outline = true; t.Center = false; t.Visible = false
        return t
    end
    local function hudEnsureElements()
        local HUD = WallHack.Internal.HUD
        if HUD.Elements.bg and HUD.Elements.accent and HUD.Elements.title
           and HUD.Elements.subtitle and HUD.Elements.line1 and HUD.Elements.line2 then
            return true
        end
        local S = WallHack.Visuals.HUDSettings
        local built = {}
        local ok = pcall(function()
            local bg = Drawing.new("Square")
            bg.Filled = true; bg.Outline = false
            bg.Color = S.BackColor; bg.Transparency = S.BackTransparency
            pcall(function() bg.Rounding = 8 end)
            bg.Visible = false; built.bg = bg
            local accent = Drawing.new("Square")
            accent.Filled = true; accent.Outline = false
            accent.Color = S.AccentColor; accent.Transparency = 0
            pcall(function() accent.Rounding = 4 end)
            accent.Visible = false; built.accent = accent
            built.title = hudNewText(16, 2); built.subtitle = hudNewText(11, 1)
            built.line1 = hudNewText(13, 2); built.line2    = hudNewText(13, 2)
        end)
        if not ok then
            for _, e in pairs(built) do
                if e and e.Remove then pcall(function() e:Remove() end) end
            end
            return false
        end
        HUD.Elements.bg = built.bg; HUD.Elements.accent = built.accent
        HUD.Elements.title = built.title; HUD.Elements.subtitle = built.subtitle
        HUD.Elements.line1 = built.line1; HUD.Elements.line2 = built.line2
        return true
    end
    local function hudHideAll()
        for _, e in pairs(WallHack.Internal.HUD.Elements) do
            pcall(function() e.Visible = false end)
        end
    end
    local function hudShowAll()
        for _, e in pairs(WallHack.Internal.HUD.Elements) do
            pcall(function() e.Visible = true end)
        end
    end
    local function hudGetPosition()
        local HUD = WallHack.Internal.HUD
        local vp = workspace.CurrentCamera.ViewportSize
        local pos = WallHack.Visuals.HUDSettings.Position or "TopLeft"
        local pad = 18
        if pos == "TopLeft"     then return Vector2.new(pad, pad) end
        if pos == "TopRight"    then return Vector2.new(vp.X - HUD.W - pad, pad) end
        if pos == "BottomLeft"  then return Vector2.new(pad, vp.Y - HUD.H - pad) end
        if pos == "BottomRight" then return Vector2.new(vp.X - HUD.W - pad, vp.Y - HUD.H - pad) end
        return Vector2.new(pad, pad)
    end
    local function hudFmtTime(sec)
        sec = math.floor(sec)
        local h = math.floor(sec / 3600)
        local m = math.floor((sec % 3600) / 60)
        local s = sec % 60
        if h > 0 then return string.format("%dh %02dm", h, m) end
        if m > 0 then return string.format("%dm %02ds", m, s) end
        return string.format("%ds", s)
    end
    local function hudUpdate()
        if H.ShuttingDown then return end
        local HUD = WallHack.Internal.HUD
        local S   = WallHack.Visuals.HUDSettings
        if not S.Enabled then
            if HUD.Visible then hudHideAll(); HUD.Visible = false end
            return
        end
        if not hudEnsureElements() then return end
        if not HUD.Visible then hudShowAll(); HUD.Visible = true end
        local pos = hudGetPosition()
        local paddingX = 14
        local bg = HUD.Elements.bg
        bg.Size = Vector2.new(HUD.W, HUD.H); bg.Position = pos
        bg.Color = SafeColor(S.BackColor, Color3.fromRGB(20,20,26))
        bg.Transparency = S.BackTransparency
        local accent = HUD.Elements.accent
        accent.Size = Vector2.new(4, HUD.H); accent.Position = pos
        accent.Color = SafeColor(S.AccentColor, Color3.fromRGB(90,140,255))
        local title = HUD.Elements.title
        title.Text = "AirHub"; title.Color = SafeColor(S.TextColor, Color3.fromRGB(240,240,245))
        title.Position = Vector2.new(pos.X + paddingX, pos.Y + 7)
        local subtitle = HUD.Elements.subtitle
        subtitle.Text = "▸ connected"; subtitle.Color = SafeColor(S.MutedColor, Color3.fromRGB(150,150,165))
        subtitle.Position = Vector2.new(pos.X + paddingX + 66, pos.Y + 12)
        local parts1 = {}
        if S.ShowPlayers then table.insert(parts1, string.format("Players  %d", #Players:GetPlayers())) end
        if S.ShowFPS     then table.insert(parts1, string.format("FPS  %d", HUD.CurrentFps)) end
        local line1 = HUD.Elements.line1
        line1.Text = table.concat(parts1, "     "); line1.Color = SafeColor(S.TextColor, Color3.fromRGB(240,240,245))
        line1.Position = Vector2.new(pos.X + paddingX, pos.Y + 36)
        local parts2 = {}
        if S.ShowPing    then table.insert(parts2, string.format("Ping  %d ms", getPingMs())) end
        if S.ShowSession then table.insert(parts2,
            string.format("Session  %s", hudFmtTime(os.clock() - HUD.SessionStart))) end
        local line2 = HUD.Elements.line2
        line2.Text = table.concat(parts2, "     "); line2.Color = SafeColor(S.MutedColor, Color3.fromRGB(150,150,165))
        line2.Position = Vector2.new(pos.X + paddingX, pos.Y + 58)
        HUD.Frames += 1
        local now = os.clock()
        if now - HUD.LastSample >= 1 then
            HUD.CurrentFps = math.floor(HUD.Frames / (now - HUD.LastSample) + 0.5)
            HUD.Frames = 0; HUD.LastSample = now
        end
    end
    local function StartHUD()
        local HUD = WallHack.Internal.HUD
        if HUD.Conn then return end
        HUD.SessionStart = os.clock(); HUD.LastSample = os.clock()
        HUD.Frames = 0; HUD.CurrentFps = 0
        HUD.Conn = RunService.RenderStepped:Connect(hudUpdate)
    end
    local function StopHUD()
        local HUD = WallHack.Internal.HUD
        WallHack.Visuals.HUDSettings.Enabled = false
        if HUD.Conn then pcall(function() HUD.Conn:Disconnect() end); HUD.Conn = nil end
        for _, e in pairs(HUD.Elements) do
            if e and e.Remove then pcall(function() e:Remove() end) end
        end
        HUD.Elements = {}; HUD.Visible = false
    end

    -- ========================================================================
    -- SELF ESP — Highlight Chams + Texture Chams + Wireframe
    -- ========================================================================
    local function applyChamsProps(hl)
        local C = WallHack.Visuals.SelfESP.Chams
        hl.FillColor = SafeColor(C.FillColor, Color3.fromRGB(90,140,255))
        hl.OutlineColor = SafeColor(C.OutlineColor, Color3.fromRGB(255,255,255))
        local fillVisible    = (C.Mode == "Fill"    or C.Mode == "Both")
        local outlineVisible = (C.Mode == "Outline" or C.Mode == "Both")
        hl.FillTransparency    = fillVisible    and C.FillTransparency    or 1
        hl.OutlineTransparency = outlineVisible and C.OutlineTransparency or 1
        hl.DepthMode = C.AlwaysOnTop
            and Enum.HighlightDepthMode.AlwaysOnTop
            or  Enum.HighlightDepthMode.Occluded
    end

    -- Texture chams via Decals
    local function removeTextureChams(char)
        local Se = WallHack.Internal.SelfESP
        if Se.TextureDecals then
            for _, d in ipairs(Se.TextureDecals) do
                if d and d.Parent then pcall(function() d:Destroy() end) end
            end
        end
        Se.TextureDecals = {}
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    for _, child in ipairs(part:GetChildren()) do
                        if child.Name and child.Name:sub(1, 10) == "AirHubTC__" then
                            pcall(function() child:Destroy() end)
                        end
                    end
                end
            end
        end
    end
    local TEXTURE_FACES_FRONT = { Enum.NormalId.Front }
    local TEXTURE_FACES_ALL = {
        Enum.NormalId.Front, Enum.NormalId.Back,
        Enum.NormalId.Left, Enum.NormalId.Right,
        Enum.NormalId.Top, Enum.NormalId.Bottom,
    }
    local function applyTextureChams(char)
        local Se = WallHack.Internal.SelfESP
        local C  = WallHack.Visuals.SelfESP.Chams
        local texId = C.TextureId or ""
        local texTrans = math.clamp(tonumber(C.TextureTransparency) or 0.3, 0, 1)
        local faces = (C.TextureFaces == "AllFaces") and TEXTURE_FACES_ALL or TEXTURE_FACES_FRONT

        if not texId or texId == "" or texId == "rbxassetid://0" then
            removeTextureChams(char)
            return
        end

        removeTextureChams(char)
        Se.TextureDecals = {}
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                for _, face in ipairs(faces) do
                    local decal = Instance.new("Decal")
                    decal.Name = "AirHubTC__" .. face.Name
                    decal.Texture = texId
                    decal.Face = face
                    decal.Transparency = texTrans
                    decal.Parent = part
                    table.insert(Se.TextureDecals, decal)
                end
            end
        end
    end

    -- Wireframe chams via Highlight with transparent fill
    local function applyWireframe(hl)
        local C = WallHack.Visuals.SelfESP.Chams
        hl.FillTransparency = 1
        hl.OutlineTransparency = math.clamp(tonumber(C.OutlineTransparency) or 0, 0, 1) * 0.5
        hl.FillColor = SafeColor(C.OutlineColor, Color3.fromRGB(255,255,255))
        hl.OutlineColor = SafeColor(C.OutlineColor, Color3.fromRGB(255,255,255))
        hl.DepthMode = C.AlwaysOnTop
            and Enum.HighlightDepthMode.AlwaysOnTop
            or  Enum.HighlightDepthMode.Occluded
    end

    local function applyChams(char)
        if not char then return end
        local Se = WallHack.Internal.SelfESP
        local C  = WallHack.Visuals.SelfESP.Chams
        local mode = C.Mode or "Both"

        if mode == "Texture" then
            if Se.Highlight and Se.Highlight.Parent then
                pcall(function() Se.Highlight:Destroy() end)
                Se.Highlight = nil
            end
            applyTextureChams(char)
            return
        else
            removeTextureChams(char)
        end

        if Se.Highlight and Se.Highlight.Parent then
            applyChamsProps(Se.Highlight)
            if mode == "Wireframe" then applyWireframe(Se.Highlight) end
            Se.Highlight.Adornee = char
            return
        end

        local hl = Instance.new("Highlight")
        hl.Name = "AirHubSelfChams"; hl.Adornee = char
        applyChamsProps(hl)
        if mode == "Wireframe" then applyWireframe(hl) end
        hl.Parent = char
        Se.Highlight = hl
    end
    local function removeChams()
        local Se = WallHack.Internal.SelfESP
        if Se.Highlight then pcall(function() Se.Highlight:Destroy() end); Se.Highlight = nil end
        removeTextureChams(LocalPlayer.Character)
    end

    -- ========================================================================
    -- CHINA HAT — fixed materials, retry loop starts before head check
    -- ========================================================================
    local HAT_CONE_MESH = "rbxassetid://1033714"

    local function getHatFolder()
        local Se = WallHack.Internal.SelfESP
        if Se.HatFolder and Se.HatFolder.Parent then return Se.HatFolder end
        local existing = workspace:FindFirstChild("AirHub_SelfESP")
        if not existing then
            existing = Instance.new("Folder")
            existing.Name = "AirHub_SelfESP"; existing.Parent = workspace
        end
        Se.HatFolder = existing
        return existing
    end

    local function buildHat(head)
        local C  = WallHack.Visuals.SelfESP.ChinaHat
        local Se = WallHack.Internal.SelfESP
        local resolved = setChinaHatMaterialInternal(C.Material, true)
        Se.LastSchemaMaterial = C.Material

        local hat = Instance.new("Part")
        hat.Name = "AirHubChinaHat"
        if not C.UseMesh then hat.Shape = Enum.PartType.Ball end
        hat.Size  = Vector3.new(1, 1, 1)
        hat.Anchored   = true
        hat.CanCollide = false
        hat.CanQuery   = false
        hat.CanTouch   = false
        hat.Massless   = true
        hat.CastShadow = false
        hat.Color      = SafeColor(C.Color, Color3.fromRGB(255,60,60))
        hat.Transparency = math.clamp(tonumber(C.Transparency) or 0, 0, 1)
        hat.LocalTransparencyModifier = 0
        hat.CFrame = head.CFrame * CFrame.new(0, C.OffsetY, 0)
        hat.Parent = getHatFolder()

        if C.UseMesh then
            local mesh = Instance.new("SpecialMesh")
            mesh.Name     = "AirHubHatMesh"
            mesh.MeshType = Enum.MeshType.FileMesh
            mesh.MeshId   = HAT_CONE_MESH
            pcall(function() mesh.TextureId = "" end)
            pcall(function() mesh.VertexColor = Vector3.new(1, 1, 1) end)
            mesh.Scale    = Vector3.new(C.Size, C.Size * 0.7, C.Size)
            mesh.Parent = hat
        end

        applyMaterialToPart(hat, resolved)
        Se.LastAppliedMaterial = resolved
        return hat
    end

    local function stopHatLoop()
        local Se = WallHack.Internal.SelfESP
        if Se.HatConn then
            pcall(function() Se.HatConn:Disconnect() end); Se.HatConn = nil
        end
    end
    local function removeChinaHat()
        stopHatLoop()
        local Se = WallHack.Internal.SelfESP
        if Se.HatPart then pcall(function() Se.HatPart:Destroy() end); Se.HatPart = nil end
        Se.HatHead = nil
        Se.LastAppliedMaterial = nil
    end

    local function startHatLoop()
        local Se = WallHack.Internal.SelfESP
        if Se.HatConn then return end
        Se.HatConn = RunService.RenderStepped:Connect(function()
            if H.ShuttingDown then return end
            if not Se.HatHead or not Se.HatHead.Parent then
                local char = LocalPlayer.Character
                local head = char and char:FindFirstChild("Head")
                if head then Se.HatHead = head else return end
            end
            if not Se.HatPart or not Se.HatPart.Parent then
                Se.HatPart = buildHat(Se.HatHead)
            end
            local hat  = Se.HatPart
            local head = Se.HatHead
            local C    = WallHack.Visuals.SelfESP.ChinaHat

            if Se.LastSchemaMaterial ~= C.Material then
                local newResolved = setChinaHatMaterialInternal(C.Material, true)
                Se.LastSchemaMaterial = C.Material
                if hat and newResolved then
                    applyMaterialToPart(hat, newResolved)
                    Se.LastAppliedMaterial = newResolved
                end
            end

            local mesh = hat:FindFirstChild("AirHubHatMesh")
            if C.UseMesh then
                if not mesh then
                    mesh = Instance.new("SpecialMesh")
                    mesh.Name = "AirHubHatMesh"
                    mesh.MeshType = Enum.MeshType.FileMesh
                    mesh.MeshId = HAT_CONE_MESH
                    pcall(function() mesh.TextureId = "" end)
                    pcall(function() mesh.VertexColor = Vector3.new(1, 1, 1) end)
                    mesh.Parent = hat
                end
                local wantScale = Vector3.new(C.Size, C.Size * 0.7, C.Size)
                if mesh.Scale ~= wantScale then mesh.Scale = wantScale end
                if hat.Shape ~= Enum.PartType.Block then hat.Shape = Enum.PartType.Block end
            else
                if mesh then pcall(function() mesh:Destroy() end); mesh = nil end
                if hat.Shape ~= Enum.PartType.Ball then hat.Shape = Enum.PartType.Ball end
                local wantSize = Vector3.new(C.Size * 1.6, C.Size * 0.55, C.Size * 1.6)
                if hat.Size ~= wantSize then hat.Size = wantSize end
            end

            hat.LocalTransparencyModifier = 0
            hat.Transparency = math.clamp(tonumber(C.Transparency) or 0, 0, 1)
            if C.Rainbow then
                local hue = (os.clock() * (C.RainbowSpeed or 0.5)) % 1
                hat.Color = Color3.fromHSV(hue, 1, 1)
            else
                hat.Color = SafeColor(C.Color, Color3.fromRGB(255,60,60))
            end

            local resolved = Se.ResolvedMaterial or Enum.Material.Neon
            if Se.LastAppliedMaterial ~= resolved or hat.Material ~= resolved then
                applyMaterialToPart(hat, resolved)
                Se.LastAppliedMaterial = resolved
            end

            if not hat.Anchored then hat.Anchored = true end
            local angle
            if C.AutoRotate then
                angle = (os.clock() * (C.RotateSpeed or 90)) % 360
            else
                angle = C.Rotation or 0
            end
            hat.CFrame = head.CFrame
                * CFrame.new(0, C.OffsetY, 0)
                * CFrame.Angles(0, math.rad(angle), 0)
        end)
    end

    -- FIX: retry loop starts before head check
    local function applyChinaHat()
        local Se = WallHack.Internal.SelfESP
        local char = LocalPlayer.Character
        if not char then
            startHatLoop()
            return
        end
        local head = char:FindFirstChild("Head")
        if head then
            if Se.HatPart and Se.HatPart.Parent then
                Se.HatHead = head
            else
                if Se.HatPart then pcall(function() Se.HatPart:Destroy() end); Se.HatPart = nil end
                Se.HatPart = buildHat(head)
                Se.HatHead = head
            end
        end
        startHatLoop()
    end

    local function refreshSelfESP()
        local S = WallHack.Visuals.SelfESP
        local char = LocalPlayer.Character
        -- FIX: sync Enabled with actual state
        S.Enabled = S.Chams.Enabled or S.ChinaHat.Enabled
        if not char then removeChams(); removeChinaHat(); return end
        if S.Chams.Enabled    then applyChams(char) else removeChams()    end
        if S.ChinaHat.Enabled then applyChinaHat()  else removeChinaHat() end
    end

    local function StartSelfESP()
        local Se = WallHack.Internal.SelfESP
        if not Se.CharConn then
            Se.CharConn = LocalPlayer.CharacterAdded:Connect(function()
                task.wait(0.5)
                if H.ShuttingDown then return end
                refreshSelfESP()
            end)
        end
        refreshSelfESP()
    end
    local function StopSelfESP()
        local Se = WallHack.Internal.SelfESP
        WallHack.Visuals.SelfESP.Enabled = false
        if Se.CharConn then pcall(function() Se.CharConn:Disconnect() end); Se.CharConn = nil end
        removeChams(); removeChinaHat()
    end

    local function ForceMaterialRefresh()
        local Se = WallHack.Internal.SelfESP
        local C  = WallHack.Visuals.SelfESP.ChinaHat
        local resolved = setChinaHatMaterialInternal(C.Material, false)
        Se.LastSchemaMaterial = C.Material
        if Se.HatPart then
            applyMaterialToPart(Se.HatPart, resolved)
            Se.LastAppliedMaterial = resolved
        end
        return resolved.Name
    end

    -- ========================================================================
    -- GLOW
    -- ========================================================================
    local function ApplyGlowForPlayer(plr)
        local data = WallHack.WrappedPlayers[plr.Name]
        if not data then return end
        local shouldShow = WallHack.Settings.Enabled and WallHack.Visuals.GlowSettings.Enabled
        if not shouldShow then
            if data.Glow then pcall(function() data.Glow:Destroy() end); data.Glow = nil end
            return
        end
        local char = plr.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if not (char and hum and hum.Health > 0) then
            if data.Glow then pcall(function() data.Glow:Destroy() end); data.Glow = nil end
            return
        end
        -- FIX: check Adornee
        if not data.Glow or not data.Glow.Parent or data.Glow.Adornee ~= char then
            if data.Glow then pcall(function() data.Glow:Destroy() end) end
            local hl = Instance.new("Highlight")
            hl.Name = "AirHub_Glow"; hl.Adornee = char; hl.Parent = char
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            data.Glow = hl
        end
        data.Glow.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        local gs = WallHack.Visuals.GlowSettings
        local safeColor = SafeColor(gs.Color, Color3.fromRGB(0,255,255))
        local safeTrans = math.clamp(tonumber(gs.Transparency) or 0.5, 0, 1)
        local mode = gs.Mode or "Outline"
        if mode == "Outline" then
            data.Glow.FillTransparency = 1
            data.Glow.OutlineTransparency = safeTrans
            data.Glow.FillColor = safeColor; data.Glow.OutlineColor = safeColor
        elseif mode == "Fill" then
            data.Glow.FillTransparency = safeTrans
            data.Glow.OutlineTransparency = 1
            data.Glow.FillColor = safeColor; data.Glow.OutlineColor = safeColor
        elseif mode == "Both" then
            data.Glow.FillTransparency = safeTrans * 0.5
            data.Glow.OutlineTransparency = safeTrans * 0.5
            data.Glow.FillColor = safeColor; data.Glow.OutlineColor = safeColor
        elseif mode == "Pulse" then
            local pulse = (math.sin(os.clock() * 2) + 1) / 2
            local r = math.clamp(safeColor.R * (0.5 + pulse * 0.5), 0, 1)
            local g = math.clamp(safeColor.G * (0.5 + pulse * 0.5), 0, 1)
            local b = math.clamp(safeColor.B * (0.5 + pulse * 0.5), 0, 1)
            local pulsed = Color3.new(r, g, b)
            data.Glow.FillColor = pulsed; data.Glow.OutlineColor = pulsed
            data.Glow.FillTransparency = safeTrans * (0.5 + pulse * 0.5)
            data.Glow.OutlineTransparency = safeTrans * (0.5 + pulse * 0.5)
        end
    end
    local function ApplyGlowToAll()
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then ApplyGlowForPlayer(plr) end
        end
    end

    -- ========================================================================
    -- BOXES
    -- ========================================================================
    local function AddBox(plr)
        local t = WallHack.WrappedPlayers[plr.Name]
        if not t then return end
        local ok = pcall(function()
            t.Box = {
                Square          = Drawing.new("Square"),
                TopLeftLine     = Drawing.new("Line"),
                TopRightLine    = Drawing.new("Line"),
                BottomLeftLine  = Drawing.new("Line"),
                BottomRightLine = Drawing.new("Line"),
            }
        end)
        if not ok then t.Box = {}; return end

        t.Connections.Box = RunService.RenderStepped:Connect(function()
            if H.ShuttingDown then return end
            if not WallHack.Settings.Enabled or not WallHack.Visuals.BoxSettings.Enabled then
                for _, v in pairs(t.Box) do v.Visible = false end; return
            end
            local char = plr.Character
            if not char or not char:FindFirstChild("HumanoidRootPart")
               or not char:FindFirstChild("Head") then
                for _, v in pairs(t.Box) do v.Visible = false end; return
            end
            local cam = workspace.CurrentCamera
            local vec, onScreen = cam:WorldToViewportPoint(char.HumanoidRootPart.Position)
            if not onScreen or not t.Checks.Alive or not t.Checks.Team then
                for _, v in pairs(t.Box) do v.Visible = false end; return
            end
            local isTarget = (H.Aimbot and H.Aimbot.Locked == plr)
            local boxColor = isTarget
                and SafeColor(WallHack.Visuals.BoxSettings.TargetColor, Color3.fromRGB(255,0,0))
                or  SafeColor(WallHack.Visuals.BoxSettings.Color, Color3.fromRGB(255,255,255))

            if WallHack.Visuals.BoxSettings.Type == 2 then
                t.Box.Square.Visible = true
                for k, v in pairs(t.Box) do if k ~= "Square" then v.Visible = false end end
                t.Box.Square.Thickness    = WallHack.Visuals.BoxSettings.Thickness
                t.Box.Square.Color        = boxColor
                t.Box.Square.Transparency = WallHack.Visuals.BoxSettings.Transparency
                t.Box.Square.Filled       = WallHack.Visuals.BoxSettings.Filled
                local headV = cam:WorldToViewportPoint(char.Head.Position + Vector3.new(0, 0.5, 0))
                local legV  = cam:WorldToViewportPoint(char.HumanoidRootPart.Position - Vector3.new(0, 3, 0))
                if not headV or not legV then
                    for _, v in pairs(t.Box) do v.Visible = false end; return
                end
                local h = math.max(2, headV.Y - legV.Y)
                t.Box.Square.Size     = Vector2.new(2000 / math.max(vec.Z, 0.01), h)
                t.Box.Square.Position = Vector2.new(vec.X - t.Box.Square.Size.X / 2, legV.Y)
            else
                local hrpCF = char.HumanoidRootPart.CFrame
                local size  = char.HumanoidRootPart.Size * WallHack.Visuals.BoxSettings.Increase
                -- FIX: safe corner projection
                local function corner(off)
                    local v, on = cam:WorldToViewportPoint((hrpCF * off).Position)
                    if not on then return nil end
                    return Vector2.new(v.X, v.Y)
                end
                local tl = corner(CFrame.new( size.X,  size.Y, 0))
                local tr = corner(CFrame.new(-size.X,  size.Y, 0))
                local bl = corner(CFrame.new( size.X, -size.Y - 0.5, 0))
                local br = corner(CFrame.new(-size.X, -size.Y - 0.5, 0))
                if not (tl and tr and bl and br) then
                    for _, v in pairs(t.Box) do v.Visible = false end; return
                end
                t.Box.Square.Visible = false
                for _, ln in pairs({"TopLeftLine", "TopRightLine", "BottomLeftLine", "BottomRightLine"}) do
                    t.Box[ln].Visible      = true
                    t.Box[ln].Thickness    = WallHack.Visuals.BoxSettings.Thickness
                    t.Box[ln].Transparency = WallHack.Visuals.BoxSettings.Transparency
                    t.Box[ln].Color        = boxColor
                end
                t.Box.TopLeftLine.From     = tl
                t.Box.TopLeftLine.To       = tr
                t.Box.TopRightLine.From    = tr
                t.Box.TopRightLine.To      = br
                t.Box.BottomLeftLine.From  = bl
                t.Box.BottomLeftLine.To    = tl
                t.Box.BottomRightLine.From = br
                t.Box.BottomRightLine.To   = bl
            end
        end)
    end

    -- ========================================================================
    -- TRACERS + NAME TAGS
    -- ========================================================================
    local function AddTracer(plr)
        local t = WallHack.WrappedPlayers[plr.Name]
        if not t then return end
        local ok = pcall(function()
            t.Tracer = Drawing.new("Line")
            t.Tracer.Transparency = 1; t.Tracer.ZIndex = 2
        end)
        if not ok then return end

        t.Connections.Tracer = RunService.RenderStepped:Connect(function()
            if H.ShuttingDown then return end
            if not WallHack.Settings.Enabled or not WallHack.Visuals.TracerSettings.Enabled then
                t.Tracer.Visible = false; return
            end
            local char = plr.Character
            if not char or not char:FindFirstChild("HumanoidRootPart")
               or not t.Checks.Alive or not t.Checks.Team then
                t.Tracer.Visible = false; return
            end
            local cam = workspace.CurrentCamera
            local vec, onScreen = cam:WorldToViewportPoint(char.HumanoidRootPart.Position)
            if not onScreen then t.Tracer.Visible = false; return end
            local S = WallHack.Visuals.TracerSettings
            local vp = cam.ViewportSize
            local origin
            if S.Origin == "Mouse" then
                origin = Vector2.new(vp.X / 2, vp.Y / 2)
            elseif S.Origin == "Top" then
                origin = Vector2.new(vp.X / 2, 0)
            else
                origin = Vector2.new(vp.X / 2, vp.Y)
            end
            t.Tracer.From         = origin
            t.Tracer.To           = Vector2.new(vec.X, vec.Y)
            t.Tracer.Color        = SafeColor(S.Color, Color3.fromRGB(255,100,100))
            t.Tracer.Thickness    = math.clamp(tonumber(S.Thickness) or 1, 1, 5)
            t.Tracer.Transparency = math.clamp(tonumber(S.Transparency) or 0.5, 0, 1)
            t.Tracer.Visible      = true
        end)
    end

    local function AddNameTag(plr)
        local t = WallHack.WrappedPlayers[plr.Name]
        if not t then return end
        local ok = pcall(function()
            t.NameTag = Drawing.new("Text")
            t.NameTag.Center = true; t.NameTag.Outline = true
            t.NameTag.Font = 2; t.NameTag.Size = 14
            t.NameTag.ZIndex = 4
        end)
        if not ok then return end

        t.Connections.NameTag = RunService.RenderStepped:Connect(function()
            if H.ShuttingDown then return end
            local S = WallHack.Visuals.NameSettings
            if not WallHack.Settings.Enabled or not S.Enabled then
                t.NameTag.Visible = false; return
            end
            local char = plr.Character
            if not char or not char:FindFirstChild("Head")
               or not t.Checks.Alive or not t.Checks.Team then
                t.NameTag.Visible = false; return
            end
            local cam = workspace.CurrentCamera
            local v, on = cam:WorldToViewportPoint(char.Head.Position + Vector3.new(0, 1.5, 0))
            if not on then t.NameTag.Visible = false; return end
            local text = plr.Name
            if S.ShowDistance and char.HumanoidRootPart and LocalPlayer.Character then
                local lhrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if lhrp then
                    local d = (char.HumanoidRootPart.Position - lhrp.Position).Magnitude
                    text = text .. string.format(" [%d]", math.floor(d))
                end
            end
            if S.ShowHealth then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    text = text .. string.format(" %dHP", math.floor(hum.Health))
                end
            end
            t.NameTag.Text       = text
            t.NameTag.Position   = Vector2.new(v.X, v.Y)
            t.NameTag.Color      = SafeColor(S.Color, Color3.fromRGB(255,255,255))
            t.NameTag.Size       = math.clamp(tonumber(S.Size) or 14, 8, 32)
            t.NameTag.Visible    = true
        end)
    end

    -- ========================================================================
    -- CHECKS + WRAP
    -- ========================================================================
    local function InitChecks(plr)
        local t = WallHack.WrappedPlayers[plr.Name]
        if not t then return end
        t.Connections.UpdateChecks = RunService.RenderStepped:Connect(function()
            if H.ShuttingDown then return end
            local char = plr.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            if char and hum then
                t.Checks.Alive = (not WallHack.Settings.AliveCheck) or hum.Health > 0
                t.Checks.Team  = (not WallHack.Settings.TeamCheck) or IsEnemyByAimbot(plr)
            else
                t.Checks.Alive = false
                t.Checks.Team = false
            end
            pcall(ApplyGlowForPlayer, plr)
        end)
    end

    local MAX_RIG_ATTEMPTS = 6
    local RIG_WAIT_TIMEOUT = 15
    local function AssignRigType(plr, attempt)
        attempt = (attempt or 0) + 1
        if attempt > MAX_RIG_ATTEMPTS then return end
        local t = WallHack.WrappedPlayers[plr.Name]
        if not t then return end
        task.spawn(function()
            local waited = 0
            while waited < RIG_WAIT_TIMEOUT do
                task.wait(0.5); waited = waited + 0.5
                if H.ShuttingDown then return end
                if plr.Character then break end
            end
            if H.ShuttingDown then return end
            local char = plr.Character
            if not char then return end
            if char:FindFirstChild("Torso") and not char:FindFirstChild("LowerTorso") then
                t.RigType = "R6"
            elseif char:FindFirstChild("LowerTorso") then
                t.RigType = "R15"
            else
                AssignRigType(plr, attempt)
            end
        end)
    end

    local function Wrap(plr)
        if not WallHack.WrappedPlayers[plr.Name] then
            local val = {
                Name = plr.Name,
                Checks = { Alive = true, Team = true },
                Connections = {}, Box = {},
            }
            WallHack.WrappedPlayers[plr.Name] = val
            AssignRigType(plr, 0)
            InitChecks(plr)
            AddBox(plr)
            AddTracer(plr)
            AddNameTag(plr)
            ApplyGlowForPlayer(plr)
            val.CharacterAddedConn = plr.CharacterAdded:Connect(function()
                if H.ShuttingDown then return end
                ApplyGlowForPlayer(plr)
            end)
        end
    end
    local function UnWrap(plr)
        local v = WallHack.WrappedPlayers[plr.Name]
        if not v then return end
        for _, c in pairs(v.Connections) do pcall(function() c:Disconnect() end) end
        if v.CharacterAddedConn then pcall(function() v.CharacterAddedConn:Disconnect() end) end
        for _, b in pairs(v.Box) do
            if b and b.Remove then pcall(function() b:Remove() end) end
        end
        if v.Tracer and v.Tracer.Remove then pcall(function() v.Tracer:Remove() end) end
        if v.NameTag and v.NameTag.Remove then pcall(function() v.NameTag:Remove() end) end
        if v.Glow then pcall(function() v.Glow:Destroy() end) end
        WallHack.WrappedPlayers[plr.Name] = nil
    end

    local WHConnections = {}
    local ReWrapToken = 0
    local function StartReWrapLoop()
        ReWrapToken += 1
        local myToken = ReWrapToken
        task.spawn(function()
            while myToken == ReWrapToken and not H.ShuttingDown do
                for _, v in pairs(Players:GetPlayers()) do
                    if v ~= LocalPlayer then Wrap(v) end
                end
                task.wait(30)
            end
        end)
    end
    local function LoadWH()
        WHConnections.PlayerAdded = Players.PlayerAdded:Connect(function(plr)
            if not H.ShuttingDown then Wrap(plr) end
        end)
        WHConnections.PlayerRemoving = Players.PlayerRemoving:Connect(function(plr)
            if not H.ShuttingDown then UnWrap(plr) end
        end)
        StartReWrapLoop()
    end
    LoadWH()

    -- ========================================================================
    -- PUBLIC API
    -- ========================================================================
    WallHack.Functions.Exit = function()
        ReWrapToken += 1
        for _, v in pairs(WHConnections) do pcall(function() v:Disconnect() end) end
        WHConnections = {}
        for _, v in pairs(Players:GetPlayers()) do
            if v ~= LocalPlayer then UnWrap(v) end
        end
        StopHUD(); StopSelfESP()
    end
    WallHack.Functions.Restart = function()
        ReWrapToken += 1
        for _, v in pairs(WHConnections) do pcall(function() v:Disconnect() end) end
        WHConnections = {}
        LoadWH()
    end

    WallHack.Functions.StartHUD = StartHUD
    WallHack.Functions.StopHUD  = StopHUD
    WallHack.Functions.SetHUDEnabled = function(v)
        WallHack.Visuals.HUDSettings.Enabled = v and true or false
        if v then StartHUD() else StopHUD() end
    end
    WallHack.Functions.GetHUDEnabled = function()
        return WallHack.Visuals.HUDSettings.Enabled
    end

    WallHack.Functions.StartSelfESP   = StartSelfESP
    WallHack.Functions.StopSelfESP    = StopSelfESP
    WallHack.Functions.RefreshSelfESP = refreshSelfESP

    WallHack.Functions.SetSelfESPEnabled = function(v)
        WallHack.Visuals.SelfESP.Enabled = v and true or false
        if v then StartSelfESP() else StopSelfESP() end
    end
    -- FIX: sync Enabled properly
    WallHack.Functions.SetSelfESPChamsEnabled = function(v)
        WallHack.Visuals.SelfESP.Chams.Enabled = v and true or false
        WallHack.Visuals.SelfESP.Enabled =
            WallHack.Visuals.SelfESP.Chams.Enabled or WallHack.Visuals.SelfESP.ChinaHat.Enabled
        StartSelfESP()
    end
    WallHack.Functions.SetSelfESPChinaHatEnabled = function(v)
        WallHack.Visuals.SelfESP.ChinaHat.Enabled = v and true or false
        WallHack.Visuals.SelfESP.Enabled =
            WallHack.Visuals.SelfESP.Chams.Enabled or WallHack.Visuals.SelfESP.ChinaHat.Enabled
        StartSelfESP()
    end
    WallHack.Functions.GetSelfESPEnabled = function()
        return WallHack.Visuals.SelfESP.Enabled
    end

    WallHack.Functions.SetChinaHatMaterial = function(name)
        local resolved = setChinaHatMaterialInternal(name, false)
        WallHack.Internal.SelfESP.LastSchemaMaterial =
            WallHack.Visuals.SelfESP.ChinaHat.Material
        return resolved.Name
    end
    WallHack.Functions.GetChinaHatMaterial = function()
        return WallHack.Internal.SelfESP.ResolvedMaterial
    end
    WallHack.Functions.ListValidMaterials = function()
        local out = {}
        for i, n in ipairs(VALID_PART_MATERIALS) do out[i] = n end
        return out
    end
    WallHack.Functions.ForceMaterialRefresh = ForceMaterialRefresh

    for _, materialName in ipairs(VALID_PART_MATERIALS) do
        WallHack.Functions[materialName] = function()
            return WallHack.Functions.SetChinaHatMaterial(materialName)
        end
    end

    setChinaHatMaterialInternal(WallHack.Visuals.SelfESP.ChinaHat.Material, true)
    WallHack.Internal.SelfESP.LastSchemaMaterial =
        WallHack.Visuals.SelfESP.ChinaHat.Material

    WallHack.ApplyGlowToAll     = ApplyGlowToAll
    WallHack.ApplyGlowForPlayer = ApplyGlowForPlayer
    WallHack.SafeColor          = SafeColor
end)

if not okInit then
    warn("[AirHub] 04_wallhack: init error → " .. tostring(errInit))
    local noop = function() end
    for _, k in ipairs({
        "Exit","Restart","StartHUD","StopHUD","SetHUDEnabled",
        "StartSelfESP","StopSelfESP","RefreshSelfESP",
        "SetSelfESPEnabled","SetSelfESPChamsEnabled","SetSelfESPChinaHatEnabled",
        "SetChinaHatMaterial","ForceMaterialRefresh",
        "ApplyGlowToAll","ApplyGlowForPlayer",
    }) do WallHack.Functions[k] = WallHack.Functions[k] or noop end
    WallHack.Functions.GetHUDEnabled       = WallHack.Functions.GetHUDEnabled       or function() return false end
    WallHack.Functions.GetSelfESPEnabled   = WallHack.Functions.GetSelfESPEnabled   or function() return false end
    WallHack.Functions.GetChinaHatMaterial = WallHack.Functions.GetChinaHatMaterial or function() return nil end
    WallHack.Functions.ListValidMaterials  = WallHack.Functions.ListValidMaterials  or function() return {} end
    WallHack.SafeColor = function(c, fb) return fb or Color3.fromRGB(255,255,255) end
end

print(okInit and "[AirHub] 04_wallhack: WallHack loaded OK v2" or "[AirHub] 04_wallhack: WallHack loaded in STUB mode")

-- ============================================================================
-- PART 3 — SERVERPOSITION (fixed torso)
-- ============================================================================
if H.ServerPosition then
    warn("[AirHub] 04_wallhack: ServerPosition already loaded")
else
    local Util        = H.Util
    local RunService  = Util.RunService
    local LocalPlayer = Util.LocalPlayer
    local Track       = Util.Track

    H.ServerPosition = {
        Settings = {
            Enabled  = false,
            RGB      = true,
            Strength = 1,
            MaxLimb  = 6,
        },
        Internal = {
            Connection = nil,
            Ghosts     = {},
        },
    }
    local ServerPosition = H.ServerPosition

    -- FIX: include torso parts
    local part_names = {
        "HumanoidRootPart", "Head",
        "Torso", "UpperTorso", "LowerTorso",
        "Left Arm", "Right Arm", "Left Leg", "Right Leg",
        "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm", "LeftHand", "RightHand",
        "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg", "LeftFoot", "RightFoot",
    }

    local function rgb(t)
        return Color3.fromHSV((t % 5) / 5, 1, 1)
    end

    local function make_ghost(real)
        local g = Instance.new("Part")
        g.Name        = real.Name .. "_ghost"
        g.Size        = real.Size
        g.Anchored    = true
        g.CanCollide  = false
        g.CanQuery    = false
        g.CanTouch    = false
        g.CastShadow  = false
        g.Transparency = 1
        g.CFrame      = real.CFrame
        g.Parent      = workspace

        local box = Instance.new("SelectionBox")
        box.Adornee       = g
        box.LineThickness = 0.04
        box.SurfaceTransparency = 1
        box.Parent = g

        local adorn = Instance.new("BoxHandleAdornment")
        adorn.Name         = "GhostAdornment"
        adorn.Adornee      = g
        adorn.AlwaysOnTop  = true
        adorn.Color3       = Color3.fromRGB(255, 255, 255)
        adorn.Transparency = 0.4
        adorn.Size         = g.Size
        adorn.ZIndex       = 5
        adorn.Parent       = g

        return { real = real, ghost = g, box = box, adornment = adorn }
    end

    local function is_replicate(p)
        return p and not p.Anchored
    end

    local function StartServerPosition()
        if ServerPosition.Internal.Connection then return end
        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildWhichIsA("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp then return end

        for _, g in pairs(ServerPosition.Internal.Ghosts) do
            if g.ghost then pcall(function() g.ghost:Destroy() end) end
        end
        ServerPosition.Internal.Ghosts = {}

        for _, n in ipairs(part_names) do
            local p = char:FindFirstChild(n)
            if p and p:IsA("BasePart") then
                ServerPosition.Internal.Ghosts[n] = make_ghost(p)
            end
        end

        local server_cf = hrp.CFrame
        local lin_vel   = Vector3.new(0, 0, 0)
        local last      = os.clock()
        local acc       = 0
        local frames    = {}

        ServerPosition.Internal.Connection = RunService.Heartbeat:Connect(function(dt)
            if H.ShuttingDown then return end

            if not hrp or not hrp.Parent then
                for _, g in pairs(ServerPosition.Internal.Ghosts) do
                    if g.ghost then pcall(function() g.ghost:Destroy() end) end
                end
                ServerPosition.Internal.Ghosts = {}
                if ServerPosition.Internal.Connection then
                    ServerPosition.Internal.Connection:Disconnect()
                    ServerPosition.Internal.Connection = nil
                end
                return
            end

            local now   = os.clock()
            local delta = now - last
            last = now
            local ping = LocalPlayer.GetNetworkPing and LocalPlayer:GetNetworkPing() or 0.08

            if is_replicate(hrp) then
                lin_vel = hrp.AssemblyLinearVelocity
                if acc >= ping then
                    server_cf = hrp.CFrame
                    acc = 0
                else
                    acc = acc + delta
                end
            end

            local hrp_cf = server_cf
            local rel = {}
            for n, g in pairs(ServerPosition.Internal.Ghosts) do
                if g.real and g.real.Parent then
                    rel[n] = hrp_cf:ToObjectSpace(g.real.CFrame)
                end
            end

            table.insert(frames, {
                t   = now,
                cf  = hrp_cf,
                pos = hrp_cf.Position,
                vel = lin_vel,
                rel = rel,
            })
            if #frames > 240 then
                for i = 1, 60 do table.remove(frames, 1) end
            end

            local target_t = now - ping
            local f
            for i = #frames, 1, -1 do
                if frames[i].t <= target_t then f = frames[i]; break end
            end
            if not f then f = frames[1] end
            if not f then return end

            local td = math.min(target_t - f.t, 0.06)
            local pred_pos = f.pos + f.vel * td * ServerPosition.Settings.Strength
            local pred_cf  = CFrame.new(pred_pos) * (f.cf - f.cf.Position)

            for n, g in pairs(ServerPosition.Internal.Ghosts) do
                local ghost = g.ghost
                local box   = g.box
                local adorn = g.adornment
                if ghost and ghost.Parent then
                    local r = f.rel[n]
                    local tgt = r and pred_cf * r or (g.real and g.real.CFrame or ghost.CFrame)
                    local d = (tgt.Position - pred_cf.Position).Magnitude
                    if d > ServerPosition.Settings.MaxLimb then
                        local dir = (tgt.Position - pred_cf.Position).Unit
                        local p = pred_cf.Position + dir * ServerPosition.Settings.MaxLimb
                        local rx, ry, rz = tgt:ToEulerAnglesXYZ()
                        tgt = CFrame.new(p) * CFrame.Angles(rx, ry, rz)
                    end
                    ghost.CFrame = ghost.CFrame:Lerp(tgt, math.min(delta * 18, 1))

                    local c
                    if ServerPosition.Settings.RGB then
                        c = rgb(now)
                    else
                        c = Color3.new(1, 1, 1)
                    end
                    if box   then box.Color3   = c end
                    if adorn then adorn.Color3 = c end
                end
            end
        end)
    end

    local function StopServerPosition()
        if ServerPosition.Internal.Connection then
            ServerPosition.Internal.Connection:Disconnect()
            ServerPosition.Internal.Connection = nil
        end
        for _, g in pairs(ServerPosition.Internal.Ghosts) do
            if g.ghost then pcall(function() g.ghost:Destroy() end) end
        end
        ServerPosition.Internal.Ghosts = {}
    end

    Track(LocalPlayer.CharacterAdded:Connect(function()
        if ServerPosition.Settings.Enabled then
            task.wait(0.2)
            if H.ShuttingDown then return end
            StopServerPosition()
            StartServerPosition()
        end
    end))

    ServerPosition.Start = StartServerPosition
    ServerPosition.Stop  = StopServerPosition

    print("[AirHub] 04_wallhack: ServerPosition loaded OK v2")
end

-- ============================================================================
-- PART 4 — UI (Visuals tab)
-- ============================================================================
local Window = getgenv().airhubUI_Window
if not Window then
    warn("[AirHub] 04_wallhack: airhubUI Window missing — Visuals tab not created")
    return
end

-- Inject translations
do
    local UI = getgenv().airhubUI
    if UI and UI.L and UI.L.en and UI.L.ru then
        local en = {
            -- section names
            vis_wallhack = "WallHack", vis_boxes = "Boxes", vis_hud = "HUD",
            vis_glow = "Glow", vis_selfesp = "Self ESP", vis_sp = "Server Position (Ghost)",
            vis_tracers = "Tracers", vis_names = "Name Tags",
            -- wallhack
            vis_enabled = "Enabled", vis_team_check = "Team Check", vis_alive_check = "Alive Check",
            -- boxes
            vis_box_enabled = "Enabled", vis_box_type = "Type",
            vis_box_color = "Color", vis_box_target = "Target Color",
            vis_box_transparency = "Transparency", vis_box_thickness = "Thickness",
            vis_box_filled = "Filled (2D)", vis_box_scale = "Scale (3D)",
            -- hud
            vis_hud_enabled = "Enable HUD", vis_hud_pos = "Position",
            vis_hud_players = "Show Players count", vis_hud_fps = "Show FPS",
            vis_hud_ping = "Show Ping", vis_hud_session = "Show Session time",
            -- glow
            vis_glow_enabled = "Enabled", vis_glow_color = "Color",
            vis_glow_transparency = "Transparency", vis_glow_mode = "Mode",
            -- self esp
            vis_se_enabled = "Enable Self ESP",
            vis_se_chams_enabled = "  Chams: Enabled",
            vis_se_chams_mode = "  Chams: Mode",
            vis_se_chams_fill_color = "  Chams: Fill Color",
            vis_se_chams_fill_transparency = "  Chams: Fill Transparency",
            vis_se_chams_outline_color = "  Chams: Outline Color",
            vis_se_chams_outline_transparency = "  Chams: Outline Transparency",
            vis_se_chams_always_top = "  Chams: Always on top",
            vis_se_chams_texture_id = "  Chams: Texture ID",
            vis_se_chams_texture_transparency = "  Chams: Texture Transparency",
            vis_se_chams_texture_faces = "  Chams: Texture Faces",
            vis_se_hat_enabled = "  China Hat: Enabled",
            vis_se_hat_color = "  China Hat: Color",
            vis_se_hat_size = "  China Hat: Size",
            vis_se_hat_offset = "  China Hat: Offset Y",
            vis_se_hat_rotation = "  China Hat: Rotation",
            vis_se_hat_autoro = "  China Hat: Auto Rotate",
            vis_se_hat_rotospeed = "  China Hat: Rotate Speed",
            vis_se_hat_rainbow = "  China Hat: Rainbow",
            vis_se_hat_rainbow_speed = "  China Hat: Rainbow Speed",
            vis_se_hat_transparency = "  China Hat: Transparency",
            vis_se_hat_material = "  China Hat: Material",
            vis_se_hat_usemesh = "  China Hat: Use Mesh",
            -- server position
            vis_sp_enabled = "Enabled", vis_sp_rgb = "RGB Color",
            vis_sp_strength = "Strength", vis_sp_maxlimb = "Max Limb Distance",
            -- tracers
            vis_tracer_enabled = "Enabled", vis_tracer_color = "Color",
            vis_tracer_transparency = "Transparency", vis_tracer_thickness = "Thickness",
            vis_tracer_origin = "Origin",
            -- names
            vis_name_enabled = "Enabled", vis_name_color = "Color",
            vis_name_size = "Size", vis_name_distance = "Show Distance",
            vis_name_health = "Show Health",

            -- tooltips
            tt_vis_enabled = "Master switch for boxes, glow, tracers, name tags",
            tt_vis_team = "Uses Aimbot's Team Check settings",
            tt_vis_alive = "Skip dead players",
            tt_vis_box_enabled = "Draw boxes around players",
            tt_vis_box_type = "3D = line-based corners | 2D = square frame",
            tt_vis_box_color = "Default box color",
            tt_vis_box_target = "Box color for current aimbot target",
            tt_vis_box_transparency = "Box line transparency (0=opaque, 1=invisible)",
            tt_vis_box_thickness = "Box line thickness in pixels",
            tt_vis_box_filled = "For 2D boxes: fill inside",
            tt_vis_box_scale = "For 3D boxes: box size multiplier",
            tt_vis_hud_enabled = "Show on-screen HUD overlay",
            tt_vis_hud_pos = "Corner where HUD appears",
            tt_vis_hud_players = "Show current player count",
            tt_vis_hud_fps = "Show current FPS",
            tt_vis_hud_ping = "Show network ping in ms",
            tt_vis_hud_session = "Show session uptime",
            tt_vis_glow_enabled = "Highlight outline around players",
            tt_vis_glow_color = "Glow color",
            tt_vis_glow_transparency = "Glow transparency",
            tt_vis_glow_mode = "Outline = edges only | Fill = solid | Both = both | Pulse = animated",
            tt_vis_se_enabled = "Master switch for self chams and china hat",
            tt_vis_se_chams_enabled = "Apply visual effect to your character",
            tt_vis_se_chams_mode = "Fill = solid color | Outline = edges | Both | Texture = custom image | Wireframe = edges only",
            tt_vis_se_chams_fill_color = "Interior fill color",
            tt_vis_se_chams_fill_transparency = "Fill transparency (0=opaque)",
            tt_vis_se_chams_outline_color = "Edge color",
            tt_vis_se_chams_outline_transparency = "Edge transparency",
            tt_vis_se_chams_always_top = "Render through walls",
            tt_vis_se_chams_texture_id = "Roblox asset ID (rbxassetid://...) for texture chams",
            tt_vis_se_chams_texture_transparency = "Texture image transparency",
            tt_vis_se_chams_texture_faces = "Front = 1 decal per part | AllFaces = 6 decals (heavier)",
            tt_vis_se_hat_enabled = "Show china hat above your head",
            tt_vis_se_hat_color = "Hat base color",
            tt_vis_se_hat_size = "Hat scale",
            tt_vis_se_hat_offset = "Vertical offset from head",
            tt_vis_se_hat_rotation = "Fixed rotation (degrees, when Auto Rotate is OFF)",
            tt_vis_se_hat_autoro = "Continuously rotate the hat",
            tt_vis_se_hat_rotospeed = "Rotation speed (degrees per second)",
            tt_vis_se_hat_rainbow = "Cycle through rainbow colors",
            tt_vis_se_hat_rainbow_speed = "Rainbow cycle speed",
            tt_vis_se_hat_transparency = "Hat transparency (0=opaque)",
            tt_vis_se_hat_material = "Roblox material for the hat",
            tt_vis_se_hat_usemesh = "ON = cone mesh | OFF = ball (materials display better)",
            tt_vis_sp_enabled = "Show ghost of your server-side position (lag-compensation view)",
            tt_vis_sp_rgb = "Rainbow color for ghosts",
            tt_vis_sp_strength = "Prediction strength (0=raw, 5=aggressive)",
            tt_vis_sp_maxlimb = "Maximum distance limb can deviate (studs)",
            tt_vis_tracer_enabled = "Draw lines from screen edge to players",
            tt_vis_tracer_color = "Tracer color",
            tt_vis_tracer_transparency = "Tracer transparency",
            tt_vis_tracer_thickness = "Tracer line thickness",
            tt_vis_tracer_origin = "Where tracers start on screen",
            tt_vis_name_enabled = "Show player name tags above heads",
            tt_vis_name_color = "Text color",
            tt_vis_name_size = "Text size in pixels",
            tt_vis_name_distance = "Append distance in studs",
            tt_vis_name_health = "Append current health",
        }
        local ru = {
            vis_wallhack = "Wallhack", vis_boxes = "Боксы", vis_hud = "HUD",
            vis_glow = "Свечение", vis_selfesp = "Сам ESP", vis_sp = "Серверная позиция (призрак)",
            vis_tracers = "Трассеры", vis_names = "Имена",
            vis_enabled = "Включен", vis_team_check = "Проверка команды", vis_alive_check = "Проверка живых",
            vis_box_enabled = "Включены", vis_box_type = "Тип",
            vis_box_color = "Цвет", vis_box_target = "Цвет цели",
            vis_box_transparency = "Прозрачность", vis_box_thickness = "Толщина",
            vis_box_filled = "Заливка (2D)", vis_box_scale = "Масштаб (3D)",
            vis_hud_enabled = "Включить HUD", vis_hud_pos = "Позиция",
            vis_hud_players = "Показывать игроков", vis_hud_fps = "Показывать FPS",
            vis_hud_ping = "Показывать Ping", vis_hud_session = "Показывать время сессии",
            vis_glow_enabled = "Включено", vis_glow_color = "Цвет",
            vis_glow_transparency = "Прозрачность", vis_glow_mode = "Режим",
            vis_se_enabled = "Включить сам ESP",
            vis_se_chams_enabled = "  Чамсы: Включены",
            vis_se_chams_mode = "  Чамсы: Режим",
            vis_se_chams_fill_color = "  Чамсы: Цвет заливки",
            vis_se_chams_fill_transparency = "  Чамсы: Прозрачность заливки",
            vis_se_chams_outline_color = "  Чамсы: Цвет обводки",
            vis_se_chams_outline_transparency = "  Чамсы: Прозрачность обводки",
            vis_se_chams_always_top = "  Чамсы: Сквозь стены",
            vis_se_chams_texture_id = "  Чамсы: ID текстуры",
            vis_se_chams_texture_transparency = "  Чамсы: Прозрачность текстуры",
            vis_se_chams_texture_faces = "  Чамсы: Грани текстуры",
            vis_se_hat_enabled = "  Китайская шляпа: Включена",
            vis_se_hat_color = "  Китайская шляпа: Цвет",
            vis_se_hat_size = "  Китайская шляпа: Размер",
            vis_se_hat_offset = "  Китайская шляпа: Смещение Y",
            vis_se_hat_rotation = "  Китайская шляпа: Поворот",
            vis_se_hat_autoro = "  Китайская шляпа: Авто-вращение",
            vis_se_hat_rotospeed = "  Китайская шляпа: Скорость вращения",
            vis_se_hat_rainbow = "  Китайская шляпа: Радуга",
            vis_se_hat_rainbow_speed = "  Китайская шляпа: Скорость радуги",
            vis_se_hat_transparency = "  Китайская шляпа: Прозрачность",
            vis_se_hat_material = "  Китайская шляпа: Материал",
            vis_se_hat_usemesh = "  Китайская шляпа: Использовать меш",
            vis_sp_enabled = "Включено", vis_sp_rgb = "RGB цвет",
            vis_sp_strength = "Сила", vis_sp_maxlimb = "Макс. дистанция конечности",
            vis_tracer_enabled = "Включены", vis_tracer_color = "Цвет",
            vis_tracer_transparency = "Прозрачность", vis_tracer_thickness = "Толщина",
            vis_tracer_origin = "Откуда",
            vis_name_enabled = "Включены", vis_name_color = "Цвет",
            vis_name_size = "Размер", vis_name_distance = "Показывать дистанцию",
            vis_name_health = "Показывать здоровье",

            tt_vis_enabled = "Главный выключатель боксов, свечения, трассеров, имён",
            tt_vis_team = "Использует настройки команды из Aimbot",
            tt_vis_alive = "Пропускать мёртвых игроков",
            tt_vis_box_enabled = "Рисовать боксы вокруг игроков",
            tt_vis_box_type = "3D = линии по углам | 2D = квадратная рамка",
            tt_vis_box_color = "Цвет бокса по умолчанию",
            tt_vis_box_target = "Цвет бокса для захваченной цели",
            tt_vis_box_transparency = "Прозрачность линий (0=непрозрачно, 1=невидимо)",
            tt_vis_box_thickness = "Толщина линий в пикселях",
            tt_vis_box_filled = "Для 2D: заливка внутри",
            tt_vis_box_scale = "Для 3D: множитель размера бокса",
            tt_vis_hud_enabled = "Показывать HUD на экране",
            tt_vis_hud_pos = "Угол, где появляется HUD",
            tt_vis_hud_players = "Показывать количество игроков",
            tt_vis_hud_fps = "Показывать FPS",
            tt_vis_hud_ping = "Показывать пинг в мс",
            tt_vis_hud_session = "Показывать время работы",
            tt_vis_glow_enabled = "Подсветка контура игроков",
            tt_vis_glow_color = "Цвет свечения",
            tt_vis_glow_transparency = "Прозрачность свечения",
            tt_vis_glow_mode = "Outline = только края | Fill = сплошной | Both = оба | Pulse = пульсация",
            tt_vis_se_enabled = "Главный выключатель чамсов и шляпы",
            tt_vis_se_chams_enabled = "Применить эффект к вашему персонажу",
            tt_vis_se_chams_mode = "Fill = сплошной | Outline = края | Both | Texture = картинка | Wireframe = только контур",
            tt_vis_se_chams_fill_color = "Цвет внутренней заливки",
            tt_vis_se_chams_fill_transparency = "Прозрачность заливки (0=непрозрачно)",
            tt_vis_se_chams_outline_color = "Цвет краёв",
            tt_vis_se_chams_outline_transparency = "Прозрачность краёв",
            tt_vis_se_chams_always_top = "Отрисовывать сквозь стены",
            tt_vis_se_chams_texture_id = "ID ассета Roblox (rbxassetid://...) для текстурных чамсов",
            tt_vis_se_chams_texture_transparency = "Прозрачность картинки",
            tt_vis_se_chams_texture_faces = "Front = 1 decal на часть | AllFaces = 6 decals (тяжелее)",
            tt_vis_se_hat_enabled = "Показывать китайскую шляпу над головой",
            tt_vis_se_hat_color = "Базовый цвет шляпы",
            tt_vis_se_hat_size = "Масштаб шляпы",
            tt_vis_se_hat_offset = "Вертикальное смещение от головы",
            tt_vis_se_hat_rotation = "Фиксированный поворот (градусы, при выкл. авто-вращении)",
            tt_vis_se_hat_autoro = "Постоянно вращать шляпу",
            tt_vis_se_hat_rotospeed = "Скорость вращения (градусов в секунду)",
            tt_vis_se_hat_rainbow = "Циклическая смена цветов радуги",
            tt_vis_se_hat_rainbow_speed = "Скорость цикла радуги",
            tt_vis_se_hat_transparency = "Прозрачность шляпы (0=непрозрачно)",
            tt_vis_se_hat_material = "Материал Roblox для шляпы",
            tt_vis_se_hat_usemesh = "ВКЛ = конус-меш | ВЫКЛ = шар (материалы видны лучше)",
            tt_vis_sp_enabled = "Показывать призрак серверной позиции (lag-compensation)",
            tt_vis_sp_rgb = "Радужный цвет для призраков",
            tt_vis_sp_strength = "Сила предсказания (0=сырое, 5=агрессивно)",
            tt_vis_sp_maxlimb = "Макс. отклонение конечности (studs)",
            tt_vis_tracer_enabled = "Линии от края экрана к игрокам",
            tt_vis_tracer_color = "Цвет трассера",
            tt_vis_tracer_transparency = "Прозрачность трассера",
            tt_vis_tracer_thickness = "Толщина линии",
            tt_vis_tracer_origin = "Откуда начинаются трассеры",
            tt_vis_name_enabled = "Показывать имена над головами",
            tt_vis_name_color = "Цвет текста",
            tt_vis_name_size = "Размер текста в пикселях",
            tt_vis_name_distance = "Добавить дистанцию в studs",
            tt_vis_name_health = "Добавить текущее здоровье",
        }
        for k, v in pairs(en) do UI.L.en[k] = v end
        for k, v in pairs(ru) do UI.L.ru[k] = v end
    end
end

H._UI = H._UI or {}
local VisualsTab = Window:AddTab({ Name = "Visuals", Icon = ">" })
H._UI.VisualsTab = VisualsTab

local Util             = H.Util
local SafeColor        = WallHack.SafeColor or function(c, fb) return fb or c end
local LocalPlayer      = Util.LocalPlayer

local function refreshGlow()
    if WallHack.ApplyGlowToAll then pcall(WallHack.ApplyGlowToAll) end
end
local function refreshSelfESP()
    if WallHack.Functions.RefreshSelfESP then pcall(WallHack.Functions.RefreshSelfESP) end
end
local function startHUD() if WallHack.Functions.StartHUD then pcall(WallHack.Functions.StartHUD) end end
local function stopHUD()  if WallHack.Functions.StopHUD  then pcall(WallHack.Functions.StopHUD)  end end
local function startSelfESP() if WallHack.Functions.StartSelfESP then pcall(WallHack.Functions.StartSelfESP) end end
local function stopSelfESP()  if WallHack.Functions.StopSelfESP  then pcall(WallHack.Functions.StopSelfESP)  end end

local function setBox(k, v)  WallHack.Visuals.BoxSettings[k] = v end
local function setHUD(k, v)  WallHack.Visuals.HUDSettings[k] = v end
local function setChams(k, v) WallHack.Visuals.SelfESP.Chams[k] = v end
local function setHat(k, v)   WallHack.Visuals.SelfESP.ChinaHat[k] = v end
local function setTracer(k, v) WallHack.Visuals.TracerSettings[k] = v end
local function setName(k, v)   WallHack.Visuals.NameSettings[k] = v end

local SP = H.ServerPosition
local function spStart() if SP and SP.Start then pcall(SP.Start) end end
local function spStop()  if SP and SP.Stop  then pcall(SP.Stop)  end end

local glowModes    = { "Outline", "Fill", "Both", "Pulse" }
local chamsModes   = { "Fill", "Outline", "Both", "Texture", "Wireframe" }
local textureFaces = { "Front", "AllFaces" }
local hudPositions = { "TopLeft", "TopRight", "BottomLeft", "BottomRight" }
local tracerOrigins = { "Bottom", "Mouse", "Top" }
local hatMaterials = WallHack.Functions.ListValidMaterials()
if not hatMaterials or #hatMaterials == 0 then
    hatMaterials = { "Neon", "ForceField", "Glass", "Plastic", "SmoothPlastic", "Metal" }
end

-- ===================== LEFT COLUMN =====================
local visWH = VisualsTab:CreateSection({ Name = "vis_wallhack" })
visWH:AddToggle({ Name = "vis_enabled", Value = WallHack.Settings.Enabled,
    Callback = function(v) WallHack.Settings.Enabled = v; refreshGlow() end,
    Tooltip = "tt_vis_enabled" })
visWH:AddToggle({ Name = "vis_team_check", Value = WallHack.Settings.TeamCheck,
    Callback = function(v) WallHack.Settings.TeamCheck = v end,
    Tooltip = "tt_vis_team" })
visWH:AddToggle({ Name = "vis_alive_check", Value = WallHack.Settings.AliveCheck,
    Callback = function(v) WallHack.Settings.AliveCheck = v end,
    Tooltip = "tt_vis_alive" })

local visBox = VisualsTab:CreateSection({ Name = "vis_boxes" })
visBox:AddToggle({ Name = "vis_box_enabled", Value = WallHack.Visuals.BoxSettings.Enabled,
    Callback = function(v) setBox("Enabled", v) end, Tooltip = "tt_vis_box_enabled" })
visBox:AddDropdown({ Name = "vis_box_type",
    Value = (WallHack.Visuals.BoxSettings.Type == 1 and "3D" or "2D"),
    List = { "3D", "2D" },
    Callback = function(v) WallHack.Visuals.BoxSettings.Type = (v == "3D") and 1 or 2 end,
    Tooltip = "tt_vis_box_type" })
-- FIX: Default not Value for colorpickers
visBox:AddColorpicker({ Name = "vis_box_color", Default = WallHack.Visuals.BoxSettings.Color,
    Callback = function(v) WallHack.Visuals.BoxSettings.Color = SafeColor(v, Color3.fromRGB(255,255,255)) end,
    Tooltip = "tt_vis_box_color" })
visBox:AddColorpicker({ Name = "vis_box_target", Default = WallHack.Visuals.BoxSettings.TargetColor,
    Callback = function(v) WallHack.Visuals.BoxSettings.TargetColor = SafeColor(v, Color3.fromRGB(255,0,0)) end,
    Tooltip = "tt_vis_box_target" })
visBox:AddSlider({ Name = "vis_box_transparency", Value = WallHack.Visuals.BoxSettings.Transparency,
    Min = 0, Max = 1, Decimals = 2,
    Callback = function(v) setBox("Transparency", v) end, Tooltip = "tt_vis_box_transparency" })
visBox:AddSlider({ Name = "vis_box_thickness", Value = WallHack.Visuals.BoxSettings.Thickness,
    Min = 1, Max = 5,
    Callback = function(v) setBox("Thickness", v) end, Tooltip = "tt_vis_box_thickness" })
visBox:AddToggle({ Name = "vis_box_filled", Value = WallHack.Visuals.BoxSettings.Filled,
    Callback = function(v) setBox("Filled", v) end, Tooltip = "tt_vis_box_filled" })
visBox:AddSlider({ Name = "vis_box_scale", Value = WallHack.Visuals.BoxSettings.Increase,
    Min = 1, Max = 5,
    Callback = function(v) setBox("Increase", v) end, Tooltip = "tt_vis_box_scale" })

local visTracer = VisualsTab:CreateSection({ Name = "vis_tracers" })
visTracer:AddToggle({ Name = "vis_tracer_enabled", Value = WallHack.Visuals.TracerSettings.Enabled,
    Callback = function(v) setTracer("Enabled", v) end, Tooltip = "tt_vis_tracer_enabled" })
visTracer:AddColorpicker({ Name = "vis_tracer_color", Default = WallHack.Visuals.TracerSettings.Color,
    Callback = function(v) WallHack.Visuals.TracerSettings.Color = SafeColor(v, Color3.fromRGB(255,100,100)) end,
    Tooltip = "tt_vis_tracer_color" })
visTracer:AddSlider({ Name = "vis_tracer_transparency", Value = WallHack.Visuals.TracerSettings.Transparency,
    Min = 0, Max = 1, Decimals = 2,
    Callback = function(v) setTracer("Transparency", v) end, Tooltip = "tt_vis_tracer_transparency" })
visTracer:AddSlider({ Name = "vis_tracer_thickness", Value = WallHack.Visuals.TracerSettings.Thickness,
    Min = 1, Max = 5,
    Callback = function(v) setTracer("Thickness", v) end, Tooltip = "tt_vis_tracer_thickness" })
visTracer:AddDropdown({ Name = "vis_tracer_origin", Value = WallHack.Visuals.TracerSettings.Origin or "Bottom",
    List = tracerOrigins,
    Callback = function(v) setTracer("Origin", v) end, Tooltip = "tt_vis_tracer_origin" })

local hudSec = VisualsTab:CreateSection({ Name = "vis_hud" })
hudSec:AddToggle({ Name = "vis_hud_enabled", Value = WallHack.Visuals.HUDSettings.Enabled,
    Callback = function(v)
        WallHack.Visuals.HUDSettings.Enabled = v
        if v then startHUD() else stopHUD() end
    end, Tooltip = "tt_vis_hud_enabled" })
hudSec:AddDropdown({ Name = "vis_hud_pos",
    Value = WallHack.Visuals.HUDSettings.Position or "TopLeft",
    List = hudPositions,
    Callback = function(v) setHUD("Position", v) end, Tooltip = "tt_vis_hud_pos" })
hudSec:AddToggle({ Name = "vis_hud_players",
    Value = WallHack.Visuals.HUDSettings.ShowPlayers ~= false,
    Callback = function(v) setHUD("ShowPlayers", v) end, Tooltip = "tt_vis_hud_players" })
hudSec:AddToggle({ Name = "vis_hud_fps",
    Value = WallHack.Visuals.HUDSettings.ShowFPS ~= false,
    Callback = function(v) setHUD("ShowFPS", v) end, Tooltip = "tt_vis_hud_fps" })
hudSec:AddToggle({ Name = "vis_hud_ping",
    Value = WallHack.Visuals.HUDSettings.ShowPing ~= false,
    Callback = function(v) setHUD("ShowPing", v) end, Tooltip = "tt_vis_hud_ping" })
hudSec:AddToggle({ Name = "vis_hud_session",
    Value = WallHack.Visuals.HUDSettings.ShowSession ~= false,
    Callback = function(v) setHUD("ShowSession", v) end, Tooltip = "tt_vis_hud_session" })

-- ===================== RIGHT COLUMN =====================
local visNames = VisualsTab:CreateSection({ Name = "vis_names", Side = "Right" })
visNames:AddToggle({ Name = "vis_name_enabled", Value = WallHack.Visuals.NameSettings.Enabled,
    Callback = function(v) setName("Enabled", v) end, Tooltip = "tt_vis_name_enabled" })
visNames:AddColorpicker({ Name = "vis_name_color", Default = WallHack.Visuals.NameSettings.Color,
    Callback = function(v) WallHack.Visuals.NameSettings.Color = SafeColor(v, Color3.fromRGB(255,255,255)) end,
    Tooltip = "tt_vis_name_color" })
visNames:AddSlider({ Name = "vis_name_size", Value = WallHack.Visuals.NameSettings.Size,
    Min = 8, Max = 24,
    Callback = function(v) setName("Size", math.floor(v)) end, Tooltip = "tt_vis_name_size" })
visNames:AddToggle({ Name = "vis_name_distance", Value = WallHack.Visuals.NameSettings.ShowDistance ~= false,
    Callback = function(v) setName("ShowDistance", v) end, Tooltip = "tt_vis_name_distance" })
visNames:AddToggle({ Name = "vis_name_health", Value = WallHack.Visuals.NameSettings.ShowHealth ~= false,
    Callback = function(v) setName("ShowHealth", v) end, Tooltip = "tt_vis_name_health" })

local glowSec = VisualsTab:CreateSection({ Name = "vis_glow", Side = "Right" })
glowSec:AddToggle({ Name = "vis_glow_enabled", Value = WallHack.Visuals.GlowSettings.Enabled,
    Callback = function(v) WallHack.Visuals.GlowSettings.Enabled = v; refreshGlow() end,
    Tooltip = "tt_vis_glow_enabled" })
glowSec:AddColorpicker({ Name = "vis_glow_color", Default = WallHack.Visuals.GlowSettings.Color,
    Callback = function(v) WallHack.Visuals.GlowSettings.Color = SafeColor(v, Color3.fromRGB(0,255,255)); refreshGlow() end,
    Tooltip = "tt_vis_glow_color" })
glowSec:AddSlider({ Name = "vis_glow_transparency", Value = WallHack.Visuals.GlowSettings.Transparency,
    Min = 0, Max = 1, Decimals = 2,
    Callback = function(v)
        local n = tonumber(v)
        if n then WallHack.Visuals.GlowSettings.Transparency = math.clamp(n, 0, 1) end
        refreshGlow()
    end, Tooltip = "tt_vis_glow_transparency" })
glowSec:AddDropdown({ Name = "vis_glow_mode",
    Value = WallHack.Visuals.GlowSettings.Mode or "Outline",
    List = glowModes,
    Callback = function(v)
        WallHack.Visuals.GlowSettings.Mode = (type(v) == "string" and v) or "Outline"
        refreshGlow()
    end, Tooltip = "tt_vis_glow_mode" })

local seSec = VisualsTab:CreateSection({ Name = "vis_selfesp", Side = "Right" })
seSec:AddToggle({ Name = "vis_se_enabled", Value = WallHack.Visuals.SelfESP.Enabled,
    Callback = function(v)
        WallHack.Visuals.SelfESP.Enabled = v
        if v then startSelfESP() else stopSelfESP() end
    end, Tooltip = "tt_vis_se_enabled" })
seSec:AddToggle({ Name = "vis_se_chams_enabled", Value = WallHack.Visuals.SelfESP.Chams.Enabled,
    Callback = function(v) setChams("Enabled", v); refreshSelfESP() end,
    Tooltip = "tt_vis_se_chams_enabled" })
seSec:AddDropdown({ Name = "vis_se_chams_mode",
    Value = WallHack.Visuals.SelfESP.Chams.Mode or "Both",
    List = chamsModes,
    Callback = function(v) setChams("Mode", v); refreshSelfESP() end,
    Tooltip = "tt_vis_se_chams_mode" })
seSec:AddColorpicker({ Name = "vis_se_chams_fill_color", Default = WallHack.Visuals.SelfESP.Chams.FillColor,
    Callback = function(v) WallHack.Visuals.SelfESP.Chams.FillColor = SafeColor(v, Color3.fromRGB(90,140,255)); refreshSelfESP() end,
    Tooltip = "tt_vis_se_chams_fill_color" })
seSec:AddSlider({ Name = "vis_se_chams_fill_transparency", Value = WallHack.Visuals.SelfESP.Chams.FillTransparency,
    Min = 0, Max = 1, Decimals = 2,
    Callback = function(v) setChams("FillTransparency", v); refreshSelfESP() end,
    Tooltip = "tt_vis_se_chams_fill_transparency" })
seSec:AddColorpicker({ Name = "vis_se_chams_outline_color", Default = WallHack.Visuals.SelfESP.Chams.OutlineColor,
    Callback = function(v) WallHack.Visuals.SelfESP.Chams.OutlineColor = SafeColor(v, Color3.fromRGB(255,255,255)); refreshSelfESP() end,
    Tooltip = "tt_vis_se_chams_outline_color" })
seSec:AddSlider({ Name = "vis_se_chams_outline_transparency", Value = WallHack.Visuals.SelfESP.Chams.OutlineTransparency,
    Min = 0, Max = 1, Decimals = 2,
    Callback = function(v) setChams("OutlineTransparency", v); refreshSelfESP() end,
    Tooltip = "tt_vis_se_chams_outline_transparency" })
seSec:AddToggle({ Name = "vis_se_chams_always_top", Value = WallHack.Visuals.SelfESP.Chams.AlwaysOnTop ~= false,
    Callback = function(v) setChams("AlwaysOnTop", v); refreshSelfESP() end,
    Tooltip = "tt_vis_se_chams_always_top" })
seSec:AddInput({ Name = "vis_se_chams_texture_id",
    Value = WallHack.Visuals.SelfESP.Chams.TextureId or "",
    Callback = function(v) setChams("TextureId", v or ""); refreshSelfESP() end,
    Tooltip = "tt_vis_se_chams_texture_id" })
seSec:AddSlider({ Name = "vis_se_chams_texture_transparency",
    Value = WallHack.Visuals.SelfESP.Chams.TextureTransparency,
    Min = 0, Max = 1, Decimals = 2,
    Callback = function(v) setChams("TextureTransparency", v); refreshSelfESP() end,
    Tooltip = "tt_vis_se_chams_texture_transparency" })
seSec:AddDropdown({ Name = "vis_se_chams_texture_faces",
    Value = WallHack.Visuals.SelfESP.Chams.TextureFaces or "Front",
    List = textureFaces,
    Callback = function(v) setChams("TextureFaces", v); refreshSelfESP() end,
    Tooltip = "tt_vis_se_chams_texture_faces" })

seSec:AddToggle({ Name = "vis_se_hat_enabled", Value = WallHack.Visuals.SelfESP.ChinaHat.Enabled,
    Callback = function(v) setHat("Enabled", v); refreshSelfESP() end,
    Tooltip = "tt_vis_se_hat_enabled" })
seSec:AddColorpicker({ Name = "vis_se_hat_color", Default = WallHack.Visuals.SelfESP.ChinaHat.Color,
    Callback = function(v) WallHack.Visuals.SelfESP.ChinaHat.Color = SafeColor(v, Color3.fromRGB(255,60,60)); refreshSelfESP() end,
    Tooltip = "tt_vis_se_hat_color" })
seSec:AddSlider({ Name = "vis_se_hat_size", Value = WallHack.Visuals.SelfESP.ChinaHat.Size,
    Min = 1, Max = 10, Decimals = 1,
    Callback = function(v) setHat("Size", v); refreshSelfESP() end,
    Tooltip = "tt_vis_se_hat_size" })
seSec:AddSlider({ Name = "vis_se_hat_offset", Value = WallHack.Visuals.SelfESP.ChinaHat.OffsetY,
    Min = 0, Max = 5, Decimals = 1,
    Callback = function(v) setHat("OffsetY", v); refreshSelfESP() end,
    Tooltip = "tt_vis_se_hat_offset" })
seSec:AddSlider({ Name = "vis_se_hat_rotation", Value = WallHack.Visuals.SelfESP.ChinaHat.Rotation,
    Min = 0, Max = 360,
    Callback = function(v) setHat("Rotation", v); refreshSelfESP() end,
    Tooltip = "tt_vis_se_hat_rotation" })
seSec:AddToggle({ Name = "vis_se_hat_autoro", Value = WallHack.Visuals.SelfESP.ChinaHat.AutoRotate,
    Callback = function(v) setHat("AutoRotate", v); refreshSelfESP() end,
    Tooltip = "tt_vis_se_hat_autoro" })
seSec:AddSlider({ Name = "vis_se_hat_rotospeed", Value = WallHack.Visuals.SelfESP.ChinaHat.RotateSpeed,
    Min = 10, Max = 720,
    Callback = function(v) setHat("RotateSpeed", v); refreshSelfESP() end,
    Tooltip = "tt_vis_se_hat_rotospeed" })
seSec:AddToggle({ Name = "vis_se_hat_rainbow", Value = WallHack.Visuals.SelfESP.ChinaHat.Rainbow,
    Callback = function(v) setHat("Rainbow", v); refreshSelfESP() end,
    Tooltip = "tt_vis_se_hat_rainbow" })
seSec:AddSlider({ Name = "vis_se_hat_rainbow_speed", Value = WallHack.Visuals.SelfESP.ChinaHat.RainbowSpeed,
    Min = 0.1, Max = 3, Decimals = 2,
    Callback = function(v) setHat("RainbowSpeed", v); refreshSelfESP() end,
    Tooltip = "tt_vis_se_hat_rainbow_speed" })
seSec:AddSlider({ Name = "vis_se_hat_transparency", Value = WallHack.Visuals.SelfESP.ChinaHat.Transparency,
    Min = 0, Max = 1, Decimals = 2,
    Callback = function(v) setHat("Transparency", v); refreshSelfESP() end,
    Tooltip = "tt_vis_se_hat_transparency" })
seSec:AddDropdown({ Name = "vis_se_hat_material",
    Value = WallHack.Visuals.SelfESP.ChinaHat.Material or "Neon",
    List = hatMaterials,
    Callback = function(v)
        WallHack.Visuals.SelfESP.ChinaHat.Material = v
        if WallHack.Functions.SetChinaHatMaterial then
            pcall(WallHack.Functions.SetChinaHatMaterial, v)
        end
        refreshSelfESP()
    end, Tooltip = "tt_vis_se_hat_material" })
seSec:AddToggle({ Name = "vis_se_hat_usemesh", Value = WallHack.Visuals.SelfESP.ChinaHat.UseMesh ~= false,
    Callback = function(v) setHat("UseMesh", v); refreshSelfESP() end,
    Tooltip = "tt_vis_se_hat_usemesh" })

local spSec = VisualsTab:CreateSection({ Name = "vis_sp", Side = "Right" })
local spInitEnabled = (SP and SP.Settings and SP.Settings.Enabled) == true

spSec:AddToggle({ Name = "vis_sp_enabled", Value = spInitEnabled,
    Callback = function(v)
        if not SP or not SP.Settings then return end
        SP.Settings.Enabled = v
        if v then spStop(); spStart() else spStop() end
    end, Tooltip = "tt_vis_sp_enabled" })

spSec:AddToggle({ Name = "vis_sp_rgb",
    Value = (SP and SP.Settings and SP.Settings.RGB) ~= false,
    Callback = function(v) if SP and SP.Settings then SP.Settings.RGB = v end end,
    Tooltip = "tt_vis_sp_rgb" })

spSec:AddSlider({ Name = "vis_sp_strength",
    Value = (SP and SP.Settings and SP.Settings.Strength) or 1,
    Min = 0, Max = 5, Decimals = 1,
    Callback = function(v) if SP and SP.Settings then SP.Settings.Strength = v end end,
    Tooltip = "tt_vis_sp_strength" })

spSec:AddSlider({ Name = "vis_sp_maxlimb",
    Value = (SP and SP.Settings and SP.Settings.MaxLimb) or 6,
    Min = 1, Max = 20,
    Callback = function(v) if SP and SP.Settings then SP.Settings.MaxLimb = v end end,
    Tooltip = "tt_vis_sp_maxlimb" })

print("[AirHub] 04_wallhack: UI 'Visuals' tab created v2 (Texture chams, Tracers, Names, RU, tooltips)")
