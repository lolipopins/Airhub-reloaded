--// AirHub — 03_antiaim.lua (airhubUI build, RU localization + tooltips)
--// Logic: Body Anti-Aim + Desync + Animation Breaker (unchanged).
--// UI:    airhubUI (AddToggle/Slider/Dropdown/Input/Button/Colorpicker).
--// Added: full RU/EN localization for every element + tooltips for all controls.

local H = getgenv().AirHub
if not H or not H._CoreLoaded then warn("[AirHub] 03_antiaim: core not loaded") return end
if H.AntiAim then warn("[AirHub] AntiAim already loaded") return end

local Util        = H.Util
local Players     = Util.Players
local RunService  = Util.RunService
local LocalPlayer = Util.LocalPlayer
local Track       = Util.Track
local HandleError = Util.HandleError

--// ===========================================================================
--// Schema
--// ===========================================================================
H.AntiAim = {
    Settings = {
        Enabled = false,
        Mode    = "Static",
        Method  = "CFrame",
        Body = {
            Reference          = "Camera",
            Yaw                = 0,
            Amount             = 15,
            Speed              = 5,
            IgnoreMoving       = false,
            MoveSpeedThreshold = 0.5,
        },
    },
    Desync = {
        Settings = {
            Enabled            = false,
            Mode               = "Default",
            Method             = "CFrame",
            X                  = 5,
            Y                  = 5,
            Z                  = 5,
            Random             = false,
            UpdateInterval     = 0.05,
            OldPosDelayEnabled = true,
            OldPosDelay        = 0.5,
            VoidDepth          = -1000,
            InPlayerOffset     = 2,
            RefreshOnShot      = false,
            RandomRotate       = false,
        },
        Internal = {
            Connection       = nil,
            RenderBindName   = "AirHubDesyncRestore",
            Acc              = 0,
            CurrentOffset    = Vector3.new(0, 0, 0),
            TargetOffset     = Vector3.new(0, 0, 0),
            SavedCFrame      = nil,
            RealCFrame       = nil,
            RealVelocity     = nil,
            RealRotVelocity  = nil,
            OldPosTimer      = 0,
            PendingRefresh   = false,
            RotAcc           = 0,
            RotPitch         = 0,
            RotYaw           = 0,
            RotRoll          = 0,
            NetworkClaimed   = false,
        },
    },
    AnimationBreaker = {
        Settings = {
            Enabled        = false,
            Mode           = "Speed",       -- Speed | RandomFrames
            Preset         = "None",        -- "None" | preset name | "Custom"
            CustomId       = "",            -- rbxassetid://...
            Speed          = 1,             -- Speed mode
            RandomInterval = 0.1,           -- RandomFrames mode
            ApplyToServer  = true,
        },
        Internal = {
            CurrentTrack    = nil,
            CurrentKey      = nil,
            LastHRP         = nil,
            NetworkOwnerSet = false,
            RandomTimer     = 0,
            LastWarnedId    = nil,
        },
        Functions = {},
    },
    Internal = {
        BodyLastUpdate    = 0,
        BodyJitterTime    = 0,
        BodyJitterOffset  = 0,
        BodyGyro          = nil,
        AlignOrientation  = nil,
        Attachment        = nil,
        AngularVelocity   = nil,
        CurrentMotor      = nil,
        OriginalC0        = nil,
    },
}
local AntiAim = H.AntiAim
local AB = AntiAim.AnimationBreaker

--// ===========================================================================
--// Generic helpers
--// ===========================================================================
local function GetBaseYaw(reference, char)
    if reference == "Camera" then
        local look = workspace.CurrentCamera.CFrame.LookVector
        local flat = Vector3.new(look.X, 0, look.Z)
        if flat.Magnitude > 0.001 then return math.atan2(flat.X, flat.Z) else return 0 end
    elseif reference == "Movement" then
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local vel = hrp.Velocity
            local horizontal = Vector3.new(vel.X, 0, vel.Z)
            if horizontal.Magnitude > 0.5 then return math.atan2(horizontal.X, horizontal.Z) end
        end
        local look = workspace.CurrentCamera.CFrame.LookVector
        local flat = Vector3.new(look.X, 0, look.Z)
        if flat.Magnitude > 0.001 then return math.atan2(flat.X, flat.Z) else return 0 end
    elseif reference == "Player" then
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local look = hrp.CFrame.LookVector
            local flat = Vector3.new(look.X, 0, look.Z)
            if flat.Magnitude > 0.001 then return math.atan2(flat.X, flat.Z) else return 0 end
        end
        return 0
    end
    return 0
end

local function GetCurrentHRP()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function BuildDefaultOffset(settings)
    local X = tonumber(settings.X) or 0
    local Y = tonumber(settings.Y) or 0
    local Z = tonumber(settings.Z) or 0
    if settings.Random then
        local rx = (math.random() * 2 - 1) * X
        local ry = (math.random() * 2 - 1) * Y
        local rz = (math.random() * 2 - 1) * Z
        return Vector3.new(rx, ry, rz)
    end
    return Vector3.new(X, Y, Z)
end

local function GetNearestPlayerHRP(myPos)
    if not myPos then return nil end
    local nearest, nearestDist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local d = (hrp.Position - myPos).Magnitude
                if d < nearestDist then
                    nearestDist = d
                    nearest = hrp
                end
            end
        end
    end
    return nearest
end

local function GetRootJoint(hrp)
    if not hrp then return nil end
    for _, child in ipairs(hrp:GetChildren()) do
        if child:IsA("Motor6D") then return child end
    end
    return nil
end

