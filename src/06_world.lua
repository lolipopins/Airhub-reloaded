--// ============================================================================
--// AirHub — 06_world.lua (airhubUI build) v2
--// World tab: Time of Day / Lighting / Fog / Atmosphere / Post-FX (RTX) /
--// Sky / Cleanup (textures, particles, lights, sounds, sky).
--// All modified properties are snapshotted and can be restored via Presets →
--// "Restore All World Settings" or by toggling the individual feature off.
--//
--// v2 CHANGES:
--//   • NEW: Time of Day quick presets (Dawn / Noon / Golden Hour / Dusk / Midnight)
--//   • NEW: Camera FOV override (auto-reapplies on respawn)
--//   • NEW: Disable Sounds (mute all Sound instances except AirHub's own)
--//   • NEW: Disable Dynamic Lights (PointLight / SpotLight / SurfaceLight)
--//   • Presets (RTX Ultra / Cinematic) now set ClockTime + Brightness cleanly
--//   • Restore also reverts Camera FOV, Sounds, Dynamic Lights
--//   • Full RU/EN localization + tooltips on every control
--// ============================================================================
local H = getgenv().AirHub
if not H or not H._CoreLoaded then warn("[AirHub] 06_world: core not loaded"); return end
if H.World then warn("[AirHub] World already loaded"); return end

local Util     = H.Util
local Track    = Util.Track
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

--// ---------------------------------------------------------------------------
--// Low-level helpers
--// ---------------------------------------------------------------------------
local function safeSet(obj, prop, value)
    pcall(function() obj[prop] = value end)
end

local function getOrCreate(class, name)
    local fx = Lighting:FindFirstChild(name)
    if fx and fx.ClassName == class then return fx, false end
    fx = Lighting:FindFirstChildOfClass(class)
    if fx then return fx, false end
    fx = Instance.new(class)
    fx.Name = name
    fx.Enabled = false
    pcall(function() fx.Parent = Lighting end)
    return fx, true
end

--// ---------------------------------------------------------------------------
--// Original state snapshots
--// ---------------------------------------------------------------------------
local OrigLighting = {
    Brightness              = Lighting.Brightness,
    ClockTime               = Lighting.ClockTime,
    Ambient                 = Lighting.Ambient,
    OutdoorAmbient          = Lighting.OutdoorAmbient,
    EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
    EnvironmentSpecularScale= Lighting.EnvironmentSpecularScale,
    ExposureCompensation    = Lighting.ExposureCompensation,
    GlobalShadows           = Lighting.GlobalShadows,
    ShadowSoftness          = Lighting.ShadowSoftness,
    FogColor                = Lighting.FogColor,
    FogStart                = Lighting.FogStart,
    FogEnd                  = Lighting.FogEnd,
}

local OrigAtmosphere = nil
do
    local atm = Lighting:FindFirstChildOfClass("Atmosphere")
    if atm then
        OrigAtmosphere = {
            instance = atm,
            Density  = atm.Density,
            Offset   = atm.Offset,
            Color    = atm.Color,
            Decay    = atm.Decay,
            Glare    = atm.Glare,
            Haze     = atm.Haze,
        }
    end
end

local OrigSky = Lighting:FindFirstChildOfClass("Sky")
local OrigSkyProps = nil
if OrigSky then
    OrigSkyProps = {
        StarCount        = OrigSky.StarCount,
        SunAngularSize   = OrigSky.SunAngularSize,
        MoonAngularSize  = OrigSky.MoonAngularSize,
    }
end

--// Snapshot any post-FX of given class that already exists in Lighting.
local FX_PROPS = {
    "Enabled", "Intensity", "Size", "Threshold",
    "Brightness", "Contrast", "Saturation", "TintColor",
    "FarIntensity", "FocusDistance", "InFocusRadius", "NearIntensity",
    "Spread",
}
local function snapshotFx(class)
    local fx = Lighting:FindFirstChildOfClass(class)
    if not fx then return nil end
    local snap = { instance = fx, properties = {} }
    for _, p in ipairs(FX_PROPS) do
        local ok, val = pcall(function() return fx[p] end)
        if ok then snap.properties[p] = val end
    end
    return snap
end

local OrigFX = {
    Bloom  = snapshotFx("BloomEffect"),
    CC     = snapshotFx("ColorCorrectionEffect"),
    DOF    = snapshotFx("DepthOfFieldEffect"),
    Sun    = snapshotFx("SunRaysEffect"),
    Blur   = snapshotFx("BlurEffect"),
}

--// ---------------------------------------------------------------------------
--// Module state
--// ---------------------------------------------------------------------------
H.World = {
    Settings = {
        -- Core / cleanup
        Fullbright      = false,
        NoShadows       = false,
        RemoveFog       = false,
        RemoveTextures  = false,
        RemoveParticles = false,
        RemoveGrass     = false,
        RemoveSky       = false,
        DisableSounds        = false,
        DisableDynamicLights = false,

        -- Custom Lighting
        CustomLighting          = false,
        Brightness              = 2,
        ClockTime               = 14,
        ExposureCompensation    = 0,
        AmbientColor            = Color3.fromRGB(70, 70, 70),
        OutdoorAmbientColor     = Color3.fromRGB(128, 128, 128),
        EnvironmentDiffuseScale = 0.5,
        EnvironmentSpecularScale= 0.5,
        ShadowSoftness          = 0.2,
        Technology              = "Future",

        -- Camera FOV
        CameraFOVEnabled = false,
        CameraFOVValue   = 70,

        -- Custom Fog
        CustomFog  = false,
        FogStart   = 0,
        FogEnd     = 100000,
        FogColor   = Color3.fromRGB(192, 192, 192),

        -- Atmosphere
        AtmosphereEnabled = false,
        AtmosphereDensity = 0.30,
        AtmosphereOffset  = 0,
        AtmosphereGlare   = 0,
        AtmosphereHaze    = 1.5,
        AtmosphereColor   = Color3.fromRGB(199, 199, 199),
        AtmosphereDecay   = Color3.fromRGB(106, 112, 125),

        -- Bloom
        BloomEnabled   = false,
        BloomIntensity = 0.8,
        BloomSize      = 24,
        BloomThreshold = 2,

        -- Color Correction
        CCEnabled    = false,
        CCBrightness = 0,
        CCContrast   = 0.10,
        CCSaturation = 0.10,
        CCTintColor  = Color3.fromRGB(255, 255, 255),

        -- Depth of Field
        DOFEnabled       = false,
        DOFFarIntensity  = 0.1,
        DOFFocusDistance = 20,
        DOFInFocusRadius = 30,
        DOFNearIntensity = 0.5,

        -- Sun Rays
        SunRaysEnabled   = false,
        SunRaysIntensity = 0.1,
        SunRaysSpread    = 1,

        -- Blur
        BlurEnabled = false,
        BlurSize    = 0,

        -- Sky
        CustomSky         = false,
        SkyStarCount      = 3000,
        SkySunAngularSize = 21,
        SkyMoonAngularSize= 11,
    },
    Internal = {
        Original = {
            Lighting   = OrigLighting,
            Atmosphere = OrigAtmosphere,
            Sky        = OrigSky,
            SkyProps   = OrigSkyProps,
            FX         = OrigFX,
            CameraFOV  = nil,  -- lazily captured on first Apply
        },
        Created = {},
        Saved   = {},
        Conns   = {},
    },
    Functions = {},
}
local World = H.World

--// ---------------------------------------------------------------------------
--// Lighting
--// ---------------------------------------------------------------------------
local function ApplyFullbright()
    safeSet(Lighting, "Brightness", 3)
    safeSet(Lighting, "ClockTime", 14)
    safeSet(Lighting, "Ambient", Color3.fromRGB(180, 180, 180))
    safeSet(Lighting, "OutdoorAmbient", Color3.fromRGB(180, 180, 180))
    safeSet(Lighting, "ExposureCompensation", 0.5)
end
local function RemoveFullbright()
    local O = World.Internal.Original.Lighting
    safeSet(Lighting, "Brightness", O.Brightness)
    safeSet(Lighting, "ClockTime", O.ClockTime)
    safeSet(Lighting, "Ambient", O.Ambient)
    safeSet(Lighting, "OutdoorAmbient", O.OutdoorAmbient)
    safeSet(Lighting, "ExposureCompensation", O.ExposureCompensation)
end

local function ApplyCustomLighting()
    local S = World.Settings
    safeSet(Lighting, "Brightness", S.Brightness)
    safeSet(Lighting, "ClockTime", S.ClockTime)
    safeSet(Lighting, "ExposureCompensation", S.ExposureCompensation)
    safeSet(Lighting, "Ambient", S.AmbientColor)
    safeSet(Lighting, "OutdoorAmbient", S.OutdoorAmbientColor)
    safeSet(Lighting, "EnvironmentDiffuseScale", S.EnvironmentDiffuseScale)
    safeSet(Lighting, "EnvironmentSpecularScale", S.EnvironmentSpecularScale)
    safeSet(Lighting, "ShadowSoftness", S.ShadowSoftness)
    local tech = Enum.Technology and Enum.Technology[S.Technology]
    if tech then pcall(function() Lighting.Technology = tech end) end
