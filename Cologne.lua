--// COLOGNE | NullUI 2.8.1
--// Butterfly Bloom, Scramble (Mech) and Wisp automation.

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

-- Runner config
local Config = {
    WalkSpeed = 320,
    RoadCenter = Vector3.new(528.7, 70.57, -364.11),
    RoadCenterZ = -364.11,
    ButterflySpeed = 320,
    WispSpeed = 320,
    ScrambleTravelSpeed = 250,
}

local function SafeRequire(instance)
    if not instance then return nil end
    local ok, result = pcall(require, instance)
    return ok and result or nil
end

local GearsModule = SafeRequire(ReplicatedStorage:FindFirstChild("Data") and ReplicatedStorage.Data:FindFirstChild("Gears"))
local ScrambleBossHazards = SafeRequire(ReplicatedStorage:FindFirstChild("Shared") and ReplicatedStorage.Shared:FindFirstChild("Util") and ReplicatedStorage.Shared.Util:FindFirstChild("ScrambleBossHazards"))
local AreaEggCycle = SafeRequire(ReplicatedStorage:FindFirstChild("Shared") and ReplicatedStorage.Shared:FindFirstChild("Util") and ReplicatedStorage.Shared.Util:FindFirstChild("AreaEggCycle"))

--==================================================
-- NULLUI
--==================================================

local NULLUI_URL = "https://pastefy.app/kmZUOJ1A/raw"

local loaded, NullUI = pcall(function()
    return loadstring(game:HttpGet(NULLUI_URL))()
end)

if not loaded or type(NullUI) ~= "table" then
    error("Cologne: failed to load NullUI")
end

if tostring(NullUI.Version) ~= "2.8.1" then
    error("Cologne: expected NullUI 2.8.1, got " .. tostring(NullUI.Version))
end

pcall(function()
    NullUI:SetBlurEnabled(true)
end)

--==================================================
-- SERVICES / RUNTIME
--==================================================

local State = {
    Alive = true,

    Butterfly = {
        Enabled = false,
        Mode = "Stand",
        Priority = "Rarest",
        Tiers = {
            Golden = true,
            Purple = true,
            Blue = true,
            Green = true,
        },
        Speed = Config.ButterflySpeed,
        Reach = 14,
        Busy = false,
        Claiming = false,
        Generation = 0,
        NextAction = 0,
    },

    Wisp = {
        Enabled = false,
        Required = 0,
        Accepted = false,
        Unlocked = false,
        Returning = false,
        Stage = 1,
        StageCount = 0,
        Status = "Off",
        NextTry = 0,
        Generation = 0,
        Busy = false,
        Revealed = false,
    },

    Movement = {
        Owner = nil,
        Target = nil,
        Speed = Config.WispSpeed,
        LastTarget = nil,
        LastMove = 0,
    },

    Task = {
        Owner = nil,
        Rank = {
            Steal = 1,
            Place = 2,
            Treadmill = 3,
            Scramble = 4,
            Boss = 5,
            Wisp = 6,
            Butterfly = 7,
        },
        Waiting = {},
    },

    Scramble = {
        Enabled = false,
        Status = "Idle",
        TravelSpeed = Config.ScrambleTravelSpeed,
        Radius = 18,
        SwingGap = 0.12,
        Dodge = false,
        TryBall = true,
        Leave = true,
        ChaseHuman = true,
        ServerHop = false,
        BaitSpeed = 225,
        RoadCenter = Config.RoadCenter,
        RoadCenterZ = Config.RoadCenterZ,
        SwapTools = true,
        MainHold = 0.30,
        SecondHold = 0.40,
        SwapIndex = 1,
        SwapSince = 0,
        LastSwing = 0,
        Generation = 0,
        Busy = false,
        Done = false,
        Hazards = {},
        EventInterval = 1800,
        EventOpenSeconds = 900,
        EventOffset = 0,
    },

    AntiGuard = {
        Enabled = false,
        Target = "line",
        LineOffset = 8,
        Height = 45,
        OffsetX = -90,
        OffsetZ = -35,
        Jitter = 0,
        Point = false,
        Disguise = true,
        Limp = true,
        Facing = "Zero",
        Freeze = false,
        StartAt = 0,
        ReleaseAt = 0.8,
        WeldScanGap = 0.03,
        BusyLimit = 2.5,
    },
}

local Connections = {}
local Loops = {}

local function AddConnection(connection)
    if connection then
        table.insert(Connections, connection)
    end
    return connection
end

local function StopLoop(name)
    local token = Loops[name]
    if token then
        token.Cancelled = true
        Loops[name] = nil
    end
end

local function StartLoop(name, fn)
    StopLoop(name)

    local token = {
        Cancelled = false,
    }

    Loops[name] = token

    task.spawn(function()
        local ok, err = xpcall(function()
            fn(token)
        end, debug.traceback)

        if not ok and not token.Cancelled then
            warn("[Cologne/" .. name .. "] " .. tostring(err))
        end

        if Loops[name] == token then
            Loops[name] = nil
        end
    end)

    return token
end

local function alive()
    return State.Alive
        and LocalPlayer
        and LocalPlayer.Parent ~= nil
end

local function Character()
    return alive() and LocalPlayer.Character or nil
end

local function Humanoid()
    local c = Character()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function Root()
    local c = Character()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function Backpack()
    return LocalPlayer and LocalPlayer:FindFirstChildOfClass("Backpack")
end

local function GetAttribute(name, default)
    local value = LocalPlayer and LocalPlayer:GetAttribute(name)
    if value == nil then
        return default
    end
    return value
end

local function Notify(title, text, kind)
    pcall(function()
        NullUI:Notify({
            Title = title,
            Text = text,
            Type = kind or "info",
            Duration = 4,
        })
    end)
end

--==================================================
-- LIGHTING / ENVIRONMENT HELPERS
--==================================================

local function IsNight()
    -- The game's own night phase (the moon timer), not the lighting clock.
    if AreaEggCycle and type(AreaEggCycle.IsNightPhase) == "function" then
        local ok, n = pcall(AreaEggCycle.IsNightPhase, Workspace:GetServerTimeNow())
        if ok then return n == true end
    end

    local clock = Workspace:GetAttribute("ClockTime")
        or Lighting.ClockTime

    return clock >= 18 or clock < 6
end

local function EventActive(name)
    return Workspace:GetAttribute(name) == true
end

local function EnchantedTreeUnlocked()
    return GetAttribute("EnchantedTreeUnlocked", false) == true
end

local function GetWorldBuild()
    local world = Workspace:FindFirstChild("World")
    return world and world:FindFirstChild("Build")
end

local function ForestRevealed()
    local world = Workspace:FindFirstChild("World")
    local build = world and world:FindFirstChild("Build")
    local forest = build and build:FindFirstChild("EnchantedForestZone")
    return forest ~= nil and forest:FindFirstChild("WispSpawn") ~= nil
end

--==================================================
-- REMOTE RESOLUTION
--==================================================

local RemoteCache = {}

local function ResolveRemote(path)
    if RemoteCache[path] and RemoteCache[path].Parent then
        return RemoteCache[path]
    end

    local current = ReplicatedStorage

    for segment in string.gmatch(path, "[^/]+") do
        current = current and current:FindFirstChild(segment)

        if not current then
            break
        end
    end

    if current and (current:IsA("RemoteFunction") or current:IsA("RemoteEvent")) then
        RemoteCache[path] = current
        return current
    end

    local direct = ReplicatedStorage:FindFirstChild(path, true)
    if direct and (direct:IsA("RemoteFunction") or direct:IsA("RemoteEvent")) then
        RemoteCache[path] = direct
        return direct
    end

    return nil
end

local function Invoke(path, ...)
    local remote = ResolveRemote(path)
    if not remote or not remote:IsA("RemoteFunction") then
        return false, "RemoteFunction unavailable: " .. path
    end

    local args = table.pack(...)

    local ok, a, b, c, d = pcall(function()
        return remote:InvokeServer(table.unpack(args, 1, args.n))
    end)

    if not ok then
        return false, tostring(a)
    end

    return true, a, b, c, d
end

local function Fire(path, ...)
    local remote = ResolveRemote(path)
    if not remote or not remote:IsA("RemoteEvent") then
        return false, "RemoteEvent unavailable: " .. path
    end

    local args = table.pack(...)

    local ok, err = pcall(function()
        remote:FireServer(table.unpack(args, 1, args.n))
    end)

    return ok, ok and nil or tostring(err)
end

local function WispRequest(action, value)
    local paths = {
        "RF/WispCompanion/Request",
        "RF/WispCompanion",
        "WispCompanion/Request",
    }

    for _, path in ipairs(paths) do
        local remote = ResolveRemote(path)
        if remote then
            local ok, a = Invoke(path, action, value)
            if ok then
                return true, a
            end
        end
    end

    return false, "Wisp request remote unavailable"
end

--==================================================
-- TARGET / POSITION HELPERS
--==================================================

local function CFrameOf(object)
    if not object then
        return nil
    end

    if object:IsA("BasePart") then
        return object.CFrame
    end

    if object:IsA("Attachment") then
        return object.WorldCFrame
    end

    if object:IsA("Model") then
        return object:GetPivot()
    end

    return nil
end

local function FindNamed(names)
    local lookup = {}

    for _, name in ipairs(names) do
        lookup[string.lower(name)] = true
    end

    for _, object in ipairs(Workspace:GetDescendants()) do
        if lookup[string.lower(object.Name)] then
            local cf = CFrameOf(object)
            if cf then
                return object, cf
            end
        end
    end

    return nil
end

local function FindButterflyBloom()
    local world=Workspace:FindFirstChild("World")
    local areas=world and world:FindFirstChild("Areas")
    local bloom=areas and areas:FindFirstChild("ButterflyBloom")
    local bounds=bloom and bloom:FindFirstChild("Bounds")
    if bounds and bounds:IsA("BasePart") then return bounds,bounds.CFrame+Vector3.new(0,6,0) end
    if bloom then
        local part=bloom:FindFirstChild("SpawnLocation",true) or bloom:FindFirstChild("Center",true) or bloom:FindFirstChildWhichIsA("BasePart",true)
        if part and part:IsA("BasePart") then return part,part.CFrame+Vector3.new(0,6,0) end
    end
    return nil
end

local function FindEnchantedTree()
    local world=Workspace:FindFirstChild("World")
    local build=world and world:FindFirstChild("Build")
    local forest=build and build:FindFirstChild("EnchantedForestZone")
    local spawn=forest and forest:FindFirstChild("WispSpawn")
    if spawn and spawn:IsA("BasePart") then return spawn,spawn.CFrame+Vector3.new(0,3,0) end
    local props=forest and forest:FindFirstChild("Zone13Props")
    local tree=props and props:FindFirstChild("EnchantedTree")
    local anchor=tree and tree:FindFirstChild("WispAnchor")
    if anchor and anchor:IsA("BasePart") then return anchor,anchor.CFrame+Vector3.new(0,3,0) end
    return FindNamed({"EnchantedTree","Enchanted Tree","WispAnchor"})
end

local function FindHome()
    local object, cf = FindNamed({
        "Home",
        "Base",
        "Plot",
        "SpawnLocation",
    })

    if object then
        return object, cf
    end

    local spawn = Workspace:FindFirstChildWhichIsA("SpawnLocation", true)
    if spawn then
        return spawn, spawn.CFrame
    end

    return nil
end

