--// AirHub — 06_movement.lua (RU loc + tooltips + improved Fly Orbit)
--// Merged: Fly + Bhop + Speed + FastStop + AutoStrafer + Noclip + Spider
--// UI: Tab "Movement" in airhubUI
--//
--// CHANGES:
--//   FLY
--//     • CFrame mode now preserves rotation properly.
--//     • First-frame dt is clamped (no launch spike on enable).
--//     • Soft anti-fling clamp on extreme velocities.
--//     • Auto-reset on respawn.
--//   ORBIT
--//     • Phase-based with real OrbitAngle (angularSpeed = orbitSpeed / radius).
--//     • Velocity feed-forward of target motion → no lag on moving targets.
--//     • Deadzone near radius → no jitter.
--//     • Independent vertical correction.
--//     • New: AimCamera (look at target during orbit).
--//     • New: FeedForward gain (0 = old behavior, 1 = perfect, >1 = predictive).
--//   UI
--//     • Full RU/EN localization + tooltips for every control.

local H = getgenv().AirHub
if not H or not H._CoreLoaded then warn("[AirHub] 06_movement: core not loaded"); return end
if H._MovementLoaded then warn("[AirHub] 06_movement: already loaded"); return end
H._MovementLoaded = true

local Util                = H.Util
local RunService          = Util.RunService
local UserInputService    = Util.UserInputService
local VirtualInputManager = Util.VirtualInputManager
local LocalPlayer         = Util.LocalPlayer
local Track               = Util.Track
local HandleError         = Util.HandleError
local SafeKeyCode         = Util.SafeKeyCode
local RAY_FILTER          = Util.RAY_FILTER

-- ============================================================================
-- FLY
-- ============================================================================
H.Fly = {
    Settings = {
        Enabled    = false, ToggleKey = "F", Toggle = false,
        Method     = "BodyVelocity", Speed = 30, UpSpeed = 20,
        Smoothness = 0.5, UseKeys = true,
        TargetOrbit = {
            Enabled = false,
            OrbitSpeed = 20, Radius = 15, Height = 0,
            Correction = 3, VerticalCorrection = 3,
            Clockwise = true, FallbackToFly = true,
            FeedForward = 1.0,     -- NEW
            Deadzone = 0.3,         -- NEW
            AimCamera = true,       -- NEW
        },
    },
    Internal = {
        BodyVelocity = nil, LinearVelocity = nil, Attachment = nil,
        Active = false, LastUpdate = 0, OrbitAngle = 0, LastCFrameTick = 0,
        OrbitTargetChar = nil,
    },
}
local Fly = H.Fly

local function Fly_ClearInstances()
    if Fly.Internal.BodyVelocity then
        pcall(function() Fly.Internal.BodyVelocity:Destroy() end)
        Fly.Internal.BodyVelocity = nil
    end
    if Fly.Internal.LinearVelocity then
        pcall(function() Fly.Internal.LinearVelocity:Destroy() end)
        Fly.Internal.LinearVelocity = nil
    end
    if Fly.Internal.Attachment then
        pcall(function() Fly.Internal.Attachment:Destroy() end)
        Fly.Internal.Attachment = nil
    end
end

local function Fly_GetHRP()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function Fly_EnsureInstance(hrp)
    local method = Fly.Settings.Method
    if method == "BodyVelocity" then
        if Fly.Internal.LinearVelocity or Fly.Internal.Attachment then Fly_ClearInstances() end
        if not Fly.Internal.BodyVelocity or not Fly.Internal.BodyVelocity.Parent then
            local bv = Instance.new("BodyVelocity")
            bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            bv.Velocity = Vector3.new(0, 0, 0)
            bv.Parent = hrp
            Fly.Internal.BodyVelocity = bv
        end
    elseif method == "LinearVelocity" then
        if Fly.Internal.BodyVelocity then Fly_ClearInstances() end
        if not Fly.Internal.Attachment or not Fly.Internal.Attachment.Parent then
            local att = Instance.new("Attachment")
            att.Parent = hrp
            Fly.Internal.Attachment = att
            Fly.Internal.LinearVelocity = nil
        end
        if not Fly.Internal.LinearVelocity or not Fly.Internal.LinearVelocity.Parent then
            local lv = Instance.new("LinearVelocity")
            lv.MaxForce = 9e9
            lv.VectorVelocity = Vector3.new(0, 0, 0)
            lv.Attachment0 = Fly.Internal.Attachment
            lv.Parent = hrp
            Fly.Internal.LinearVelocity = lv
        end
    else
        Fly_ClearInstances()
    end
end

local function Fly_GetMoveDir()
    local moveDir = Vector3.new(0, 0, 0)
    if not Fly.Settings.UseKeys then return moveDir end
    local cam = workspace.CurrentCamera
    if not cam then return moveDir end
    local forward = cam.CFrame.LookVector
    local right = cam.CFrame.RightVector
    local up = Vector3.new(0, 1, 0)
    local forwardFlat = Vector3.new(forward.X, 0, forward.Z)
    local rightFlat = Vector3.new(right.X, 0, right.Z)
    if forwardFlat.Magnitude > 0.001 then forwardFlat = forwardFlat.Unit end
    if rightFlat.Magnitude > 0.001 then rightFlat = rightFlat.Unit end
    local w = UserInputService:IsKeyDown(Enum.KeyCode.W)
    local s = UserInputService:IsKeyDown(Enum.KeyCode.S)
    local a = UserInputService:IsKeyDown(Enum.KeyCode.A)
    local d = UserInputService:IsKeyDown(Enum.KeyCode.D)
    local sp = UserInputService:IsKeyDown(Enum.KeyCode.Space)
    local ct = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
        or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
    if w then moveDir = moveDir + forwardFlat end
    if s then moveDir = moveDir - forwardFlat end
    if a then moveDir = moveDir - rightFlat end
    if d then moveDir = moveDir + rightFlat end
    if sp then moveDir = moveDir + up end
    if ct then moveDir = moveDir - up end
    if moveDir.Magnitude > 0 then moveDir = moveDir.Unit end
    return moveDir
end

--// Возвращает (targetBasePos, targetVelocity) вокруг HRP цели (не Head)
local function Fly_GetAimbotTargetInfo()
    local A = H.Aimbot
    if not A then return nil, nil end
    local part = A.LockPartInstance
    if not part or not part.Parent then return nil, nil end
    local char = part.Parent
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local basePos = hrp and hrp.Position or part.Position
    local vel
    if hrp then
        vel = hrp.AssemblyLinearVelocity or hrp.Velocity or Vector3.zero
    else
        vel = part.AssemblyLinearVelocity or part.Velocity or Vector3.zero
    end
    return basePos, vel, char
end

local function Fly_ClampVec(v, maxLen)
    local m = v.Magnitude
    if m > maxLen and m > 0.0001 then return v * (maxLen / m) end
    return v
end

--// NEW phase-based orbit with feed-forward and deadzone
local function Fly_ComputeOrbitVelocity(hrp, targetPos, targetVel, dt)
    local O = Fly.Settings.TargetOrbit
    local orbitSpeed = math.max(0.1, tonumber(O.OrbitSpeed) or 20)
    local radius     = math.max(1,   tonumber(O.Radius)     or 15)
    local height     = tonumber(O.Height)    or 0
    local corr       = math.max(0,   tonumber(O.Correction) or 3)
    local vCorr      = math.max(0,   tonumber(O.VerticalCorrection) or 3)
    local clockwise  = O.Clockwise ~= false
    local ffGain     = math.max(0,   tonumber(O.FeedForward) or 1.0)
    local deadzone   = math.max(0,   tonumber(O.Deadzone) or 0.3)

    -- Advance phase (angular speed = linear / radius)
    local angularSpeed = orbitSpeed / radius
    if not clockwise then angularSpeed = -angularSpeed end
    Fly.Internal.OrbitAngle = ((Fly.Internal.OrbitAngle or 0) + angularSpeed * dt) % (math.pi * 2)

    -- Desired position on orbit
    local angle = Fly.Internal.OrbitAngle
    local offset = Vector3.new(
        math.cos(angle) * radius,
        height,
        math.sin(angle) * radius
    )
    local desiredPos = targetPos + offset

    -- Feed-forward of target velocity
    local ff = (targetVel or Vector3.zero) * ffGain

    -- PD corrections
    local err = desiredPos - hrp.Position
    local horizErr = Vector3.new(err.X, 0, err.Z)
    local vertErr  = err.Y

    local horizCorr = Vector3.zero
    if horizErr.Magnitude > deadzone then
        horizCorr = horizErr * corr
    end
    local vertCorr = vertErr * vCorr

    local desiredVel = horizCorr + Vector3.new(0, vertCorr, 0) + ff

    -- Clamp total magnitude
    local maxSpeed = orbitSpeed * 2 + ff.Magnitude
    local mag = desiredVel.Magnitude
    if mag > maxSpeed and mag > 0.001 then
        desiredVel = desiredVel.Unit * maxSpeed
    end
    return desiredVel
end

local function Fly_ApplyVelocity(hrp, vel, dt)
    local S = Fly.Settings
    local I = Fly.Internal
    if S.Method == "BodyVelocity" then
        if I.BodyVelocity then
            local alpha = math.clamp(S.Smoothness, 0.01, 1)
            I.BodyVelocity.Velocity = I.BodyVelocity.Velocity:Lerp(vel, alpha)
        end
    elseif S.Method == "LinearVelocity" then
        if I.LinearVelocity then
            local alpha = math.clamp(S.Smoothness, 0.01, 1)
            I.LinearVelocity.VectorVelocity = I.LinearVelocity.VectorVelocity:Lerp(vel, alpha)
        end
    elseif S.Method == "Velocity" then
        hrp.Velocity = vel
    elseif S.Method == "CFrame" then
        -- FIX: preserve rotation properly
        local newPos = hrp.Position + (vel * dt)
        local rot = hrp.CFrame - hrp.CFrame.Position
        hrp.CFrame = CFrame.new(newPos) * rot
    end
end