end
local function RemoveCustomLighting()
    local O = World.Internal.Original.Lighting
    safeSet(Lighting, "Brightness", O.Brightness)
    safeSet(Lighting, "ClockTime", O.ClockTime)
    safeSet(Lighting, "ExposureCompensation", O.ExposureCompensation)
    safeSet(Lighting, "Ambient", O.Ambient)
    safeSet(Lighting, "OutdoorAmbient", O.OutdoorAmbient)
    safeSet(Lighting, "EnvironmentDiffuseScale", O.EnvironmentDiffuseScale)
    safeSet(Lighting, "EnvironmentSpecularScale", O.EnvironmentSpecularScale)
    safeSet(Lighting, "ShadowSoftness", O.ShadowSoftness)
end

local function ApplyNoShadows() safeSet(Lighting, "GlobalShadows", false) end
local function RemoveNoShadows()
    safeSet(Lighting, "GlobalShadows", World.Internal.Original.Lighting.GlobalShadows)
end

--// ---------------------------------------------------------------------------
--// Camera FOV
--// ---------------------------------------------------------------------------
local function ApplyCameraFOV()
    local cam = workspace.CurrentCamera
    if not cam then return end
    if World.Internal.Original.CameraFOV == nil then
        World.Internal.Original.CameraFOV = cam.FieldOfView or 70
    end
    safeSet(cam, "FieldOfView", World.Settings.CameraFOVValue)
end
local function RemoveCameraFOV()
    local cam = workspace.CurrentCamera
    if not cam then return end
    local orig = World.Internal.Original.CameraFOV
    if orig then safeSet(cam, "FieldOfView", orig) end
end

--// ---------------------------------------------------------------------------
--// Fog
--// ---------------------------------------------------------------------------
local function ApplyNoFog()
    safeSet(Lighting, "FogEnd", 1e6)
    safeSet(Lighting, "FogStart", 1e6)
end
local function RemoveNoFog()
    local O = World.Internal.Original.Lighting
    safeSet(Lighting, "FogEnd", O.FogEnd)
    safeSet(Lighting, "FogStart", O.FogStart)
end

local function ApplyCustomFog()
    local S = World.Settings
    safeSet(Lighting, "FogStart", S.FogStart)
    safeSet(Lighting, "FogEnd", S.FogEnd)
    safeSet(Lighting, "FogColor", S.FogColor)
end
local function RemoveCustomFog()
    local O = World.Internal.Original.Lighting
    safeSet(Lighting, "FogStart", O.FogStart)
    safeSet(Lighting, "FogEnd", O.FogEnd)
    safeSet(Lighting, "FogColor", O.FogColor)
end

--// ---------------------------------------------------------------------------
--// Atmosphere
--// ---------------------------------------------------------------------------
local function GetAtmosphere()
    local atm = Lighting:FindFirstChildOfClass("Atmosphere")
    if atm then return atm, false end
    atm = Instance.new("Atmosphere")
    pcall(function() atm.Parent = Lighting end)
    World.Internal.Created[atm] = true
    return atm, true
end

local function ApplyAtmosphere()
    local S = World.Settings
    local atm = GetAtmosphere()
    safeSet(atm, "Density", S.AtmosphereDensity)
    safeSet(atm, "Offset",  S.AtmosphereOffset)
    safeSet(atm, "Glare",   S.AtmosphereGlare)
    safeSet(atm, "Haze",    S.AtmosphereHaze)
    safeSet(atm, "Color",   S.AtmosphereColor)
    safeSet(atm, "Decay",   S.AtmosphereDecay)
end
local function RemoveAtmosphere()
    local atm = Lighting:FindFirstChildOfClass("Atmosphere")
    if not atm then return end
    if World.Internal.Created[atm] then
        pcall(function() atm:Destroy() end)
        World.Internal.Created[atm] = nil
        return
    end
    local O = World.Internal.Original.Atmosphere
    if O and O.instance == atm then
        safeSet(atm, "Density", O.Density)
        safeSet(atm, "Offset",  O.Offset)
        safeSet(atm, "Color",   O.Color)
        safeSet(atm, "Decay",   O.Decay)
        safeSet(atm, "Glare",   O.Glare)
        safeSet(atm, "Haze",    O.Haze)
    end
end

--// ---------------------------------------------------------------------------
--// Post-FX (RTX)
--// ---------------------------------------------------------------------------
local function ApplyBloom()
    local S = World.Settings
    local fx, created = getOrCreate("BloomEffect", "AirHub_Bloom")
    if created then World.Internal.Created[fx] = true end
    safeSet(fx, "Enabled",   S.BloomEnabled)
    safeSet(fx, "Intensity", S.BloomIntensity)
    safeSet(fx, "Size",      S.BloomSize)
    safeSet(fx, "Threshold", S.BloomThreshold)
end
local function RestoreBloom()
    local fx = Lighting:FindFirstChildOfClass("BloomEffect")
    if not fx then return end
    if World.Internal.Created[fx] then
        pcall(function() fx:Destroy() end)
        World.Internal.Created[fx] = nil
        return
    end
    local snap = World.Internal.Original.FX.Bloom
    if snap and snap.instance == fx then
        for k, v in pairs(snap.properties) do safeSet(fx, k, v) end
    else
        safeSet(fx, "Enabled", false)
    end
end

local function ApplyCC()
    local S = World.Settings
    local fx, created = getOrCreate("ColorCorrectionEffect", "AirHub_ColorCorrection")
    if created then World.Internal.Created[fx] = true end
    safeSet(fx, "Enabled",    S.CCEnabled)
    safeSet(fx, "Brightness", S.CCBrightness)
    safeSet(fx, "Contrast",   S.CCContrast)
    safeSet(fx, "Saturation", S.CCSaturation)
    safeSet(fx, "TintColor",  S.CCTintColor)
end
local function RestoreCC()
    local fx = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
    if not fx then return end
    if World.Internal.Created[fx] then
        pcall(function() fx:Destroy() end)
        World.Internal.Created[fx] = nil
        return
    end
    local snap = World.Internal.Original.FX.CC
    if snap and snap.instance == fx then
        for k, v in pairs(snap.properties) do safeSet(fx, k, v) end
    else
        safeSet(fx, "Enabled", false)
    end
end

local function ApplyDOF()
    local S = World.Settings
    local fx, created = getOrCreate("DepthOfFieldEffect", "AirHub_DepthOfField")
    if created then World.Internal.Created[fx] = true end
    safeSet(fx, "Enabled",       S.DOFEnabled)
    safeSet(fx, "FarIntensity",  S.DOFFarIntensity)
    safeSet(fx, "FocusDistance", S.DOFFocusDistance)
    safeSet(fx, "InFocusRadius", S.DOFInFocusRadius)
    safeSet(fx, "NearIntensity", S.DOFNearIntensity)
end
local function RestoreDOF()
    local fx = Lighting:FindFirstChildOfClass("DepthOfFieldEffect")
    if not fx then return end
    if World.Internal.Created[fx] then
        pcall(function() fx:Destroy() end)
        World.Internal.Created[fx] = nil
        return
    end
    local snap = World.Internal.Original.FX.DOF
    if snap and snap.instance == fx then
        for k, v in pairs(snap.properties) do safeSet(fx, k, v) end
    else
        safeSet(fx, "Enabled", false)
    end
end

local function ApplySunRays()
    local S = World.Settings
    local fx, created = getOrCreate("SunRaysEffect", "AirHub_SunRays")
    if created then World.Internal.Created[fx] = true end
    safeSet(fx, "Enabled",   S.SunRaysEnabled)
    safeSet(fx, "Intensity", S.SunRaysIntensity)
    safeSet(fx, "Spread",    S.SunRaysSpread)
end
local function RestoreSunRays()
    local fx = Lighting:FindFirstChildOfClass("SunRaysEffect")
    if not fx then return end
    if World.Internal.Created[fx] then
        pcall(function() fx:Destroy() end)
        World.Internal.Created[fx] = nil
        return
    end
    local snap = World.Internal.Original.FX.Sun
    if snap and snap.instance == fx then
        for k, v in pairs(snap.properties) do safeSet(fx, k, v) end
    else
        safeSet(fx, "Enabled", false)
    end
end

local function ApplyBlur()
    local S = World.Settings
    local fx, created = getOrCreate("BlurEffect", "AirHub_Blur")
    if created then World.Internal.Created[fx] = true end
    safeSet(fx, "Enabled", S.BlurEnabled)
    safeSet(fx, "Size",    S.BlurSize)
end
local function RestoreBlur()
    local fx = Lighting:FindFirstChildOfClass("BlurEffect")
    if not fx then return end
    if World.Internal.Created[fx] then
        pcall(function() fx:Destroy() end)
        World.Internal.Created[fx] = nil
        return
    end
    local snap = World.Internal.Original.FX.Blur
    if snap and snap.instance == fx then
        for k, v in pairs(snap.properties) do safeSet(fx, k, v) end
    else
        safeSet(fx, "Enabled", false)
    end
end

