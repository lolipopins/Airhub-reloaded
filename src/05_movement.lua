--// AirHub — 06_movement.lua
--// Merged: Fly + Bhop + Speed + FastStop + AutoStrafer + Noclip + Spider
--// Also: Tab "Movement" in airhubUI

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
            Enabled = false, OrbitSpeed = 20, Radius = 15, Height = 0,
            Correction = 3, VerticalCorrection = 3, Clockwise = true,
            FallbackToFly = true,
        },
    },
    Internal = {
        BodyVelocity = nil, LinearVelocity = nil, Attachment = nil,
        Active = false, LastUpdate = 0, OrbitAngle = 0, LastCFrameTick = 0,
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
    local forward = workspace.CurrentCamera.CFrame.LookVector
    local right = workspace.CurrentCamera.CFrame.RightVector
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

local function Fly_GetAimbotTargetPos()
    local A = H.Aimbot
    if not A then return nil end
    local part = A.LockPartInstance
    if part and part.Parent then return part.Position end
    return nil
end

local function Fly_ClampVec(v, maxLen)
    local m = v.Magnitude
    if m > maxLen and m > 0.0001 then return v * (maxLen / m) end
    return v
end

local function Fly_ComputeOrbitVelocity(hrp, targetPos)
    local O = Fly.Settings.TargetOrbit
    local orbitSpeed = O.OrbitSpeed or 20
    local radius     = O.Radius     or 15
    local height     = O.Height     or 0
    local corr       = O.Correction or 3
    local vCorr      = O.VerticalCorrection or 3

    local toTarget = targetPos - hrp.Position
    local horizontal = Vector3.new(toTarget.X, 0, toTarget.Z)
    local dist = horizontal.Magnitude

    local radialDir, tangentDir
    if dist < 0.01 then
        radialDir  = Vector3.new(1, 0, 0)
        tangentDir = Vector3.new(0, 0, 1)
    else
        radialDir  = horizontal.Unit
        if O.Clockwise then
            tangentDir = Vector3.new( radialDir.Z, 0, -radialDir.X)
        else
            tangentDir = Vector3.new(-radialDir.Z, 0,  radialDir.X)
        end
    end

    local tangential = tangentDir * orbitSpeed
    local radialError = dist - radius
    local radial = radialDir * (radialError * corr)
    radial = Fly_ClampVec(radial, orbitSpeed)

    local targetY = targetPos.Y + height
    local yVel = (targetY - hrp.Position.Y) * vCorr
    if math.abs(yVel) > orbitSpeed then
        yVel = (yVel > 0 and 1 or -1) * orbitSpeed
    end

    return tangential + radial + Vector3.new(0, yVel, 0)
end

local function Fly_ApplyVelocity(hrp, vel)
    local S = Fly.Settings
    local I = Fly.Internal
    if S.Method == "BodyVelocity" then
        if I.BodyVelocity then
            I.BodyVelocity.Velocity = I.BodyVelocity.Velocity:Lerp(
                vel, math.clamp(S.Smoothness, 0.01, 1))
        end
    elseif S.Method == "LinearVelocity" then
        if I.LinearVelocity then
            I.LinearVelocity.VectorVelocity = I.LinearVelocity.VectorVelocity:Lerp(
                vel, math.clamp(S.Smoothness, 0.01, 1))
        end
    elseif S.Method == "Velocity" then
        hrp.Velocity = vel
    elseif S.Method == "CFrame" then
        local now = tick()
        local dt = now - (I.LastCFrameTick or now)
        I.LastCFrameTick = now
        if dt <= 0 or dt > 0.5 then dt = 1 / 60 end
        hrp.CFrame = hrp.CFrame + (vel * dt)
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

    local targetVel = nil
    local O = S.TargetOrbit
    if O and O.Enabled then
        local targetPos = Fly_GetAimbotTargetPos()
        if targetPos then
            targetVel = Fly_ComputeOrbitVelocity(hrp, targetPos)
        elseif not O.FallbackToFly then
            targetVel = Vector3.new(0, 0, 0)
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

    local now = tick()
    local dt = now - I.LastUpdate
    if dt <= 0 or dt > 0.5 then dt = 1 / 60 end
    I.LastUpdate = now

    Fly_ApplyVelocity(hrp, targetVel)

    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = true end
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
end))