local function Fly_Update()
    if H.ShuttingDown then return end
    local S = Fly.Settings
    local I = Fly.Internal
    if not S.Enabled or not I.Active then
        if I.BodyVelocity or I.LinearVelocity or I.Attachment then Fly_ClearInstances() end
        if I.Active and not S.Enabled then I.Active = false end
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.PlatformStand then hum.PlatformStand = false end
        end
        return
    end
    local hrp = Fly_GetHRP()
    if not hrp then Fly_ClearInstances() return end
    Fly_EnsureInstance(hrp)

    local now = tick()
    local dt = now - (I.LastUpdate or now)
    if dt <= 0 or dt > 0.5 then dt = 1 / 60 end
    I.LastUpdate = now

    local targetVel = nil
    local O = S.TargetOrbit
    local targetPos, targetVelWorld, targetChar = nil, nil, nil
    if O and O.Enabled then
        targetPos, targetVelWorld, targetChar = Fly_GetAimbotTargetInfo()
        if targetPos then
            targetVel = Fly_ComputeOrbitVelocity(hrp, targetPos, targetVelWorld, dt)
            I.OrbitTargetChar = targetChar
            -- Aim camera at target (optional)
            if O.AimCamera ~= false then
                local cam = workspace.CurrentCamera
                if cam and targetPos then
                    local look = CFrame.lookAt(cam.CFrame.Position, targetPos + Vector3.new(0, 1, 0))
                    cam.CFrame = cam.CFrame:Lerp(look, math.clamp(dt * 10, 0, 1))
                end
            end
        elseif not O.FallbackToFly then
            targetVel = Vector3.zero
        end
    end

    if targetVel == nil then
        local moveDir = Fly_GetMoveDir()
        if moveDir.Y ~= 0 then
            targetVel = Vector3.new(moveDir.X * S.Speed, moveDir.Y * S.UpSpeed, moveDir.Z * S.Speed)
        else
            targetVel = Vector3.new(moveDir.X * S.Speed, 0, moveDir.Z * S.Speed)
        end
    end

    Fly_ApplyVelocity(hrp, targetVel, dt)

    -- Soft anti-fling on absurd velocity
    if S.Method ~= "CFrame" then
        local v = hrp.AssemblyLinearVelocity or hrp.Velocity
        local maxV = math.max(S.Speed, S.UpSpeed) * 5 + 200
        if v and v.Magnitude > maxV then
            local clamped = v.Unit * maxV
            pcall(function() hrp.AssemblyLinearVelocity = clamped end)
            pcall(function() hrp.Velocity = clamped end)
        end
    end

    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health > 0 then hum.PlatformStand = true end
end

Track(RunService.RenderStepped:Connect(function() xpcall(Fly_Update, HandleError) end))

Track(UserInputService.InputBegan:Connect(function(inp)
    if UserInputService:GetFocusedTextBox() then return end
    if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if not Fly.Settings.Enabled then return end
    local kc = SafeKeyCode(Fly.Settings.ToggleKey)
    if not kc or inp.KeyCode ~= kc then return end
    if Fly.Settings.Toggle then
        Fly.Internal.Active = not Fly.Internal.Active
        if not Fly.Internal.Active then
            Fly_ClearInstances()
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum.PlatformStand = false end
            end
        end
    else
        Fly.Internal.Active = true
    end
end))

Track(UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
    local kc = SafeKeyCode(Fly.Settings.ToggleKey)
    if not kc or inp.KeyCode ~= kc then return end
    if not Fly.Settings.Toggle then
        Fly.Internal.Active = false
        Fly_ClearInstances()
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.PlatformStand = false end
        end
    end
end))

Track(LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.3)
    if H.ShuttingDown then return end
    Fly_ClearInstances()
    Fly.Internal.Active = false
    Fly.Internal.LastUpdate = 0
    Fly.Internal.OrbitAngle = 0
    Fly.Internal.OrbitTargetChar = nil
end))

Fly.Functions = {
    ResetSettings = function()
        Fly.Settings = {
            Enabled = false, ToggleKey = "F", Toggle = false, Method = "BodyVelocity",
            Speed = 30, UpSpeed = 20, Smoothness = 0.5, UseKeys = true,
            TargetOrbit = {
                Enabled = false, OrbitSpeed = 20, Radius = 15, Height = 0,
                Correction = 3, VerticalCorrection = 3, Clockwise = true,
                FallbackToFly = true, FeedForward = 1.0, Deadzone = 0.3, AimCamera = true,
            },
        }
        Fly_ClearInstances()
        Fly.Internal.Active = false
        Fly.Internal.LastUpdate = 0
        Fly.Internal.OrbitAngle = 0
        Fly.Internal.OrbitTargetChar = nil
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.PlatformStand = false end
        end
    end,
    ResetOrbitAngle = function()
        Fly.Internal.OrbitAngle = 0
    end,
}
Fly.ClearInstances = Fly_ClearInstances

-- ============================================================================
-- BHOP + SPIDER
-- ============================================================================
H.Bhop = {
    Settings = {
        Enabled = false,
        Mode        = "New",
        AutoJumpKey = "Space",
        BypassJump  = true,
        JumpCooldown= 0.05,
        AirBoost        = true,
        AirBoostDivisor = 5.9,
        BlockSpaceFromGame = true,
        SpaceReleasePulse  = false,
        Spider = {
            Enabled  = false,
            Mode     = "Default",
            Range    = 2.5,
            RayCount = 8,
            Pixelwalk = {
                DownRange    = 5.0, MaxWidth     = 0.6, SnapDistance = 4.0,
                StickPower   = 1.0, ForceRunning = true, CoyoteTime   = 0.15,
                MaxFallSpeed = 5.0, PredictTime  = 0.04, HeightOffset = 2.0,
                RequireFlat  = true,
            },
            Wallfucker = {
                Chance       = 0.5, WallRange    = 3.0, HoldY        = true,
                PushStrength = 0.0, RayCount     = 8,
            },
        },
    },
    Internal = {
        KeyHeld = false, LastJumpTime = 0, Active = false,
        SpiderTouching = false, WallNormal = nil,
        Pixelwalk_LastThin = 0, Pixelwalk_LastThinNormal = nil,
        HookInstalled = false, Humanoid = nil, PendingPulses = 0,
    },
}
local Bhop = H.Bhop

local function Bhop_InstallSpaceHook()
    if Bhop.Internal.HookInstalled then return end
    if not Bhop.Settings.BlockSpaceFromGame then return end

    local hm  = rawget(getfenv(), "hookmetamethod") or hookmetamethod
    local gnm = rawget(getfenv(), "getnamecallmethod") or getnamecallmethod
    if type(hm) ~= "function" or type(gnm) ~= "function" then return end

    local ok = pcall(function()
        local oldNamecall
        oldNamecall = hm(game, "__namecall", function(self, ...)
            local method = gnm()
            if method == "IsKeyDown" then
                local args = {...}
                local code = args[1]
                if code == Enum.KeyCode.Space
                   and Bhop.Settings.Enabled
                   and Bhop.Settings.BlockSpaceFromGame
                   and Bhop.Internal.KeyHeld then
                    return false
                end
            end
            return oldNamecall(self, ...)
        end)
    end)

    if ok then Bhop.Internal.HookInstalled = true end
end

local function Bhop_SpaceReleasePulse()
    if not Bhop.Settings.SpaceReleasePulse then return end
    if Bhop.Internal.HookInstalled then return end
    Bhop.Internal.PendingPulses = (Bhop.Internal.PendingPulses or 0) + 1
    if Bhop.Internal.PendingPulses > 4 then Bhop.Internal.PendingPulses = 4 end
    if VirtualInputManager then
        pcall(function()
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        end)
        return
    end
    local kr = rawget(getfenv(), "keyrelease")
    if type(kr) == "function" then pcall(function() kr(0x20) end) end
end

Track(UserInputService.InputBegan:Connect(function(inp)
    if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if UserInputService:GetFocusedTextBox() then return end
    if not Bhop.Settings.Enabled then return end
    local kc = SafeKeyCode(Bhop.Settings.AutoJumpKey)
    if kc and inp.KeyCode == kc then
        Bhop.Internal.KeyHeld = true
        Bhop_InstallSpaceHook()
    end
end))

Track(UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if (Bhop.Internal.PendingPulses or 0) > 0 then
        Bhop.Internal.PendingPulses = Bhop.Internal.PendingPulses - 1
        return
    end
    local kc = SafeKeyCode(Bhop.Settings.AutoJumpKey)
    if kc and inp.KeyCode == kc then
        Bhop.Internal.KeyHeld = false
    end
end))

Track(LocalPlayer.CharacterAdded:Connect(function()
    Bhop.Internal.KeyHeld = false
    Bhop.Internal.Active = false
    Bhop.Internal.SpiderTouching = false
    Bhop.Internal.WallNormal = nil
    Bhop.Internal.Pixelwalk_LastThin = 0
    Bhop.Internal.Pixelwalk_LastThinNormal = nil
    Bhop.Internal.Humanoid = nil
    Bhop.Internal.PendingPulses = 0
end))

local function Spider_DetectWall(char, hrp)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = { char }
    rayParams.FilterType = RAY_FILTER
    rayParams.IgnoreWater = true
    local range = Bhop.Settings.Spider.Range
    local rayCount = math.max(4, Bhop.Settings.Spider.RayCount or 8)
    local step = (math.pi * 2) / rayCount
    local heights = { -1.2, 0, 1.2 }
    for _, hOffset in ipairs(heights) do
        local origin = hrp.Position + Vector3.new(0, hOffset, 0)
        for i = 0, rayCount - 1 do
            local angle = i * step
            local dir = Vector3.new(math.cos(angle), 0, math.sin(angle))
            local result = workspace:Raycast(origin, dir * range, rayParams)
            if result and result.Instance and result.Instance.Collide then
                Bhop.Internal.WallNormal = result.Normal
                return true
            end
        end
    end
    Bhop.Internal.WallNormal = nil
    return false
end