--// ---------------------------------------------------------------------------
--// Sky
--// ---------------------------------------------------------------------------
local function ApplySky()
    local S = World.Settings
    local sky = Lighting:FindFirstChildOfClass("Sky")
    if not sky then
        sky = Instance.new("Sky")
        pcall(function() sky.Parent = Lighting end)
        World.Internal.Created[sky] = true
    end
    safeSet(sky, "StarCount",       S.SkyStarCount)
    safeSet(sky, "SunAngularSize",  S.SkySunAngularSize)
    safeSet(sky, "MoonAngularSize", S.SkyMoonAngularSize)
end
local function RemoveSkyCustom()
    local sky = Lighting:FindFirstChildOfClass("Sky")
    if not sky then return end
    if World.Internal.Created[sky] then
        pcall(function() sky:Destroy() end)
        World.Internal.Created[sky] = nil
        return
    end
    local O = World.Internal.Original.SkyProps
    if O then
        safeSet(sky, "StarCount",       O.StarCount)
        safeSet(sky, "SunAngularSize",  O.SunAngularSize)
        safeSet(sky, "MoonAngularSize", O.MoonAngularSize)
    end
end

--// ---------------------------------------------------------------------------
--// Cleanup — Textures / Particles / Grass / Sky / Sounds / Lights
--// ---------------------------------------------------------------------------
local function stripTextures(obj)
    if obj:IsA("BasePart") then
        for _, d in ipairs(obj:GetChildren()) do
            if d:IsA("Decal") or d:IsA("Texture") then
                if not World.Internal.Saved[d] then
                    World.Internal.Saved[d] = { kind = "decal", value = d.Transparency }
                end
                safeSet(d, "Transparency", 1)
            end
        end
    elseif obj:IsA("Decal") or obj:IsA("Texture") then
        if not World.Internal.Saved[obj] then
            World.Internal.Saved[obj] = { kind = "decal", value = obj.Transparency }
        end
        safeSet(obj, "Transparency", 1)
    end
end
local function ApplyRemoveTextures()
    for _, obj in ipairs(workspace:GetDescendants()) do
        stripTextures(obj)
    end
    if not World.Internal.Conns.tex then
        World.Internal.Conns.tex = workspace.DescendantAdded:Connect(function(obj)
            if World.Settings.RemoveTextures then stripTextures(obj) end
        end)
    end
end
local function RemoveRemoveTextures()
    local toRemove = {}
    for obj, data in pairs(World.Internal.Saved) do
        if data.kind == "decal" then
            safeSet(obj, "Transparency", data.value)
            table.insert(toRemove, obj)
        end
    end
    for _, obj in ipairs(toRemove) do
        World.Internal.Saved[obj] = nil
    end
    if World.Internal.Conns.tex then
        World.Internal.Conns.tex:Disconnect()
        World.Internal.Conns.tex = nil
    end
end

local PARTICLE_CLASSES = { "ParticleEmitter", "Trail", "Beam", "Fire", "Smoke", "Sparkles" }
local function isParticle(obj)
    for _, c in ipairs(PARTICLE_CLASSES) do
        if obj:IsA(c) then return true end
    end
    return false
end
local function ApplyRemoveParticles()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if isParticle(obj) then
            if not World.Internal.Saved[obj] then
                World.Internal.Saved[obj] = { kind = "particle", value = obj.Enabled }
            end
            safeSet(obj, "Enabled", false)
        end
    end
end
local function RemoveRemoveParticles()
    local toRemove = {}
    for obj, data in pairs(World.Internal.Saved) do
        if data.kind == "particle" then
            safeSet(obj, "Enabled", data.value)
            table.insert(toRemove, obj)
        end
    end
    for _, obj in ipairs(toRemove) do
        World.Internal.Saved[obj] = nil
    end
end

local function ApplyRemoveGrass()
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain then safeSet(terrain, "Decoration", false) end
end
local function RemoveRemoveGrass()
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain then safeSet(terrain, "Decoration", true) end
end

local function ApplyRemoveSky()
    local sky = Lighting:FindFirstChildOfClass("Sky")
    if sky then
        World.Internal.Original.Sky = sky
        safeSet(sky, "Parent", nil)
    end
end
local function RemoveRemoveSky()
    local O = World.Internal.Original.Sky
    if O and not O.Parent then
        safeSet(O, "Parent", Lighting)
    end
end

--// Sounds
local function isAirHubSound(snd)
    local cam = workspace.CurrentCamera
    return cam and snd.Parent == cam
end
local function stripSoundsIn(root)
    for _, obj in ipairs(root:GetDescendants()) do
        if obj:IsA("Sound") and not isAirHubSound(obj) then
            if not World.Internal.Saved[obj] then
                World.Internal.Saved[obj] = { kind = "sound", value = obj.Volume }
            end
            safeSet(obj, "Volume", 0)
        end
    end
end
local function ApplyDisableSounds()
    stripSoundsIn(workspace)
    stripSoundsIn(Lighting)
    stripSoundsIn(SoundService)
    if not World.Internal.Conns.sound then
        World.Internal.Conns.sound = workspace.DescendantAdded:Connect(function(obj)
            if not World.Settings.DisableSounds then return end
            if obj:IsA("Sound") and not isAirHubSound(obj) then
                if not World.Internal.Saved[obj] then
                    World.Internal.Saved[obj] = { kind = "sound", value = obj.Volume }
                end
                safeSet(obj, "Volume", 0)
            end
        end)
    end
end
local function RemoveDisableSounds()
    local toRemove = {}
    for obj, data in pairs(World.Internal.Saved) do
        if data.kind == "sound" then
            safeSet(obj, "Volume", data.value)
            table.insert(toRemove, obj)
        end
    end
    for _, obj in ipairs(toRemove) do
        World.Internal.Saved[obj] = nil
    end
    if World.Internal.Conns.sound then
        World.Internal.Conns.sound:Disconnect()
        World.Internal.Conns.sound = nil
    end
end

--// Dynamic lights
local LIGHT_CLASSES = { "PointLight", "SpotLight", "SurfaceLight" }
local function isDynamicLight(obj)
    for _, c in ipairs(LIGHT_CLASSES) do
        if obj:IsA(c) then return true end
    end
    return false
end
local function ApplyDisableDynamicLights()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if isDynamicLight(obj) then
            if not World.Internal.Saved[obj] then
                World.Internal.Saved[obj] = { kind = "light", value = obj.Enabled }
            end
            safeSet(obj, "Enabled", false)
        end
    end
    if not World.Internal.Conns.light then
        World.Internal.Conns.light = workspace.DescendantAdded:Connect(function(obj)
            if not World.Settings.DisableDynamicLights then return end
            if isDynamicLight(obj) then
                if not World.Internal.Saved[obj] then
                    World.Internal.Saved[obj] = { kind = "light", value = obj.Enabled }
                end
                safeSet(obj, "Enabled", false)
            end
        end)
    end
end
local function RemoveDisableDynamicLights()
    local toRemove = {}
    for obj, data in pairs(World.Internal.Saved) do
        if data.kind == "light" then
            safeSet(obj, "Enabled", data.value)
            table.insert(toRemove, obj)
        end
    end
    for _, obj in ipairs(toRemove) do
        World.Internal.Saved[obj] = nil
    end
    if World.Internal.Conns.light then
        World.Internal.Conns.light:Disconnect()
        World.Internal.Conns.light = nil
    end
end

--// ---------------------------------------------------------------------------
--// Master apply
--// ---------------------------------------------------------------------------
local function ApplyLook()
    RemoveFullbright()
    RemoveCustomLighting()
    RemoveNoFog()
    RemoveCustomFog()
    RemoveNoShadows()
    RemoveAtmosphere()
    RemoveSkyCustom()

    local S = World.Settings
    if S.Fullbright       then ApplyFullbright()      end
    if S.CustomLighting   then ApplyCustomLighting()  end
    if S.RemoveFog        then ApplyNoFog()           end
    if S.CustomFog        then ApplyCustomFog()       end
    if S.NoShadows        then ApplyNoShadows()       end
    if S.AtmosphereEnabled then ApplyAtmosphere()     end
    if S.CustomSky        then ApplySky()             end
    if S.CameraFOVEnabled then ApplyCameraFOV()       else RemoveCameraFOV() end

    ApplyBloom()
    ApplyCC()
    ApplyDOF()
    ApplySunRays()
    ApplyBlur()
end
World.ApplyLook = ApplyLook

--// ---------------------------------------------------------------------------
--// Time of Day presets
--// ---------------------------------------------------------------------------
local function ApplyTimePreset(clock, brightness, ambC, outC, exp)
    local S = World.Settings
    S.Fullbright = false
    S.CustomLighting = true
    S.ClockTime = clock
    S.Brightness = brightness
    S.AmbientColor = ambC
    S.OutdoorAmbientColor = outC
    S.ExposureCompensation = exp
    ApplyLook()
end
World.Functions.TimeDawn = function()
    ApplyTimePreset(6, 1.5, Color3.fromRGB(80, 90, 120), Color3.fromRGB(120, 130, 160), -0.1)
end
World.Functions.TimeNoon = function()
    ApplyTimePreset(12, 3, Color3.fromRGB(140, 140, 140), Color3.fromRGB(180, 180, 180), 0)