--// ===========================================================================
--// Desync
--// ===========================================================================
local function StartDesync()
    local desync = AntiAim.Desync
    if desync.Internal.Connection then return end

    desync.Internal.Acc             = 0
    desync.Internal.CurrentOffset   = Vector3.new(0, 0, 0)
    desync.Internal.TargetOffset    = Vector3.new(0, 0, 0)
    desync.Internal.PendingRefresh  = false
    desync.Internal.RealCFrame      = nil
    desync.Internal.RealVelocity    = nil
    desync.Internal.RealRotVelocity = nil
    desync.Internal.RotAcc          = 0
    desync.Internal.RotPitch        = 0
    desync.Internal.RotYaw          = 0
    desync.Internal.RotRoll         = 0
    desync.Internal.NetworkClaimed  = false

    if desync.Settings.Mode == "OldPosition" then
        local hrp = GetCurrentHRP()
        if hrp then desync.Internal.SavedCFrame = hrp.CFrame end
        desync.Internal.OldPosTimer = 0
    end

    desync.Internal.Connection = RunService.Heartbeat:Connect(function(dt)
        if H.ShuttingDown then return end
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local hum = char:FindFirstChildOfClass("Humanoid")

        local oldcf     = hrp.CFrame
        local oldvel    = hrp.Velocity
        local oldrotvel = hrp.RotVelocity
        local oldPos    = oldcf.Position

        desync.Internal.RealCFrame      = oldcf
        desync.Internal.RealVelocity    = oldvel
        desync.Internal.RealRotVelocity = oldrotvel

        local S = desync.Settings
        local mode   = S.Mode
        local method = S.Method or "CFrame"
        local interval = tonumber(S.UpdateInterval) or 0.05
        if interval < 0.01 then interval = 0.01 end

        local rootJoint   = GetRootJoint(hrp)
        local oldRootC0   = rootJoint and rootJoint.C0
        local oldHipH     = hum and hum.HipHeight

        local targetCF

        if mode == "OldPosition" then
            if not desync.Internal.SavedCFrame then
                desync.Internal.SavedCFrame = oldcf
            end
            if desync.Internal.PendingRefresh then
                desync.Internal.PendingRefresh = false
                desync.Internal.SavedCFrame = oldcf
                desync.Internal.OldPosTimer = 0
            end
            if S.OldPosDelayEnabled then
                local delay = tonumber(S.OldPosDelay) or 0.5
                if delay < 0.01 then delay = 0.01 end
                desync.Internal.OldPosTimer = desync.Internal.OldPosTimer + dt
                if desync.Internal.OldPosTimer >= delay then
                    desync.Internal.SavedCFrame = oldcf
                    desync.Internal.OldPosTimer = 0
                end
            end
            targetCF = desync.Internal.SavedCFrame

        elseif mode == "Void" then
            local voidY = tonumber(S.VoidDepth) or -1000
            targetCF = CFrame.new(oldcf.X, voidY, oldcf.Z)

        elseif mode == "InPlayer" then
            local targetHrp = GetNearestPlayerHRP(oldcf.Position)
            if targetHrp then
                local offset = tonumber(S.InPlayerOffset) or 0
                local look = targetHrp.CFrame.LookVector
                local flatLook = Vector3.new(look.X, 0, look.Z)
                if flatLook.Magnitude < 0.001 then
                    targetCF = targetHrp.CFrame
                else
                    targetCF = targetHrp.CFrame - flatLook.Unit * offset
                end
            else
                targetCF = oldcf
            end

        else
            desync.Internal.Acc = desync.Internal.Acc + dt
            if desync.Internal.Acc >= interval then
                desync.Internal.Acc = 0
                desync.Internal.TargetOffset = BuildDefaultOffset(S)
            end
            targetCF = oldcf * CFrame.new(desync.Internal.TargetOffset)
        end

        if S.RandomRotate then
            desync.Internal.RotAcc = desync.Internal.RotAcc + dt
            if desync.Internal.RotAcc >= interval then
                desync.Internal.RotAcc = 0
                desync.Internal.RotPitch = (math.random() * 2 - 1) * math.pi
                desync.Internal.RotYaw   = (math.random() * 2 - 1) * math.pi
                desync.Internal.RotRoll  = (math.random() * 2 - 1) * math.pi
            end
            targetCF = targetCF * CFrame.Angles(
                desync.Internal.RotPitch,
                desync.Internal.RotYaw,
                desync.Internal.RotRoll
            )
        end

        local applied = false
        if method == "CFrame" then
            hrp.CFrame = targetCF
            applied = true
        elseif method == "Position" then
            hrp.Position = targetCF.Position
            applied = true
        elseif method == "Velocity" then
            local diff = targetCF.Position - oldPos
            local mag  = diff.Magnitude
            if mag > 0.001 then
                local speed = math.min(mag / math.max(dt, 0.001), 1000)
                hrp.Velocity = diff.Unit * speed
            else
                hrp.Velocity = Vector3.new(0, 0, 0)
            end
            applied = true
        elseif method == "Motor6D" then
            if rootJoint and oldRootC0 then
                local offset = targetCF.Position - oldPos
                pcall(function() rootJoint.C0 = oldRootC0 + offset end)
                applied = true
            end
        elseif method == "HipHeight" then
            if hum and oldHipH then
                local yOff = targetCF.Position.Y - oldPos.Y
                pcall(function() hum.HipHeight = oldHipH + yOff end)
                applied = true
            end
        elseif method == "Network" then
            if not desync.Internal.NetworkClaimed then
                pcall(function() hrp:SetNetworkOwner(LocalPlayer) end)
                desync.Internal.NetworkClaimed = true
            end
            hrp.CFrame = targetCF
            applied = true
        end

        if applied then
            RunService:BindToRenderStep(desync.Internal.RenderBindName, 101, function()
                pcall(function()
                    hrp.CFrame      = oldcf
                    hrp.Velocity    = oldvel
                    hrp.RotVelocity = oldrotvel
                end)
                if rootJoint and oldRootC0 then
                    pcall(function() rootJoint.C0 = oldRootC0 end)
                end
                if hum and oldHipH then
                    pcall(function() hum.HipHeight = oldHipH end)
                end
                RunService:UnbindFromRenderStep(desync.Internal.RenderBindName)
            end)
        end
    end)
end

local function StopDesync()
    local desync = AntiAim.Desync

    local hrp = GetCurrentHRP()
    if hrp then
        local realCF = desync.Internal.RealCFrame
        if realCF then
            pcall(function()
                hrp.CFrame = realCF
                if desync.Internal.RealVelocity    then hrp.Velocity    = desync.Internal.RealVelocity    end
                if desync.Internal.RealRotVelocity then hrp.RotVelocity = desync.Internal.RealRotVelocity end
            end)
        end
    end

    if desync.Internal.Connection then
        pcall(function() desync.Internal.Connection:Disconnect() end)
        desync.Internal.Connection = nil
    end

    pcall(function() RunService:UnbindFromRenderStep(desync.Internal.RenderBindName) end)

    desync.Internal.SavedCFrame      = nil
    desync.Internal.RealCFrame       = nil
    desync.Internal.RealVelocity     = nil
    desync.Internal.RealRotVelocity  = nil
    desync.Internal.OldPosTimer      = 0
    desync.Internal.PendingRefresh   = false
    desync.Internal.Acc              = 0
    desync.Internal.CurrentOffset    = Vector3.new(0, 0, 0)
    desync.Internal.TargetOffset     = Vector3.new(0, 0, 0)
    desync.Internal.RotAcc           = 0
    desync.Internal.RotPitch         = 0
    desync.Internal.RotYaw           = 0
    desync.Internal.RotRoll          = 0
    desync.Internal.NetworkClaimed   = false
end

--// ===========================================================================
--// Animation Breaker — presets
--// ===========================================================================
AB.AnimationPresets = {
    ["None"]              = nil,
    ["Default R15 Idle"]  = 507766666,
    ["Default R15 Walk"]  = 507777826,
    ["Default R15 Run"]   = 507767714,
    ["Default R15 Jump"]  = 507765000,
    ["Default R15 Fall"]  = 507767968,
    ["Default R6 Idle"]   = 180435571,
    ["Default R6 Walk"]   = 180426354,
    ["Default R6 Run"]    = 180426354,
    ["Default R6 Jump"]   = 125750702,
    ["Default R6 Fall"]   = 180436148,
    ["Zombie Idle"]       = 616006778,
    ["Zombie Walk"]       = 616008936,
    ["Zombie Run"]        = 616010382,
    ["Zombie Jump"]       = 616005621,
    ["Ninja Idle"]        = 656117400,
    ["Ninja Run"]         = 656118852,
    ["Pirate Idle"]       = 750781171,
    ["Pirate Run"]        = 750779262,
    ["Robot Idle"]        = 616088791,
    ["Toy Idle"]          = 782850875,
    ["Levitation Idle"]   = 616006778,
    ["Tornado"]           = 82995540773684,
    ["AntiAim"]           = 121890511737627,
    ["Moving AntiAim"]    = 127105358105170,
    ["Custom"]            = nil,
}