local function Spider_Pixelwalk(char, hrp, hum)
    local P = Bhop.Settings.Spider.Pixelwalk or {}
    local I = Bhop.Internal
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = { char }
    rayParams.FilterType = RAY_FILTER
    rayParams.IgnoreWater = true

    local downRange    = P.DownRange    or 5.0
    local maxWidth     = P.MaxWidth     or 0.6
    local snapDistance = P.SnapDistance or 4.0
    local stickPower   = math.clamp(P.StickPower or 1.0, 0, 1)
    local coyoteTime   = P.CoyoteTime   or 0.15
    local maxFallSpeed = P.MaxFallSpeed or 5.0
    local predictTime  = P.PredictTime  or 0.04
    local heightOffset = P.HeightOffset or 2.0
    local requireFlat  = P.RequireFlat ~= false
    local forceRunning = P.ForceRunning ~= false

    local vel = hrp.Velocity
    local now = tick()

    local lookAhead = Vector3.new(vel.X, 0, vel.Z) * (predictTime * 2)
    local predicted = hrp.Position
        + Vector3.new(0, vel.Y * predictTime, 0)
        + lookAhead

    local origins = {
        hrp.Position,
        predicted,
        hrp.Position - Vector3.new(0, heightOffset, 0),
        hrp.Position + lookAhead,
    }

    local offsets = {
        Vector3.new(0,     0,  0),
        Vector3.new( 0.5,  0,  0),
        Vector3.new(-0.5,  0,  0),
        Vector3.new( 0,    0,  0.5),
        Vector3.new( 0,    0, -0.5),
        Vector3.new( 0.35, 0,  0.35),
        Vector3.new(-0.35, 0, -0.35),
        Vector3.new( 0.35, 0, -0.35),
        Vector3.new(-0.35, 0,  0.35),
    }

    local down = Vector3.new(0, -downRange, 0)
    local bestHit, bestThinHit = nil, nil
    local thinFound = false

    for _, origin in ipairs(origins) do
        for _, off in ipairs(offsets) do
            local r = workspace:Raycast(origin + off, down, rayParams)
            if r and r.Instance and r.Instance.CanCollide then
                local isFlat = r.Normal.Y >= 0.5
                if (not requireFlat) or isFlat then
                    local sz = r.Instance.Size
                    local minAxis = math.min(sz.X, sz.Z)
                    if minAxis <= maxWidth then
                        thinFound = true
                        if not bestThinHit or r.Distance < bestThinHit.Distance then
                            bestThinHit = r
                        end
                    end
                end
                if not bestHit or r.Distance < bestHit.Distance then
                    bestHit = r
                end
            end
        end
    end

    if thinFound then
        I.Pixelwalk_LastThin = now
        I.Pixelwalk_LastThinNormal = bestThinHit and bestThinHit.Normal or nil
    end
    local inCoyote = I.Pixelwalk_LastThin
        and (now - I.Pixelwalk_LastThin) < coyoteTime

    if not bestHit and not inCoyote then
        I.WallNormal = nil
        return false
    end

    if not thinFound and not inCoyote then
        if bestHit and bestHit.Distance > snapDistance then
            I.WallNormal = nil
            return false
        end
    end

    if vel.Y < 0 then
        local newY = vel.Y * (1 - stickPower)
        if math.abs(newY) < 0.05 then newY = 0 end
        hrp.Velocity = Vector3.new(vel.X, newY, vel.Z)
    end

    if not thinFound and not inCoyote and bestHit
       and bestHit.Distance <= snapDistance then
        local y = hrp.Velocity.Y
        if y < -maxFallSpeed then
            hrp.Velocity = Vector3.new(hrp.Velocity.X, -maxFallSpeed, hrp.Velocity.Z)
        end
    end

    if forceRunning and hum then
        pcall(function()
            local st = hum:GetState()
            if st == Enum.HumanoidStateType.Freefall
               or st == Enum.HumanoidStateType.FallingDown then
                hum:ChangeState(Enum.HumanoidStateType.Running)
            end
        end)
    end

    I.WallNormal = (bestThinHit and bestThinHit.Normal)
        or (bestHit and bestHit.Normal)
        or I.Pixelwalk_LastThinNormal
    return true
end

local function Spider_Wallfucker(char, hrp)
    local W = Bhop.Settings.Spider.Wallfucker or {}
    local chance   = math.clamp(W.Chance or 0.5, 0, 1)
    local wallRange= W.WallRange or 3.0
    local holdY    = W.HoldY ~= false
    local push     = W.PushStrength or 0
    local rayCount = math.max(4, W.RayCount or 8)

    if math.random() > chance then
        Bhop.Internal.WallNormal = nil
        return false
    end

    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = { char }
    rayParams.FilterType = RAY_FILTER
    rayParams.IgnoreWater = true

    local step = (math.pi * 2) / rayCount
    local bestNormal = nil
    for i = 0, rayCount - 1 do
        local angle = i * step
        local dir = Vector3.new(math.cos(angle), 0, math.sin(angle))
        local r = workspace:Raycast(hrp.Position, dir * wallRange, rayParams)
        if r and r.Instance and r.Instance.CanCollide then
            bestNormal = r.Normal
            break
        end
    end

    if not bestNormal then
        Bhop.Internal.WallNormal = nil
        return false
    end

    if holdY then
        local vel = hrp.Velocity
        if vel.Y < 0 or push > 0 then
            local targetY = vel.Y
            if vel.Y < 0 then targetY = 0 end
            if push > 0 then targetY = math.max(targetY, push) end
            hrp.Velocity = Vector3.new(vel.X, targetY, vel.Z)
        end
    end

    Bhop.Internal.WallNormal = bestNormal
    return true
end

local function Bhop_Tick()
    if H.ShuttingDown then return end
    local S = Bhop.Settings
    local I = Bhop.Internal
    if not S.Enabled then
        I.Active = false
        I.SpiderTouching = false
        I.WallNormal = nil
        I.Pixelwalk_LastThin = 0
        I.Pixelwalk_LastThinNormal = nil
        return
    end

    if not I.HookInstalled and S.BlockSpaceFromGame then
        Bhop_InstallSpaceHook()
    end

    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end
    if hum.Health <= 0 then return end

    I.Active = true
    I.Humanoid = hum
    I.SpiderTouching = false

    if S.Spider.Enabled then
        local smode = S.Spider.Mode or "Default"
        if smode == "Pixelwalk" then
            I.SpiderTouching = Spider_Pixelwalk(char, hrp, hum)
        elseif smode == "Wallfucker" then
            I.SpiderTouching = Spider_Wallfucker(char, hrp)
        else
            I.SpiderTouching = Spider_DetectWall(char, hrp)
        end
    end

    if not I.KeyHeld then return end

    local trigger = SafeKeyCode(S.AutoJumpKey)
    if trigger == Enum.KeyCode.Space then
        Bhop_SpaceReleasePulse()
    end

    local bmode = S.Mode or "New"
    if bmode == "New" then
        hum.Jump = not hum.Jump
        if S.AirBoost
           and hum:GetState() == Enum.HumanoidStateType.Freefall
           and hum.MoveDirection.Magnitude > 0 then
            local divisor = S.AirBoostDivisor or 5.9
            if divisor > 0 then
                pcall(function() char:TranslateBy(hum.MoveDirection / divisor) end)
            end
        end
    else
        local now = tick()
        if now - (I.LastJumpTime or 0) >= (S.JumpCooldown or 0.05) then
            local bypass = S.BypassJump
            if I.SpiderTouching then bypass = true end
            local isGround = hum.FloorMaterial ~= Enum.Material.Air
            if bypass or isGround then
                pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
                pcall(function() hum.Jump = true end)
                I.LastJumpTime = now
            end
        end
    end
end

Track(RunService.Heartbeat:Connect(function() xpcall(Bhop_Tick, HandleError) end))

Bhop.Functions = {
    ResetSettings = function()
        Bhop.Settings = {
            Enabled = false, Mode = "New", AutoJumpKey = "Space",
            BypassJump = true, JumpCooldown = 0.05,
            AirBoost = true, AirBoostDivisor = 5.9,
            BlockSpaceFromGame = true, SpaceReleasePulse = false,
            Spider = {
                Enabled = false, Mode = "Default", Range = 2.5, RayCount = 8,
                Pixelwalk = {
                    DownRange = 5.0, MaxWidth = 0.6, SnapDistance = 4.0,
                    StickPower = 1.0, ForceRunning = true, CoyoteTime = 0.15,
                    MaxFallSpeed = 5.0, PredictTime = 0.04, HeightOffset = 2.0,
                    RequireFlat = true,
                },
                Wallfucker = {
                    Chance = 0.5, WallRange = 3.0, HoldY = true,
                    PushStrength = 0.0, RayCount = 8,
                },
            },
        }
        Bhop.Internal = {
            KeyHeld = false, LastJumpTime = 0, Active = false,
            SpiderTouching = false, WallNormal = nil,
            Pixelwalk_LastThin = 0, Pixelwalk_LastThinNormal = nil,
            HookInstalled = false, Humanoid = nil, PendingPulses = 0,
        }
    end,
}

-- ============================================================================
-- SPEED
-- ============================================================================
H.Speed = {
    Settings = { Enabled = false, Method = "WalkSpeed", GroundSpeed = 30, AirSpeed = 30, UseAirSpeed = false, InAirOnly = false },
    Internal = { Active = false, OriginalWalkSpeed = 16, LastClock = 0 },
}
local Speed = H.Speed

local function Speed_IsGrounded(character)
    if not character then return false end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local hum = character:FindFirstChildOfClass("Humanoid")
    if hum and hum.FloorMaterial ~= Enum.Material.Air then return true end
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = { character }
    params.FilterType = RAY_FILTER
    return workspace:Raycast(hrp.Position, Vector3.new(0, -2.2, 0), params) ~= nil
end

local function Speed_GetMoveDirection()
    local char = LocalPlayer.Character
    if not char then return Vector3.new(0, 0, 0) end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return Vector3.new(0, 0, 0) end
    local w = UserInputService:IsKeyDown(Enum.KeyCode.W)
    local s = UserInputService:IsKeyDown(Enum.KeyCode.S)
    local a = UserInputService:IsKeyDown(Enum.KeyCode.A)
    local d = UserInputService:IsKeyDown(Enum.KeyCode.D)
    if not (w or s or a or d) then return Vector3.new(0, 0, 0) end
    local cam = workspace.CurrentCamera
    if not cam then return Vector3.new(0, 0, 0) end
    local camForward = cam.CFrame.LookVector
    local camRight = cam.CFrame.RightVector
    local forward = Vector3.new(camForward.X, 0, camForward.Z).Unit
    local right = Vector3.new(camRight.X, 0, camRight.Z).Unit
    local dir = Vector3.new(0, 0, 0)
    if w then dir = dir + forward end
    if s then dir = dir - forward end
    if a then dir = dir - right end
    if d then dir = dir + right end
    if dir.Magnitude > 0 then dir = dir.Unit end
    return dir