end
World.Functions.TimeGolden = function()
    ApplyTimePreset(18, 2, Color3.fromRGB(100, 80, 60), Color3.fromRGB(180, 140, 100), 0.1)
end
World.Functions.TimeDusk = function()
    ApplyTimePreset(19.5, 1, Color3.fromRGB(60, 60, 90), Color3.fromRGB(90, 80, 120), -0.2)
end
World.Functions.TimeMidnight = function()
    ApplyTimePreset(0, 0.5, Color3.fromRGB(30, 30, 50), Color3.fromRGB(40, 40, 70), -0.3)
end

--// ---------------------------------------------------------------------------
--// Restore everything
--// ---------------------------------------------------------------------------
World.Functions.Restore = function()
    RemoveFullbright()
    RemoveCustomLighting()
    RemoveNoFog()
    RemoveCustomFog()
    RemoveNoShadows()
    RemoveAtmosphere()
    RemoveSkyCustom()
    RemoveCameraFOV()
    RemoveRemoveTextures()
    RemoveRemoveParticles()
    RemoveRemoveGrass()
    RemoveRemoveSky()
    RemoveDisableSounds()
    RemoveDisableDynamicLights()
    RestoreBloom()
    RestoreCC()
    RestoreDOF()
    RestoreSunRays()
    RestoreBlur()

    local S = World.Settings
    S.Fullbright = false
    S.NoShadows = false
    S.RemoveFog = false
    S.CustomLighting = false
    S.CustomFog = false
    S.AtmosphereEnabled = false
    S.CustomSky = false
    S.BloomEnabled = false
    S.CCEnabled = false
    S.DOFEnabled = false
    S.SunRaysEnabled = false
    S.BlurEnabled = false
    S.RemoveTextures = false
    S.RemoveParticles = false
    S.RemoveGrass = false
    S.RemoveSky = false
    S.DisableSounds = false
    S.DisableDynamicLights = false
    S.CameraFOVEnabled = false
end

--// ---------------------------------------------------------------------------
--// Presets
--// ---------------------------------------------------------------------------
local function Preset_RTXUltra()
    local S = World.Settings
    S.CustomLighting = true
    S.Brightness = 2
    S.ClockTime = 14
    S.ExposureCompensation = 0.15
    S.AmbientColor = Color3.fromRGB(70, 70, 70)
    S.OutdoorAmbientColor = Color3.fromRGB(128, 128, 128)
    S.EnvironmentDiffuseScale = 1
    S.EnvironmentSpecularScale = 1
    S.ShadowSoftness = 0.15
    S.Technology = "Future"

    S.CustomFog = false
    S.RemoveFog = false

    S.AtmosphereEnabled = true
    S.AtmosphereDensity = 0.25
    S.AtmosphereOffset = 0
    S.AtmosphereGlare = 0.2
    S.AtmosphereHaze = 1.2
    S.AtmosphereColor = Color3.fromRGB(199, 199, 199)
    S.AtmosphereDecay = Color3.fromRGB(106, 112, 125)

    S.BloomEnabled = true
    S.BloomIntensity = 1.2
    S.BloomSize = 24
    S.BloomThreshold = 1.5

    S.CCEnabled = true
    S.CCBrightness = 0
    S.CCContrast = 0.15
    S.CCSaturation = 0.15
    S.CCTintColor = Color3.fromRGB(255, 255, 255)

    S.SunRaysEnabled = true
    S.SunRaysIntensity = 0.15
    S.SunRaysSpread = 1

    S.DOFEnabled = false
    S.BlurEnabled = false

    ApplyLook()
end

local function Preset_Cinematic()
    local S = World.Settings
    S.CustomLighting = true
    S.Brightness = 1.8
    S.ClockTime = 17.5
    S.ExposureCompensation = -0.1
    S.AmbientColor = Color3.fromRGB(60, 60, 70)
    S.OutdoorAmbientColor = Color3.fromRGB(110, 110, 130)
    S.EnvironmentDiffuseScale = 0.8
    S.EnvironmentSpecularScale = 1
    S.ShadowSoftness = 0.3
    S.Technology = "Future"

    S.AtmosphereEnabled = true
    S.AtmosphereDensity = 0.35
    S.AtmosphereGlare = 0.4
    S.AtmosphereHaze = 2.0
    S.AtmosphereColor = Color3.fromRGB(220, 200, 190)

    S.BloomEnabled = true
    S.BloomIntensity = 0.8
    S.BloomSize = 32
    S.BloomThreshold = 2

    S.CCEnabled = true
    S.CCBrightness = -0.02
    S.CCContrast = 0.2
    S.CCSaturation = -0.05
    S.CCTintColor = Color3.fromRGB(230, 235, 255)

    S.DOFEnabled = true
    S.DOFFarIntensity = 0.5
    S.DOFFocusDistance = 25
    S.DOFInFocusRadius = 18
    S.DOFNearIntensity = 0.3

    S.SunRaysEnabled = true
    S.SunRaysIntensity = 0.2
    S.SunRaysSpread = 0.9

    ApplyLook()
end

local function Preset_Clean()
    local S = World.Settings
    S.CustomLighting = false
    S.CustomFog = false
    S.AtmosphereEnabled = false
    S.CustomSky = false
    S.BloomEnabled = false
    S.CCEnabled = false
    S.DOFEnabled = false
    S.SunRaysEnabled = false
    S.BlurEnabled = false

    S.Fullbright = true
    S.RemoveFog = true
    S.NoShadows = true

    ApplyLook()
end

--// ---------------------------------------------------------------------------
--// UI + Localization
--// ---------------------------------------------------------------------------
local Window = getgenv().airhubUI_Window
if not Window then
    warn("[AirHub] 06_world: airhubUI Window missing — World tab not created")
    return
end