--// Animation Breaker helpers
local function GetAnimator(char)
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return nil end
    return hum:FindFirstChildOfClass("Animator")
end

local function ParseAssetId(str)
    if type(str) ~= "string" then return nil end
    str = str:gsub("%s", "")
    if str == "" then return nil end
    if str:match("^rbxassetid://%d+$") then return str end
    local n = tonumber(str:match("%d+") or "")
    if n and n > 0 then return "rbxassetid://" .. n end
    return nil
end

local function ResolvePresetId()
    local presetName = AB.Settings.Preset
    if presetName == "Custom" then
        return ParseAssetId(AB.Settings.CustomId)
    end
    local id = AB.AnimationPresets[presetName]
    if id then return "rbxassetid://" .. tostring(id) end
    return nil
end

local function CurrentKey()
    if AB.Settings.Preset == "Custom" then
        return "custom:" .. tostring(AB.Settings.CustomId or "")
    end
    return "preset:" .. tostring(AB.Settings.Preset or "None")
end

local function StopOurTrack()
    if AB.Internal.CurrentTrack then
        pcall(function() AB.Internal.CurrentTrack:Stop(0) end)
        AB.Internal.CurrentTrack = nil
    end
end

local function LoadPresetTrack(animator)
    StopOurTrack()
    local assetId = ResolvePresetId()
    if not assetId then
        if AB.Settings.Preset == "Custom" then
            local cur = tostring(AB.Settings.CustomId or "")
            if AB.Internal.LastWarnedId ~= cur then
                AB.Internal.LastWarnedId = cur
                warn("[AirHub AB] Custom ID не задан или невалиден: '" .. cur .. "'")
            end
        end
        return false
    end

    local anim = Instance.new("Animation")
    anim.AnimationId = assetId
    local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
    if not ok or not track then
        warn("[AirHub AB] LoadAnimation не удался для " .. assetId)
        return false
    end

    track.Looped   = true
    track.Priority = Enum.AnimationPriority.Action4
    AB.Internal.CurrentTrack = track
    pcall(function() track:Play(0.15) end)
    return true
end

local function ApplySpeedToAllTracks(speed)
    local char = LocalPlayer.Character
    if not char then return end
    local animator = GetAnimator(char)
    if not animator then return end
    local ok, tracks = pcall(function() return animator:GetPlayingAnimationTracks() end)
    if not ok or not tracks then return end
    for _, t in ipairs(tracks) do
        pcall(function()
            t:AdjustSpeed(speed)
            if t.Speed ~= speed then t.Speed = speed end
        end)
    end
end

local function ApplyRandomFramesToAllTracks(dt)
    local interval = tonumber(AB.Settings.RandomInterval) or 0.1
    if interval < 0.02 then interval = 0.02 end
    AB.Internal.RandomTimer = AB.Internal.RandomTimer + dt
    local doJump = AB.Internal.RandomTimer >= interval
    if doJump then AB.Internal.RandomTimer = 0 end

    local char = LocalPlayer.Character
    if not char then return end
    local animator = GetAnimator(char)
    if not animator then return end
    local ok, tracks = pcall(function() return animator:GetPlayingAnimationTracks() end)
    if not ok or not tracks then return end
    for _, t in ipairs(tracks) do
        pcall(function()
            t:AdjustSpeed(0)
            if t.Speed ~= 0 then t.Speed = 0 end
            if doJump then
                local len = t.Length or 0
                if len > 0 then t.TimePosition = math.random() * len end
            end
        end)
    end
end

local function ApplyRandomFramesToOurTrack(tr, dt)
    if not tr then return end
    pcall(function()
        tr:AdjustSpeed(0)
        if tr.Speed ~= 0 then tr.Speed = 0 end
    end)

    local interval = tonumber(AB.Settings.RandomInterval) or 0.1
    if interval < 0.02 then interval = 0.02 end
    AB.Internal.RandomTimer = AB.Internal.RandomTimer + dt
    if AB.Internal.RandomTimer >= interval then
        AB.Internal.RandomTimer = 0
        local len = 0
        pcall(function() len = tr.Length or 0 end)
        if len > 0 then
            pcall(function() tr.TimePosition = math.random() * len end)
        end
    end
end

--// Main Animation Breaker entry
local function ApplyAnimationBreaker(dt)
    if H.ShuttingDown then return end
    if not AB.Settings.Enabled then return end

    local char = LocalPlayer.Character
    if not char then
        StopOurTrack()
        AB.Internal.NetworkOwnerSet = false
        AB.Internal.LastHRP         = nil
        AB.Internal.CurrentKey      = nil
        return
    end

    local animator = GetAnimator(char)
    if not animator then
        AB.Internal.CurrentKey = nil
        return
    end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp ~= AB.Internal.LastHRP then
        AB.Internal.LastHRP         = hrp
        AB.Internal.NetworkOwnerSet = false
        StopOurTrack()
        AB.Internal.CurrentKey      = nil
        AB.Internal.RandomTimer     = 0
    end

    if AB.Settings.ApplyToServer and hrp and not AB.Internal.NetworkOwnerSet then
        pcall(function() hrp:SetNetworkOwner(LocalPlayer) end)
        AB.Internal.NetworkOwnerSet = true
    end

    local mode = AB.Settings.Mode or "Speed"

    if AB.Settings.Preset == "None" then
        if AB.Internal.CurrentTrack then StopOurTrack() end
        AB.Internal.CurrentKey = "preset:None"

        if mode == "RandomFrames" then
            ApplyRandomFramesToAllTracks(dt)
        else
            local speed = tonumber(AB.Settings.Speed) or 1
            ApplySpeedToAllTracks(speed)
        end
        return
    end

    local key = CurrentKey()
    if AB.Internal.CurrentKey ~= key then
        AB.Internal.CurrentKey  = key
        LoadPresetTrack(animator)
        AB.Internal.RandomTimer = 0
    end

    local tr = AB.Internal.CurrentTrack
    if not tr then return end

    local okP, isPlaying = pcall(function() return tr.IsPlaying end)
    if okP and not isPlaying then
        pcall(function() tr:Play(0.15) end)
    end

    if mode == "RandomFrames" then
        ApplyRandomFramesToOurTrack(tr, dt)
    else
        local speed = tonumber(AB.Settings.Speed) or 1
        pcall(function()
            tr:AdjustSpeed(speed)
            if tr.Speed ~= speed then tr.Speed = speed end
        end)
    end