end

task.spawn(function()
    Speed.Internal.LastClock = os.clock()
    while not H.ShuttingDown and task.wait(0.016) do
        local nowClock = os.clock()
        local dt = nowClock - Speed.Internal.LastClock
        Speed.Internal.LastClock = nowClock
        if dt <= 0 or dt > 0.5 then dt = 0.016 end
        if not Speed.Settings.Enabled then
            if Speed.Internal.Active then
                Speed.Internal.Active = false
                local char = LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum and hum.WalkSpeed ~= Speed.Internal.OriginalWalkSpeed then
                        hum.WalkSpeed = Speed.Internal.OriginalWalkSpeed
                    end
                end
            end
            continue
        end
        local char = LocalPlayer.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp then continue end
        if not Speed.Internal.Active then
            Speed.Internal.OriginalWalkSpeed = hum.WalkSpeed
            Speed.Internal.Active = true
        end
        local method = Speed.Settings.Method
        local grounded = Speed_IsGrounded(char)
        local spd
        if Speed.Settings.UseAirSpeed and not grounded then
            spd = Speed.Settings.AirSpeed
        else
            spd = Speed.Settings.GroundSpeed
        end
        if Speed.Settings.InAirOnly then
            if grounded then
                if method == "WalkSpeed" and hum.WalkSpeed ~= Speed.Internal.OriginalWalkSpeed then
                    hum.WalkSpeed = Speed.Internal.OriginalWalkSpeed
                end
                continue
            end
        end
        if method == "WalkSpeed" then
            if hum.WalkSpeed ~= spd then hum.WalkSpeed = spd end
        elseif method == "CFrame" then
            local dir = Speed_GetMoveDirection()
            if dir.Magnitude > 0 then hrp.CFrame = hrp.CFrame + dir * spd * dt end
        elseif method == "Velocity" then
            local dir = Speed_GetMoveDirection()
            if dir.Magnitude > 0 then
                hrp.Velocity = Vector3.new(dir.X * spd, hrp.Velocity.Y, dir.Z * spd)
            end
        end
    end
end)

Speed.Functions = {
    ResetSettings = function()
        Speed.Settings = { Enabled = false, Method = "WalkSpeed", GroundSpeed = 30, AirSpeed = 30, UseAirSpeed = false, InAirOnly = false }
        Speed.Internal = { Active = false, OriginalWalkSpeed = 16, LastClock = 0 }
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.WalkSpeed ~= 16 then hum.WalkSpeed = 16 end
        end
    end,
}

-- ============================================================================
-- FASTSTOP
-- ============================================================================
H.FastStop = {
    Settings = { Enabled = false, StopY = false },
    Internal = { LastActive = false },
}
local FastStop = H.FastStop

local function FS_AnyMoveHeld()
    return UserInputService:IsKeyDown(Enum.KeyCode.W)
        or UserInputService:IsKeyDown(Enum.KeyCode.A)
        or UserInputService:IsKeyDown(Enum.KeyCode.S)
        or UserInputService:IsKeyDown(Enum.KeyCode.D)
end

task.spawn(function()
    while not H.ShuttingDown and task.wait(0.01) do
        if not FastStop.Settings.Enabled then
            FastStop.Internal.LastActive = false
            continue
        end
        if FS_AnyMoveHeld() then
            FastStop.Internal.LastActive = false
            continue
        end
        local char = LocalPlayer.Character
        if not char then continue end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then continue end
        if hum.Health <= 0 then continue end
        if FastStop.Settings.StopY then
            hrp.Velocity = Vector3.new(0, 0, 0)
        else
            hrp.Velocity = Vector3.new(0, hrp.Velocity.Y, 0)
        end
        FastStop.Internal.LastActive = true
    end
end)

FastStop.Functions = {
    ResetSettings = function()
        FastStop.Settings = { Enabled = false, StopY = false }
        FastStop.Internal = { LastActive = false }
    end,
}

-- ============================================================================
-- AUTOSTRAFER
-- ============================================================================
H.AutoStrafer = {
    Settings = { Enabled = false, Mode = "Legit", Key = "Space", Toggle = false, Invert = false, SpamDelay = 0.05 },
    Internal = { Active = false, LastYaw = nil, KeyA = false, KeyD = false, SpamDir = -1, LastSpam = 0 },
}
local AutoStrafer = H.AutoStrafer

local function AS_IsTyping() return UserInputService:GetFocusedTextBox() ~= nil end
local function AS_GetCameraYaw()
    local cam = workspace.CurrentCamera
    if not cam then return 0 end
    local look = cam.CFrame.LookVector
    return math.atan2(look.X, look.Z)
end
local function AS_WrapAngle(d)
    while d > math.pi do d = d - math.pi * 2 end
    while d < -math.pi do d = d + math.pi * 2 end
    return d
end

local function AS_PressA()
    if AutoStrafer.Internal.KeyA then return end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then return end
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.A, false, game)
    AutoStrafer.Internal.KeyA = true
end
local function AS_ReleaseA()
    if not AutoStrafer.Internal.KeyA then return end
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.A, false, game)
    AutoStrafer.Internal.KeyA = false
end
local function AS_PressD()
    if AutoStrafer.Internal.KeyD then return end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then return end
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.D, false, game)
    AutoStrafer.Internal.KeyD = true
end
local function AS_ReleaseD()
    if not AutoStrafer.Internal.KeyD then return end
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.D, false, game)
    AutoStrafer.Internal.KeyD = false
end
local function AS_ReleaseAll() AS_ReleaseA(); AS_ReleaseD() end

local function AS_Update()
    if H.ShuttingDown then return end
    local S = AutoStrafer.Settings
    local I = AutoStrafer.Internal
    if not S.Enabled or not I.Active then AS_ReleaseAll() return end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then AS_ReleaseAll() return end
    if S.Mode == "Spam" then
        local now = tick()
        if now - I.LastSpam >= S.SpamDelay then
            I.LastSpam = now
            I.SpamDir = -I.SpamDir
            if I.SpamDir == -1 then AS_PressA() AS_ReleaseD()
            else AS_PressD() AS_ReleaseA() end
        end
        return
    end
    local yaw = AS_GetCameraYaw()
    if I.LastYaw == nil then I.LastYaw = yaw return end
    local delta = AS_WrapAngle(yaw - I.LastYaw)
    I.LastYaw = yaw
    if delta == 0 then AS_ReleaseAll() return end
    local turningRight = delta > 0
    if S.Invert then turningRight = not turningRight end
    if turningRight then AS_PressA() AS_ReleaseD()
    else AS_PressD() AS_ReleaseA() end
end

Track(RunService.RenderStepped:Connect(function() xpcall(AS_Update, HandleError) end))

Track(UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe or AS_IsTyping() then return end
    if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if not AutoStrafer.Settings.Enabled then return end
    local kc = SafeKeyCode(AutoStrafer.Settings.Key)
    if not kc or inp.KeyCode ~= kc then return end
    if AutoStrafer.Settings.Toggle then
        AutoStrafer.Internal.Active = not AutoStrafer.Internal.Active
        if not AutoStrafer.Internal.Active then AS_ReleaseAll() end
    else
        AutoStrafer.Internal.Active = true
    end
end))

Track(UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
    local kc = SafeKeyCode(AutoStrafer.Settings.Key)
    if not kc or inp.KeyCode ~= kc then return end
    if not AutoStrafer.Settings.Toggle then
        AutoStrafer.Internal.Active = false
        AS_ReleaseAll()
    end
end))

Track(LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if H.ShuttingDown then return end
    AS_ReleaseAll()
    AutoStrafer.Internal.Active = false
    AutoStrafer.Internal.LastYaw = nil
end))

AutoStrafer.Functions = {
    ResetSettings = function()
        AS_ReleaseAll()
        AutoStrafer.Settings = { Enabled = false, Mode = "Legit", Key = "Space", Toggle = false, Invert = false, SpamDelay = 0.05 }
        AutoStrafer.Internal = { Active = false, LastYaw = nil, KeyA = false, KeyD = false, SpamDir = -1, LastSpam = 0 }
    end,
    Stop = function()
        AutoStrafer.Settings.Enabled = false
        AutoStrafer.Internal.Active = false
        AS_ReleaseAll()
    end,
}
AutoStrafer.ReleaseAll = AS_ReleaseAll

-- ============================================================================
-- NOCLIP
-- ============================================================================
H.Noclip = {
    Settings = { Enabled = false },
    Internal = { Active = false, Saved = {} },
}
local Noclip = H.Noclip

task.spawn(function()
    while not H.ShuttingDown and task.wait(0.1) do
        if not Noclip.Settings.Enabled then
            if Noclip.Internal.Active then
                Noclip.Internal.Active = false
                for part, orig in pairs(Noclip.Internal.Saved) do
                    if part and part.Parent then
                        pcall(function() part.CanCollide = orig end)
                    end
                end
                Noclip.Internal.Saved = {}
            end
            continue
        end
        Noclip.Internal.Active = true
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    if Noclip.Internal.Saved[part] == nil then
                        Noclip.Internal.Saved[part] = part.CanCollide
                    end
                    if part.CanCollide then part.CanCollide = false end
                end
            end
        end
    end
end)

Track(LocalPlayer.CharacterAdded:Connect(function()
    Noclip.Internal.Saved = {}
    Noclip.Internal.Active = false
end))

Noclip.Functions = {
    ResetSettings = function()
        for part, orig in pairs(Noclip.Internal.Saved) do
            if part and part.Parent then
                pcall(function() part.CanCollide = orig end)
            end
        end
        Noclip.Settings = { Enabled = false }
        Noclip.Internal = { Active = false, Saved = {} }
    end,
}

-- ============================================================================
-- UI — Tab "Movement" + Localization
-- ============================================================================
local Window = getgenv().airhubUI_Window
if not Window then
    warn("[AirHub] 06_movement: airhubUI Window missing")
    return
end