do
    local UI = getgenv().airhubUI
    if UI and UI.L and UI.L.en and UI.L.ru then
        local en = {
            -- Sections
            w_tod        = "Time of Day",
            w_lighting   = "Lighting",
            w_fog_atmo   = "Fog & Atmosphere",
            w_pfx        = "Post-FX (RTX)",
            w_sky        = "Sky",
            w_cleanup    = "Cleanup",
            w_presets    = "Presets",

            -- Time of Day buttons
            w_tod_dawn       = "Dawn (6:00)",
            w_tod_noon       = "Noon (12:00)",
            w_tod_golden     = "Golden Hour (18:00)",
            w_tod_dusk       = "Dusk (19:30)",
            w_tod_midnight   = "Midnight (0:00)",

            -- Lighting
            w_fullbright         = "Fullbright",
            w_custom_lighting    = "Custom Lighting (RTX)",
            w_brightness         = "Brightness",
            w_clock_time         = "Clock Time (h)",
            w_exposure           = "Exposure Compensation",
            w_ambient_color      = "Ambient Color",
            w_outdoor_ambient    = "Outdoor Ambient Color",
            w_env_diffuse        = "Env Diffuse Scale (soft light)",
            w_env_specular       = "Env Specular Scale (reflections)",
            w_shadow_softness    = "Shadow Softness",
            w_shadow_tech        = "Shadow Technology",
            w_cam_fov_enabled    = "Camera FOV Override",
            w_cam_fov_value      = "Camera FOV (degrees)",

            -- Fog & Atmosphere
            w_remove_fog         = "Remove Fog",
            w_custom_fog         = "Custom Fog",
            w_fog_start          = "Fog Start",
            w_fog_end            = "Fog End",
            w_fog_color          = "Fog Color",
            w_atmo_enabled       = "Atmosphere",
            w_atmo_density       = "Atmosphere Density",
            w_atmo_offset        = "Atmosphere Offset",
            w_atmo_glare         = "Atmosphere Glare",
            w_atmo_haze          = "Atmosphere Haze",
            w_atmo_color         = "Atmosphere Color",
            w_atmo_decay         = "Atmosphere Decay",

            -- Post-FX
            w_bloom              = "Bloom",
            w_bloom_intensity    = "Bloom Intensity",
            w_bloom_size         = "Bloom Size",
            w_bloom_threshold    = "Bloom Threshold",
            w_cc                 = "Color Correction",
            w_cc_brightness      = "CC Brightness",
            w_cc_contrast        = "CC Contrast",
            w_cc_saturation      = "CC Saturation",
            w_cc_tint            = "CC Tint",
            w_dof                = "Depth of Field",
            w_dof_far            = "DOF Far Intensity",
            w_dof_focus          = "DOF Focus Distance",
            w_dof_infocus        = "DOF In-Focus Radius",
            w_dof_near           = "DOF Near Intensity",
            w_sunrays            = "Sun Rays",
            w_sunrays_intensity  = "Sun Rays Intensity",
            w_sunrays_spread     = "Sun Rays Spread",
            w_blur               = "Blur",
            w_blur_size          = "Blur Size",

            -- Sky
            w_custom_sky         = "Custom Sky Params",
            w_sky_stars          = "Star Count",
            w_sky_sun_size       = "Sun Angular Size",
            w_sky_moon_size      = "Moon Angular Size",

            -- Cleanup
            w_no_shadows         = "No Global Shadows",
            w_remove_textures    = "Remove Textures / Decals",
            w_remove_particles   = "Remove Particles",
            w_remove_grass       = "Remove Grass",
            w_remove_sky         = "Remove Sky (hide skybox)",
            w_disable_sounds     = "Disable Sounds",
            w_disable_lights     = "Disable Dynamic Lights",

            -- Presets
            w_preset_rtx         = "RTX Ultra",
            w_preset_cinematic   = "Cinematic",
            w_preset_clean       = "Clean (Performance)",
            w_preset_restore     = "Restore All World Settings",

            -- Tooltips
            tt_w_tod_dawn        = "Quick lighting preset: cold morning light (6:00)",
            tt_w_tod_noon        = "Quick lighting preset: bright midday (12:00)",
            tt_w_tod_golden      = "Quick lighting preset: warm sunset (18:00)",
            tt_w_tod_dusk        = "Quick lighting preset: dark purple dusk (19:30)",
            tt_w_tod_midnight    = "Quick lighting preset: night (0:00)",

            tt_w_fullbright      = "Max brightness + no ambient darkness",
            tt_w_custom_lighting = "Full manual control over every Lighting property",
            tt_w_brightness      = "Lighting.Brightness (0-10)",
            tt_w_clock_time      = "Time of day in hours (0-24)",
            tt_w_exposure        = "Overall image exposure (-3 to +3)",
            tt_w_ambient_color   = "Indoor ambient light color",
            tt_w_outdoor_ambient = "Outdoor ambient light color",
            tt_w_env_diffuse     = "How strongly the environment light diffuses (soft lighting)",
            tt_w_env_specular    = "How strongly surfaces reflect the environment",
            tt_w_shadow_softness = "Shadow edge softness (0 = hard, 1 = very soft)",
            tt_w_shadow_tech     = "Voxel / ShadowMap / Future / Legacy. 'Future' = best reflections",
            tt_w_cam_fov_enabled = "Override the camera FieldOfView (auto-reapplies on respawn)",
            tt_w_cam_fov_value   = "FieldOfView in degrees (40-120)",

            tt_w_remove_fog      = "Push fog out of render range",
            tt_w_custom_fog      = "Fully manual fog control",
            tt_w_fog_start       = "Distance where fog starts to appear",
            tt_w_fog_end         = "Distance where fog is fully opaque",
            tt_w_fog_color       = "Fog tint color",
            tt_w_atmo_enabled    = "Enable custom Atmosphere (sky haze)",
            tt_w_atmo_density    = "Atmosphere thickness (0 = none, 1 = thick)",
            tt_w_atmo_offset     = "Vertical position offset",
            tt_w_atmo_glare      = "Bright halo around the sun",
            tt_w_atmo_haze       = "Atmospheric haze strength",
            tt_w_atmo_color      = "Atmosphere base color",
            tt_w_atmo_decay      = "How fast atmosphere fades to black",

            tt_w_bloom           = "Glow around bright areas",
            tt_w_bloom_intensity = "Bloom strength",
            tt_w_bloom_size      = "Bloom halo radius (px)",
            tt_w_bloom_threshold = "Only pixels brighter than this glow",
            tt_w_cc              = "Color correction (brightness/contrast/saturation/tint)",
            tt_w_cc_brightness   = "Global brightness shift",
            tt_w_cc_contrast     = "Contrast (lower = flatter, higher = punchier)",
            tt_w_cc_saturation   = "Color saturation",
            tt_w_cc_tint         = "Color tint multiplier",
            tt_w_dof             = "Depth of field (blur far/near)",
            tt_w_dof_far         = "How blurry the far plane is",
            tt_w_dof_focus       = "Focus distance (studs)",
            tt_w_dof_infocus     = "In-focus zone radius (studs)",
            tt_w_dof_near        = "How blurry the near plane is",
            tt_w_sunrays         = "Rays spreading from the sun",
            tt_w_sunrays_intensity = "Sun ray strength",
            tt_w_sunrays_spread  = "Ray spread angle (0 = tight, 1 = wide)",
            tt_w_blur            = "Screen blur effect",
            tt_w_blur_size       = "Blur kernel size (0 = off)",

            tt_w_custom_sky      = "Customize star/sun/moon sizes on the existing sky",
            tt_w_sky_stars       = "Number of visible stars",
            tt_w_sky_sun_size    = "Sun angular diameter (degrees)",
            tt_w_sky_moon_size   = "Moon angular diameter (degrees)",

            tt_w_no_shadows      = "Disable global shadows (big FPS gain on many parts)",
            tt_w_remove_textures = "Make all Decals/Textures invisible",
            tt_w_remove_particles= "Disable all ParticleEmitters / Trails / Beams / Fire / Smoke",
            tt_w_remove_grass    = "Disable terrain grass decoration",
            tt_w_remove_sky      = "Detach the skybox (renders black space)",
            tt_w_disable_sounds  = "Mute all Sound instances (AirHub hitsounds unaffected)",
            tt_w_disable_lights  = "Disable PointLight / SpotLight / SurfaceLight (perf on heavy maps)",

            tt_w_preset_rtx      = "Modern high-quality look: atmosphere + bloom + color correction + sun rays",
            tt_w_preset_cinematic= "Warm sunset with DOF, bloom, softer shadows",
            tt_w_preset_clean    = "Fullbright + no fog + no shadows. Best FPS",
            tt_w_preset_restore  = "Revert every World tweak to the game's original state",
        }
        local ru = {
            -- Sections
            w_tod        = "Время суток",
            w_lighting   = "Освещение",
            w_fog_atmo   = "Туман и атмосфера",
            w_pfx        = "Пост-эффекты (RTX)",
            w_sky        = "Небо",
            w_cleanup    = "Очистка",
            w_presets    = "Пресеты",

            w_tod_dawn       = "Рассвет (6:00)",
            w_tod_noon       = "Полдень (12:00)",
            w_tod_golden     = "Золотой час (18:00)",
            w_tod_dusk       = "Закат (19:30)",
            w_tod_midnight   = "Полночь (0:00)",

            w_fullbright         = "Полная яркость",
            w_custom_lighting    = "Своё освещение (RTX)",
            w_brightness         = "Яркость",
            w_clock_time         = "Время (ч)",
            w_exposure           = "Экспозиция",
            w_ambient_color      = "Цвет внутреннего света",
            w_outdoor_ambient    = "Цвет наружного света",
            w_env_diffuse        = "Диффузия окружения (мягкий свет)",
            w_env_specular       = "Отражения окружения",
            w_shadow_softness    = "Мягкость теней",
            w_shadow_tech        = "Технология теней",
            w_cam_fov_enabled    = "Свой FOV камеры",
            w_cam_fov_value      = "FOV камеры (градусы)",

            w_remove_fog         = "Убрать туман",
            w_custom_fog         = "Свой туман",
            w_fog_start          = "Начало тумана",
            w_fog_end            = "Конец тумана",
            w_fog_color          = "Цвет тумана",
            w_atmo_enabled       = "Атмосфера",
            w_atmo_density       = "Плотность атмосферы",
            w_atmo_offset        = "Смещение атмосферы",
            w_atmo_glare         = "Ореол атмосферы",
            w_atmo_haze          = "Дымка атмосферы",
            w_atmo_color         = "Цвет атмосферы",
            w_atmo_decay         = "Затухание атмосферы",

            w_bloom              = "Bloom (свечение)",
            w_bloom_intensity    = "Сила Bloom",
            w_bloom_size         = "Размер Bloom",
            w_bloom_threshold    = "Порог Bloom",
            w_cc                 = "Цветокоррекция",
            w_cc_brightness      = "Яркость CC",
            w_cc_contrast        = "Контраст CC",
            w_cc_saturation      = "Насыщенность CC",
            w_cc_tint            = "Оттенок CC",
            w_dof                = "Глубина резкости",
            w_dof_far            = "DOF дальний план",
            w_dof_focus          = "DOF дистанция фокуса",
            w_dof_infocus        = "DOF радиус в фокусе",
            w_dof_near           = "DOF ближний план",
            w_sunrays            = "Солнечные лучи",
            w_sunrays_intensity  = "Сила лучей",
            w_sunrays_spread     = "Разброс лучей",
            w_blur               = "Размытие",
            w_blur_size          = "Размер размытия",

            w_custom_sky         = "Свои параметры неба",
            w_sky_stars          = "Количество звёзд",
            w_sky_sun_size       = "Угловой размер солнца",
            w_sky_moon_size      = "Угловой размер луны",

            w_no_shadows         = "Убрать глобальные тени",
            w_remove_textures    = "Убрать текстуры / декали",
            w_remove_particles   = "Убрать частицы",
            w_remove_grass       = "Убрать траву",
            w_remove_sky         = "Убрать небо (скрыть skybox)",
            w_disable_sounds     = "Отключить звуки",
            w_disable_lights     = "Отключить динамические лампы",

            w_preset_rtx         = "RTX Ultra",
            w_preset_cinematic   = "Кинематографично",
            w_preset_clean       = "Чистый (перфоманс)",
            w_preset_restore     = "Восстановить всё в мире",

            tt_w_tod_dawn        = "Быстрый пресет: холодный утренний свет (6:00)",
            tt_w_tod_noon        = "Быстрый пресет: яркий полдень (12:00)",
            tt_w_tod_golden      = "Быстрый пресет: тёплый закат (18:00)",
            tt_w_tod_dusk        = "Быстрый пресет: тёмно-фиолетовый закат (19:30)",
            tt_w_tod_midnight    = "Быстрый пресет: ночь (0:00)",

            tt_w_fullbright      = "Максимальная яркость + нет затемнения",
            tt_w_custom_lighting = "Полный ручной контроль над Lighting",
            tt_w_brightness      = "Lighting.Brightness (0-10)",
            tt_w_clock_time      = "Время суток в часах (0-24)",
            tt_w_exposure        = "Общая экспозиция (-3 до +3)",
            tt_w_ambient_color   = "Цвет внутреннего окружающего света",
            tt_w_outdoor_ambient = "Цвет наружного окружающего света",
            tt_w_env_diffuse     = "Насколько сильно рассеивается свет окружения",
            tt_w_env_specular    = "Насколько сильно отражают поверхности",
            tt_w_shadow_softness = "Мягкость краёв тени (0 = резкие, 1 = очень мягкие)",
            tt_w_shadow_tech     = "Voxel / ShadowMap / Future / Legacy. 'Future' = лучшие отражения",
            tt_w_cam_fov_enabled = "Переопределить FieldOfView камеры (авто-переприменение при респавне)",
            tt_w_cam_fov_value   = "FieldOfView в градусах (40-120)",

            tt_w_remove_fog      = "Убрать туман из рендера",
            tt_w_custom_fog      = "Полностью ручной контроль тумана",
            tt_w_fog_start       = "Дистанция начала тумана",
            tt_w_fog_end         = "Дистанция полной непрозрачности",
            tt_w_fog_color       = "Цвет тумана",
            tt_w_atmo_enabled    = "Включить свою атмосферу (дымка)",
            tt_w_atmo_density    = "Плотность атмосферы (0 = нет, 1 = густая)",
            tt_w_atmo_offset     = "Вертикальное смещение",
            tt_w_atmo_glare      = "Свечение вокруг солнца",
            tt_w_atmo_haze       = "Сила дымки",
            tt_w_atmo_color      = "Базовый цвет атмосферы",
            tt_w_atmo_decay      = "Скорость затухания в темноту",

            tt_w_bloom           = "Свечение вокруг ярких мест",
            tt_w_bloom_intensity = "Сила Bloom",
            tt_w_bloom_size      = "Радиус Bloom (px)",
            tt_w_bloom_threshold = "Только пиксели ярче этого светятся",
            tt_w_cc              = "Цветокоррекция (яркость/контраст/насыщенность/оттенок)",
            tt_w_cc_brightness   = "Глобальный сдвиг яркости",
            tt_w_cc_contrast     = "Контраст (ниже = плоское, выше = резче)",
            tt_w_cc_saturation   = "Насыщенность цвета",
            tt_w_cc_tint         = "Цветовой множитель",
            tt_w_dof             = "Глубина резкости (размытие ближнего/дальнего плана)",
            tt_w_dof_far         = "Насколько размыт дальний план",
            tt_w_dof_focus       = "Дистанция фокуса (studs)",
            tt_w_dof_infocus     = "Радиус зоны в фокусе (studs)",
            tt_w_dof_near        = "Насколько размыт ближний план",
            tt_w_sunrays         = "Лучи, расходящиеся от солнца",
            tt_w_sunrays_intensity = "Сила солнечных лучей",
            tt_w_sunrays_spread  = "Угол разброса лучей (0 = узко, 1 = широко)",
            tt_w_blur            = "Размытие экрана",
            tt_w_blur_size       = "Размер ядра размытия (0 = выкл)",

            tt_w_custom_sky      = "Настроить размеры звёзд/солнца/луны на существующем небе",
            tt_w_sky_stars       = "Количество видимых звёзд",
            tt_w_sky_sun_size    = "Угловой диаметр солнца (градусы)",
            tt_w_sky_moon_size   = "Угловой диаметр луны (градусы)",

            tt_w_no_shadows      = "Отключить глобальные тени (большой FPS-буст на многих деталях)",
            tt_w_remove_textures = "Сделать все Decals/Textures невидимыми",
            tt_w_remove_particles= "Отключить все ParticleEmitters / Trails / Beams / Fire / Smoke",
            tt_w_remove_grass    = "Отключить траву на террейне",
            tt_w_remove_sky      = "Открепить skybox (будет чёрный космос)",
            tt_w_disable_sounds  = "Отключить все звуки (хитсаунды AirHub не затрагиваются)",
            tt_w_disable_lights  = "Отключить PointLight / SpotLight / SurfaceLight (перф на тяжёлых картах)",

            tt_w_preset_rtx      = "Современный качественный вид: атмосфера + bloom + цветокоррекция + солнечные лучи",
            tt_w_preset_cinematic= "Тёплый закат с DOF, bloom и мягкими тенями",
            tt_w_preset_clean    = "Fullbright + без тумана + без теней. Лучший FPS",
            tt_w_preset_restore  = "Вернуть все настройки мира к оригинальному состоянию",
        }
        for k, v in pairs(en) do UI.L.en[k] = v end
        for k, v in pairs(ru) do UI.L.ru[k] = v end
        if UI.RefreshTheme then pcall(UI.RefreshTheme) end
    end