local function TargetByName(name)
    if name=="Butterfly Bloom" then return FindButterflyBloom() end
    if name=="Enchanted Tree" then return FindEnchantedTree() end
    if name=="Home" then return FindHome() end
    return nil
end

local function IsTreadmillSeat(seat)
    if not seat or not seat:IsA("BasePart") then return false end
    local n = string.lower(seat.Name)
    if n:find("treadmill", 1, true) then return true end
    local parent = seat.Parent
    for _ = 1, 4 do
        if not parent then break end
        local pn = string.lower(parent.Name)
        if pn:find("treadmill", 1, true) then return true end
        parent = parent.Parent
    end
    return false
end

-- The treadmill belt of OUR plot (found through the plot sign with our name).
local function GetOwnTreadmillBelt()
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return nil end
    local name = string.lower(LocalPlayer.Name)
    local display = string.lower(LocalPlayer.DisplayName)
    for _, plot in ipairs(plots:GetChildren()) do
        local belt = plot:FindFirstChild("TreadmillBottom")
        local sign = plot:FindFirstChild("PlotSign")
        if belt and belt:IsA("BasePart") and sign then
            for _, d in ipairs(sign:GetDescendants()) do
                if d:IsA("TextLabel") then
                    local t = string.lower(d.Text)
                    if t ~= "" and (string.find(t, name, 1, true) or string.find(t, display, 1, true)) then
                        return belt
                    end
                end
            end
        end
    end
    return nil
end

local LastDismountAt = 0

-- True while we are riding the treadmill. On the treadmill the game anchors the
-- character, so Anchored is the main signal; standing on our own belt counts too.
local function OnTreadmill()
    local root = Root()
    local anchored = root ~= nil and root.Anchored == true

    if not anchored and os.clock() - LastDismountAt < 4 then
        return false
    end
    if anchored then return true end

    if LocalPlayer:GetAttribute("Treadmill") or LocalPlayer:GetAttribute("OnTreadmill") or LocalPlayer:GetAttribute("BeltIndex") then
        return true
    end
    local c = Character()
    if c and (c:FindFirstChild("TreadmillWeld") or c:FindFirstChild("TreadmillAttachment")) then
        return true
    end
    local hum = Humanoid()
    if hum and hum.SeatPart and IsTreadmillSeat(hum.SeatPart) then
        return true
    end

    local belt = GetOwnTreadmillBelt()
    if belt and root then
        local rel = belt.CFrame:PointToObjectSpace(root.Position)
        if math.abs(rel.X) <= belt.Size.X / 2 + 2
            and math.abs(rel.Z) <= belt.Size.Z / 2 + 2
            and rel.Y >= -2 and rel.Y <= belt.Size.Y / 2 + 8 then
            return true
        end
    end
    return false
end

-- Ask the game to take us off the belt, free the character and jump off.
local function DismountTreadmill()
    local rf = ResolveRemote("RF/Treadmill/AskDoff")
    if rf and rf:IsA("RemoteFunction") then
        pcall(rf.InvokeServer, rf)
    end

    local root = Root()
    if root and root.Anchored then
        pcall(function() root.Anchored = false end)
    end

    local hum = Humanoid()
    if hum then
        local seat = hum.SeatPart
        pcall(function() hum.Sit = false end)
        pcall(function() hum.Jump = true end)
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
        if seat then
            local weld = seat:FindFirstChild("SeatWeld")
            if weld then pcall(function() weld:Destroy() end) end
        end
    end
    return true
end

-- Only used when an event is really about to be run: get off the treadmill first.
local function EnsureOffTreadmill(abortFn)
    if not OnTreadmill() then return true end

    local deadline = os.clock() + 2.5
    while os.clock() < deadline and alive() and not (abortFn and abortFn()) do
        local rf = ResolveRemote("RF/Treadmill/AskDoff")
        if rf and rf:IsA("RemoteFunction") then
            pcall(rf.InvokeServer, rf)
        end
        local root = Root()
        if root and not root.Anchored then break end
        task.wait(0.15)
    end

    DismountTreadmill()
    LastDismountAt = os.clock()
    task.wait(0.35)
    return not (Root() and Root().Anchored)
end

local function ClockText(seconds)
    seconds = math.max(0, math.floor((tonumber(seconds) or 0) + 0.5))
    return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

local ButterflyFlags = nil
pcall(function()
    local flags = ReplicatedStorage:FindFirstChild("Shared") and ReplicatedStorage.Shared:FindFirstChild("Flags")
    local module = flags and flags:FindFirstChild("ButterflyFlags")
    if module and module:IsA("ModuleScript") then ButterflyFlags = require(module) end
end)

local function FlagNumber(tbl, key, fallback)
    local v = tbl and tbl[key]
    if type(v) == "table" then
        if type(v.Get) == "function" then
            local ok, x = pcall(v.Get)
            if ok and tonumber(x) then return tonumber(x) end
        end
        if tonumber(v.Value) then return tonumber(v.Value) end
    end
    return fallback
end

local function ButterflySchedule()
    local interval = FlagNumber(ButterflyFlags, "IntervalSeconds", 1800)
    local offset = FlagNumber(ButterflyFlags, "OffsetSeconds", 900)
    if interval <= 0 then interval = 1800 end
    return interval, offset
end

local function ButterflyEventTimerText()
    local now = Workspace:GetServerTimeNow()
    local active = Workspace:GetAttribute("Event_ButterflyBloom") == true

    local ends = tonumber(Workspace:GetAttribute("ButterflyBloomEndsAt"))
    if active and ends and ends > now then
        return "Butterfly Bloom live, " .. ClockText(ends - now) .. " left"
    end
    if active then
        return "Butterfly Bloom live"
    end
    local interval, offset = ButterflySchedule()
    local nextAt = math.floor((now - offset) / interval) * interval + offset
    if nextAt <= now then nextAt += interval end
    return "Next Butterfly Bloom in " .. ClockText(nextAt - now)
end

local ScrambleFlags = nil
pcall(function()
    local flags = ReplicatedStorage:FindFirstChild("Shared") and ReplicatedStorage.Shared:FindFirstChild("Flags")
    local module = flags and flags:FindFirstChild("ScrambleBossFlags")
    if module and module:IsA("ModuleScript") then ScrambleFlags = require(module) end
end)

local function ScrambleInterval()
    local interval = FlagNumber(ScrambleFlags, "ScheduleIntervalSeconds", State.Scramble.EventInterval)
    if interval and interval > 0 then State.Scramble.EventInterval = interval end
    return State.Scramble.EventInterval
end

local function ScrambleEventTimerText()
    local now = Workspace:GetServerTimeNow()
    local arena = Workspace:FindFirstChild("ScrambleArena")
    local spawnAt = arena and tonumber(arena:GetAttribute("SpawnsAt")) or 0
    if Workspace:FindFirstChild("ScrambleArenaPortal") then
        if spawnAt > now then
            return "Mech portal is open  |  boss spawns in " .. ClockText(spawnAt - now)
        end
        return "Mech portal is open now"
    end
    local interval = ScrambleInterval()
    return "Next Mech portal in " .. ClockText(math.ceil(now / interval) * interval - now)
end

--==================================================
-- MOVEMENT CORE 
--==================================================

local MovementToken = 0

local function ReleaseMovement(owner)
    if State.Movement.Owner == owner or owner == nil then
        State.Movement.Owner = nil
    end

    MovementToken += 1

    local hum = Humanoid()
    if hum then
        pcall(function()
            hum:Move(Vector3.zero, false)
        end)
    end
end

local function ClaimMovement(owner)
    if State.Movement.Owner
        and State.Movement.Owner ~= owner then
        return false
    end

    State.Movement.Owner = owner
    return true
end

local function flatVec(v)
    return Vector3.new(v.X, 0, v.Z)
end

-- Runner: Heartbeat drives WalkSpeed + Humanoid:Move + horizontal velocity
-- and faces the target. Used by Butterfly, Wisp and Scramble.
local function realWalkTo(targetPos, maxSpeed, stopDist, abortFn)
    maxSpeed = tonumber(maxSpeed) or Config.WalkSpeed
    stopDist = tonumber(stopDist) or 2.2

    local hrp = Root()
    local hum = Humanoid()
    if not hrp or not hum or typeof(targetPos) ~= "Vector3" then
        return false
    end

    local done, reached = false, false
    local t0 = os.clock()
    local timeout = (flatVec(targetPos - hrp.Position).Magnitude / math.max(maxSpeed, 20)) * 2.5 + 4
    local conn
    State.Movement.BaseWalkSpeed = State.Movement.BaseWalkSpeed or hum.WalkSpeed

    conn = RunService.Heartbeat:Connect(function()
        hrp = Root()
        hum = Humanoid()
        if not hrp or not hum or not alive() then done = true; return end
        if abortFn and abortFn() then done = true; return end
        if os.clock() - t0 > timeout then done = true; return end

        local delta = flatVec(targetPos - hrp.Position)
        local dist = delta.Magnitude
        if dist <= stopDist then reached = true; done = true; return end

        local speed = maxSpeed
        if dist < 32 then speed = math.clamp(maxSpeed * (dist / 32), 40, maxSpeed) end

        hum.WalkSpeed = speed
        local dir = delta.Unit
        local look = CFrame.lookAt(hrp.Position, Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z))
        hrp.CFrame = CFrame.new(hrp.Position) * look.Rotation
        hum:Move(Vector3.new(0, 0, -1), true)
        local mv = dir * speed
        hrp.AssemblyLinearVelocity = Vector3.new(mv.X, hrp.AssemblyLinearVelocity.Y, mv.Z)
    end)

    while not done do RunService.Heartbeat:Wait() end
    conn:Disconnect()

    hum = Humanoid()
    if hum then
        hum:Move(Vector3.zero, false)
        -- give normal walking back to the player
        if State.Movement.BaseWalkSpeed then
            pcall(function() hum.WalkSpeed = State.Movement.BaseWalkSpeed end)
        end
    end
    return reached
end

-- Road-center routing: join the road lane (Z = RoadCenterZ), run along it
-- to the destination X, then leave the lane toward the destination.
local function realWalkViaRoadCenter(destPos, speed, abortFn)
    local hrp = Root()
    if not hrp or typeof(destPos) ~= "Vector3" then return false end

    local cur = hrp.Position
    local roadZ = Config.RoadCenterZ
    local wps = {}

    if math.abs(cur.Z - roadZ) > 12 then
        table.insert(wps, Vector3.new(cur.X, cur.Y, roadZ))
    end
    table.insert(wps, Vector3.new(destPos.X, destPos.Y, roadZ))
    if math.abs(destPos.Z - roadZ) > 4 then
        table.insert(wps, destPos)
    end

    for _, pt in ipairs(wps) do
        if abortFn and abortFn() then return false end
        local r = realWalkTo(pt, speed or Config.WalkSpeed, 3.2, abortFn)
        if not r and abortFn and abortFn() then return false end
    end
    return true
end

local function StopRealWalk()
    local hum = Humanoid()
    if hum then pcall(function() hum:Move(Vector3.zero,false) end) end
end

local function MoveToPosition(destination, speed, token)
    if token and token ~= MovementToken then return false end
    return realWalkViaRoadCenter(destination, speed, function()
        return token and token ~= MovementToken
    end)
end

local function PathMoveTo(destination, speed, token)
    return MoveToPosition(destination, speed, token)
end

local function MoveController(owner, targetCF, speed)
    if not ClaimMovement(owner) then return false end
    EnsureOffTreadmill()
    MovementToken += 1
    local token = MovementToken
    local ok = MoveToPosition(targetCF.Position, speed, token)
    if not ok then ReleaseMovement(owner) end
    return ok