--// RU/EN localization injection
do
    local UI = getgenv().airhubUI
    if UI and UI.L and UI.L.en and UI.L.ru then
        local en = {
            -- Sections
            sec_mov_autostrafer = "AutoStrafer",
            sec_mov_fly         = "Fly",
            sec_mov_flyorbit    = "Fly — Target Orbit",
            sec_mov_bhop        = "Bhop",
            sec_mov_spider      = "Spider (Bhop assist)",
            sec_mov_pixelwalk   = "Spider: Pixelwalk",
            sec_mov_wallfucker  = "Spider: Wallfucker",
            sec_mov_speed       = "Speed",
            sec_mov_faststop    = "FastStop",
            sec_mov_noclip      = "Noclip",

            -- AutoStrafer
            mv_as_enabled = "Enabled",
            mv_as_key     = "Key",
            mv_as_toggle  = "Toggle Mode",
            mv_as_mode    = "Mode",
            mv_as_invert  = "Invert",
            mv_as_spam    = "Spam Delay (Spam mode)",

            -- Fly
            mv_fly_enabled    = "Enabled",
            mv_fly_method     = "Method",
            mv_fly_key        = "Key",
            mv_fly_toggle     = "Toggle Mode",
            mv_fly_speed      = "Speed",
            mv_fly_upspeed    = "Up/Down Speed",
            mv_fly_smoothness = "Smoothness",
            mv_fly_usekeys    = "Use WASD + Space/Ctrl",

            -- Orbit
            mv_fo_enabled    = "Orbit Aimbot Target",
            mv_fo_speed      = "Orbit Speed",
            mv_fo_radius     = "Radius",
            mv_fo_height     = "Height",
            mv_fo_corr       = "Radial Correction",
            mv_fo_vcorr      = "Vertical Correction",
            mv_fo_ff         = "Feed Forward Gain",
            mv_fo_deadzone   = "Deadzone",
            mv_fo_clockwise  = "Clockwise",
            mv_fo_fallback   = "Fallback to normal Fly (no target)",
            mv_fo_aimcam     = "Aim Camera at Target",

            -- Bhop
            mv_bhop_enabled       = "Enabled",
            mv_bhop_mode          = "Mode",
            mv_bhop_key           = "Jump Key",
            mv_bhop_blockspace    = "Block Space from Game (hook)",
            mv_bhop_pulse         = "Space Release Pulse (fallback)",
            mv_bhop_bypass        = "Bypass Jump Restrictions",
            mv_bhop_cooldown      = "Jump Cooldown (Old only)",
            mv_bhop_airboost      = "Air Boost (New only)",
            mv_bhop_airboostdiv   = "Air Boost Divisor (New)",

            -- Spider
            mv_spider_enabled = "Enabled",
            mv_spider_mode    = "Mode",
            mv_spider_range   = "Wall Range (Default)",
            mv_spider_rays    = "Ray Count (Default)",

            -- Pixelwalk
            mv_pxw_downrange   = "Down Range",
            mv_pxw_maxwidth    = "Max Part Width (thin)",
            mv_pxw_snapdistance= "Snap Distance",
            mv_pxw_stickpower  = "Stick Power (0..1)",
            mv_pxw_coyotetime  = "Coyote Time (s)",
            mv_pxw_maxfall     = "Max Fall Speed",
            mv_pxw_predicttime = "Predict Time (s)",
            mv_pxw_heightoffset= "Height Offset",
            mv_pxw_forcerunning= "Force Running State",
            mv_pxw_requireflat = "Require Flat Surface",

            -- Wallfucker
            mv_wfk_chance = "Chance per Frame (0..1)",
            mv_wfk_range  = "Wall Range",
            mv_wfk_rays   = "Ray Count",
            mv_wfk_holdY  = "Hold Y (prevent fall)",
            mv_wfk_push   = "Push Up Strength",

            -- Speed
            mv_speed_enabled = "Enabled",
            mv_speed_method  = "Method",
            mv_speed_ground  = "Ground Speed",
            mv_speed_useair  = "Use Different Air Speed",
            mv_speed_air     = "Air Speed",
            mv_speed_inair   = "In Air Only",

            -- FastStop
            mv_fs_enabled = "Enabled",
            mv_fs_stopy   = "Also stop Y velocity (falling)",

            -- Noclip
            mv_noclip_enabled = "Enabled",

            -- Tooltips
            tt_mv_as_enabled = "Master switch for AutoStrafer",
            tt_mv_as_key     = "Key that activates AutoStrafer",
            tt_mv_as_toggle  = "If ON, key toggles AutoStrafer instead of holds",
            tt_mv_as_mode    = "Legit = counter-steer based on camera yaw | Spam = alternate A/D taps",
            tt_mv_as_invert  = "Invert strafe direction",
            tt_mv_as_spam    = "Interval between A/D taps in Spam mode",

            tt_mv_fly_enabled    = "Master switch for Fly",
            tt_mv_fly_method     = "BodyVelocity = legacy force | LinearVelocity = modern constraint | Velocity = raw write | CFrame = direct teleport per frame",
            tt_mv_fly_key        = "Key that holds/toggles Fly",
            tt_mv_fly_toggle     = "If ON, key toggles Fly instead of holds",
            tt_mv_fly_speed      = "Horizontal fly speed (studs/s)",
            tt_mv_fly_upspeed    = "Vertical fly speed (studs/s)",
            tt_mv_fly_smoothness = "Velocity Lerp factor (1 = instant, 0.05 = very smooth)",
            tt_mv_fly_usekeys    = "Read WASD + Space/Ctrl for movement input",

            tt_mv_fo_enabled  = "Orbit around current Aimbot target",
            tt_mv_fo_speed    = "Tangential speed along the orbit (studs/s)",
            tt_mv_fo_radius   = "Orbit radius from target (studs)",
            tt_mv_fo_height   = "Vertical offset above/below target HRP",
            tt_mv_fo_corr     = "How aggressively to correct radius error (higher = snappier)",
            tt_mv_fo_vcorr    = "How aggressively to correct vertical error",
            tt_mv_fo_ff       = "Feed-forward of target velocity. 0 = lag behind, 1 = perfect tracking, >1 = predictive",
            tt_mv_fo_deadzone = "Radius tolerance where radial correction is disabled (avoids jitter)",
            tt_mv_fo_clockwise= "Orbit clockwise (ON) or counter-clockwise (OFF)",
            tt_mv_fo_fallback = "If no aimbot target — behave like normal Fly",
            tt_mv_fo_aimcam   = "Continuously aim camera at the orbit target",

            tt_mv_bhop_enabled     = "Master switch for Bunnyhop",
            tt_mv_bhop_mode        = "New = auto-bounce via Jump property | Old = ChangeState with cooldown",
            tt_mv_bhop_key         = "Key you hold to auto-jump",
            tt_mv_bhop_blockspace  = "Prevent the game from reading your Space presses (hook IsKeyDown)",
            tt_mv_bhop_pulse       = "Fallback for executors without hookmetamethod — sends Space release events. Keep OFF if Block Space works",
            tt_mv_bhop_bypass      = "Jump even when game reports not-on-ground",
            tt_mv_bhop_cooldown    = "Min interval between jumps in Old mode",
            tt_mv_bhop_airboost    = "Add extra horizontal push while airborne",
            tt_mv_bhop_airboostdiv = "Higher = weaker air boost (1 = massive, 30 = tiny)",

            tt_mv_spider_enabled = "Enable Spider (wall climb / stick) as part of Bhop",
            tt_mv_spider_mode    = "Default = horizontal wall-detect | Pixelwalk = stick to thin surfaces | Wallfucker = probabilistic stick",
            tt_mv_spider_range   = "How far to check for walls (studs)",
            tt_mv_spider_rays    = "Number of rays around the player",

            tt_mv_pxw_downrange   = "How far down to raycast for surfaces",
            tt_mv_pxw_maxwidth    = "Only surfaces thinner than this stick",
            tt_mv_pxw_snapdistance= "Snap to ground if within this distance",
            tt_mv_pxw_stickpower  = "How strongly to reduce falling speed on thin surfaces (1 = full stop)",
            tt_mv_pxw_coyotetime  = "Grace period after leaving a thin surface",
            tt_mv_pxw_maxfall     = "Clamp fall speed when stuck",
            tt_mv_pxw_predicttime = "Lookahead time for predictive raycast",
            tt_mv_pxw_heightoffset= "Extra raycast origins below the player",
            tt_mv_pxw_forcerunning= "Force humanoid into Running state while stuck",
            tt_mv_pxw_requireflat = "Only stick to horizontal (flat) surfaces",

            tt_mv_wfk_chance = "Probability per frame to try sticking (0 = never, 1 = always)",
            tt_mv_wfk_range  = "How far to check for walls",
            tt_mv_wfk_rays   = "Rays around player",
            tt_mv_wfk_holdY  = "Zero out falling velocity when against wall",
            tt_mv_wfk_push   = "Extra upward velocity while sticking (studs/s)",

            tt_mv_speed_enabled = "Master switch for Speed",
            tt_mv_speed_method  = "WalkSpeed = set Humanoid.WalkSpeed | CFrame = direct teleport | Velocity = write HRP velocity",
            tt_mv_speed_ground  = "Ground speed (studs/s)",
            tt_mv_speed_useair  = "Use a different speed while airborne",
            tt_mv_speed_air     = "Air speed (studs/s)",
            tt_mv_speed_inair   = "Only speed up when airborne (skip on ground)",

            tt_mv_fs_enabled = "Instantly stop horizontal movement when keys released",
            tt_mv_fs_stopy   = "Also zero vertical velocity (prevents fall-out-of-world)",

            tt_mv_noclip_enabled = "Disable collision on all character parts",
        }
        local ru = {
            -- Sections
            sec_mov_autostrafer = "Автострафер",
            sec_mov_fly         = "Полёт",
            sec_mov_flyorbit    = "Полёт — Орбита вокруг цели",
            sec_mov_bhop        = "Bhop",
            sec_mov_spider      = "Спайдер (для Bhop)",
            sec_mov_pixelwalk   = "Спайдер: Pixelwalk",
            sec_mov_wallfucker  = "Спайдер: Wallfucker",
            sec_mov_speed       = "Скорость",
            sec_mov_faststop    = "FastStop",
            sec_mov_noclip      = "Noclip",

            -- AutoStrafer
            mv_as_enabled = "Включён",
            mv_as_key     = "Клавиша",
            mv_as_toggle  = "Режим переключения",
            mv_as_mode    = "Режим",
            mv_as_invert  = "Инвертировать",
            mv_as_spam    = "Задержка спама (режим Spam)",

            -- Fly
            mv_fly_enabled    = "Включён",
            mv_fly_method     = "Метод",
            mv_fly_key        = "Клавиша",
            mv_fly_toggle     = "Режим переключения",
            mv_fly_speed      = "Скорость",
            mv_fly_upspeed    = "Вверх/вниз скорость",
            mv_fly_smoothness = "Сглаживание",
            mv_fly_usekeys    = "Использовать WASD + Space/Ctrl",

            -- Orbit
            mv_fo_enabled    = "Орбита вокруг цели аимбота",
            mv_fo_speed      = "Скорость орбиты",
            mv_fo_radius     = "Радиус",
            mv_fo_height     = "Высота",
            mv_fo_corr       = "Радиальная коррекция",
            mv_fo_vcorr      = "Вертикальная коррекция",
            mv_fo_ff         = "Feed-forward скорости",
            mv_fo_deadzone   = "Мёртвая зона",
            mv_fo_clockwise  = "По часовой",
            mv_fo_fallback   = "Откат на обычный Полёт (нет цели)",
            mv_fo_aimcam     = "Направлять камеру на цель",

            -- Bhop
            mv_bhop_enabled       = "Включён",
            mv_bhop_mode          = "Режим",
            mv_bhop_key           = "Клавиша прыжка",
            mv_bhop_blockspace    = "Блокировать Space от игры (хук)",
            mv_bhop_pulse         = "Pulse release Space (фолбэк)",
            mv_bhop_bypass        = "Обходить ограничения прыжка",
            mv_bhop_cooldown      = "Кулдаун прыжка (только Old)",
            mv_bhop_airboost      = "Air Boost (только New)",
            mv_bhop_airboostdiv   = "Делитель Air Boost (New)",

            -- Spider
            mv_spider_enabled = "Включён",
            mv_spider_mode    = "Режим",
            mv_spider_range   = "Дальность стены (Default)",
            mv_spider_rays    = "Кол-во лучей (Default)",

            -- Pixelwalk
            mv_pxw_downrange   = "Дальность вниз",
            mv_pxw_maxwidth    = "Макс. толщина (тонкие)",
            mv_pxw_snapdistance= "Дистанция прилипания",
            mv_pxw_stickpower  = "Сила прилипания (0..1)",
            mv_pxw_coyotetime  = "Coyote Time (с)",
            mv_pxw_maxfall     = "Макс. скорость падения",
            mv_pxw_predicttime = "Время предсказания (с)",
            mv_pxw_heightoffset= "Смещение по высоте",
            mv_pxw_forcerunning= "Форсировать Running",
            mv_pxw_requireflat = "Только плоские поверхности",

            -- Wallfucker
            mv_wfk_chance = "Шанс за кадр (0..1)",
            mv_wfk_range  = "Дальность стены",
            mv_wfk_rays   = "Кол-во лучей",
            mv_wfk_holdY  = "Держать Y (не падать)",
            mv_wfk_push   = "Сила подъёма",

            -- Speed
            mv_speed_enabled = "Включён",
            mv_speed_method  = "Метод",
            mv_speed_ground  = "Скорость по земле",
            mv_speed_useair  = "Другая скорость в воздухе",
            mv_speed_air     = "Скорость в воздухе",
            mv_speed_inair   = "Только в воздухе",

            -- FastStop
            mv_fs_enabled = "Включён",
            mv_fs_stopy   = "Также стоп по Y (падение)",

            -- Noclip
            mv_noclip_enabled = "Включён",

            -- Tooltips
            tt_mv_as_enabled = "Главный выключатель автострафера",
            tt_mv_as_key     = "Клавиша активации автострафера",
            tt_mv_as_toggle  = "Если ВКЛ, клавиша переключает, а не удерживает",
            tt_mv_as_mode    = "Legit = контр-стрейф по углу камеры | Spam = чередование A/D",
            tt_mv_as_invert  = "Инвертировать направление стрейфа",
            tt_mv_as_spam    = "Интервал между нажатиями A/D в режиме Spam",

            tt_mv_fly_enabled    = "Главный выключатель полёта",
            tt_mv_fly_method     = "BodyVelocity = классика | LinearVelocity = современный constraint | Velocity = прямая запись | CFrame = телепорт каждый кадр",
            tt_mv_fly_key        = "Клавиша удержания/переключения полёта",
            tt_mv_fly_toggle     = "Если ВКЛ, клавиша переключает полёт",
            tt_mv_fly_speed      = "Горизонтальная скорость (studs/s)",
            tt_mv_fly_upspeed    = "Вертикальная скорость (studs/s)",
            tt_mv_fly_smoothness = "Коэффициент сглаживания (1 = мгновенно, 0.05 = очень плавно)",
            tt_mv_fly_usekeys    = "Читать WASD + Space/Ctrl как ввод движения",

            tt_mv_fo_enabled  = "Вращаться вокруг текущей цели аимбота",
            tt_mv_fo_speed    = "Тангенциальная скорость по орбите (studs/s)",
            tt_mv_fo_radius   = "Радиус орбиты от цели (studs)",
            tt_mv_fo_height   = "Вертикальное смещение над/под HRP цели",
            tt_mv_fo_corr     = "Сила радиальной коррекции (выше = резче)",
            tt_mv_fo_vcorr    = "Сила вертикальной коррекции",
            tt_mv_fo_ff       = "Feed-forward скорости цели. 0 = отставать, 1 = точное следование, >1 = предиктивно",
            tt_mv_fo_deadzone = "Радиус-толеранс без коррекции (устраняет джиттер)",
            tt_mv_fo_clockwise= "Орбита по часовой (ВКЛ) или против (ВЫКЛ)",
            tt_mv_fo_fallback = "Если цели нет — вести себя как обычный Полёт",
            tt_mv_fo_aimcam   = "Постоянно направлять камеру на цель орбиты",

            tt_mv_bhop_enabled     = "Главный выключатель Bunnyhop",
            tt_mv_bhop_mode        = "New = авто-прыжок через Jump | Old = ChangeState с кулдауном",
            tt_mv_bhop_key         = "Клавиша удержания для авто-прыжка",
            tt_mv_bhop_blockspace  = "Скрыть нажатия Space от игры (хук IsKeyDown)",
            tt_mv_bhop_pulse       = "Фолбэк для экзекуторов без hookmetamethod — шлёт release-события Space. Держи ВЫКЛ если Block Space работает",
            tt_mv_bhop_bypass      = "Прыгать даже когда игра считает что вы не на земле",
            tt_mv_bhop_cooldown    = "Мин. интервал между прыжками в Old режиме",
            tt_mv_bhop_airboost    = "Доп. горизонтальный толчок в воздухе",
            tt_mv_bhop_airboostdiv = "Больше = слабее буст (1 = огромный, 30 = крошечный)",

            tt_mv_spider_enabled = "Спайдер (липкость к стенам) как часть Bhop",
            tt_mv_spider_mode    = "Default = лучи по горизонтали | Pixelwalk = липкость к тонким | Wallfucker = вероятностная липкость",
            tt_mv_spider_range   = "Как далеко проверять стены (studs)",
            tt_mv_spider_rays    = "Кол-во лучей вокруг игрока",

            tt_mv_pxw_downrange   = "Как далеко смотреть вниз",
            tt_mv_pxw_maxwidth    = "Только поверхности тоньше этого",
            tt_mv_pxw_snapdistance= "Прилипнуть к земле в пределах этой дистанции",
            tt_mv_pxw_stickpower  = "Сила уменьшения падения на тонких (1 = полный стоп)",
            tt_mv_pxw_coyotetime  = "Грейс-период после ухода с тонкой поверхности",
            tt_mv_pxw_maxfall     = "Ограничение скорости падения",
            tt_mv_pxw_predicttime = "Время упреждения для предиктивного рейкаста",
            tt_mv_pxw_heightoffset= "Доп. источники лучей ниже игрока",
            tt_mv_pxw_forcerunning= "Форсировать Running пока прилип",
            tt_mv_pxw_requireflat = "Только горизонтальные (плоские) поверхности",

            tt_mv_wfk_chance = "Шанс за кадр попытаться прилипнуть (0 = никогда, 1 = всегда)",
            tt_mv_wfk_range  = "Дальность проверки стен",
            tt_mv_wfk_rays   = "Лучей вокруг игрока",
            tt_mv_wfk_holdY  = "Обнулять скорость падения у стены",
            tt_mv_wfk_push   = "Доп. вертикальная скорость при прилипании (studs/s)",

            tt_mv_speed_enabled = "Главный выключатель скорости",
            tt_mv_speed_method  = "WalkSpeed = Humanoid.WalkSpeed | CFrame = телепорт | Velocity = скорость HRP",
            tt_mv_speed_ground  = "Скорость по земле (studs/s)",
            tt_mv_speed_useair  = "Использовать отдельную скорость в воздухе",
            tt_mv_speed_air     = "Скорость в воздухе (studs/s)",
            tt_mv_speed_inair   = "Ускорять только в воздухе (пропускать на земле)",

            tt_mv_fs_enabled = "Мгновенная остановка горизонтального движения при отпускании клавиш",
            tt_mv_fs_stopy   = "Также обнулять вертикальную скорость (не падать)",

            tt_mv_noclip_enabled = "Отключить коллизию у всех частей персонажа",
        }
        for k, v in pairs(en) do UI.L.en[k] = v end
        for k, v in pairs(ru) do UI.L.ru[k] = v end
        if UI.RefreshTheme then pcall(UI.RefreshTheme) end
    end