end

local function ResetAllSpeeds()
    local char = LocalPlayer.Character
    if not char then return end
    local animator = GetAnimator(char)
    if not animator then return end
    local ok, tracks = pcall(function() return animator:GetPlayingAnimationTracks() end)
    if not ok or not tracks then return end
    for _, t in ipairs(tracks) do
        pcall(function()
            if t.Speed ~= 1 then t.Speed = 1 end
        end)
    end
end

local function StopAnimationBreaker()
    ResetAllSpeeds()
    StopOurTrack()
    AB.Internal.CurrentKey      = nil
    AB.Internal.RandomTimer     = 0
    AB.Internal.NetworkOwnerSet = false
    AB.Internal.LastHRP         = nil
end

local function ReloadAnimationPreset()
    StopOurTrack()
    AB.Internal.CurrentKey  = nil
    AB.Internal.RandomTimer = 0
end

AB.Functions.Reload = ReloadAnimationPreset
AB.Functions.Stop   = StopAnimationBreaker
AB.Functions.ListPresets = function()
    local out = {}
    for k in pairs(AB.AnimationPresets) do out[#out + 1] = k end
    table.sort(out)
    return out
end
-- Fixed: the original returned false for "None" because nil == nil is true
-- and "None" ~= "Custom" was true, causing the guard to short-circuit.
AB.Functions.ApplyPreset = function(name)
    if name ~= "None" and name ~= "Custom" and AB.AnimationPresets[name] == nil then
        return false
    end
    AB.Settings.Preset = name
    ReloadAnimationPreset()
    return true
end

Track(RunService.Heartbeat:Connect(function(dt)
    if H.ShuttingDown then return end
    if not AB.Settings.Enabled then return end
    xpcall(function() ApplyAnimationBreaker(dt) end, HandleError)
end))

--// ===========================================================================
--// Anti-Aim body
--// ===========================================================================
local function CleanupAntiAim()
    if AntiAim.Internal.BodyGyro then
        pcall(function() AntiAim.Internal.BodyGyro:Destroy() end)
        AntiAim.Internal.BodyGyro = nil
    end
    if AntiAim.Internal.AlignOrientation then
        pcall(function() AntiAim.Internal.AlignOrientation:Destroy() end)
        AntiAim.Internal.AlignOrientation = nil
    end
    if AntiAim.Internal.Attachment then
        pcall(function() AntiAim.Internal.Attachment:Destroy() end)
        AntiAim.Internal.Attachment = nil
    end
    if AntiAim.Internal.AngularVelocity then
        pcall(function() AntiAim.Internal.AngularVelocity:Destroy() end)
        AntiAim.Internal.AngularVelocity = nil
    end
    if AntiAim.Internal.CurrentMotor then
        local motor = AntiAim.Internal.CurrentMotor
        local orig  = AntiAim.Internal.OriginalC0
        if motor.Parent and orig then
            pcall(function() motor.C0 = orig end)
        end
        AntiAim.Internal.CurrentMotor = nil
        AntiAim.Internal.OriginalC0   = nil
    end
end

local function ApplyAntiAim()
    if H.ShuttingDown then return end
    if not AntiAim.Settings.Enabled then CleanupAntiAim() return end

    local char = LocalPlayer.Character
    if not char then CleanupAntiAim() return end

    local now = tick()
    AntiAim.Internal.BodyLastUpdate = now

    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local bodySet = AntiAim.Settings.Body
    local mode    = AntiAim.Settings.Mode
    local method  = AntiAim.Settings.Method

    local shouldApply = true
    if bodySet.IgnoreMoving then
        if root.Velocity.Magnitude > bodySet.MoveSpeedThreshold then
            shouldApply = false
        end
    end

    if shouldApply then
        local baseYaw = GetBaseYaw(bodySet.Reference, char)
        local amount  = tonumber(bodySet.Amount) or 15
        local speed   = tonumber(bodySet.Speed) or 5
        if speed <= 0 then speed = 0.01 end
        local yaw = 0

        if mode == "Static" then
            yaw = baseYaw + math.rad(bodySet.Yaw + amount)
        elseif mode == "Spin" then
            yaw = baseYaw + math.rad((now * speed) % 360 + bodySet.Yaw)
        elseif mode == "Jitter" then
            if now - AntiAim.Internal.BodyJitterTime > 1 / speed then
                AntiAim.Internal.BodyJitterTime = now
                AntiAim.Internal.BodyJitterOffset = (math.random() - 0.5) * 2 * amount
            end
            yaw = baseYaw + math.rad(bodySet.Yaw + AntiAim.Internal.BodyJitterOffset)
        elseif mode == "Sway" then
            yaw = baseYaw + math.rad(bodySet.Yaw + math.sin(now * speed) * amount)
        end

        if method == "CFrame" then
            CleanupAntiAim()
            root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, yaw, 0)
        elseif method == "BodyGyro" then
            if AntiAim.Internal.AlignOrientation or AntiAim.Internal.AngularVelocity or AntiAim.Internal.CurrentMotor then
                CleanupAntiAim()
            end
            if not AntiAim.Internal.BodyGyro or not AntiAim.Internal.BodyGyro.Parent then
                local bg = Instance.new("BodyGyro")
                bg.MaxTorque = Vector3.new(0, 4000, 0)
                bg.P = 10000
                bg.D = 100
                bg.Parent = root
                AntiAim.Internal.BodyGyro = bg
            end
            AntiAim.Internal.BodyGyro.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, yaw, 0)
        elseif method == "Motor6D" then
            if AntiAim.Internal.BodyGyro or AntiAim.Internal.AlignOrientation or AntiAim.Internal.AngularVelocity then
                CleanupAntiAim()
            end
            local motor
            for _, child in ipairs(char:GetDescendants()) do
                if child:IsA("Motor6D") and (
                    child.Name == "Neck" or child.Name == "Waist"
                    or child.Name:lower():find("neck") or child.Name:lower():find("waist")
                ) then
                    motor = child
                    break
                end
            end
            if motor then
                if not AntiAim.Internal.CurrentMotor or AntiAim.Internal.CurrentMotor ~= motor
                   or not AntiAim.Internal.CurrentMotor.Parent then
                    if AntiAim.Internal.CurrentMotor and AntiAim.Internal.OriginalC0 then
                        local oldMotor = AntiAim.Internal.CurrentMotor
                        local oldC0    = AntiAim.Internal.OriginalC0
                        if oldMotor.Parent then pcall(function() oldMotor.C0 = oldC0 end) end
                    end
                    AntiAim.Internal.CurrentMotor = motor
                    AntiAim.Internal.OriginalC0   = motor.C0
                end
                if AntiAim.Internal.CurrentMotor.Parent then
                    pcall(function()
                        AntiAim.Internal.CurrentMotor.C0 = AntiAim.Internal.OriginalC0 * CFrame.Angles(0, yaw, 0)
                    end)
                end
            else
                CleanupAntiAim()
            end
        elseif method == "AlignOrientation" then
            if AntiAim.Internal.BodyGyro or AntiAim.Internal.AngularVelocity or AntiAim.Internal.CurrentMotor then
                CleanupAntiAim()
            end
            if not AntiAim.Internal.Attachment or not AntiAim.Internal.Attachment.Parent then
                local attachment = Instance.new("Attachment")
                attachment.Parent = root
                AntiAim.Internal.Attachment = attachment
                AntiAim.Internal.AlignOrientation = nil
            end
            if not AntiAim.Internal.AlignOrientation or not AntiAim.Internal.AlignOrientation.Parent then
                local align = Instance.new("AlignOrientation")
                align.MaxTorque = 4000
                align.MaxAngularVelocity = math.huge
                align.Responsiveness = 50
                align.Parent = root
                align.Attachment0 = AntiAim.Internal.Attachment
                align.RigidityEnabled = false
                AntiAim.Internal.AlignOrientation = align
            end
            AntiAim.Internal.AlignOrientation.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, yaw, 0)
            AntiAim.Internal.AlignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
            AntiAim.Internal.AlignOrientation.RigidityEnabled = false
        elseif method == "AngularVelocity" then
            if AntiAim.Internal.BodyGyro or AntiAim.Internal.AlignOrientation or AntiAim.Internal.CurrentMotor then
                CleanupAntiAim()
            end
            if not AntiAim.Internal.AngularVelocity or not AntiAim.Internal.AngularVelocity.Parent then
                local av = Instance.new("AngularVelocity")
                av.MaxTorque = Vector3.new(0, 4000, 0)
                av.AngularVelocity = Vector3.new(0, 0, 0)
                av.Parent = root
                AntiAim.Internal.AngularVelocity = av
            end
            local spinSpeed = (mode == "Spin") and math.rad(speed) or 0
            AntiAim.Internal.AngularVelocity.AngularVelocity = Vector3.new(0, spinSpeed, 0)
        end
    else
        CleanupAntiAim()
    end