end

H._UI = H._UI or {}
local WorldTab = Window:AddTab({ Name = "World", Icon = ">" })
H._UI.WorldTab = WorldTab

local refs = {}
local function setRef(key, ctrl) refs[key] = ctrl end
local function syncRef(key, value)
    local c = refs[key]
    if not c then return end
    if type(c.Set) == "function" then pcall(function() c:Set(value) end) end
end

local function SyncPresetUI()
    local S = World.Settings
    syncRef("Fullbright", S.Fullbright)
    syncRef("CustomLighting", S.CustomLighting)
    syncRef("Brightness", S.Brightness)
    syncRef("ClockTime", S.ClockTime)
    syncRef("ExposureCompensation", S.ExposureCompensation)
    syncRef("EnvironmentDiffuseScale", S.EnvironmentDiffuseScale)
    syncRef("EnvironmentSpecularScale", S.EnvironmentSpecularScale)
    syncRef("ShadowSoftness", S.ShadowSoftness)
    syncRef("AtmosphereEnabled", S.AtmosphereEnabled)
    syncRef("AtmosphereDensity", S.AtmosphereDensity)
    syncRef("AtmosphereGlare", S.AtmosphereGlare)
    syncRef("AtmosphereHaze", S.AtmosphereHaze)
    syncRef("BloomEnabled", S.BloomEnabled)
    syncRef("BloomIntensity", S.BloomIntensity)
    syncRef("BloomSize", S.BloomSize)
    syncRef("BloomThreshold", S.BloomThreshold)
    syncRef("CCEnabled", S.CCEnabled)
    syncRef("CCBrightness", S.CCBrightness)
    syncRef("CCContrast", S.CCContrast)
    syncRef("CCSaturation", S.CCSaturation)
    syncRef("DOFEnabled", S.DOFEnabled)
    syncRef("DOFFarIntensity", S.DOFFarIntensity)
    syncRef("DOFFocusDistance", S.DOFFocusDistance)
    syncRef("DOFInFocusRadius", S.DOFInFocusRadius)
    syncRef("DOFNearIntensity", S.DOFNearIntensity)
    syncRef("SunRaysEnabled", S.SunRaysEnabled)
    syncRef("SunRaysIntensity", S.SunRaysIntensity)
    syncRef("SunRaysSpread", S.SunRaysSpread)
    syncRef("RemoveFog", S.RemoveFog)
    syncRef("NoShadows", S.NoShadows)
end

local S = World.Settings

-- =====================================================================
-- LEFT: Time of Day
-- =====================================================================
local secTOD = WorldTab:CreateSection({ Name = "w_tod" })

secTOD:AddButton({
    Name = "w_tod_dawn",
    Callback = function()
        World.Functions.TimeDawn()
        SyncPresetUI()
    end,
    Tooltip = "tt_w_tod_dawn",
})
secTOD:AddButton({
    Name = "w_tod_noon",
    Callback = function()
        World.Functions.TimeNoon()
        SyncPresetUI()
    end,
    Tooltip = "tt_w_tod_noon",
})
secTOD:AddButton({
    Name = "w_tod_golden",
    Callback = function()
        World.Functions.TimeGolden()
        SyncPresetUI()
    end,
    Tooltip = "tt_w_tod_golden",
})
secTOD:AddButton({
    Name = "w_tod_dusk",
    Callback = function()
        World.Functions.TimeDusk()
        SyncPresetUI()
    end,
    Tooltip = "tt_w_tod_dusk",
})
secTOD:AddButton({
    Name = "w_tod_midnight",
    Callback = function()
        World.Functions.TimeMidnight()
        SyncPresetUI()
    end,
    Tooltip = "tt_w_tod_midnight",
})

-- =====================================================================
-- LEFT: Lighting
-- =====================================================================
local secL = WorldTab:CreateSection({ Name = "w_lighting" })