end

H._UI = H._UI or {}
local tab = Window:AddTab({ Name = "Movement", Icon = ">" })
H._UI.MovementTab = tab

local strafeModes  = { "Legit", "Spam" }
local strafeKeys   = { "Space", "LeftShift", "LeftControl", "C", "X", "Z", "Q", "E" }
local flyMethods   = { "BodyVelocity", "LinearVelocity", "Velocity", "CFrame" }
local flyKeys      = { "F", "G", "H", "V", "B", "N", "Space", "LeftShift" }
local bhopKeys     = { "Space", "LeftShift", "LeftControl", "C", "X", "Z", "E", "Q", "F", "G", "V", "B" }
local bhopModes    = { "Old", "New" }
local speedMethods = { "WalkSpeed", "CFrame", "Velocity" }
local spiderModes  = { "Default", "Pixelwalk", "Wallfucker" }

-- ---------- AutoStrafer (Left) ----------
local asSec = tab:CreateSection({ Name = "sec_mov_autostrafer" })
asSec:AddToggle({ Name = "mv_as_enabled", Value = AutoStrafer.Settings.Enabled,
    Callback = function(v)
        AutoStrafer.Settings.Enabled = v
        if not v and AutoStrafer.Functions.Stop then AutoStrafer.Functions.Stop() end
    end, Tooltip = "tt_mv_as_enabled" })