Fly.Functions = {
    ResetSettings = function()
        Fly.Settings = {
            Enabled = false, ToggleKey = "F", Toggle = false, Method = "BodyVelocity",
            Speed = 30, UpSpeed = 20, Smoothness = 0.5, UseKeys = true,
            TargetOrbit = {
                Enabled = false, OrbitSpeed = 20, Radius = 15, Height = 0,
                Correction = 3, VerticalCorrection = 3, Clockwise = true,
                FallbackToFly = true,
            },
        }
        Fly_ClearInstances()
        Fly.Internal.Active = false
        Fly.Internal.LastUpdate = 0
        Fly.Internal.OrbitAngle = 0
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.PlatformStand = false end
        end
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
    local camForward = workspace.CurrentCamera.CFrame.LookVector
    local camRight = workspace.CurrentCamera.CFrame.RightVector
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
    local look = workspace.CurrentCamera.CFrame.LookVector
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
-- UI — Tab "Movement"
-- ============================================================================
local Window = getgenv().airhubUI_Window
if not Window then
    warn("[AirHub] 06_movement: airhubUI Window missing")
    return
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
local asSec = tab:CreateSection({ Name = "AutoStrafer" })
asSec:AddToggle({ Name = "Enabled", Value = AutoStrafer.Settings.Enabled,
    Callback = function(v)
        AutoStrafer.Settings.Enabled = v
        if not v and AutoStrafer.Functions.Stop then AutoStrafer.Functions.Stop() end
    end })
asSec:AddDropdown({ Name = "Key", Value = AutoStrafer.Settings.Key or "Space", List = strafeKeys,
    Callback = function(v) AutoStrafer.Settings.Key = v end })
asSec:AddToggle({ Name = "Toggle Mode", Value = AutoStrafer.Settings.Toggle or false,
    Callback = function(v) AutoStrafer.Settings.Toggle = v end })
asSec:AddDropdown({ Name = "Mode", Value = AutoStrafer.Settings.Mode or "Legit", List = strafeModes,
    Callback = function(v) AutoStrafer.Settings.Mode = v end })
asSec:AddToggle({ Name = "Invert", Value = AutoStrafer.Settings.Invert or false,
    Callback = function(v) AutoStrafer.Settings.Invert = v end })
asSec:AddSlider({ Name = "Spam Delay (Spam mode)", Value = AutoStrafer.Settings.SpamDelay or 0.05,
    Min = 0.01, Max = 0.3, Decimals = 2,
    Callback = function(v) AutoStrafer.Settings.SpamDelay = v end })

-- ---------- Fly (Left) ----------
local flySec = tab:CreateSection({ Name = "Fly" })
flySec:AddToggle({ Name = "Enabled", Value = Fly.Settings.Enabled,
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
    end })
flySec:AddDropdown({ Name = "Method", Value = Fly.Settings.Method or "BodyVelocity", List = flyMethods,
    Callback = function(v) Fly.Settings.Method = v; Fly_ClearInstances() end })
flySec:AddDropdown({ Name = "Key", Value = Fly.Settings.ToggleKey or "F", List = flyKeys,
    Callback = function(v) Fly.Settings.ToggleKey = v end })
flySec:AddToggle({ Name = "Toggle Mode", Value = Fly.Settings.Toggle or false,
    Callback = function(v) Fly.Settings.Toggle = v end })
flySec:AddSlider({ Name = "Speed", Value = Fly.Settings.Speed or 30, Min = 1, Max = 200,
    Callback = function(v) Fly.Settings.Speed = v end })
flySec:AddSlider({ Name = "Up/Down Speed", Value = Fly.Settings.UpSpeed or 20, Min = 1, Max = 200,
    Callback = function(v) Fly.Settings.UpSpeed = v end })
flySec:AddSlider({ Name = "Smoothness", Value = Fly.Settings.Smoothness or 0.5,
    Min = 0.05, Max = 1, Decimals = 2,
    Callback = function(v) Fly.Settings.Smoothness = v end })
flySec:AddToggle({ Name = "Use WASD + Space/Ctrl", Value = Fly.Settings.UseKeys ~= false,
    Callback = function(v) Fly.Settings.UseKeys = v end })

-- ---------- Fly — Target Orbit (Left) ----------
local flyOrbSec = tab:CreateSection({ Name = "Fly — Target Orbit" })
flyOrbSec:AddToggle({ Name = "Orbit Aimbot Target", Value = Fly.Settings.TargetOrbit.Enabled,
    Callback = function(v) Fly.Settings.TargetOrbit.Enabled = v end })
flyOrbSec:AddSlider({ Name = "Orbit Speed", Value = Fly.Settings.TargetOrbit.OrbitSpeed,
    Min = 1, Max = 100, Decimals = 1,
    Callback = function(v) Fly.Settings.TargetOrbit.OrbitSpeed = v end })
flyOrbSec:AddSlider({ Name = "Radius", Value = Fly.Settings.TargetOrbit.Radius,
    Min = 1, Max = 60, Decimals = 1,
    Callback = function(v) Fly.Settings.TargetOrbit.Radius = v end })
flyOrbSec:AddSlider({ Name = "Height", Value = Fly.Settings.TargetOrbit.Height,
    Min = -30, Max = 30, Decimals = 1,
    Callback = function(v) Fly.Settings.TargetOrbit.Height = v end })
flyOrbSec:AddSlider({ Name = "Radial Correction", Value = Fly.Settings.TargetOrbit.Correction,
    Min = 0, Max = 10, Decimals = 1,
    Callback = function(v) Fly.Settings.TargetOrbit.Correction = v end })
flyOrbSec:AddSlider({ Name = "Vertical Correction", Value = Fly.Settings.TargetOrbit.VerticalCorrection,
    Min = 0, Max = 10, Decimals = 1,
    Callback = function(v) Fly.Settings.TargetOrbit.VerticalCorrection = v end })
flyOrbSec:AddToggle({ Name = "Clockwise", Value = Fly.Settings.TargetOrbit.Clockwise ~= false,
    Callback = function(v) Fly.Settings.TargetOrbit.Clockwise = v end })
flyOrbSec:AddToggle({ Name = "Fallback to normal Fly (no target)", Value = Fly.Settings.TargetOrbit.FallbackToFly ~= false,
    Callback = function(v) Fly.Settings.TargetOrbit.FallbackToFly = v end })

-- ---------- Bhop (Right) ----------
local bhopSec = tab:CreateSection({ Name = "Bhop", Side = "Right" })
bhopSec:AddToggle({ Name = "Enabled", Value = Bhop.Settings.Enabled,
    Callback = function(v)
        Bhop.Settings.Enabled = v
        if not v then
            Bhop.Internal.KeyHeld = false
            Bhop.Internal.Active = false
            Bhop.Internal.SpiderTouching = false
            Bhop.Internal.PendingPulses = 0
        end
    end })
bhopSec:AddDropdown({ Name = "Mode", Value = Bhop.Settings.Mode or "New", List = bhopModes,
    Callback = function(v) Bhop.Settings.Mode = v end })
bhopSec:AddDropdown({ Name = "Jump Key", Value = Bhop.Settings.AutoJumpKey or "Space", List = bhopKeys,
    Callback = function(v) Bhop.Settings.AutoJumpKey = v end })
bhopSec:AddToggle({ Name = "Block Space from Game (hook)", Value = Bhop.Settings.BlockSpaceFromGame ~= false,
    Callback = function(v) Bhop.Settings.BlockSpaceFromGame = v end })
bhopSec:AddToggle({ Name = "Space Release Pulse (fallback, leave OFF)", Value = Bhop.Settings.SpaceReleasePulse == true,
    Callback = function(v) Bhop.Settings.SpaceReleasePulse = v end })
bhopSec:AddToggle({ Name = "Bypass Jump Restrictions", Value = Bhop.Settings.BypassJump ~= false,
    Callback = function(v) Bhop.Settings.BypassJump = v end })
bhopSec:AddSlider({ Name = "Jump Cooldown (Old only)", Value = Bhop.Settings.JumpCooldown or 0.05,
    Min = 0.01, Max = 0.5, Decimals = 2,
    Callback = function(v) Bhop.Settings.JumpCooldown = v end })
bhopSec:AddToggle({ Name = "Air Boost (New only)", Value = Bhop.Settings.AirBoost ~= false,
    Callback = function(v) Bhop.Settings.AirBoost = v end })
bhopSec:AddSlider({ Name = "Air Boost Divisor (New)", Value = Bhop.Settings.AirBoostDivisor or 5.9,
    Min = 1, Max = 30, Decimals = 1,
    Callback = function(v) Bhop.Settings.AirBoostDivisor = v end })

-- ---------- Spider (Right) ----------
local spiderSec = tab:CreateSection({ Name = "Spider (Bhop assist)", Side = "Right" })
spiderSec:AddToggle({ Name = "Enabled", Value = Bhop.Settings.Spider.Enabled,
    Callback = function(v) Bhop.Settings.Spider.Enabled = v end })
spiderSec:AddDropdown({ Name = "Mode",
    Value = Bhop.Settings.Spider.Mode or "Default",
    List = spiderModes,
    Callback = function(v) Bhop.Settings.Spider.Mode = v end })
spiderSec:AddSlider({ Name = "Wall Range (Default)", Value = Bhop.Settings.Spider.Range,
    Min = 1, Max = 10, Decimals = 1,
    Callback = function(v) Bhop.Settings.Spider.Range = v end })
spiderSec:AddSlider({ Name = "Ray Count (Default)", Value = Bhop.Settings.Spider.RayCount,
    Min = 4, Max = 24,
    Callback = function(v) Bhop.Settings.Spider.RayCount = v end })

local pxwSec = tab:CreateSection({ Name = "Spider: Pixelwalk", Side = "Right" })
pxwSec:AddSlider({ Name = "Down Range", Value = Bhop.Settings.Spider.Pixelwalk.DownRange,
    Min = 1, Max = 12, Decimals = 1,
    Callback = function(v) Bhop.Settings.Spider.Pixelwalk.DownRange = v end })
pxwSec:AddSlider({ Name = "Max Part Width (thin)", Value = Bhop.Settings.Spider.Pixelwalk.MaxWidth,
    Min = 0.05, Max = 5, Decimals = 2,
    Callback = function(v) Bhop.Settings.Spider.Pixelwalk.MaxWidth = v end })
pxwSec:AddSlider({ Name = "Snap Distance", Value = Bhop.Settings.Spider.Pixelwalk.SnapDistance,
    Min = 0.1, Max = 8, Decimals = 2,
    Callback = function(v) Bhop.Settings.Spider.Pixelwalk.SnapDistance = v end })
pxwSec:AddSlider({ Name = "Stick Power (0..1)", Value = Bhop.Settings.Spider.Pixelwalk.StickPower,
    Min = 0, Max = 1, Decimals = 2,
    Callback = function(v) Bhop.Settings.Spider.Pixelwalk.StickPower = v end })
pxwSec:AddSlider({ Name = "Coyote Time (s)", Value = Bhop.Settings.Spider.Pixelwalk.CoyoteTime,
    Min = 0, Max = 0.5, Decimals = 2,
    Callback = function(v) Bhop.Settings.Spider.Pixelwalk.CoyoteTime = v end })
pxwSec:AddSlider({ Name = "Max Fall Speed", Value = Bhop.Settings.Spider.Pixelwalk.MaxFallSpeed,
    Min = 0, Max = 30, Decimals = 1,
    Callback = function(v) Bhop.Settings.Spider.Pixelwalk.MaxFallSpeed = v end })
pxwSec:AddSlider({ Name = "Predict Time (s)", Value = Bhop.Settings.Spider.Pixelwalk.PredictTime,
    Min = 0, Max = 0.15, Decimals = 3,
    Callback = function(v) Bhop.Settings.Spider.Pixelwalk.PredictTime = v end })
pxwSec:AddSlider({ Name = "Height Offset", Value = Bhop.Settings.Spider.Pixelwalk.HeightOffset,
    Min = 0, Max = 5, Decimals = 1,
    Callback = function(v) Bhop.Settings.Spider.Pixelwalk.HeightOffset = v end })
pxwSec:AddToggle({ Name = "Force Running State", Value = Bhop.Settings.Spider.Pixelwalk.ForceRunning ~= false,
    Callback = function(v) Bhop.Settings.Spider.Pixelwalk.ForceRunning = v end })
pxwSec:AddToggle({ Name = "Require Flat Surface", Value = Bhop.Settings.Spider.Pixelwalk.RequireFlat ~= false,
    Callback = function(v) Bhop.Settings.Spider.Pixelwalk.RequireFlat = v end })

local wfkSec = tab:CreateSection({ Name = "Spider: Wallfucker", Side = "Right" })
wfkSec:AddSlider({ Name = "Chance per Frame (0..1)", Value = Bhop.Settings.Spider.Wallfucker.Chance,
    Min = 0, Max = 1, Decimals = 2,
    Callback = function(v) Bhop.Settings.Spider.Wallfucker.Chance = v end })
wfkSec:AddSlider({ Name = "Wall Range", Value = Bhop.Settings.Spider.Wallfucker.WallRange,
    Min = 1, Max = 10, Decimals = 1,
    Callback = function(v) Bhop.Settings.Spider.Wallfucker.WallRange = v end })
wfkSec:AddSlider({ Name = "Ray Count", Value = Bhop.Settings.Spider.Wallfucker.RayCount,
    Min = 4, Max = 24,
    Callback = function(v) Bhop.Settings.Spider.Wallfucker.RayCount = v end })
wfkSec:AddToggle({ Name = "Hold Y (prevent fall)", Value = Bhop.Settings.Spider.Wallfucker.HoldY ~= false,
    Callback = function(v) Bhop.Settings.Spider.Wallfucker.HoldY = v end })
wfkSec:AddSlider({ Name = "Push Up Strength", Value = Bhop.Settings.Spider.Wallfucker.PushStrength,
    Min = 0, Max = 50, Decimals = 1,
    Callback = function(v) Bhop.Settings.Spider.Wallfucker.PushStrength = v end })

-- ---------- Speed (Right) ----------
local speedSec = tab:CreateSection({ Name = "Speed", Side = "Right" })
speedSec:AddToggle({ Name = "Enabled", Value = Speed.Settings.Enabled,
    Callback = function(v) Speed.Settings.Enabled = v end })
speedSec:AddDropdown({ Name = "Method", Value = Speed.Settings.Method or "WalkSpeed", List = speedMethods,
    Callback = function(v) Speed.Settings.Method = v end })
speedSec:AddSlider({ Name = "Ground Speed", Value = Speed.Settings.GroundSpeed or 30, Min = 1, Max = 500,
    Callback = function(v) Speed.Settings.GroundSpeed = v end })
speedSec:AddToggle({ Name = "Use Different Air Speed", Value = Speed.Settings.UseAirSpeed or false,
    Callback = function(v) Speed.Settings.UseAirSpeed = v end })
speedSec:AddSlider({ Name = "Air Speed", Value = Speed.Settings.AirSpeed or 30, Min = 1, Max = 500,
    Callback = function(v) Speed.Settings.AirSpeed = v end })
speedSec:AddToggle({ Name = "In Air Only", Value = Speed.Settings.InAirOnly or false,
    Callback = function(v) Speed.Settings.InAirOnly = v end })

-- ---------- FastStop (Left) ----------
local fsSec = tab:CreateSection({ Name = "FastStop" })
fsSec:AddToggle({ Name = "Enabled", Value = FastStop.Settings.Enabled,
    Callback = function(v) FastStop.Settings.Enabled = v end })
fsSec:AddToggle({ Name = "Also stop Y velocity (falling)", Value = FastStop.Settings.StopY or false,
    Callback = function(v) FastStop.Settings.StopY = v end })

-- ---------- Noclip (Right) ----------
local noclipSec = tab:CreateSection({ Name = "Noclip", Side = "Right" })
noclipSec:AddToggle({ Name = "Enabled", Value = Noclip.Settings.Enabled,
    Callback = function(v) Noclip.Settings.Enabled = v end })

print("[AirHub] 06_movement: loaded OK")