setRef("Fullbright", secL:AddToggle({
    Name = "w_fullbright", Value = S.Fullbright,
    Callback = function(v)
        S.Fullbright = v
        if v then S.CustomLighting = false; syncRef("CustomLighting", false) end
        ApplyLook()
    end,
    Tooltip = "tt_w_fullbright",
}))
setRef("CustomLighting", secL:AddToggle({
    Name = "w_custom_lighting", Value = S.CustomLighting,
    Callback = function(v)
        S.CustomLighting = v
        if v then S.Fullbright = false; syncRef("Fullbright", false) end
        ApplyLook()
    end,
    Tooltip = "tt_w_custom_lighting",
}))
setRef("Brightness", secL:AddSlider({
    Name = "w_brightness", Value = S.Brightness, Min = 0, Max = 10, Decimals = 2,
    Callback = function(v) S.Brightness = v ApplyLook() end,
    Tooltip = "tt_w_brightness",
}))
setRef("ClockTime", secL:AddSlider({
    Name = "w_clock_time", Value = S.ClockTime, Min = 0, Max = 24, Decimals = 2,
    Callback = function(v) S.ClockTime = v ApplyLook() end,
    Tooltip = "tt_w_clock_time",
}))
setRef("ExposureCompensation", secL:AddSlider({
    Name = "w_exposure", Value = S.ExposureCompensation,
    Min = -3, Max = 3, Decimals = 2,
    Callback = function(v) S.ExposureCompensation = v ApplyLook() end,
    Tooltip = "tt_w_exposure",
}))
secL:AddColorpicker({
    Name = "w_ambient_color", Default = S.AmbientColor,
    Callback = function(v) S.AmbientColor = v ApplyLook() end,
    Tooltip = "tt_w_ambient_color",
})
secL:AddColorpicker({
    Name = "w_outdoor_ambient", Default = S.OutdoorAmbientColor,
    Callback = function(v) S.OutdoorAmbientColor = v ApplyLook() end,
    Tooltip = "tt_w_outdoor_ambient",
})
setRef("EnvironmentDiffuseScale", secL:AddSlider({
    Name = "w_env_diffuse", Value = S.EnvironmentDiffuseScale,
    Min = 0, Max = 1, Decimals = 2,
    Callback = function(v) S.EnvironmentDiffuseScale = v ApplyLook() end,
    Tooltip = "tt_w_env_diffuse",
}))
setRef("EnvironmentSpecularScale", secL:AddSlider({
    Name = "w_env_specular", Value = S.EnvironmentSpecularScale,
    Min = 0, Max = 1, Decimals = 2,
    Callback = function(v) S.EnvironmentSpecularScale = v ApplyLook() end,
    Tooltip = "tt_w_env_specular",
}))
setRef("ShadowSoftness", secL:AddSlider({
    Name = "w_shadow_softness", Value = S.ShadowSoftness,
    Min = 0, Max = 1, Decimals = 2,
    Callback = function(v) S.ShadowSoftness = v ApplyLook() end,
    Tooltip = "tt_w_shadow_softness",
}))
secL:AddDropdown({
    Name = "w_shadow_tech", Value = S.Technology,
    List = { "Voxel", "ShadowMap", "Future", "Legacy" },
    Callback = function(v) S.Technology = v ApplyLook() end,
    Tooltip = "tt_w_shadow_tech",
})

-- Camera FOV
secL:AddToggle({
    Name = "w_cam_fov_enabled", Value = S.CameraFOVEnabled,
    Callback = function(v)
        S.CameraFOVEnabled = v
        if v then
            ApplyCameraFOV()
            if not World.Internal.Conns.camFOV then
                World.Internal.Conns.camFOV = workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
                    if World.Settings.CameraFOVEnabled then
                        task.wait(0.1)
                        ApplyCameraFOV()
                    end
                end)
            end
        else
            RemoveCameraFOV()
            if World.Internal.Conns.camFOV then
                World.Internal.Conns.camFOV:Disconnect()
                World.Internal.Conns.camFOV = nil
            end
        end
    end,
    Tooltip = "tt_w_cam_fov_enabled",
})
secL:AddSlider({
    Name = "w_cam_fov_value", Value = S.CameraFOVValue, Min = 40, Max = 120,
    Callback = function(v)
        S.CameraFOVValue = v
        if S.CameraFOVEnabled then ApplyCameraFOV() end
    end,
    Tooltip = "tt_w_cam_fov_value",
})

-- =====================================================================
-- LEFT: Fog & Atmosphere
-- =====================================================================
local secFog = WorldTab:CreateSection({ Name = "w_fog_atmo" })

setRef("RemoveFog", secFog:AddToggle({
    Name = "w_remove_fog", Value = S.RemoveFog,
    Callback = function(v)
        S.RemoveFog = v
        if v then S.CustomFog = false end
        ApplyLook()
    end,
    Tooltip = "tt_w_remove_fog",
}))
secFog:AddToggle({
    Name = "w_custom_fog", Value = S.CustomFog,
    Callback = function(v)
        S.CustomFog = v
        if v then S.RemoveFog = false; syncRef("RemoveFog", false) end
        ApplyLook()
    end,
    Tooltip = "tt_w_custom_fog",
})
secFog:AddSlider({
    Name = "w_fog_start", Value = S.FogStart, Min = 0, Max = 5000,
    Callback = function(v) S.FogStart = v ApplyLook() end,
    Tooltip = "tt_w_fog_start",
})
secFog:AddSlider({
    Name = "w_fog_end", Value = S.FogEnd, Min = 0, Max = 100000,
    Callback = function(v) S.FogEnd = v ApplyLook() end,
    Tooltip = "tt_w_fog_end",
})
secFog:AddColorpicker({
    Name = "w_fog_color", Default = S.FogColor,
    Callback = function(v) S.FogColor = v ApplyLook() end,
    Tooltip = "tt_w_fog_color",
})

setRef("AtmosphereEnabled", secFog:AddToggle({
    Name = "w_atmo_enabled", Value = S.AtmosphereEnabled,
    Callback = function(v) S.AtmosphereEnabled = v ApplyLook() end,
    Tooltip = "tt_w_atmo_enabled",
}))
setRef("AtmosphereDensity", secFog:AddSlider({
    Name = "w_atmo_density", Value = S.AtmosphereDensity,
    Min = 0, Max = 1, Decimals = 2,
    Callback = function(v) S.AtmosphereDensity = v ApplyLook() end,
    Tooltip = "tt_w_atmo_density",
}))
secFog:AddSlider({
    Name = "w_atmo_offset", Value = S.AtmosphereOffset,
    Min = -1, Max = 1, Decimals = 2,
    Callback = function(v) S.AtmosphereOffset = v ApplyLook() end,
    Tooltip = "tt_w_atmo_offset",
})
setRef("AtmosphereGlare", secFog:AddSlider({
    Name = "w_atmo_glare", Value = S.AtmosphereGlare,
    Min = 0, Max = 10, Decimals = 2,
    Callback = function(v) S.AtmosphereGlare = v ApplyLook() end,
    Tooltip = "tt_w_atmo_glare",
}))
setRef("AtmosphereHaze", secFog:AddSlider({
    Name = "w_atmo_haze", Value = S.AtmosphereHaze,
    Min = 0, Max = 10, Decimals = 2,
    Callback = function(v) S.AtmosphereHaze = v ApplyLook() end,
    Tooltip = "tt_w_atmo_haze",
}))
secFog:AddColorpicker({
    Name = "w_atmo_color", Default = S.AtmosphereColor,
    Callback = function(v) S.AtmosphereColor = v ApplyLook() end,
    Tooltip = "tt_w_atmo_color",
})
secFog:AddColorpicker({
    Name = "w_atmo_decay", Default = S.AtmosphereDecay,
    Callback = function(v) S.AtmosphereDecay = v ApplyLook() end,
    Tooltip = "tt_w_atmo_decay",
})

-- =====================================================================
-- RIGHT: Post-FX
-- =====================================================================
local secFx = WorldTab:CreateSection({ Name = "w_pfx", Side = "Right" })

setRef("BloomEnabled", secFx:AddToggle({
    Name = "w_bloom", Value = S.BloomEnabled,
    Callback = function(v) S.BloomEnabled = v ApplyLook() end,
    Tooltip = "tt_w_bloom",
}))
setRef("BloomIntensity", secFx:AddSlider({
    Name = "w_bloom_intensity", Value = S.BloomIntensity,
    Min = 0, Max = 5, Decimals = 2,
    Callback = function(v) S.BloomIntensity = v ApplyLook() end,
    Tooltip = "tt_w_bloom_intensity",
}))
setRef("BloomSize", secFx:AddSlider({
    Name = "w_bloom_size", Value = S.BloomSize, Min = 0, Max = 56,
    Callback = function(v) S.BloomSize = v ApplyLook() end,
    Tooltip = "tt_w_bloom_size",
}))
setRef("BloomThreshold", secFx:AddSlider({
    Name = "w_bloom_threshold", Value = S.BloomThreshold,
    Min = 0, Max = 5, Decimals = 2,
    Callback = function(v) S.BloomThreshold = v ApplyLook() end,
    Tooltip = "tt_w_bloom_threshold",
}))