end

local AA_BIND_NAME = "AirHubAntiAim"
AntiAim.AA_BIND_NAME = AA_BIND_NAME
pcall(function() RunService:UnbindFromRenderStep(AA_BIND_NAME) end)
RunService:BindToRenderStep(AA_BIND_NAME, 201, function()
    xpcall(ApplyAntiAim, HandleError)
end)

--// ===========================================================================
--// Public functions / exports
--// ===========================================================================
AntiAim.Functions = {
    ResetSettings = function()
        AntiAim.Settings = {
            Enabled = false,
            Mode = "Static",
            Method = "CFrame",
            Body = {
                Reference = "Camera",
                Yaw = 0,
                Amount = 15,
                Speed = 5,
                IgnoreMoving = false,
                MoveSpeedThreshold = 0.5,
            },
        }
        AntiAim.Desync.Settings = {
            Enabled = false,
            Mode = "Default",
            Method = "CFrame",
            X = 5, Y = 5, Z = 5,
            Random = false,
            UpdateInterval = 0.05,
            OldPosDelayEnabled = true,
            OldPosDelay = 0.5,
            VoidDepth = -1000,
            InPlayerOffset = 2,
            RefreshOnShot = false,
            RandomRotate = false,
        }
        AB.Settings = {
            Enabled        = false,
            Mode           = "Speed",
            Preset         = "None",
            CustomId       = "",
            Speed          = 1,
            RandomInterval = 0.1,
            ApplyToServer  = true,
        }
        pcall(StopAnimationBreaker)

        AntiAim.Internal = {
            BodyLastUpdate = 0, BodyJitterTime = 0, BodyJitterOffset = 0,
            BodyGyro = nil, AlignOrientation = nil,
            Attachment = nil, AngularVelocity = nil,
            CurrentMotor = nil, OriginalC0 = nil,
        }
        AntiAim.Desync.Internal.SavedCFrame     = nil
        AntiAim.Desync.Internal.RealCFrame      = nil
        AntiAim.Desync.Internal.RealVelocity    = nil
        AntiAim.Desync.Internal.RealRotVelocity = nil
        AntiAim.Desync.Internal.OldPosTimer     = 0
        AntiAim.Desync.Internal.PendingRefresh  = false
        AntiAim.Desync.Internal.RotAcc          = 0
        AntiAim.Desync.Internal.NetworkClaimed  = false
        CleanupAntiAim()
        StopDesync()
    end,

    SaveOldPosition = function()
        local hrp = GetCurrentHRP()
        if hrp then
            AntiAim.Desync.Internal.SavedCFrame    = hrp.CFrame
            AntiAim.Desync.Internal.OldPosTimer    = 0
            AntiAim.Desync.Internal.PendingRefresh = false
            return true
        end
        return false
    end,

    RestorePlayer = function()
        local hrp = GetCurrentHRP()
        local realCF = AntiAim.Desync.Internal.RealCFrame
        if hrp and realCF then
            pcall(function() hrp.CFrame = realCF end)
        end
    end,
}

AntiAim.StartDesync    = StartDesync
AntiAim.StopDesync     = StopDesync
AntiAim.CleanupAntiAim = CleanupAntiAim

AntiAim.StartAnimationBreaker = function() AB.Settings.Enabled = true end
AntiAim.StopAnimationBreaker  = StopAnimationBreaker
AntiAim.ReloadAnimationPreset = ReloadAnimationPreset
AntiAim.ApplyAnimationPreset  = AB.Functions.ApplyPreset
AntiAim.AnimationPresets      = AB.AnimationPresets

--// ===========================================================================
--// UI — Tab "Anti-Aim"
--// ===========================================================================
local Window = getgenv().airhubUI_Window
if not Window then
    warn("[AirHub] 03_antiaim: airhubUI Window missing — Anti-Aim tab not created")
    return
end