end

-- NOTE: defined BEFORE Butterfly/Wisp so they can call it (it used to be defined
-- further down the file, which made it nil and stopped all movement).
local function MoveViaRoadCenter(owner, destinationCF, speed, abortFn)
    if not destinationCF then return false end
    if not ClaimMovement(owner) then return false end
    EnsureOffTreadmill(abortFn)
    MovementToken += 1
    local token = MovementToken
    local function cancelled()
        return (abortFn and abortFn()) or token ~= MovementToken or State.Movement.Owner ~= owner
    end
    local ok = realWalkViaRoadCenter(destinationCF.Position, speed or Config.WalkSpeed, cancelled)
    if not ok then ReleaseMovement(owner) end
    return ok
end

--==================================================
-- TASK PRIORITY
--==================================================

local function TaskRank(name)
    return State.Task.Rank[name] or 99
end

local function SetTaskOwner(owner)
    State.Task.Owner = owner
end

local function TaskCanRun(owner)
    if not State.Task.Owner then
        return true
    end

    return State.Task.Owner == owner
end

local function PriorityMessage()
    if State.Butterfly.Busy or State.Butterfly.Claiming then
        return "Butterfly Bloom goes first"
    end

    if State.Wisp.Busy then
        return "Wisp goes first"
    end

    if State.Movement.Owner then
        return "Movement: " .. tostring(State.Movement.Owner)
    end

    return "Idle"
end

--==================================================
-- BUTTERFLY
--==================================================

local TierMap = {
    ["Radiant Butterfly"] = "Golden",
    ["Amethyst Butterfly"] = "Purple",
    ["Sapphire Butterfly"] = "Blue",
    ["Emerald Butterfly"] = "Green",

    ["Legendary (Radiant)"] = "Golden",
    ["Epic (Amethyst)"] = "Purple",
    ["Rare (Sapphire)"] = "Blue",
    ["Common (Emerald)"] = "Green",

    Golden = "Golden",
    Purple = "Purple",
    Blue = "Blue",
    Green = "Green",
}

local function ButterflySelected(name)
    local tier = TierMap[name] or name
    return State.Butterfly.Tiers[tier] == true
end

local function ButterflyBloomActive()
    return Workspace:GetAttribute("Event_ButterflyBloom") == true
end
local ButterflySwarm
local ButterflyCatalog
pcall(function()
    local shared = ReplicatedStorage:FindFirstChild("Shared")
    local modules = shared and shared:FindFirstChild("Modules")
    local cat = modules and modules:FindFirstChild("ButterflyCatalog")
    if cat and cat:IsA("ModuleScript") then ButterflyCatalog = require(cat) end
end)
pcall(function()
    local c=ReplicatedStorage:FindFirstChild("Controllers"); local g=c and c:FindFirstChild("Game"); local a=g and g:FindFirstChild("AdminAbuseClientController"); local e=a and a:FindFirstChild("Events"); local b=e and e:FindFirstChild("ButterflyBloom"); local m=b and b:FindFirstChild("Swarm")
    if m and m:IsA("ModuleScript") then ButterflySwarm=require(m) end
end)
local function ButterflyPart(x)
    if typeof(x)~="Instance" then return nil end
    if x:IsA("BasePart") then return x end
    if x:IsA("Model") then return x.PrimaryPart or x:FindFirstChild("HumanoidRootPart") or x:FindFirstChildWhichIsA("BasePart",true) end
end
local function GetButterflyTargets()
    local out, seen = {}, {}
    local wanted = {Golden="Radiant Butterfly",Purple="Amethyst Butterfly",Blue="Sapphire Butterfly",Green="Emerald Butterfly"}

    local function add(id, tier, body, flight, posOverride)
        tier = tostring(tier or "Green")
        local name = wanted[tier]
        if not name or not ButterflySelected(name) then return end
        local part = ButterflyPart(body)
        local pos = part and part.Position or posOverride
        if not pos then return end
        local key = tostring(id or part or pos)
        if seen[key] then return end
        seen[key] = true
        table.insert(out, {Id=id, Object=body, Name=name, Tier=tier, Position=pos, Flight=flight})
    end

    pcall(function()
        if ButterflySwarm and type(ButterflySwarm.Each) == "function" then
            for id, data in ButterflySwarm.Each() do
                local f = type(data) == "table" and data.Flight or nil
                local body = type(data) == "table" and data.Body or nil
                local tier = (type(f) == "table" and f.Tier) or (type(data) == "table" and data.Tier)
                local fid = (type(f) == "table" and f.Id) or id
                local pos
                if not ButterflyPart(body) and ButterflyCatalog and type(ButterflyCatalog.PositionAt) == "function" and type(f) == "table" then
                    local ok, p = pcall(ButterflyCatalog.PositionAt, f, Workspace:GetServerTimeNow())
                    if ok and typeof(p) == "Vector3" then pos = p end
                end
                add(fid, tier, body, f, pos)
            end
        end
    end)

    local swarm = Workspace:FindFirstChild("ButterflyBloomSwarm")
    if swarm then
        for _, d in ipairs(swarm:GetDescendants()) do
            if d:IsA("Model") or d:IsA("BasePart") then
                local n = string.lower(d.Name)
                local tier = n:find("radiant") and "Golden" or n:find("amethyst") and "Purple" or n:find("sapphire") and "Blue" or n:find("emerald") and "Green"
                if tier then add(nil, tier, d) end
            end
        end
    end
    return out
end

local function IsButterflyNetTool(t)
    if typeof(t) ~= "Instance" or not t:IsA("Tool") then return false end
    local itemType = tostring(t:GetAttribute("ItemType") or "")
    local gearLower = string.lower(tostring(t:GetAttribute("GearName") or ""))
    local toolName = string.lower(t.Name)
    return t:GetAttribute("ButterflyNet") == true
        or itemType == "ButterflyNet"
        or toolName == "butterfly net"
        or toolName:find("butterfly", 1, true) ~= nil
        or gearLower:find("butterfly", 1, true) ~= nil
        or gearLower:find("net", 1, true) ~= nil
end

local function FindButterflyNet()
    for _, container in ipairs({Character(), Backpack()}) do
        if container then
            for _, t in ipairs(container:GetChildren()) do
                if IsButterflyNetTool(t) then return t end
            end
        end
    end
    return nil
end

local function EquipButterflyNet()
    local net = FindButterflyNet()
    if not net then return nil end
    local c, h = Character(), Humanoid()
    if c and h and net.Parent ~= c then
        pcall(function() h:EquipTool(net) end)
        task.wait(.08)
    end
    return net
end

--------------------------------------------------
-- Bloom movement: once inside the bloom everything is driven by
-- direct velocity / snapping (NO road-lane routing). The lane is only used
-- to get to the bloom from far away.
--------------------------------------------------
local BloomRayParams = RaycastParams.new()
BloomRayParams.FilterType = Enum.RaycastFilterType.Exclude

local TierBonus = {Golden = 4, Purple = 1.6, Blue = 0.8, Green = 0}
local TierLabel = {Green = "Emerald", Blue = "Sapphire", Purple = "Amethyst", Golden = "Radiant"}

local function BloomBoundsPart()
    local world = Workspace:FindFirstChild("World")
    local areas = world and world:FindFirstChild("Areas")
    local bloom = areas and areas:FindFirstChild("ButterflyBloom")
    local b = bloom and bloom:FindFirstChild("Bounds")
    if b and b:IsA("BasePart") then return b end
    return nil
end

local function BloomCenter()
    local b = BloomBoundsPart()
    if b then return b.Position + Vector3.new(0, 6, 0) end
    return Vector3.new(6700, 74, -364)
end

local function InBloomArea(pos)
    local b = BloomBoundsPart()
    if not b then return true end
    local rel = b.CFrame:PointToObjectSpace(pos)
    return math.abs(rel.X) <= b.Size.X / 2 + 80
        and math.abs(rel.Z) <= b.Size.Z / 2 + 80
        and math.abs(rel.Y) <= 120
end

local function BloomGround(p)
    local ch, root, hum = Character(), Root(), Humanoid()
    if not ch or not root then return p end
    local swarm = Workspace:FindFirstChild("ButterflyBloomSwarm")
    BloomRayParams.FilterDescendantsInstances = swarm and {ch, swarm} or {ch}
    local hit = Workspace:Raycast(p + Vector3.new(0, 25, 0), Vector3.new(0, -120, 0), BloomRayParams)
    if not hit then return p end
    local h = (hum and hum.HipHeight or 2) + root.Size.Y / 2
    return Vector3.new(p.X, hit.Position.Y + h, p.Z)
end

local function BloomFacing()
    local b = BloomBoundsPart()
    local d = Vector3.new(0, 0, -1)
    if b then
        local v = b.Size.X >= b.Size.Z and b.CFrame.LookVector or b.CFrame.RightVector
        local f = Vector3.new(v.X, 0, v.Z)
        if f.Magnitude > 0.1 then d = f.Unit end
    end
    return CFrame.lookAt(Vector3.zero, d)
end

local function BloomPatrolPoint()
    local b = BloomBoundsPart()
    if not b then return BloomCenter() end
    local B = State.Butterfly
    local xAxis = b.Size.X >= b.Size.Z
    local axis = xAxis and b.CFrame.RightVector or b.CFrame.LookVector
    axis = Vector3.new(axis.X, 0, axis.Z).Unit
    local O = math.max(20, (xAxis and b.Size.X or b.Size.Z) / 2 - 30)
    local now = os.clock()
    B.PatrolTravel = ((B.PatrolTravel or 0) + (B.Speed or 320) * math.clamp(now - (B.PatrolAt or now), 0, 0.1)) % (4 * O)
    B.PatrolAt = now
    local t = B.PatrolTravel
    local r = t < 2 * O and t - O or 3 * O - t
    return b.Position + axis * r + Vector3.new(0, 6, 0)
end

local function BloomCirclePoint()
    local b = BloomBoundsPart()
    if not b then return BloomCenter() end
    local B = State.Butterfly
    local right = Vector3.new(b.CFrame.RightVector.X, 0, b.CFrame.RightVector.Z).Unit
    local look = Vector3.new(b.CFrame.LookVector.X, 0, b.CFrame.LookVector.Z).Unit
    local now = os.clock()
    B.CircleAngle = ((B.CircleAngle or 0) + (B.Speed or 320) / 25 * math.clamp(now - (B.CircleAt or now), 0, 0.1)) % (math.pi * 2)
    B.CircleAt = now
    return b.Position + right * (math.cos(B.CircleAngle) * 25) + look * (math.sin(B.CircleAngle) * 25) + Vector3.new(0, 6, 0)
end

local function PickButterfly(list, fromPos)
    local best, bestScore
    for _, t in ipairs(list) do
        if InBloomArea(t.Position) then
            local score = (t.Position - fromPos).Magnitude / math.max(State.Butterfly.Speed, 1)
            if State.Butterfly.Priority == "Rarest" then
                score = score - (TierBonus[t.Tier] or 0)
            end
            if not bestScore or score < bestScore then
                best, bestScore = t, score
            end
        end
    end
    return best
end

-- velocity mover : speed capped so we land exactly on the point
local function BloomMoveTo(target, dt)
    local root = Root()
    if not root then return math.huge end
    local diff = target - root.Position
    local dist = diff.Magnitude
    if dist < 0.5 then
        pcall(function()
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)
        return dist
    end
    local spd = math.min(State.Butterfly.Speed, dist / math.max(dt, 1 / 60))
    pcall(function()
        root.AssemblyLinearVelocity = diff.Unit * spd
        root.AssemblyAngularVelocity = Vector3.zero
    end)
    return dist