asSec:AddDropdown({ Name = "mv_as_key", Value = AutoStrafer.Settings.Key or "Space", List = strafeKeys,
    Callback = function(v) AutoStrafer.Settings.Key = v end, Tooltip = "tt_mv_as_key" })
asSec:AddToggle({ Name = "mv_as_toggle", Value = AutoStrafer.Settings.Toggle or false,
    Callback = function(v) AutoStrafer.Settings.Toggle = v end, Tooltip = "tt_mv_as_toggle" })
asSec:AddDropdown({ Name = "mv_as_mode", Value = AutoStrafer.Settings.Mode or "Legit", List = strafeModes,
    Callback = function(v) AutoStrafer.Settings.Mode = v end, Tooltip = "tt_mv_as_mode" })
asSec:AddToggle({ Name = "mv_as_invert", Value = AutoStrafer.Settings.Invert or false,
    Callback = function(v) AutoStrafer.Settings.Invert = v end, Tooltip = "tt_mv_as_invert" })
asSec:AddSlider({ Name = "mv_as_spam", Value = AutoStrafer.Settings.SpamDelay or 0.05,
    Min = 0.01, Max = 0.3, Decimals = 2,
    Callback = function(v) AutoStrafer.Settings.SpamDelay = v end, Tooltip = "tt_mv_as_spam" })

-- ---------- Fly (Left) ----------
local flySec = tab:CreateSection({ Name = "sec_mov_fly" })
flySec:AddToggle({ Name = "mv_fly_enabled", Value = Fly.Settings.Enabled,
    Callback = function(v)
        Fly.Settings.Enabled = v
        if not v then
            Fly.Internal.Active = false
            Fly_ClearInstances()
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum.PlatformStand = false end
            end
        end
    end, Tooltip = "tt_mv_fly_enabled" })
flySec:AddDropdown({ Name = "mv_fly_method", Value = Fly.Settings.Method or "BodyVelocity", List = flyMethods,
    Callback = function(v) Fly.Settings.Method = v; Fly_ClearInstances() end, Tooltip = "tt_mv_fly_method" })
flySec:AddDropdown({ Name = "mv_fly_key", Value = Fly.Settings.ToggleKey or "F", List = flyKeys,
    Callback = function(v) Fly.Settings.ToggleKey = v end, Tooltip = "tt_mv_fly_key" })
flySec:AddToggle({ Name = "mv_fly_toggle", Value = Fly.Settings.Toggle or false,
    Callback = function(v) Fly.Settings.Toggle = v end, Tooltip = "tt_mv_fly_toggle" })
flySec:AddSlider({ Name = "mv_fly_speed", Value = Fly.Settings.Speed or 30, Min = 1, Max = 200,
    Callback = function(v) Fly.Settings.Speed = v end, Tooltip = "tt_mv_fly_speed" })
flySec:AddSlider({ Name = "mv_fly_upspeed", Value = Fly.Settings.UpSpeed or 20, Min = 1, Max = 200,
    Callback = function(v) Fly.Settings.UpSpeed = v end, Tooltip = "tt_mv_fly_upspeed" })
flySec:AddSlider({ Name = "mv_fly_smoothness", Value = Fly.Settings.Smoothness or 0.5,
    Min = 0.05, Max = 1, Decimals = 2,
    Callback = function(v) Fly.Settings.Smoothness = v end, Tooltip = "tt_mv_fly_smoothness" })
flySec:AddToggle({ Name = "mv_fly_usekeys", Value = Fly.Settings.UseKeys ~= false,
    Callback = function(v) Fly.Settings.UseKeys = v end, Tooltip = "tt_mv_fly_usekeys" })

-- ---------- Fly — Target Orbit (Left) ----------
local flyOrbSec = tab:CreateSection({ Name = "sec_mov_flyorbit" })
flyOrbSec:AddToggle({ Name = "mv_fo_enabled", Value = Fly.Settings.TargetOrbit.Enabled,
    Callback = function(v) Fly.Settings.TargetOrbit.Enabled = v end, Tooltip = "tt_mv_fo_enabled" })
flyOrbSec:AddSlider({ Name = "mv_fo_speed", Value = Fly.Settings.TargetOrbit.OrbitSpeed or 20,
    Min = 1, Max = 100, Decimals = 1,
    Callback = function(v) Fly.Settings.TargetOrbit.OrbitSpeed = v end, Tooltip = "tt_mv_fo_speed" })
flyOrbSec:AddSlider({ Name = "mv_fo_radius", Value = Fly.Settings.TargetOrbit.Radius or 15,
    Min = 1, Max = 60, Decimals = 1,
    Callback = function(v) Fly.Settings.TargetOrbit.Radius = v end, Tooltip = "tt_mv_fo_radius" })
flyOrbSec:AddSlider({ Name = "mv_fo_height", Value = Fly.Settings.TargetOrbit.Height or 0,
    Min = -30, Max = 30, Decimals = 1,
    Callback = function(v) Fly.Settings.TargetOrbit.Height = v end, Tooltip = "tt_mv_fo_height" })
flyOrbSec:AddSlider({ Name = "mv_fo_corr", Value = Fly.Settings.TargetOrbit.Correction or 3,
    Min = 0, Max = 10, Decimals = 1,
    Callback = function(v) Fly.Settings.TargetOrbit.Correction = v end, Tooltip = "tt_mv_fo_corr" })
flyOrbSec:AddSlider({ Name = "mv_fo_vcorr", Value = Fly.Settings.TargetOrbit.VerticalCorrection or 3,
    Min = 0, Max = 10, Decimals = 1,
    Callback = function(v) Fly.Settings.TargetOrbit.VerticalCorrection = v end, Tooltip = "tt_mv_fo_vcorr" })
flyOrbSec:AddSlider({ Name = "mv_fo_ff", Value = Fly.Settings.TargetOrbit.FeedForward or 1.0,
    Min = 0, Max = 3, Decimals = 2,
    Callback = function(v) Fly.Settings.TargetOrbit.FeedForward = v end, Tooltip = "tt_mv_fo_ff" })
flyOrbSec:AddSlider({ Name = "mv_fo_deadzone", Value = Fly.Settings.TargetOrbit.Deadzone or 0.3,
    Min = 0, Max = 3, Decimals = 2,
    Callback = function(v) Fly.Settings.TargetOrbit.Deadzone = v end, Tooltip = "tt_mv_fo_deadzone" })
flyOrbSec:AddToggle({ Name = "mv_fo_clockwise", Value = Fly.Settings.TargetOrbit.Clockwise ~= false,
    Callback = function(v) Fly.Settings.TargetOrbit.Clockwise = v end, Tooltip = "tt_mv_fo_clockwise" })
flyOrbSec:AddToggle({ Name = "mv_fo_fallback", Value = Fly.Settings.TargetOrbit.FallbackToFly ~= false,
    Callback = function(v) Fly.Settings.TargetOrbit.FallbackToFly = v end, Tooltip = "tt_mv_fo_fallback" })
flyOrbSec:AddToggle({ Name = "mv_fo_aimcam", Value = Fly.Settings.TargetOrbit.AimCamera ~= false,
    Callback = function(v) Fly.Settings.TargetOrbit.AimCamera = v end, Tooltip = "tt_mv_fo_aimcam" })

-- ---------- Bhop (Right) ----------
local bhopSec = tab:CreateSection({ Name = "sec_mov_bhop", Side = "Right" })
bhopSec:AddToggle({ Name = "mv_bhop_enabled", Value = Bhop.Settings.Enabled,
    Callback = function(v)
        Bhop.Settings.Enabled = v
        if not v then
            Bhop.Internal.KeyHeld = false
            Bhop.Internal.Active = false
            Bhop.Internal.SpiderTouching = false
            Bhop.Internal.PendingPulses = 0
        end
    end, Tooltip = "tt_mv_bhop_enabled" })
bhopSec:AddDropdown({ Name = "mv_bhop_mode", Value = Bhop.Settings.Mode or "New", List = bhopModes,
    Callback = function(v) Bhop.Settings.Mode = v end, Tooltip = "tt_mv_bhop_mode" })
bhopSec:AddDropdown({ Name = "mv_bhop_key", Value = Bhop.Settings.AutoJumpKey or "Space", List = bhopKeys,
    Callback = function(v) Bhop.Settings.AutoJumpKey = v end, Tooltip = "tt_mv_bhop_key" })
bhopSec:AddToggle({ Name = "mv_bhop_blockspace", Value = Bhop.Settings.BlockSpaceFromGame ~= false,
    Callback = function(v) Bhop.Settings.BlockSpaceFromGame = v end, Tooltip = "tt_mv_bhop_blockspace" })
bhopSec:AddToggle({ Name = "mv_bhop_pulse", Value = Bhop.Settings.SpaceReleasePulse == true,
    Callback = function(v) Bhop.Settings.SpaceReleasePulse = v end, Tooltip = "tt_mv_bhop_pulse" })
bhopSec:AddToggle({ Name = "mv_bhop_bypass", Value = Bhop.Settings.BypassJump ~= false,
    Callback = function(v) Bhop.Settings.BypassJump = v end, Tooltip = "tt_mv_bhop_bypass" })
bhopSec:AddSlider({ Name = "mv_bhop_cooldown", Value = Bhop.Settings.JumpCooldown or 0.05,
    Min = 0.01, Max = 0.5, Decimals = 2,
    Callback = function(v) Bhop.Settings.JumpCooldown = v end, Tooltip = "tt_mv_bhop_cooldown" })