--// ---------------------------------------------------------------------------
--// Localization injection (RU + EN) — compatible with airhubUI.L
--// ---------------------------------------------------------------------------
do
    local UI = getgenv().airhubUI
    if UI and UI.L and UI.L.en and UI.L.ru then
        local en = {
            -- sections
            aa_body = "Body (Server)",
            aa_anim = "Animation Breaker",
            aa_desync = "Desync (Client)",
            -- body
            aa_enabled = "Enabled",
            aa_mode = "Mode",
            aa_method = "Method",
            aa_reference = "Reference",
            aa_yaw = "Yaw",
            aa_amount = "Amount (any number)",
            aa_speed = "Speed (any number)",
            aa_ignore_moving = "Ignore when moving",
            aa_move_threshold = "Move speed threshold",
            -- animation breaker
            aa_anim_enabled = "Enabled",
            aa_anim_preset = "Animation",
            aa_anim_custom_id = "Custom ID (rbxassetid://...)",
            aa_anim_mode = "Mode",
            aa_anim_speed = "Speed (neg = reverse, 0 = freeze)",
            aa_anim_interval = "Random Interval (s) [RandomFrames]",
            aa_anim_apply_server = "Apply to Server (SetNetworkOwner)",
            aa_anim_reload = "Reload",
            aa_anim_stop = "Stop",
            -- desync
            aa_desync_enabled = "Enabled",
            aa_desync_mode = "Mode",
            aa_desync_method = "Method",
            aa_desync_random_rotate = "Random Rotate (pitch/yaw/roll)",
            aa_desync_x = "X",
            aa_desync_y = "Y",
            aa_desync_z = "Z",
            aa_desync_random = "Random (X/Y/Z = max range)",
            aa_desync_interval = "Update Interval",
            aa_desync_oldpos_enabled = "OldPosition Delay Enabled",
            aa_desync_oldpos_delay = "OldPosition Delay (s)",
            aa_desync_void = "Void Depth (Y)",
            aa_desync_inplayer = "InPlayer Offset (studs)",
            aa_desync_refresh_shot = "Refresh position on shot",
            aa_desync_save = "Save Current Position",

            -- tooltips
            tt_aa_enabled = "Master switch for body anti-aim",
            tt_aa_mode = "Static = fixed angle | Spin = continuous rotation | Jitter = random angle | Sway = sinusoidal oscillation",
            tt_aa_method = "CFrame = direct write | BodyGyro = physics body | Motor6D = neck/waist C0 | AlignOrientation = constraint | AngularVelocity = spin force",
            tt_aa_reference = "Camera = relative to look | Movement = relative to velocity | Player = relative to HRP look",
            tt_aa_yaw = "Base yaw offset in degrees (-180 to 180)",
            tt_aa_amount = "Amplitude for Jitter/Sway/Static (in degrees)",
            tt_aa_speed = "Spin speed / Jitter frequency / Sway frequency",
            tt_aa_ignore_moving = "Skip anti-aim while your character is moving",
            tt_aa_move_threshold = "Velocity magnitude above which movement counts as 'moving'",
            tt_aa_anim_enabled = "Master switch for Animation Breaker",
            tt_aa_anim_preset = "Choose a preset animation or 'Custom'",
            tt_aa_anim_custom_id = "Only used when preset = Custom. Paste rbxassetid://NUMBER",
            tt_aa_anim_mode = "Speed = adjust playback speed | RandomFrames = freeze + jump to random frame",
            tt_aa_anim_speed = "Speed multiplier (negative = reverse, 0 = freeze)",
            tt_aa_anim_interval = "How often RandomFrames jumps (seconds)",
            tt_aa_anim_apply_server = "SetNetworkOwner(LocalPlayer) on HRP so animation replicates",
            tt_aa_anim_reload = "Re-load the selected animation",
            tt_aa_anim_stop = "Stop and reset all animation speeds",
            tt_aa_desync_enabled = "Master switch for desync",
            tt_aa_desync_mode = "Default = positional offset | OldPosition = lag position | Void = under map | InPlayer = inside nearest player",
            tt_aa_desync_method = "How the offset is applied (CFrame/Position/Velocity/Motor6D/HipHeight/Network)",
            tt_aa_desync_random_rotate = "Also apply random pitch/yaw/roll rotations",
            tt_aa_desync_x = "X offset magnitude",
            tt_aa_desync_y = "Y offset magnitude",
            tt_aa_desync_z = "Z offset magnitude",
            tt_aa_desync_random = "Randomize offset within X/Y/Z each update",
            tt_aa_desync_interval = "How often the offset changes (seconds)",
            tt_aa_desync_oldpos_enabled = "Refresh the saved OldPosition every N seconds",
            tt_aa_desync_oldpos_delay = "Delay between OldPosition snapshots",
            tt_aa_desync_void = "Y coordinate for Void mode",
            tt_aa_desync_inplayer = "Forward offset from nearest player when InPlayer mode",
            tt_aa_desync_refresh_shot = "Refresh saved position right before shooting",
            tt_aa_desync_save = "Manually save current position for OldPosition mode",
        }
        local ru = {
            -- sections
            aa_body = "Тело (сервер)",
            aa_anim = "Ломатель анимаций",
            aa_desync = "Десинк (клиент)",
            -- body
            aa_enabled = "Включено",
            aa_mode = "Режим",
            aa_method = "Метод",
            aa_reference = "Ориентация",
            aa_yaw = "Рыскание (Yaw)",
            aa_amount = "Амплитуда (любое число)",
            aa_speed = "Скорость (любое число)",
            aa_ignore_moving = "Игнорировать при движении",
            aa_move_threshold = "Порог скорости движения",
            -- animation breaker
            aa_anim_enabled = "Включено",
            aa_anim_preset = "Анимация",
            aa_anim_custom_id = "Свой ID (rbxassetid://...)",
            aa_anim_mode = "Режим",
            aa_anim_speed = "Скорость (отриц. = реверс, 0 = стоп)",
            aa_anim_interval = "Случайный интервал (с) [RandomFrames]",
            aa_anim_apply_server = "Применять на сервере (SetNetworkOwner)",
            aa_anim_reload = "Перезагрузить",
            aa_anim_stop = "Остановить",
            -- desync
            aa_desync_enabled = "Включено",
            aa_desync_mode = "Режим",
            aa_desync_method = "Метод",
            aa_desync_random_rotate = "Случайный поворот (pitch/yaw/roll)",
            aa_desync_x = "X",
            aa_desync_y = "Y",
            aa_desync_z = "Z",
            aa_desync_random = "Случайно (X/Y/Z = макс. диапазон)",
            aa_desync_interval = "Интервал обновления",
            aa_desync_oldpos_enabled = "Задержка OldPosition включена",
            aa_desync_oldpos_delay = "Задержка OldPosition (с)",
            aa_desync_void = "Глубина пустоты (Y)",
            aa_desync_inplayer = "Смещение InPlayer (studs)",
            aa_desync_refresh_shot = "Обновлять позицию при выстреле",
            aa_desync_save = "Сохранить текущую позицию",

            -- tooltips
            tt_aa_enabled = "Главный выключатель анти-аима тела",
            tt_aa_mode = "Static = фикс. угол | Spin = непрерывное вращение | Jitter = случайный угол | Sway = синусоида",
            tt_aa_method = "CFrame = прямая запись | BodyGyro = физическое тело | Motor6D = neck/waist C0 | AlignOrientation = constraint | AngularVelocity = сила вращения",
            tt_aa_reference = "Camera = относительно взгляда | Movement = относительно скорости | Player = относительно HRP",
            tt_aa_yaw = "Базовое смещение рыскания в градусах (-180 до 180)",
            tt_aa_amount = "Амплитуда для Jitter/Sway/Static (в градусах)",
            tt_aa_speed = "Скорость вращения / частота Jitter / частота Sway",
            tt_aa_ignore_moving = "Пропускать анти-аим пока персонаж движется",
            tt_aa_move_threshold = "Порог скорости, выше которого движение считается 'движением'",
            tt_aa_anim_enabled = "Главный выключатель ломателя анимаций",
            tt_aa_anim_preset = "Выберите пресет анимации или 'Custom'",
            tt_aa_anim_custom_id = "Используется только при preset = Custom. Вставь rbxassetid://NUMBER",
            tt_aa_anim_mode = "Speed = менять скорость | RandomFrames = стоп + случайный кадр",
            tt_aa_anim_speed = "Множитель скорости (отрицательный = реверс, 0 = стоп)",
            tt_aa_anim_interval = "Как часто RandomFrames прыгает (секунды)",
            tt_aa_anim_apply_server = "SetNetworkOwner(LocalPlayer) на HRP, чтобы анимация реплицировалась",
            tt_aa_anim_reload = "Перезагрузить выбранную анимацию",
            tt_aa_anim_stop = "Остановить и сбросить скорости всех анимаций",
            tt_aa_desync_enabled = "Главный выключатель десинка",
            tt_aa_desync_mode = "Default = смещение позиции | OldPosition = лаг позиции | Void = под картой | InPlayer = внутри ближайшего игрока",
            tt_aa_desync_method = "Как применяется смещение (CFrame/Position/Velocity/Motor6D/HipHeight/Network)",
            tt_aa_desync_random_rotate = "Также применять случайные повороты pitch/yaw/roll",
            tt_aa_desync_x = "Амплитуда смещения по X",
            tt_aa_desync_y = "Амплитуда смещения по Y",
            tt_aa_desync_z = "Амплитуда смещения по Z",
            tt_aa_desync_random = "Рандомизировать смещение в пределах X/Y/Z при каждом обновлении",
            tt_aa_desync_interval = "Как часто меняется смещение (секунды)",
            tt_aa_desync_oldpos_enabled = "Обновлять сохранённую OldPosition каждые N секунд",
            tt_aa_desync_oldpos_delay = "Задержка между снимками OldPosition",
            tt_aa_desync_void = "Координата Y для режима Void",
            tt_aa_desync_inplayer = "Смещение вперёд от ближайшего игрока в режиме InPlayer",
            tt_aa_desync_refresh_shot = "Обновлять сохранённую позицию прямо перед выстрелом",
            tt_aa_desync_save = "Вручную сохранить текущую позицию для режима OldPosition",
        }
        for k, v in pairs(en) do UI.L.en[k] = v end
        for k, v in pairs(ru) do UI.L.ru[k] = v end
        if UI.RefreshTheme then pcall(UI.RefreshTheme) end
    end