end

local function BloomStop()
    local root, hum = Root(), Humanoid()
    if root then
        pcall(function()
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)
    end
    if hum then pcall(function() hum.AutoRotate = true end) end
end

-- Give the player their character back (only if we were driving it).
local function ButterflyRelease()
    local B = State.Butterfly
    if B.Controlling then
        B.Controlling = false
        BloomStop()
        ReleaseMovement("butterfly")
    end
end

local function ButterflyBody(token)
    local B = State.Butterfly

    local net
    local lastSwing = 0
    local statusAt = 0
    -- in-bloom status text only changes about once a second (no flicker)
    local function setStatus(text)
        local now = os.clock()
        if now - statusAt >= 1 then
            B.Status = text
            statusAt = now
        end
    end
    local MODE_TEXT = {Stand = "Standing in the bloom", Patrol = "Patrolling the bloom", Circle = "Circling the bloom"}

    local function swing()
        local now = os.clock()
        if now - lastSwing < 0.06 then return end
        lastSwing = now
        if net and net.Parent then
            pcall(function() net:Activate() end)
        end
    end

    while not token.Cancelled and alive() and B.Enabled do
        local dt = RunService.Heartbeat:Wait()

        -- Night: stop until daylight, then carry on by itself.
        if IsNight() then
            B.Status = "Night, paused until daylight"
            ButterflyRelease()
            task.wait(0.4)
            continue
        end

        if not ButterflyBloomActive() then
            B.Status = "Waiting for Butterfly Bloom"
            ButterflyRelease()
            task.wait(0.25)
            continue
        end

        local root = Root()
        if not root then task.wait(0.2); continue end

        -- Bloom is live: first make sure we own a net.
        local ch = Character()
        if not net or net.Parent ~= ch then
            net = EquipButterflyNet()
        end
        if not net then
            B.Status = "No Butterfly Net"
            ButterflyRelease()
            task.wait(0.5)
            continue
        end

        -- Bloom is live and we have a net: get off the treadmill, then go.
        if OnTreadmill() then
            B.Status = "Getting off the treadmill"
            B.Controlling = true
            EnsureOffTreadmill(function()
                return token.Cancelled or not B.Enabled or IsNight()
            end)
            root = Root()
            if not root then continue end
        end

        -- Far away: use the road lane ONLY to reach the bloom.
        if not InBloomArea(root.Position) then
            B.Status = "Going to the butterfly bloom"
            B.Controlling = true
            MoveViaRoadCenter("butterfly", CFrame.new(BloomCenter()), B.Speed, function()
                return token.Cancelled or not B.Enabled or not ButterflyBloomActive() or IsNight()
            end)
            ReleaseMovement("butterfly")
            continue
        end

        -- Inside the bloom: direct movement, no routing.
        B.Controlling = true
        local hum = Humanoid()
        if hum then pcall(function() hum.AutoRotate = false end) end

        local targets = GetButterflyTargets()
        local facing = BloomFacing()
        local reach = B.Reach or 14

        if B.Mode ~= "Chase" then
            local near = {}
            for _, t in ipairs(targets) do
                if (t.Position - root.Position).Magnitude <= reach - 2 then
                    table.insert(near, t)
                end
            end
            local best = PickButterfly(near, root.Position)

            local pt
            if B.Mode == "Patrol" then
                pt = BloomPatrolPoint()
            elseif B.Mode == "Circle" then
                pt = BloomCirclePoint()
            else
                pt = BloomCenter()
            end
            pt = BloomGround(pt)

            if (pt - root.Position).Magnitude > 8 then
                BloomMoveTo(pt, dt)
                pcall(function()
                    root.CFrame = CFrame.new(root.Position) * facing
                    root.AssemblyAngularVelocity = Vector3.zero
                end)
                setStatus("Moving to the middle of the bloom")
            else
                pcall(function()
                    root.CFrame = CFrame.new(pt) * facing
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                end)
                setStatus(string.format("%s  |  %d flying", MODE_TEXT[B.Mode] or "In the bloom", #targets))
            end

            if best then swing() end
        else
            local target
            local lock = B.ChaseLock
            if lock and lock.Id ~= nil and os.clock() < lock.Until then
                for _, t in ipairs(targets) do
                    if t.Id == lock.Id then target = t break end
                end
            end
            if not target then
                target = PickButterfly(targets, root.Position)
                if target and target.Id ~= nil then
                    B.ChaseLock = {Id = target.Id, Until = os.clock() + 1}
                end
            end

            if target then
                local vel = Vector3.zero
                if ButterflyCatalog and type(ButterflyCatalog.VelocityAt) == "function" and type(target.Flight) == "table" then
                    local ok, v = pcall(ButterflyCatalog.VelocityAt, target.Flight, Workspace:GetServerTimeNow())
                    if ok and typeof(v) == "Vector3" then vel = v end
                end
                local lead = vel.Magnitude > 0.1 and vel.Unit * 1.5 or Vector3.zero
                local from = root.Position
                local dist = (target.Position - from).Magnitude
                local aim = target.Position + lead

                if (aim - from).Magnitude <= 8 then
                    pcall(function()
                        root.CFrame = CFrame.new(aim) * facing
                        root.AssemblyLinearVelocity = Vector3.new(vel.X, 0, vel.Z)
                        root.AssemblyAngularVelocity = Vector3.zero
                    end)
                else
                    BloomMoveTo(aim, dt)
                    pcall(function()
                        root.CFrame = CFrame.new(root.Position) * facing
                        root.AssemblyAngularVelocity = Vector3.zero
                    end)
                end

                setStatus(string.format("Chasing %s butterflies  |  %d flying", TierLabel[target.Tier] or target.Tier, #targets))
                if dist <= reach - 2 then swing() end
            else
                BloomMoveTo(BloomGround(BloomCenter()), dt)
                setStatus("Waiting for butterflies")
            end
        end
    end
end

local function StartButterflyLoop(token)
    local B = State.Butterfly
    B.Busy = true
    SetTaskOwner("butterfly")

    local ok, err = pcall(ButterflyBody, token)

    -- always hand the character back, even after an error
    ButterflyRelease()
    B.Busy = false
    ReleaseMovement("butterfly")
    if not B.Enabled then B.Status = "Off" end
    if not ok and not token.Cancelled then
        warn("[Cologne/Butterfly] " .. tostring(err))
    end
end

--==================================================
-- WISP
--==================================================
local WispQuestList; local WispStageCount=4; local WispRequired=50000000000
pcall(function() local d=ReplicatedStorage:FindFirstChild("Data"); local q=d and d:FindFirstChild("WispQuests"); if q and q:IsA("ModuleScript") then local x=require(q); if type(x)=="table" then WispQuestList=x.List; WispStageCount=tonumber(x.StageCount) or 4; WispRequired=tonumber(x.RequiredSpeedPower) or WispRequired end end end)
State.Wisp.Required=WispRequired; State.Wisp.StageCount=WispStageCount
local WispSaveProvider
local function ReadSaveFromObject(obj)
    if type(obj) ~= "table" then return nil, nil end
    local function readProvider(provider)
        if type(provider) ~= "table" then return nil end
        local getter = provider.Get or provider.Peek
        if type(getter) ~= "function" then return nil end
        local ok, data = pcall(getter)
        if ok and type(data) == "table" then return data end
        ok, data = pcall(getter, provider)
        if ok and type(data) == "table" then return data end
        return nil
    end
    local save = type(obj.Save) == "table" and obj.Save or nil
    local data = readProvider(save or obj)
    if type(data) ~= "table" then return nil, nil end
    if type(data.WispCompanion) ~= "table" and data.SpeedPower == nil then return nil, nil end
    return data, save or obj
end

local function SaveScore(data)
    if type(data) ~= "table" then return -1 end
    local w = type(data.WispCompanion) == "table" and data.WispCompanion or {}
    local score = 0
    if w.Unlocked == true then score += 1000000000 end
    if w.Accepted == true then score += 100000000 end
    local sp = tonumber(data.SpeedPower)
    if sp and sp > 0 then score += math.min(sp, 10000000) end
    if type(w.Stage) == "number" then score += math.min(w.Stage, 100) end
    return score
end

local WispLastScan = 0
local function GetWispSaveTable()
    -- fast path: keep reading the provider we already found
    if WispSaveProvider and os.clock() - WispLastScan < 30 then
        local cached = ReadSaveFromObject(WispSaveProvider)
        if cached then return cached end
    end
    WispLastScan = os.clock()

    local candidates = {}
    local g = (getgenv and getgenv()) or _G
    for _,key in ipairs({"Save","StateSave","PlayerSave","SaveData"}) do
        if type(g[key]) == "table" then table.insert(candidates,g[key]) end
    end

    pcall(function()
        local shared = ReplicatedStorage:FindFirstChild("Shared")
        local saveModule = shared and shared:FindFirstChild("Save")
        if saveModule and saveModule:IsA("ModuleScript") then
            local provider = require(saveModule)
            if type(provider) == "table" then table.insert(candidates, provider) end
        end
    end)
    if type(getgc) == "function" then
        pcall(function()
            for _,obj in ipairs(getgc(true)) do
                if type(obj) == "table" then
                    if type(obj.Save) == "table" then table.insert(candidates,obj) end
                    if type(obj.Get) == "function" or type(obj.Peek) == "function" then table.insert(candidates,obj) end
                end
            end
        end)
    end
    local bestData, bestProvider, bestScore = nil, nil, -1
    for _,obj in ipairs(candidates) do
        local data, provider = ReadSaveFromObject(obj)
        if data then
            local score = SaveScore(data)
            if score > bestScore then
                bestData, bestProvider, bestScore = data, provider, score
            end
        end
    end
    if bestData then
        WispSaveProvider = bestProvider
        return bestData
    end
    if WispSaveProvider then
        local data = ReadSaveFromObject(WispSaveProvider)
        if data then return data end
    end
    return nil
end
local function ReadWispState()
    local data=GetWispSaveTable()
    if type(data)=="table" then
        local w=type(data.WispCompanion)=="table" and data.WispCompanion or {}
        local ws=type(w.State)=="table" and w.State or w
        State.Wisp.Accepted=ws.Accepted==true
        State.Wisp.Unlocked=ws.Unlocked==true
        State.Wisp.Returning=ws.Returning==true
        State.Wisp.Stage=tonumber(ws.Stage) or State.Wisp.Stage
        State.Wisp.Progress=type(ws.Progress)=="table" and ws.Progress or {}
        State.Wisp.Claimed=type(ws.Claimed)=="table" and ws.Claimed or {}
        State.Wisp.SpeedPower=tonumber(data.SpeedPower) or tonumber(GetAttribute("SpeedPower",0)) or 0
    else
        State.Wisp.SpeedPower=tonumber(GetAttribute("SpeedPower",0)) or 0
    end
    State.Wisp.Revealed=ForestRevealed()

    if Workspace:GetAttribute("EnchantedTreeUnlocked") == true then
        State.Wisp.Unlocked = true
    end

    local build = GetWorldBuild()
    if build and build:GetAttribute("EnchantedTreeUnlocked") == true then
        State.Wisp.Unlocked = true
    end
    local world = Workspace:FindFirstChild("World")
    local build2 = world and world:FindFirstChild("Build")
    if build2 and build2:GetAttribute("EnchantedTreeUnlocked") == true then
        State.Wisp.Unlocked = true
    end
    if LocalPlayer:GetAttribute("EnchantedTreeUnlocked") == true
        or LocalPlayer:GetAttribute("WispUnlocked") == true then
        State.Wisp.Unlocked = true
    end

    if State.Wisp.Unlocked == true then
        State.Wisp.Accepted = true
    end
end
local function WispPoint(path) local cur=Workspace:FindFirstChild("World"); for seg in string.gmatch(path,"[^/]+") do cur=cur and cur:FindFirstChild(seg) end; if cur and cur:IsA("BasePart") then return cur.Position end if cur and cur:IsA("Model") then return cur:GetPivot().Position end end
local function CurrentWispQuest() return WispQuestList and WispQuestList[tonumber(State.Wisp.Stage) or 1] or nil end
local function WispLoop(token)
    State.Movement.Speed = math.clamp(
        tonumber(State.Movement.Speed) or Config.WispSpeed or Config.WalkSpeed,
        40, 600
    )
    ReadWispState()
    while not token.Cancelled and alive() and State.Wisp.Enabled do
        ReadWispState(); if State.Wisp.Unlocked then State.Wisp.Status="Done, the Enchanted Tree is open"; task.wait(1); continue end
        if not State.Wisp.Accepted and State.Wisp.SpeedPower<State.Wisp.Required then State.Wisp.Status=string.format("Needs %.0fB Speed  |  You have %.2fB",State.Wisp.Required/1e9,State.Wisp.SpeedPower/1e9); task.wait(1); continue end
        if not State.Wisp.Revealed then State.Wisp.Status="Enchanted Forest is not open yet"; task.wait(1); continue end
        if not State.Wisp.Accepted then State.Wisp.Busy=true; SetTaskOwner("wisp"); State.Wisp.Status="Meeting the Wisp"; local pos=WispPoint("Build/EnchantedForestZone/WispSpawn"); if pos then MoveController("wisp",CFrame.new(pos+Vector3.new(0,3,0)),State.Movement.Speed) end; local ok,a=WispRequest("Accept"); State.Wisp.Status=ok and "Wisp accepted" or ("Accept: "..tostring(a or "no answer")); State.Wisp.Busy=false; ReleaseMovement("wisp"); task.wait(.5); continue end
        local q=CurrentWispQuest(); if q then local progress=tonumber(State.Wisp.Progress[q.Id]) or 0; local target=tonumber(q.Target) or 1; if not State.Wisp.Claimed[q.Id] and progress>=target then State.Wisp.Busy=true; SetTaskOwner("wisp"); State.Wisp.Status="Claiming "..tostring(q.Title); local ok,a=WispRequest("Claim",q.Id); if not ok then State.Wisp.Status="Claim: "..tostring(a or "no answer") end; State.Wisp.Busy=false; ReleaseMovement("wisp"); task.wait(.5); continue end; State.Wisp.Status=string.format("Stage %d/%d  |  %s %d/%d",tonumber(State.Wisp.Stage) or 1,State.Wisp.StageCount,tostring(q.Title),progress,target); task.wait(.5); continue end
        if (tonumber(State.Wisp.Stage) or 1)>=State.Wisp.StageCount then State.Wisp.Busy=true; SetTaskOwner("wisp"); if not State.Wisp.Returning then WispRequest("BeginReturn") end; local pos=WispPoint("Build/EnchantedForestZone/Zone13Props/EnchantedTree/WispAnchor"); if pos then State.Wisp.Status="Taking the Wisp back to the Enchanted Tree"; MoveController("wisp",CFrame.new(pos+Vector3.new(0,3,0)),State.Movement.Speed) end; local ok,a=WispRequest("Return"); State.Wisp.Status=ok and "Wisp returned, the seal is broken" or ("Return: "..tostring(a or "no answer")); State.Wisp.Busy=false; ReleaseMovement("wisp"); task.wait(.75); continue end
        task.wait(.5)
    end
    State.Wisp.Busy=false; ReleaseMovement("wisp")
end

-- ANTI-GUARD
--==================================================

local AntiGuardOriginal = {}
local AntiGuardLastScan = 0

local function ApplyNoCollision()
    if not State.AntiGuard.Enabled then
        return
    end

    local c = Character()
    if not c then
        return
    end

    for _, part in ipairs(c:GetDescendants()) do
        if part:IsA("BasePart") then
            if AntiGuardOriginal[part] == nil then
                AntiGuardOriginal[part] = part.CanCollide
            end

            part.CanCollide = false
        end
    end
end

local function RestoreCollision()
    for part, original in pairs(AntiGuardOriginal) do
        if part and part.Parent then
            pcall(function()
                part.CanCollide = original
            end)
        end
    end

    table.clear(AntiGuardOriginal)
end

local function AntiGuardLoop(token)
    while not token.Cancelled and alive() do
        if State.AntiGuard.Enabled then
            ApplyNoCollision()

            local hrp = Root()

            if hrp then
                local jitter = State.AntiGuard.Jitter

                if jitter > 0 then
                    local offset = Vector3.new(
                        (math.random() - 0.5) * jitter,
                        0,
                        (math.random() - 0.5) * jitter
                    )

                    pcall(function()
                        hrp.CFrame = hrp.CFrame + offset
                    end)
                end

                if State.AntiGuard.Freeze then
                    hrp.AssemblyLinearVelocity = Vector3.zero
                end
            end
        else
            RestoreCollision()
        end

        task.wait(State.AntiGuard.WeldScanGap)
    end

    RestoreCollision()
end

--==================================================
-- HEARTBEAT CONTROLLER
--==================================================

local Runtime = {
    Heartbeat = nil,
    Stepped = nil,
    RenderStepped = nil,
}

Runtime.Heartbeat = AddConnection(
    RunService.Heartbeat:Connect(function(dt)
        if not alive() then
            State.Alive = false
            return
        end

        State.Movement.LastMove =
            State.Movement.LastMove + dt

        if State.Butterfly.Enabled and EventActive("Event_ButterflyBloom") then
            if not State.Butterfly.Busy then
                State.Task.Waiting.butterfly = os.clock()
            end
        end
    end)
)

Runtime.Stepped = AddConnection(
    RunService.Stepped:Connect(function()
        if State.AntiGuard.Enabled then
            ApplyNoCollision()
        end
    end)
)

Runtime.RenderStepped = AddConnection(
    RunService.RenderStepped:Connect(function()
    end)
)

--==================================================
-- CHARACTER RESPAWN HANDLING
--==================================================

AddConnection(
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.5)

        MovementToken += 1
        State.Movement.Owner = nil
        State.Butterfly.Busy = false
        State.Butterfly.Claiming = false
        State.Wisp.Busy = false
        State.Scramble.Run = nil
        State.Scramble.HumanModel = nil
        State.Butterfly.ChaseLock = nil

        if State.AntiGuard.Enabled then
            ApplyNoCollision()
        end
    end)
)

--==================================================
-- SCRAMBLE / MECH BOSS
--==================================================

local function ScrambleArena()
    return Workspace:FindFirstChild("ScrambleArena")
end

local function ScramblePortal()
    return Workspace:FindFirstChild("ScrambleArenaPortal")
end

local function InScrambleArena()
    local ch = LocalPlayer.Character
    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    if LocalPlayer:GetAttribute("InScrambleArena") == true then return true end
    local arena = ScrambleArena()
    if not arena then return false end
    local ok, cf = pcall(function() return arena:GetPivot() end)
    if not ok or typeof(cf) ~= "CFrame" then return false end
    local d = Vector2.new(hrp.Position.X-cf.Position.X, hrp.Position.Z-cf.Position.Z).Magnitude
    return d < 900 and math.abs(hrp.Position.Y-cf.Position.Y) < 400
end

local function ScrambleHitbox(model)
    if not model then return nil end
    local h=model:FindFirstChild("Hitbox",true)
    return h and h:IsA("BasePart") and h or nil
end

local function ScrambleBoss(arena)
    if not arena then return nil,nil end
    local mech=arena:FindFirstChild("Mech")
    local hit=ScrambleHitbox(mech)
    if hit then return hit,mech end
    for _,v in ipairs(arena:GetChildren()) do
        if v:IsA("Model") and v.Name~="Ball" and v.Name~="LeaveTeleport" and v.Name~="Structure" then
            hit=ScrambleHitbox(v)
            if hit then return hit,v end
        end
    end
    return nil,nil
end

local function FindScrambler()
    local ch=LocalPlayer.Character
    local bag=LocalPlayer:FindFirstChildOfClass("Backpack")
    for _,container in ipairs({ch,bag}) do
        if container then
            for _,tool in ipairs(container:GetChildren()) do
                if tool:IsA("Tool") and tostring(tool:GetAttribute("ItemType"))=="Gear" then
                    local n=string.lower(tostring(tool:GetAttribute("GearName") or ""))
                    if string.find(n,"scrambler",1,true) then return tool end
                end
            end
        end
    end
end

local function IsBatTool(tool)
    if typeof(tool) ~= "Instance" or not tool:IsA("Tool") then return false end
    if tool:GetAttribute("IsBat") == true then return true end
    local gn = tool:GetAttribute("GearName")
    local dir = GearsModule and GearsModule.Directory
    if type(gn) == "string" and type(dir) == "table" then
        local info = dir[gn]
        return type(info) == "table" and type(info.BatControllerData) == "table"
    end
    if tool:GetAttribute("ItemType") ~= nil then return false end
    local n = string.lower(tool.Name)
    for _, kw in ipairs({"bat","katana","axe","staff","club","hammer","sword","blade"}) do
        if string.find(n, kw, 1, true) then return true end
    end
    return false
end

local function FindMainWeapon()
    local ch = LocalPlayer.Character
    local bag = LocalPlayer:FindFirstChildOfClass("Backpack")
    local current = ch and ch:FindFirstChildWhichIsA("Tool")
    if IsBatTool(current) then return current end
    local best, bestRange = nil, -math.huge
    local dir = GearsModule and GearsModule.Directory
    for _, container in ipairs({ch, bag}) do
        if container then
            for _, tool in ipairs(container:GetChildren()) do
                if IsBatTool(tool) then
                    local gn = tool:GetAttribute("GearName")
                    local info = type(dir) == "table" and gn and dir[gn] or nil
                    local range = type(info) == "table" and info.BatControllerData and tonumber(info.BatControllerData.RangeBonus) or 0
                    if range > bestRange then bestRange, best = range, tool end
                end
            end
        end
    end
    if best then return best end
    if type(_G.FindBat) == "function" then
        local ok, tool = pcall(_G.FindBat)
        if ok and tool then return tool end
    end
end

local function ScrambleEquip(tool)
    local hum = Humanoid()
    local ch = LocalPlayer.Character
    if not tool or not hum or not ch then return false end
    if tool.Parent ~= ch then
        pcall(function() hum:EquipTool(tool) end)
        if tool.Parent ~= ch then pcall(function() tool.Parent = ch end) end
    end
    return tool.Parent == ch
end

local function ScrambleSwing()
    local now = os.clock()
    if now - State.Scramble.LastSwing < State.Scramble.SwingGap then return end
    State.Scramble.LastSwing = now
    local main = FindMainWeapon()
    local second = State.Scramble.SwapTools and FindScrambler() or nil
    local tool
    if main and second and main ~= second then
        local hold = State.Scramble.SwapIndex == 2 and State.Scramble.SecondHold or State.Scramble.MainHold
        if now - State.Scramble.SwapSince >= math.max(0.03, hold) then
            State.Scramble.SwapIndex = State.Scramble.SwapIndex == 2 and 1 or 2
            State.Scramble.SwapSince = now
        end
        tool = State.Scramble.SwapIndex == 2 and second or main
    else
        tool = main or second
    end
    if tool and ScrambleEquip(tool) then
        pcall(function() tool:Activate() end)
        task.defer(function() pcall(function() tool:Deactivate() end) end)
    end
end

local function ScrambleTouch(part)
    local root=Root()
    if not root or not part or type(firetouchinterest)~="function" then return false end
    pcall(function()
        firetouchinterest(root,part,0)
        task.wait(0.05)
        firetouchinterest(root,part,1)
    end)
    return true
end

local function ScrambleLeave()
    local arena=ScrambleArena()
    if not arena then return true end
    local tp=arena:FindFirstChild("LeaveTeleport",true)
    local hit=ScrambleHitbox(tp) or (tp and tp:IsA("BasePart") and tp)
    if not hit then return false end
    local root=Root()
    if root then
        pcall(function()
            root.CFrame=CFrame.new(hit.Position+Vector3.new(0,3,0))
            root.AssemblyLinearVelocity=Vector3.zero
            root.AssemblyAngularVelocity=Vector3.zero
        end)
    end
    ScrambleTouch(hit)
    return true
end

local function ScrambleEnter()
    local portal=ScramblePortal()
    if not portal then return false end
    local hit=ScrambleHitbox(portal) or (portal:IsA("BasePart") and portal)
    local root=Root()
    if not hit or not root then return false end
    pcall(function()
        root.CFrame=hit.CFrame+Vector3.new(0,1,0)
        root.AssemblyLinearVelocity=Vector3.zero
        root.AssemblyAngularVelocity=Vector3.zero
    end)
    ScrambleTouch(hit)
    task.wait(0.4)
    if InScrambleArena() then return true end
    local rf=ResolveRemote("RF/ScrambleBoss/EnterArena")
    if rf and rf:IsA("RemoteFunction") then pcall(function() rf:InvokeServer() end) end
    task.wait(0.25)
    return InScrambleArena()
end

local function IsScrambleHazardAt(position, serverTime)
    if not State.Scramble.Dodge or not ScrambleBossHazards or type(ScrambleBossHazards.Contains) ~= "function" then return false end
    for id, hazard in pairs(State.Scramble.Hazards) do
        local at = tonumber(hazard.At) or 0
        local warnT = tonumber(hazard.Warn) or 0
        local duration = tonumber(hazard.Duration) or 0.5
        if at + duration + 1.5 < serverTime then
            State.Scramble.Hazards[id] = nil
        elseif serverTime >= at - warnT - 0.1 then
            local ok, inside = pcall(ScrambleBossHazards.Contains, hazard, position, serverTime)
            if ok and inside then return true end
        end
    end
    return false
end

local function ScrambleSnapTo(position, lookAt)
    local ch, root = LocalPlayer.Character, Root()
    if not ch or not root then return end
    if (root.Position - position).Magnitude <= 3 then return end
    local cf = lookAt and CFrame.lookAt(position, Vector3.new(lookAt.X, position.Y, lookAt.Z)) or CFrame.new(position) * root.CFrame.Rotation
    pcall(function()
        ch:PivotTo(cf)
        root.AssemblyLinearVelocity = Vector3.zero
    end)
end

local function ScrambleStopHorizontal()
    local root = Root()
    if root then
        pcall(function()
            root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
        end)
    end
end

-- Ball phase: the glowing coil is run INTO (its Home point), and we wait
-- there for the ball; when the core is stunned we stand next to it and smash.
local function ScrambleBallPhase(arena, root)
    local S = State.Scramble
    local ball = arena:FindFirstChild("Ball")
    if not ball then return false end

    local ballPos
    if ball:IsA("BasePart") then
        ballPos = ball.Position
    else
        local ok, cf = pcall(function() return (ball:GetBoundingBox()) end)
        if not ok or typeof(cf) ~= "CFrame" then return false end
        ballPos = cf.Position
    end

    local floorY = (tonumber(arena:GetAttribute("FloorY")) or ballPos.Y) + 3
    local stage = tonumber(arena:GetAttribute("CoreStage")) or 0

    if arena:GetAttribute("BallStunned") == true then
        S.Run = nil
        local away = Vector3.new(root.Position.X - ballPos.X, 0, root.Position.Z - ballPos.Z)
        local dir = away.Magnitude > 1 and away.Unit or Vector3.new(1, 0, 0)
        ScrambleSnapTo(Vector3.new(ballPos.X, floorY, ballPos.Z) + dir * 10, ballPos)
        ScrambleSwing()
        S.Status = string.format("Smashing the core  |  stage %d / 3  |  core %s", stage, tostring(arena:GetAttribute("CoreHealth") or "?"))
        return true
    end

    local targetId = tostring(arena:GetAttribute("BallTarget"))
    local coilName = arena:GetAttribute("BallCoil")
    local isTarget = targetId == tostring(LocalPlayer.UserId)

    if not S.Run and isTarget and type(coilName) == "string" and coilName ~= "" then
        local coils = arena:FindFirstChild("Coils")
        local coil = coils and coils:FindFirstChild(coilName)
        local home = coil and coil:GetAttribute("Home")
        if typeof(home) == "Vector3" then
            S.Run = {
                Centre = Vector3.new(home.X, floorY, home.Z),
                Goal = Vector3.new(home.X, floorY, home.Z),
                Leg = 1,
                Until = os.clock() + 10,
                Coil = coilName,
            }
        end
    end

    local run = S.Run
    if run then
        if os.clock() > run.Until or not isTarget or coilName ~= run.Coil then
            S.Run = nil
            ScrambleStopHorizontal()
            return true
        end

        local d = Vector3.new(run.Goal.X - root.Position.X, 0, run.Goal.Z - root.Position.Z)
        if d.Magnitude < 3 then
            run.Leg = 2
            ScrambleStopHorizontal()
            S.Status = string.format("In the middle of %s, waiting for the ball  |  stage %d / 3", tostring(run.Coil), stage)
            return true
        end

        local v = d.Unit * math.min(S.BaitSpeed, d.Magnitude / 0.05)
        pcall(function()
            root.AssemblyLinearVelocity = Vector3.new(v.X, root.AssemblyLinearVelocity.Y, v.Z)
        end)
        S.Status = string.format("Flying into %s  |  stage %d / 3", tostring(run.Coil), stage)
        return true
    end

    -- Not the ball's target: keep a safe distance from it.
    local away = Vector3.new(root.Position.X - ballPos.X, 0, root.Position.Z - ballPos.Z)
    if away.Magnitude > 18 or away.Magnitude < 6 then
        local dir = away.Magnitude < 1 and Vector3.new(1, 0, 0) or away.Unit
        ScrambleSnapTo(Vector3.new(ballPos.X, floorY, ballPos.Z) + dir * 12, ballPos)
    end
    S.Status = string.format("Ball phase, waiting for it to lock on  |  stage %d / 3", stage)
    return true
end

-- Human phase: stand just ahead of Dr Scramble and keep swinging.
local function ScrambleHumanPhase(arena, root)
    local S = State.Scramble
    local human = S.HumanModel
    if not (human and human.Parent and human:IsDescendantOf(Workspace)) then
        human = arena:FindFirstChild("ScrambleHuman") or arena:FindFirstChild("ScrambleHuman", true) or Workspace:FindFirstChild("ScrambleHuman", true)
        S.HumanModel = human
    end
    if not human then
        S.Status = "Final phase, looking for Dr Scramble"
        return false
    end

    local hrp = human:FindFirstChild("HumanoidRootPart") or human.PrimaryPart or human:FindFirstChildWhichIsA("BasePart")
    local okp, pivotPos = pcall(function() return human:GetPivot().Position end)
    local pos = hrp and hrp.Position or (okp and pivotPos) or nil
    if not pos then return false end

    local vel = hrp and hrp.AssemblyLinearVelocity or Vector3.zero
    local hv = Vector3.new(vel.X, 0, vel.Z)
    if hv.Magnitude > 3 then
        S.HumanAhead = hv.Unit
    elseif not S.HumanAhead then
        local d = Vector3.new(root.Position.X - pos.X, 0, root.Position.Z - pos.Z)
        S.HumanAhead = d.Magnitude > 0.5 and d.Unit or Vector3.new(1, 0, 0)
    end

    local y = math.abs(root.Position.Y - pos.Y) > 6 and pos.Y + 1 or root.Position.Y
    local stand = Vector3.new(pos.X, y, pos.Z) + S.HumanAhead * 2
    local dist = (Vector3.new(stand.X, 0, stand.Z) - Vector3.new(root.Position.X, 0, root.Position.Z)).Magnitude
    local look = Vector3.new(pos.X - stand.X, 0, pos.Z - stand.Z)
    local rot = look.Magnitude > 0.05 and CFrame.lookAt(Vector3.zero, look.Unit) or root.CFrame.Rotation

    if dist > 3 or math.abs(root.Position.Y - y) > 6 then
        local ch = LocalPlayer.Character
        pcall(function()
            ch:PivotTo(CFrame.new(stand) * rot)
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)
    else
        pcall(function()
            root.AssemblyLinearVelocity = Vector3.new(0, math.min(root.AssemblyLinearVelocity.Y, 0), 0)
            root.AssemblyAngularVelocity = Vector3.zero
            if look.Magnitude > 0.5 and root.CFrame.LookVector:Dot(look.Unit) < 0.94 then
                root.CFrame = CFrame.new(root.Position) * rot
            end
        end)
    end

    ScrambleSwing()
    S.Status = string.format("Chasing Dr Scramble  |  hits %d / %d%s",
        tonumber(arena:GetAttribute("HumanHits")) or 0,
        tonumber(arena:GetAttribute("HumanNeeded")) or 3,
        human:GetAttribute("Immune") == true and "  |  he is immune, still swinging" or "")
    return true
end

-- One fight step, in order: grab -> ball -> human -> mech orbit.
-- (The boss lookup used to run first and returned early in the ball phase,
-- because the Mech has no Hitbox then. That is why the ball phase never ran.)
local function ScrambleFightStep(arena)
    local S = State.Scramble
    local root = Root()
    if not root then return end

    local phase = tostring(arena:GetAttribute("Phase"))
    local hum = Humanoid()

    if hum and tostring(arena:GetAttribute("GrabVictim")) == tostring(LocalPlayer.UserId) then
        pcall(function() hum.Jump = true end)
        ScrambleSwing()
        S.Status = "Grabbed, breaking free"
        return
    end

    if phase == "Ball" and S.TryBall and ScrambleBallPhase(arena, root) then return end
    if phase == "Human" and S.ChaseHuman and ScrambleHumanPhase(arena, root) then return end

    local boss, bossModel = ScrambleBoss(arena)
    if not boss then
        local spawns = (tonumber(arena:GetAttribute("SpawnsAt")) or 0) - Workspace:GetServerTimeNow()
        S.Status = spawns > 0 and ("In the arena  |  boss spawns in " .. ClockText(spawns)) or string.format("Phase %s, waiting for the boss", phase)
        return
    end

    local bossPos = boss.Position
    local health = tonumber(arena:GetAttribute("Health")) or 0
    local maxHealth = tonumber(arena:GetAttribute("MaxHealth")) or 0
    local floorY = (tonumber(arena:GetAttribute("FloorY")) or bossPos.Y) + 3
    local now = Workspace:GetServerTimeNow()

    local best, bestScore
    for i = 0, 15 do
        local a = i / 16 * math.pi * 2
        local point = Vector3.new(bossPos.X + math.cos(a) * S.Radius, floorY, bossPos.Z + math.sin(a) * S.Radius)
        local score = (point - root.Position).Magnitude
        if IsScrambleHazardAt(point, now) or IsScrambleHazardAt(point, now + 0.4) then
            score = score + 10000
        end
        if not bestScore or score < bestScore then bestScore, best = score, point end
    end
    if best then ScrambleSnapTo(best, bossPos) end
    ScrambleSwing()

    local overheat = bossModel and bossModel:GetAttribute("Overheated") == true
    S.Status = string.format("Fighting %s  |  boss %d / %d%s", phase, math.floor(health + 0.5), math.floor(maxHealth + 0.5), overheat and "  |  OVERHEAT" or "")
end

local function ScrambleBody(token)
    local S = State.Scramble

    while not token.Cancelled and alive() and S.Enabled do
        if not InScrambleArena() then
            S.Busy = false
            S.Run = nil
            S.FinalAt = nil
            local portal = ScramblePortal()

            -- Night: do not travel or enter, wait for daylight.
            if IsNight() then
                S.Status = "Night, paused until daylight"
                task.wait(0.5)
                continue
            end

            -- Fight already finished: do NOT go back in until a new Mech event.
            if S.Done then
                if portal then
                    S.Status = "Mech done, waiting for the next event"
                    task.wait(0.5)
                    continue
                end
                S.Done = false
            end

            if portal then
                local hit = ScrambleHitbox(portal) or (portal:IsA("BasePart") and portal)
                if hit then
                    S.Status = "Going to the Mech portal"
                    local ok = MoveViaRoadCenter("scramble", CFrame.new(hit.Position), S.TravelSpeed, function()
                        return token.Cancelled or InScrambleArena() or not S.Enabled or IsNight()
                    end)
                    ReleaseMovement("scramble")
                    if not InScrambleArena() and not token.Cancelled and not IsNight() then
                        ScrambleEnter()
                        if not ok then task.wait(0.2) end
                    end
                end
            else
                local arena = ScrambleArena()
                local spawns = arena and tonumber(arena:GetAttribute("SpawnsAt")) or 0
                local now = Workspace:GetServerTimeNow()
                S.Status = spawns > now and ("Mech portal opens in " .. math.max(0, math.floor(spawns - now + 0.5)) .. "s") or "Waiting for Mech portal"
                task.wait(0.2)
            end
            RunService.Heartbeat:Wait()
            continue
        end

        -- ===== inside the arena =====
        S.Busy = true
        local arena = ScrambleArena()
        if not arena then RunService.Heartbeat:Wait(); continue end

        local phase = tostring(arena:GetAttribute("Phase") or "")
        if phase == "Defeated" or phase == "Final" or phase == "Ended" or phase == "Won" then
            S.Done = true
            S.Status = "Dr Scramble defeated"
            S.Run = nil

            -- "Final" is held back a few seconds.
            if phase == "Final" then
                S.FinalAt = S.FinalAt or os.clock()
                if not S.Leave or os.clock() - S.FinalAt < 5 then
                    task.wait(0.3)
                    continue
                end
            end

            if S.Leave then
                S.Status = "Leaving the arena"
                ScrambleLeave()
                local t = 0
                while InScrambleArena() and t < 4 and not token.Cancelled do
                    t = t + task.wait(0.2)
                end
            else
                task.wait(0.5)
            end
            continue
        end
        S.FinalAt = nil

        local ok, err = pcall(ScrambleFightStep, arena)
        if not ok then warn("[Cologne/Scramble] " .. tostring(err)) end
        RunService.Heartbeat:Wait()
    end
end

local function StartScrambleLoop(token)
    local S = State.Scramble
    S.SwapIndex = 1
    S.SwapSince = os.clock()
    S.LastSwing = 0
    S.Run = nil
    S.HumanModel = nil

    -- hazards from the server (used by Auto Dodge)
    local hazardConn
    local hazardRemote = ResolveRemote("RE/ScrambleBoss/Hazard")
    if hazardRemote and hazardRemote:IsA("RemoteEvent") then
        hazardConn = hazardRemote.OnClientEvent:Connect(function(h)
            if type(h) == "table" then S.Hazards[h.Id or (#S.Hazards + 1)] = h end
        end)
    end

    -- no collisions with the arena while fighting
    local saved = {}
    local stepConn = RunService.Stepped:Connect(function()
        if not InScrambleArena() then return end
        local ch = LocalPlayer.Character
        if not ch then return end
        for _, part in ipairs(ch:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                if saved[part] == nil then saved[part] = true end
                part.CanCollide = false
            end
        end
    end)

    local ok, err = pcall(ScrambleBody, token)

    -- cleanup always runs, even if the body errored
    if hazardConn then hazardConn:Disconnect() end
    stepConn:Disconnect()
    for part in pairs(saved) do
        if part.Parent then pcall(function() part.CanCollide = true end) end
    end
    S.Busy = false
    S.Status = "Off"
    S.Run = nil
    ReleaseMovement("scramble")
    local root = Root()
    if root then pcall(function() root.AssemblyLinearVelocity = Vector3.zero end) end

    if not ok and not token.Cancelled then
        warn("[Cologne/Scramble] " .. tostring(err))
    end
end

--==================================================
-- UI
--==================================================

local Window = NullUI:CreateWindow({
    Title = "Cologne",
    Subtitle = "Automation",
    Icon = "sparkles",
    DefaultTab = "Butterfly Bloom",
})

local ButterflyTab = Window:AddTab({
    Name = "Butterfly Bloom",
    Icon = "sparkles",
})

local ScrambleTab = Window:AddTab({
    Name = "Scramble",
    Icon = "swords",
})

local WispTab = Window:AddTab({
    Name = "Wisp",
    Icon = "wind",
})

local StatusTab = Window:AddTab({
    Name = "Status",
    Icon = "activity",
})

local ConfigTab = Window:AddTab({
    Name = "Configs",
    Icon = "save",
})

--==================================================
-- BUTTERFLY UI
--==================================================

ButterflyTab:AddSection("Butterfly Bloom", "sparkles")

local ButterflyStatusLabel = ButterflyTab:AddLabel(State.Butterfly.Enabled and (State.Butterfly.Status or "Waiting") or "Off")
local ButterflyTimerLabel = ButterflyTab:AddLabel(ButterflyEventTimerText())
task.spawn(function()
    while alive() do
        task.wait(0.2)
        pcall(function()
            if State.Butterfly.Enabled then
                ButterflyStatusLabel:Set(State.Butterfly.Status or "Waiting")
            else
                ButterflyStatusLabel:Set("Off")
            end
            ButterflyTimerLabel:Set(ButterflyEventTimerText())
        end)
    end
end)

local ButterflyToggle
ButterflyToggle = ButterflyTab:AddToggle({
    Flag = "Butterfly.Enabled",
    Text = "Auto Butterfly Bloom",
    Description = "Catches butterflies for you during the Butterfly Bloom event. You need a Butterfly Net.",
    Default = false,

    Callback = function(value)
        -- No Butterfly Net -> Butterfly Bloom must not run at all.
        if value == true and not FindButterflyNet() then
            State.Butterfly.Enabled = false
            State.Butterfly.Status = "No Butterfly Net"
            StopLoop("Butterfly")
            Notify("Butterfly Bloom", "You need a Butterfly Net to use Auto Butterfly Bloom.", "error")
            task.defer(function()
                if ButterflyToggle then
                    for _, method in ipairs({"Set", "SetValue", "SetState"}) do
                        if pcall(function() ButterflyToggle[method](ButterflyToggle, false) end) then break end
                    end
                end
            end)
            return
        end

        State.Butterfly.Enabled = value == true
        State.Butterfly.Generation += 1

        StopLoop("Butterfly")

        if State.Butterfly.Enabled then
            StartLoop("Butterfly", StartButterflyLoop)
        else
            State.Butterfly.Busy = false
            State.Butterfly.Claiming = false
            MovementToken += 1
            if State.Movement.Owner == "butterfly" then
                ReleaseMovement("butterfly")
            end
            State.Butterfly.Status = "Off"
            ButterflyStatusLabel:Set("Off")
        end
    end,
})

ButterflyTab:AddDropdown({
    Flag = "Butterfly.Mode",
    Text = "Catch Mode",
    Description = "How you catch: stand in the middle, chase butterflies, run in a circle, or patrol the bloom.",
    Options = {
        "Stand",
        "Chase",
        "Circle",
        "Patrol",
    },
    Default = "Stand",

    Callback = function(value)
        State.Butterfly.Mode = tostring(value)
    end,
})

ButterflyTab:AddDropdown({
    Flag = "Butterfly.Priority",
    Text = "Catch Priority",
    Description = "Go for the rarest butterflies first, or the closest ones first.",
    Options = {
        "Rarest",
        "Nearest",
    },
    Default = "Rarest",

    Callback = function(value)
        State.Butterfly.Priority = tostring(value)
    end,
})

ButterflyTab:AddDropdown({
    Flag = "Butterfly.Tiers",
    Text = "Catch Butterflies",
    Description = "Pick which butterflies you want to catch.",
    Options = {
        "Radiant Butterfly",
        "Amethyst Butterfly",
        "Sapphire Butterfly",
        "Emerald Butterfly",
    },
    Default = {
        "Radiant Butterfly",
        "Amethyst Butterfly",
        "Sapphire Butterfly",
        "Emerald Butterfly",
    },
    MultiSelect = true,

    Callback = function(value)
        State.Butterfly.Tiers = {
            Golden = false,
            Purple = false,
            Blue = false,
            Green = false,
        }

        if type(value) == "table" then
            for key, selected in pairs(value) do
                local name

                if selected == true and type(key) == "string" then
                    name = key
                elseif type(selected) == "string" then
                    name = selected
                end

                if name then
                    local tier = TierMap[name]
                    if tier then
                        State.Butterfly.Tiers[tier] = true
                    end
                end
            end
        end
    end,
})

ButterflyTab:AddSlider({
    Flag = "Butterfly.Speed",
    Text = "Tween Speed",
    Description = "How fast you travel to and around the bloom.",
    Min = 100,
    Max = 600,
    Default = 320,
    Increment = 10,
    Suffix = " studs/s",

    Callback = function(value)
        State.Butterfly.Speed =
            math.clamp(tonumber(value) or 320, 100, 600)
    end,
})

--==================================================
-- SCRAMBLE UI
--==================================================

ScrambleTab:AddSection("Scramble", "swords")
local ScrambleStatusLabel=ScrambleTab:AddLabel(State.Scramble.Status)
local ScrambleTimerLabel=ScrambleTab:AddLabel(ScrambleEventTimerText())
task.spawn(function()
    while alive() do
        task.wait(0.2)
        pcall(function() ScrambleStatusLabel:Set(State.Scramble.Status); ScrambleTimerLabel:Set(ScrambleEventTimerText()) end)
    end
end)

ScrambleTab:AddToggle({
    Flag="Scramble.Enabled", Text="Auto Scramble", Description="Joins the Mech event and defeats Dr Scramble for you.", Default=false,
    Callback=function(v)
        State.Scramble.Enabled=v==true
        State.Scramble.Generation+=1
        StopLoop("Scramble")
        if State.Scramble.Enabled then
            StartLoop("Scramble",StartScrambleLoop)
        else
            State.Scramble.Busy=false
            if State.Movement.Owner == "scramble" then
                ReleaseMovement("scramble")
            end
            StopRealWalk()
        end
    end,
})

ScrambleTab:AddSlider({Flag="Scramble.MainHold",Text="Main Weapon Hold",Description="How long to hold your main weapon before switching.",Min=0,Max=1.5,Default=0.3,Increment=0.01,Suffix=" s",Callback=function(v) State.Scramble.MainHold=math.clamp(tonumber(v) or 0.3,0,1.5) end})
ScrambleTab:AddSlider({Flag="Scramble.SecondHold",Text="Scrambler Hold",Description="How long to hold the Scrambler before switching.",Min=0,Max=1.5,Default=0.4,Increment=0.01,Suffix=" s",Callback=function(v) State.Scramble.SecondHold=math.clamp(tonumber(v) or 0.4,0,1.5) end})
ScrambleTab:AddToggle({Flag="Scramble.SwapTools",Text="Swap Two Weapons",Description="Switches between your main weapon and the Scrambler while fighting.",Default=true,Callback=function(v) State.Scramble.SwapTools=v~=false end})
ScrambleTab:AddToggle({Flag="Scramble.Dodge",Text="Auto Dodge Attacks",Description="Steps out of Dr Scramble's attacks before they hit you.",Default=true,Callback=function(v) State.Scramble.Dodge=v==true end})
ScrambleTab:AddToggle({Flag="Scramble.TryBall",Text="Ball And Core Phase",Description="Plays the ball phase for you: runs into the glowing coil, then smashes the core.",Default=true,Callback=function(v) State.Scramble.TryBall=v~=false end})
ScrambleTab:AddToggle({Flag="Scramble.Leave",Text="Leave After Fight",Description="Leaves the arena as soon as Dr Scramble is defeated.",Default=true,Callback=function(v) State.Scramble.Leave=v~=false end})
ScrambleTab:AddToggle({Flag="Scramble.ChaseHuman",Text="Chase Human Phase",Description="Follows Dr Scramble and keeps hitting him in the human phase.",Default=true,Callback=function(v) State.Scramble.ChaseHuman=v~=false end})

ScrambleTab:AddSlider({Flag="Scramble.BaitSpeed",Text="Bait Speed",Description="How fast you run into the glowing coil during the ball phase.",Min=100,Max=500,Default=225,Increment=5,Suffix=" studs/s",Callback=function(v) State.Scramble.BaitSpeed=math.clamp(tonumber(v) or 225,100,500) end})
ScrambleTab:AddSlider({Flag="Scramble.Radius",Text="Boss Radius",Description="How far you stay from the Mech while fighting it.",Min=8,Max=40,Default=18,Increment=1,Suffix=" studs",Callback=function(v) State.Scramble.Radius=math.clamp(tonumber(v) or 18,8,40) end})
ScrambleTab:AddSlider({Flag="Scramble.SwingGap",Text="Swing Gap",Description="Time between swings. Lower swings faster.",Min=0.03,Max=0.5,Default=0.12,Increment=0.01,Suffix=" s",Callback=function(v) State.Scramble.SwingGap=math.clamp(tonumber(v) or 0.12,0.03,0.5) end})
ScrambleTab:AddSlider({Flag="Scramble.TravelSpeed",Text="Mech Tween Speed",Description="How fast you travel to the Mech portal.",Min=100,Max=1000,Default=250,Increment=10,Suffix=" studs/s",Callback=function(v) State.Scramble.TravelSpeed=math.clamp(tonumber(v) or 250,100,1000) end})

--==================================================
-- WISP UI
--==================================================

WispTab:AddSection("Wisp", "wind")

local WispStatus = WispTab:AddLabel("Off")
task.spawn(function() while alive() do task.wait(0.2); pcall(function() WispStatus:Set(State.Wisp.Status) end) end end)

WispTab:AddToggle({
    Flag = "Wisp.Enabled",
    Text = "Auto Wisp",
    Description = "Meets the Wisp, finishes its stages and returns it to the Enchanted Tree.",
    Default = false,

    Callback = function(value)
        State.Wisp.Enabled = value == true
        State.Wisp.Generation += 1

        StopLoop("Wisp")

        if State.Wisp.Enabled then
            StartLoop("Wisp", WispLoop)
        else
            State.Wisp.Busy = false
            StopRealWalk()
            State.Wisp.Status = "Off"

            if State.Movement.Owner == "wisp" then
                ReleaseMovement("wisp")
            end
        end
    end,
})

WispTab:AddSection("Wisp State", "info")
local WispAcceptedLabel = WispTab:AddLabel("Accepted: false")
local WispUnlockedLabel = WispTab:AddLabel("Unlocked: false")
local WispStageLabel = WispTab:AddLabel("Stage: 1/0")
local WispPowerLabel = WispTab:AddLabel("Speed: 0")
local WispRequiredLabel = WispTab:AddLabel("Required: 0")

task.spawn(function()
    while alive() do
        task.wait(0.25)
        pcall(function()
            WispAcceptedLabel:Set("Accepted: " .. tostring(State.Wisp.Accepted))
            WispUnlockedLabel:Set("Unlocked: " .. tostring(State.Wisp.Unlocked))
            WispStageLabel:Set(string.format("Stage: %d/%d", tonumber(State.Wisp.Stage) or 1, tonumber(State.Wisp.StageCount) or 0))
            WispPowerLabel:Set(string.format("Speed: %.2fB", (tonumber(State.Wisp.SpeedPower) or 0) / 1e9))
            WispRequiredLabel:Set(string.format("Required: %.0fB", (tonumber(State.Wisp.Required) or 0) / 1e9))
        end)
    end
end)

-- The Wisp state is always kept up to date, Auto Wisp does not need to be on.
StartLoop("WispState", function(token)
    while not token.Cancelled and alive() do
        pcall(ReadWispState)
        task.wait(1)
    end
end)

--==================================================
-- MOVEMENT UI
--==================================================
StatusTab:AddSection("Anti Guard", "shield")

StatusTab:AddToggle({
    Flag = "AntiGuard.Enabled",
    Text = "Anti Guard",
    Description = "Turns off your collisions so guards cannot push or block you.",
    Default = false,

    Callback = function(value)
        State.AntiGuard.Enabled = value == true

        if State.AntiGuard.Enabled then
            StopLoop("AntiGuard")
            StartLoop("AntiGuard", AntiGuardLoop)
        else
            StopLoop("AntiGuard")
            RestoreCollision()
        end
    end,
})

StatusTab:AddToggle({
    Flag = "AntiGuard.Freeze",
    Text = "Freeze",
    Description = "Holds you still so nothing can push you while Anti Guard is on.",
    Default = false,

    Callback = function(value)
        State.AntiGuard.Freeze = value == true
    end,
})

--==================================================
-- STATUS UI
--==================================================

StatusTab:AddSection("Runtime", "activity")

local StatusInfo = StatusTab:AddInfoGrid({
    Title = "Cologne Runtime",
    Description = "Live status of every Cologne feature.",
    Columns = 2,
    Items = {
        {Label = "Task", Value = "Idle"},
        {Label = "Butterfly", Value = "Off"},
        {Label = "Wisp", Value = "Off"},
        {Label = "Movement", Value = "None"},
        {Label = "Night", Value = "No"},
        {Label = "Tree", Value = "Locked"},
    },
})

StatusTab:AddConsole({
    Title = "Runtime Log",
    Height = 210,
    MaxLogs = 100,
    AutoCapture = true,
})

--==================================================
-- STATUS REFRESH
--==================================================

StartLoop("Status", function(token)
    while not token.Cancelled and alive() do
        pcall(function()
            StatusInfo:SetValue(
                "Task",
                PriorityMessage()
            )

            StatusInfo:SetValue(
                "Butterfly",
                State.Butterfly.Enabled
                    and (State.Butterfly.Busy and "Running" or "Waiting")
                    or "Off"
            )

            StatusInfo:SetValue(
                "Wisp",
                State.Wisp.Enabled
                    and State.Wisp.Status
                    or "Off"
            )

            StatusInfo:SetValue(
                "Movement",
                State.Movement.Owner
                    or "None"
            )

            StatusInfo:SetValue(
                "Night",
                IsNight() and "Yes" or "No"
            )

            StatusInfo:SetValue(
                "Tree",
                EnchantedTreeUnlocked()
                    and "Unlocked"
                    or "Locked"
            )

            if WispStatus and WispStatus.Set then
                WispStatus:Set(
                    State.Wisp.Enabled
                        and State.Wisp.Status
                        or "Off",
                    true
                )
            end
        end)

        task.wait(0.25)
    end
end)

--==================================================
-- CONFIGS
--==================================================

ConfigTab:AddSection("Profiles", "save")

ConfigTab:AddButton({
    Text = "Save Default",
    Description = "Saves your current settings to your default profile.",
    Icon = "save",

    Callback = function()
        local ok, err = NullUI:SaveConfig(
            "default",
            {
                Description = "Cologne default profile",
                Tags = {
                    "Cologne",
                    "Butterfly",
                    "Wisp",
                },
            }
        )

        Notify(
            "Configs",
            ok
                and "Default profile saved."
                or ("Save failed: " .. tostring(err)),
            ok and "success" or "error"
        )
    end,
})

ConfigTab:AddButton({
    Text = "Load Default",
    Description = "Loads your saved default profile.",
    Icon = "folder-open",

    Callback = function()
        local ok, err =
            NullUI:LoadConfig("default", false)

        Notify(
            "Configs",
            ok
                and "Default profile loaded."
                or ("Load failed: " .. tostring(err)),
            ok and "success" or "error"
        )
    end,
})

ConfigTab:AddButton({
    Text = "Reset Runtime",
    Description = "Turns every running feature off without closing the menu.",
    Icon = "rotate-ccw",

    Callback = function()
        State.Butterfly.Enabled = false
        State.Butterfly.Busy = false
        State.Butterfly.Claiming = false

        State.Wisp.Enabled = false
        State.Wisp.Busy = false
        StopRealWalk()
        State.Wisp.Status = "Off"

        State.Movement.Target = nil

        for name in pairs(Loops) do
            if name ~= "Status" and name ~= "WispState" then
                StopLoop(name)
            end
        end

        ReleaseMovement(nil)
        RestoreCollision()

        Notify(
            "Cologne",
            "Everything is turned off.",
            "success"
        )
    end,
})

ConfigTab:AddSection("About", "info")
ConfigTab:AddLabel("Cologne")
ConfigTab:AddLabel("Made by Auzaa, FakeChan, Egoistic")
ConfigTab:AddLabel("NullUI 2.8.1")

--==================================================
-- AUTO LOAD
--==================================================

pcall(function()
    NullUI:LoadConfig("default", true)
end)

--==================================================
-- CLEANUP
--==================================================

local oldUnload
pcall(function()
    oldUnload = NullUI.__CologneUnload
end)

NullUI.__CologneUnload = function()
    if not State.Alive then
        return
    end

    State.Alive = false

    for name in pairs(Loops) do
        StopLoop(name)
    end

    for _, connection in ipairs(Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    table.clear(Connections)

    MovementToken += 1

    RestoreCollision()

    pcall(function()
        NullUI:Unload()
    end)
end

pcall(function()
    local env = getgenv and getgenv() or _G
    env.CologneRuntime = State
    env.CologneUnload = NullUI.__CologneUnload
end)

Notify(
    "Cologne",
    "Loaded. Pick a feature to get started.",
    "success"
)