bhopSec:AddToggle({ Name = "mv_bhop_airboost", Value = Bhop.Settings.AirBoost ~= false,
    Callback = function(v) Bhop.Settings.AirBoost = v end, Tooltip = "tt_mv_bhop_airboost" })
bhopSec:AddSlider({ Name = "mv_bhop_airboostdiv", Value = Bhop.Settings.AirBoostDivisor or 5.9,
    Min = 1, Max = 30, Decimals = 1,
    Callback = function(v) Bhop.Settings.AirBoostDivisor = v end, Tooltip = "tt_mv_bhop_airboostdiv" })

-- ---------- Spider (Right) ----------
local spiderSec = tab:CreateSection({ Name = "sec_mov_spider", Side = "Right" })
spiderSec:AddToggle({ Name = "mv_spider_enabled", Value = Bhop.Settings.Spider.Enabled,
    Callback = function(v) Bhop.Settings.Spider.Enabled = v end, Tooltip = "tt_mv_spider_enabled" })
spiderSec:AddDropdown({ Name = "mv_spider_mode",
    Value = Bhop.Settings.Spider.Mode or "Default",
    List = spiderModes,
    Callback = function(v) Bhop.Settings.Spider.Mode = v end, Tooltip = "tt_mv_spider_mode" })
spiderSec:AddSlider({ Name = "mv_spider_range", Value = Bhop.Settings.Spider.Range or 2.5,
    Min = 1, Max = 10, Decimals = 1,
    Callback = function(v) Bhop.Settings.Spider.Range = v end, Tooltip = "tt_mv_spider_range" })
spiderSec:AddSlider({ Name = "mv_spider_rays", Value = Bhop.Settings.Spider.RayCount or 8,
    Min = 4, Max = 24,
    Callback = function(v) Bhop.Settings.Spider.RayCount = math.floor(v) end, Tooltip = "tt_mv_spider_rays" })

local pxwSec = tab:CreateSection({ Name = "sec_mov_pixelwalk", Side = "Right" })
pxwSec:AddSlider({ Name = "mv_pxw_downrange", Value = Bhop.Settings.Spider.Pixelwalk.DownRange or 5.0,
    Min = 1, Max = 12, Decimals = 1,
    Callback = function(v) Bhop.Settings.Spider.Pixelwalk.DownRange = v end, Tooltip = "tt_mv_pxw_downrange" })
pxwSec:AddSlider({ Name = "mv_pxw_maxwidth", Value = Bhop.Settings.Spider.Pixelwalk.MaxWidth or 0.6,
    Min = 0.05, Max = 5, Decimals = 2,
    Callback = function(v) Bhop.Settings.Spider.Pixelwalk.MaxWidth = v end, Tooltip = "tt_mv_pxw_maxwidth" })
pxwSec:AddSlider({ Name = "mv_pxw_snapdistance", Value = Bhop.Settings.Spider.Pixelwalk.SnapDistance or 4.0,
    Min = 0.1, Max = 8, Decimals = 2,
    Callback = function(v) Bhop.Settings.Spider.Pixelwalk.SnapDistance = v end, Tooltip = "tt_mv_pxw_snapdistance" })
pxwSec:AddSlider({ Name = "mv_pxw_stickpower", Value = Bhop.Settings.Spider.Pixelwalk.StickPower or 1.0,
    Min = 0, Max = 1, Decimals = 2,
    Callback = function(v) Bhop.Settings.Spider.Pixelwalk.StickPower = v end, Tooltip = "tt_mv_pxw_stickpower" })
pxwSec:AddSlider({ Name = "mv_pxw_coyotetime", Value = Bhop.Settings.Spider.Pixelwalk.CoyoteTime or 0.15,
    Min = 0, Max = 0.5, Decimals = 2,
    Callback = function(v) Bhop.Settings.Spider.Pixelwalk.CoyoteTime = v end, Tooltip = "tt_mv_pxw_coyotetime" })
pxwSec:AddSlider({ Name = "mv_pxw_maxfall", Value = Bhop.Settings.Spider.Pixelwalk.MaxFallSpeed or 5.0,
    Min = 0, Max = 30, Decimals = 1,
    Callback = function(v) Bhop.Settings.Spider.Pixelwalk.MaxFallSpeed = v end, Tooltip = "tt_mv_pxw_maxfall" })
pxwSec:AddSlider({ Name = "mv_pxw_predicttime", Value = Bhop.Settings.Spider.Pixelwalk.PredictTime or 0.04,
    Min = 0, Max = 0.15, Decimals = 3,
    Callback = function(v) Bhop.Settings.Spider.Pixelwalk.PredictTime = v end, Tooltip = "tt_mv_pxw_predicttime" })
pxwSec:AddSlider({ Name = "mv_pxw_heightoffset", Value = Bhop.Settings.Spider.Pixelwalk.HeightOffset or 2.0,
    Min = 0, Max = 5, Decimals = 1,
    Callback = function(v) Bhop.Settings.Spider.Pixelwalk.HeightOffset = v end, Tooltip = "tt_mv_pxw_heightoffset" })
pxwSec:AddToggle({ Name = "mv_pxw_forcerunning", Value = Bhop.Settings.Spider.Pixelwalk.ForceRunning ~= false,
    Callback = function(v) Bhop.Settings.Spider.Pixelwalk.ForceRunning = v end, Tooltip = "tt_mv_pxw_forcerunning" })
pxwSec:AddToggle({ Name = "mv_pxw_requireflat", Value = Bhop.Settings.Spider.Pixelwalk.RequireFlat ~= false,
    Callback = function(v) Bhop.Settings.Spider.Pixelwalk.RequireFlat = v end, Tooltip = "tt_mv_pxw_requireflat" })

local wfkSec = tab:CreateSection({ Name = "sec_mov_wallfucker", Side = "Right" })
wfkSec:AddSlider({ Name = "mv_wfk_chance", Value = Bhop.Settings.Spider.Wallfucker.Chance or 0.5,
    Min = 0, Max = 1, Decimals = 2,
    Callback = function(v) Bhop.Settings.Spider.Wallfucker.Chance = v end, Tooltip = "tt_mv_wfk_chance" })
wfkSec:AddSlider({ Name = "mv_wfk_range", Value = Bhop.Settings.Spider.Wallfucker.WallRange or 3.0,
    Min = 1, Max = 10, Decimals = 1,
    Callback = function(v) Bhop.Settings.Spider.Wallfucker.WallRange = v end, Tooltip = "tt_mv_wfk_range" })
wfkSec:AddSlider({ Name = "mv_wfk_rays", Value = Bhop.Settings.Spider.Wallfucker.RayCount or 8,
    Min = 4, Max = 24,
    Callback = function(v) Bhop.Settings.Spider.Wallfucker.RayCount = math.floor(v) end, Tooltip = "tt_mv_wfk_rays" })
wfkSec:AddToggle({ Name = "mv_wfk_holdY", Value = Bhop.Settings.Spider.Wallfucker.HoldY ~= false,
    Callback = function(v) Bhop.Settings.Spider.Wallfucker.HoldY = v end, Tooltip = "tt_mv_wfk_holdY" })
wfkSec:AddSlider({ Name = "mv_wfk_push", Value = Bhop.Settings.Spider.Wallfucker.PushStrength or 0,
    Min = 0, Max = 50, Decimals = 1,
    Callback = function(v) Bhop.Settings.Spider.Wallfucker.PushStrength = v end, Tooltip = "tt_mv_wfk_push" })

-- ---------- Speed (Right) ----------
local speedSec = tab:CreateSection({ Name = "sec_mov_speed", Side = "Right" })
speedSec:AddToggle({ Name = "mv_speed_enabled", Value = Speed.Settings.Enabled,
    Callback = function(v) Speed.Settings.Enabled = v end, Tooltip = "tt_mv_speed_enabled" })
speedSec:AddDropdown({ Name = "mv_speed_method", Value = Speed.Settings.Method or "WalkSpeed", List = speedMethods,
    Callback = function(v) Speed.Settings.Method = v end, Tooltip = "tt_mv_speed_method" })
speedSec:AddSlider({ Name = "mv_speed_ground", Value = Speed.Settings.GroundSpeed or 30, Min = 1, Max = 500,
    Callback = function(v) Speed.Settings.GroundSpeed = v end, Tooltip = "tt_mv_speed_ground" })
speedSec:AddToggle({ Name = "mv_speed_useair", Value = Speed.Settings.UseAirSpeed or false,
    Callback = function(v) Speed.Settings.UseAirSpeed = v end, Tooltip = "tt_mv_speed_useair" })
speedSec:AddSlider({ Name = "mv_speed_air", Value = Speed.Settings.AirSpeed or 30, Min = 1, Max = 500,
    Callback = function(v) Speed.Settings.AirSpeed = v end, Tooltip = "tt_mv_speed_air" })
speedSec:AddToggle({ Name = "mv_speed_inair", Value = Speed.Settings.InAirOnly or false,
    Callback = function(v) Speed.Settings.InAirOnly = v end, Tooltip = "tt_mv_speed_inair" })

-- ---------- FastStop (Left) ----------
local fsSec = tab:CreateSection({ Name = "sec_mov_faststop" })
fsSec:AddToggle({ Name = "mv_fs_enabled", Value = FastStop.Settings.Enabled,
    Callback = function(v) FastStop.Settings.Enabled = v end, Tooltip = "tt_mv_fs_enabled" })
fsSec:AddToggle({ Name = "mv_fs_stopy", Value = FastStop.Settings.StopY or false,
    Callback = function(v) FastStop.Settings.StopY = v end, Tooltip = "tt_mv_fs_stopy" })

-- ---------- Noclip (Right) ----------
local noclipSec = tab:CreateSection({ Name = "sec_mov_noclip", Side = "Right" })
noclipSec:AddToggle({ Name = "mv_noclip_enabled", Value = Noclip.Settings.Enabled,
    Callback = function(v) Noclip.Settings.Enabled = v end, Tooltip = "tt_mv_noclip_enabled" })

print("[AirHub] 06_movement: loaded OK (RU loc + tooltips + improved Fly Orbit)")