end

H._UI = H._UI or {}
local AntiTab = Window:AddTab({ Name = "Anti-Aim", Icon = ">" })
H._UI.AntiTab = AntiTab

local relAnimPreset  = AntiAim.ReloadAnimationPreset
local stopAnimBreaker = AntiAim.StopAnimationBreaker
local applyAnimPreset = AntiAim.ApplyAnimationPreset

-- setters
local function setBody(k, v) AntiAim.Settings.Body[k] = v end
local function setDesync(k, v) AntiAim.Desync.Settings[k] = v end
local function setAB(k, v) AB.Settings[k] = v end

local aaModes      = { "Static", "Spin", "Jitter", "Sway" }
local refModes     = { "Camera", "Movement", "Player" }
local aaMethods    = { "CFrame", "BodyGyro", "Motor6D", "AlignOrientation", "AngularVelocity" }
local desyncModes  = { "Default", "OldPosition", "Void", "InPlayer" }
local desyncMethods = { "CFrame", "Position", "Velocity", "Motor6D", "HipHeight", "Network" }
local animModeList = { "Speed", "RandomFrames" }
local animPresetList = {
    "None",
    "Custom",
    "Tornado",
    "AntiAim",
    "Moving AntiAim",
    "Default R15 Idle",
    "Default R15 Walk",
    "Default R15 Run",
    "Default R15 Jump",
    "Default R15 Fall",
    "Default R6 Idle",
    "Default R6 Walk",
    "Default R6 Run",
    "Default R6 Jump",
    "Default R6 Fall",
    "Zombie Idle",
    "Zombie Walk",
    "Zombie Run",
    "Zombie Jump",
    "Ninja Idle",
    "Ninja Run",
    "Pirate Idle",
    "Pirate Run",
    "Robot Idle",
    "Toy Idle",
    "Levitation Idle",
}

--// -------- LEFT: Body (Server) --------
local aaMain = AntiTab:CreateSection({ Name = "aa_body" })
aaMain:AddToggle({ Name = "aa_enabled", Value = AntiAim.Settings.Enabled,
    Callback = function(v) AntiAim.Settings.Enabled = v end,
    Tooltip = "tt_aa_enabled" })
aaMain:AddDropdown({ Name = "aa_mode", Value = AntiAim.Settings.Mode, List = aaModes,
    Callback = function(v) AntiAim.Settings.Mode = v end,
    Tooltip = "tt_aa_mode" })
aaMain:AddDropdown({ Name = "aa_method", Value = AntiAim.Settings.Method, List = aaMethods,
    Callback = function(v) AntiAim.Settings.Method = v end,
    Tooltip = "tt_aa_method" })
aaMain:AddDropdown({ Name = "aa_reference", Value = AntiAim.Settings.Body.Reference, List = refModes,
    Callback = function(v) setBody("Reference", v) end,
    Tooltip = "tt_aa_reference" })
aaMain:AddSlider({ Name = "aa_yaw", Value = AntiAim.Settings.Body.Yaw,
    Min = -180, Max = 180,
    Callback = function(v) setBody("Yaw", v) end,
    Tooltip = "tt_aa_yaw" })
aaMain:AddInput({ Name = "aa_amount",
    Value = tostring(AntiAim.Settings.Body.Amount),
    Callback = function(v)
        local n = tonumber(v)
        if n then setBody("Amount", n) end
    end,
    Tooltip = "tt_aa_amount" })
aaMain:AddInput({ Name = "aa_speed",
    Value = tostring(AntiAim.Settings.Body.Speed),
    Callback = function(v)
        local n = tonumber(v)
        if n then setBody("Speed", n) end
    end,
    Tooltip = "tt_aa_speed" })
aaMain:AddToggle({ Name = "aa_ignore_moving",
    Value = AntiAim.Settings.Body.IgnoreMoving,
    Callback = function(v) setBody("IgnoreMoving", v) end,
    Tooltip = "tt_aa_ignore_moving" })
aaMain:AddSlider({ Name = "aa_move_threshold",
    Value = AntiAim.Settings.Body.MoveSpeedThreshold,
    Min = 0.1, Max = 5, Decimals = 2,
    Callback = function(v) setBody("MoveSpeedThreshold", v) end,
    Tooltip = "tt_aa_move_threshold" })

--// -------- LEFT: Animation Breaker --------
local animSec = AntiTab:CreateSection({ Name = "aa_anim" })
animSec:AddToggle({ Name = "aa_anim_enabled", Value = AB.Settings.Enabled,
    Callback = function(v)
        setAB("Enabled", v)
        if not v then pcall(stopAnimBreaker) end
    end,
    Tooltip = "tt_aa_anim_enabled" })
animSec:AddDropdown({ Name = "aa_anim_preset", Value = AB.Settings.Preset or "None",
    List = animPresetList,
    Callback = function(v)
        setAB("Preset", v)
        pcall(applyAnimPreset, v)
    end,
    Tooltip = "tt_aa_anim_preset" })