setRef("CCEnabled", secFx:AddToggle({
    Name = "w_cc", Value = S.CCEnabled,
    Callback = function(v) S.CCEnabled = v ApplyLook() end,
    Tooltip = "tt_w_cc",
}))
setRef("CCBrightness", secFx:AddSlider({
    Name = "w_cc_brightness", Value = S.CCBrightness,
    Min = -1, Max = 1, Decimals = 2,
    Callback = function(v) S.CCBrightness = v ApplyLook() end,
    Tooltip = "tt_w_cc_brightness",
}))
setRef("CCContrast", secFx:AddSlider({
    Name = "w_cc_contrast", Value = S.CCContrast,
    Min = -1, Max = 1, Decimals = 2,
    Callback = function(v) S.CCContrast = v ApplyLook() end,
    Tooltip = "tt_w_cc_contrast",
}))
setRef("CCSaturation", secFx:AddSlider({
    Name = "w_cc_saturation", Value = S.CCSaturation,
    Min = -1, Max = 1, Decimals = 2,
    Callback = function(v) S.CCSaturation = v ApplyLook() end,
    Tooltip = "tt_w_cc_saturation",
}))
secFx:AddColorpicker({
    Name = "w_cc_tint", Default = S.CCTintColor,
    Callback = function(v) S.CCTintColor = v ApplyLook() end,
    Tooltip = "tt_w_cc_tint",
})

setRef("DOFEnabled", secFx:AddToggle({
    Name = "w_dof", Value = S.DOFEnabled,
    Callback = function(v) S.DOFEnabled = v ApplyLook() end,
    Tooltip = "tt_w_dof",
}))
setRef("DOFFarIntensity", secFx:AddSlider({
    Name = "w_dof_far", Value = S.DOFFarIntensity,
    Min = 0, Max = 1, Decimals = 2,
    Callback = function(v) S.DOFFarIntensity = v ApplyLook() end,
    Tooltip = "tt_w_dof_far",
}))
setRef("DOFFocusDistance", secFx:AddSlider({
    Name = "w_dof_focus", Value = S.DOFFocusDistance,
    Min = 0, Max = 200,
    Callback = function(v) S.DOFFocusDistance = v ApplyLook() end,
    Tooltip = "tt_w_dof_focus",
}))
setRef("DOFInFocusRadius", secFx:AddSlider({
    Name = "w_dof_infocus", Value = S.DOFInFocusRadius,
    Min = 0, Max = 200,
    Callback = function(v) S.DOFInFocusRadius = v ApplyLook() end,
    Tooltip = "tt_w_dof_infocus",
}))
setRef("DOFNearIntensity", secFx:AddSlider({
    Name = "w_dof_near", Value = S.DOFNearIntensity,
    Min = 0, Max = 1, Decimals = 2,
    Callback = function(v) S.DOFNearIntensity = v ApplyLook() end,
    Tooltip = "tt_w_dof_near",
}))

setRef("SunRaysEnabled", secFx:AddToggle({
    Name = "w_sunrays", Value = S.SunRaysEnabled,
    Callback = function(v) S.SunRaysEnabled = v ApplyLook() end,
    Tooltip = "tt_w_sunrays",
}))
setRef("SunRaysIntensity", secFx:AddSlider({
    Name = "w_sunrays_intensity", Value = S.SunRaysIntensity,
    Min = 0, Max = 1, Decimals = 2,
    Callback = function(v) S.SunRaysIntensity = v ApplyLook() end,
    Tooltip = "tt_w_sunrays_intensity",
}))
setRef("SunRaysSpread", secFx:AddSlider({
    Name = "w_sunrays_spread", Value = S.SunRaysSpread,
    Min = 0, Max = 1, Decimals = 2,
    Callback = function(v) S.SunRaysSpread = v ApplyLook() end,
    Tooltip = "tt_w_sunrays_spread",
}))

secFx:AddToggle({
    Name = "w_blur", Value = S.BlurEnabled,
    Callback = function(v) S.BlurEnabled = v ApplyLook() end,
    Tooltip = "tt_w_blur",
})
secFx:AddSlider({
    Name = "w_blur_size", Value = S.BlurSize, Min = 0, Max = 56,
    Callback = function(v) S.BlurSize = v ApplyLook() end,
    Tooltip = "tt_w_blur_size",
})

-- =====================================================================
-- RIGHT: Sky
-- =====================================================================
local secSky = WorldTab:CreateSection({ Name = "w_sky", Side = "Right" })
secSky:AddToggle({
    Name = "w_custom_sky", Value = S.CustomSky,
    Callback = function(v) S.CustomSky = v ApplyLook() end,
    Tooltip = "tt_w_custom_sky",
})
secSky:AddSlider({
    Name = "w_sky_stars", Value = S.SkyStarCount, Min = 0, Max = 10000,
    Callback = function(v) S.SkyStarCount = v ApplyLook() end,
    Tooltip = "tt_w_sky_stars",
})
secSky:AddSlider({
    Name = "w_sky_sun_size", Value = S.SkySunAngularSize,
    Min = 0, Max = 90,
    Callback = function(v) S.SkySunAngularSize = v ApplyLook() end,
    Tooltip = "tt_w_sky_sun_size",
})
secSky:AddSlider({
    Name = "w_sky_moon_size", Value = S.SkyMoonAngularSize,
    Min = 0, Max = 90,
    Callback = function(v) S.SkyMoonAngularSize = v ApplyLook() end,
    Tooltip = "tt_w_sky_moon_size",
})

-- =====================================================================
-- LEFT: Cleanup
-- =====================================================================
local secClean = WorldTab:CreateSection({ Name = "w_cleanup" })
setRef("NoShadows", secClean:AddToggle({
    Name = "w_no_shadows", Value = S.NoShadows,
    Callback = function(v) S.NoShadows = v ApplyLook() end,
    Tooltip = "tt_w_no_shadows",
}))
secClean:AddToggle({
    Name = "w_remove_textures", Value = S.RemoveTextures,
    Callback = function(v)
        S.RemoveTextures = v
        if v then ApplyRemoveTextures() else RemoveRemoveTextures() end
    end,
    Tooltip = "tt_w_remove_textures",
})
secClean:AddToggle({
    Name = "w_remove_particles", Value = S.RemoveParticles,
    Callback = function(v)
        S.RemoveParticles = v
        if v then ApplyRemoveParticles() else RemoveRemoveParticles() end
    end,
    Tooltip = "tt_w_remove_particles",
})
secClean:AddToggle({
    Name = "w_remove_grass", Value = S.RemoveGrass,
    Callback = function(v)
        S.RemoveGrass = v
        if v then ApplyRemoveGrass() else RemoveRemoveGrass() end
    end,
    Tooltip = "tt_w_remove_grass",
})
secClean:AddToggle({
    Name = "w_remove_sky", Value = S.RemoveSky,
    Callback = function(v)
        S.RemoveSky = v
        if v then ApplyRemoveSky() else RemoveRemoveSky() end
    end,
    Tooltip = "tt_w_remove_sky",
})
secClean:AddToggle({
    Name = "w_disable_sounds", Value = S.DisableSounds,
    Callback = function(v)
        S.DisableSounds = v
        if v then ApplyDisableSounds() else RemoveDisableSounds() end
    end,
    Tooltip = "tt_w_disable_sounds",
})
secClean:AddToggle({
    Name = "w_disable_lights", Value = S.DisableDynamicLights,
    Callback = function(v)
        S.DisableDynamicLights = v
        if v then ApplyDisableDynamicLights() else RemoveDisableDynamicLights() end
    end,
    Tooltip = "tt_w_disable_lights",
})

-- =====================================================================
-- RIGHT: Presets
-- =====================================================================
local secPre = WorldTab:CreateSection({ Name = "w_presets", Side = "Right" })
secPre:AddButton({
    Name = "w_preset_rtx",
    Callback = function()
        Preset_RTXUltra()
        SyncPresetUI()
        if Util.ShowError then Util.ShowError("RTX Ultra applied") end
    end,
    Tooltip = "tt_w_preset_rtx",
})
secPre:AddButton({
    Name = "w_preset_cinematic",
    Callback = function()
        Preset_Cinematic()
        SyncPresetUI()
        if Util.ShowError then Util.ShowError("Cinematic applied") end
    end,
    Tooltip = "tt_w_preset_cinematic",
})
secPre:AddButton({
    Name = "w_preset_clean",
    Callback = function()
        Preset_Clean()
        SyncPresetUI()
        if Util.ShowError then Util.ShowError("Clean preset applied") end
    end,
    Tooltip = "tt_w_preset_clean",
})
secPre:AddButton({
    Name = "w_preset_restore",
    Callback = function()
        World.Functions.Restore()
        SyncPresetUI()
        if Util.ShowError then Util.ShowError("World restored") end
    end,
    Tooltip = "tt_w_preset_restore",
})

print("[AirHub] 06_world: loaded OK v2 (RU loc + tooltips + Time of Day + FOV + Sounds + Lights)")