animSec:AddInput({ Name = "aa_anim_custom_id",
    Value = AB.Settings.CustomId or "",
    Callback = function(v)
        setAB("CustomId", v)
        if AB.Settings.Preset == "Custom" then pcall(relAnimPreset) end
    end,
    Tooltip = "tt_aa_anim_custom_id" })
animSec:AddDropdown({ Name = "aa_anim_mode", Value = AB.Settings.Mode or "Speed",
    List = animModeList,
    Callback = function(v) setAB("Mode", v) end,
    Tooltip = "tt_aa_anim_mode" })
animSec:AddInput({ Name = "aa_anim_speed",
    Value = tostring(AB.Settings.Speed or 1),
    Callback = function(v)
        local n = tonumber(v)
        if n then setAB("Speed", n) end
    end,
    Tooltip = "tt_aa_anim_speed" })
animSec:AddSlider({ Name = "aa_anim_interval",
    Value = AB.Settings.RandomInterval or 0.1,
    Min = 0.02, Max = 1, Decimals = 2,
    Callback = function(v) setAB("RandomInterval", v) end,
    Tooltip = "tt_aa_anim_interval" })
animSec:AddToggle({ Name = "aa_anim_apply_server",
    Value = AB.Settings.ApplyToServer ~= false,
    Callback = function(v) setAB("ApplyToServer", v) end,
    Tooltip = "tt_aa_anim_apply_server" })
animSec:AddButton({ Name = "aa_anim_reload",
    Callback = function()
        pcall(relAnimPreset)
        if H.Util and H.Util.ShowError then
            H.Util.ShowError("Animation reloaded")
        end
    end,
    Tooltip = "tt_aa_anim_reload" })
animSec:AddButton({ Name = "aa_anim_stop",
    Callback = function()
        pcall(stopAnimBreaker)
        AB.Settings.Enabled = false
    end,
    Tooltip = "tt_aa_anim_stop" })

--// -------- RIGHT: Desync (Client) --------
local desyncSec = AntiTab:CreateSection({ Name = "aa_desync", Side = "Right" })
desyncSec:AddToggle({ Name = "aa_desync_enabled", Value = AntiAim.Desync.Settings.Enabled,
    Callback = function(v)
        AntiAim.Desync.Settings.Enabled = v
        if v then StartDesync() else StopDesync() end
    end,
    Tooltip = "tt_aa_desync_enabled" })
desyncSec:AddDropdown({ Name = "aa_desync_mode",
    Value = AntiAim.Desync.Settings.Mode or "Default",
    List = desyncModes,
    Callback = function(v)
        setDesync("Mode", v)
        if AntiAim.Desync.Settings.Enabled then
            StopDesync(); task.wait(0.05); StartDesync()
        end
    end,
    Tooltip = "tt_aa_desync_mode" })
desyncSec:AddDropdown({ Name = "aa_desync_method",
    Value = AntiAim.Desync.Settings.Method or "CFrame",
    List = desyncMethods,
    Callback = function(v)
        setDesync("Method", v)
        if AntiAim.Desync.Settings.Enabled then
            StopDesync(); task.wait(0.05); StartDesync()
        end
    end,
    Tooltip = "tt_aa_desync_method" })
desyncSec:AddToggle({ Name = "aa_desync_random_rotate",
    Value = AntiAim.Desync.Settings.RandomRotate or false,
    Callback = function(v) setDesync("RandomRotate", v) end,
    Tooltip = "tt_aa_desync_random_rotate" })
desyncSec:AddInput({ Name = "aa_desync_x",
    Value = tostring(AntiAim.Desync.Settings.X or 5),
    Callback = function(v)
        local n = tonumber(v)
        if n then setDesync("X", n) end
    end,
    Tooltip = "tt_aa_desync_x" })
desyncSec:AddInput({ Name = "aa_desync_y",
    Value = tostring(AntiAim.Desync.Settings.Y or 5),
    Callback = function(v)
        local n = tonumber(v)
        if n then setDesync("Y", n) end
    end,
    Tooltip = "tt_aa_desync_y" })
desyncSec:AddInput({ Name = "aa_desync_z",
    Value = tostring(AntiAim.Desync.Settings.Z or 5),
    Callback = function(v)
        local n = tonumber(v)
        if n then setDesync("Z", n) end
    end,
    Tooltip = "tt_aa_desync_z" })
desyncSec:AddToggle({ Name = "aa_desync_random",
    Value = AntiAim.Desync.Settings.Random or false,
    Callback = function(v) setDesync("Random", v) end,
    Tooltip = "tt_aa_desync_random" })
desyncSec:AddSlider({ Name = "aa_desync_interval",
    Value = AntiAim.Desync.Settings.UpdateInterval or 0.05,
    Min = 0.01, Max = 1, Decimals = 2,
    Callback = function(v) setDesync("UpdateInterval", v) end,
    Tooltip = "tt_aa_desync_interval" })
desyncSec:AddToggle({ Name = "aa_desync_oldpos_enabled",
    Value = AntiAim.Desync.Settings.OldPosDelayEnabled ~= false,
    Callback = function(v) setDesync("OldPosDelayEnabled", v) end,
    Tooltip = "tt_aa_desync_oldpos_enabled" })
desyncSec:AddSlider({ Name = "aa_desync_oldpos_delay",
    Value = AntiAim.Desync.Settings.OldPosDelay or 0.5,
    Min = 0.01, Max = 5, Decimals = 2,
    Callback = function(v) setDesync("OldPosDelay", v) end,
    Tooltip = "tt_aa_desync_oldpos_delay" })
desyncSec:AddSlider({ Name = "aa_desync_void",
    Value = AntiAim.Desync.Settings.VoidDepth or -1000,
    Min = -5000, Max = -100,
    Callback = function(v) setDesync("VoidDepth", v) end,
    Tooltip = "tt_aa_desync_void" })
desyncSec:AddSlider({ Name = "aa_desync_inplayer",
    Value = AntiAim.Desync.Settings.InPlayerOffset or 2,
    Min = 0, Max = 20, Decimals = 1,
    Callback = function(v) setDesync("InPlayerOffset", v) end,
    Tooltip = "tt_aa_desync_inplayer" })
desyncSec:AddToggle({ Name = "aa_desync_refresh_shot",
    Value = AntiAim.Desync.Settings.RefreshOnShot or false,
    Callback = function(v) setDesync("RefreshOnShot", v) end,
    Tooltip = "tt_aa_desync_refresh_shot" })
desyncSec:AddButton({ Name = "aa_desync_save",
    Callback = function()
        if AntiAim.Functions and AntiAim.Functions.SaveOldPosition then
            local ok = AntiAim.Functions.SaveOldPosition()
            if H.Util and H.Util.ShowError then
                H.Util.ShowError(ok and "Old position saved" or "No character")
            end
        end
    end,
    Tooltip = "tt_aa_desync_save" })

print("[AirHub] 03_antiaim: loaded OK (logic + airhubUI tab + RU localization + tooltips)")
