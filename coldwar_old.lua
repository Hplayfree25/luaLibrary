--[[
    cold war - vault.cc
    ui: linorialib (https://github.com/violin-suzutsuki/LinoriaLib)
    esp: dacces on v3rm
]]

--[[
TODO:
fix healthbar, health is an attribute/item under each body part, we can either average it or just use health of target part
add auto reload
look at infinite ammo, or auto get ammo from ammo boxes
look at infinite penetration
look at terrain wallbang
look at viewmodel mods like instant aim, visuals, etc
look at instant equip, instant reload (reload debug logs are being printed in console rn, so find reload func like that)
]]

local gc = getgc(true)

-- print crash fix
local oldStringMatch
oldStringMatch = hookfunction(string.match, function(...)
    local args = {...}

    if args[2] == "^:%d+:" then
        return nil
    end

    return oldStringMatch(...)
end)

-- services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local Client = RS.Client
local Tools = Client.Tools
local WeaponControllers = Tools.Weapon.controllers

local RecoilController = require(WeaponControllers.RecoilController)
local AimController = require(WeaponControllers.AimController)
local FiremodeController = require(Tools.Weapon.Muzzle.firemodes.FireController)
local Trajectory = require(RS:WaitForChild("Shared"):WaitForChild("Ballistics"):WaitForChild("Trajectory"))
local Wielder = require(Client:WaitForChild("Character"):WaitForChild("Wielder"))

local Library -- forward-declared here; assigned when linoria loads (revive notify needs it)

local cfg = {
    Combat = {
        RecoilMult = 0,
        SpreadMult = 0,
        SilentEnabled = true,
        Ragebot = false,
        RagebotWallbang = false,
        RagebotAutoReload = false,
        InstantReload = false,
        SilentTarget = "Head",
        SilentFov = 100,
        SilentFovEnabled = false,
        SilentExcludeTeammates = true,
        FovDrawEnabled = false,
        FovColor = Color3.fromRGB(255, 255, 255),
        FovThickness = 1,
        AimAnywhere = true,
        InstantADS = true,
        NoADSSlowdown = true,
        ForceAuto = true,
        InfiniteMags = false,
        InstantEquip = false,
        NoBulletDrop = false,
        InstantBullet = false,
        Snaplines = false,
        SnapTargetColor = Color3.fromRGB(255, 0, 0),
        NoHurtSlowdown = false,
        NoBandageSlowdown = false,
        OmniSprint = false,
        AutoHeal = false,
        InstantHeal = false,
        FastRevive = false,
        CarMods = false,
        DriveAnyCar = false,
        QuickClimb = false,
        ShootInCar = false,
    }
}

local util = {}
util.target = nil -- cached target part, refreshed every few frames

-- downed players aren't dead but lie there with CharacterValues.Unconscious set true
-- (the same value the revive prompt reads). skip them so we don't shoot corpses
local function isDowned(char)
    if not char then return false end
    local cv = char:FindFirstChild("CharacterValues")
    local u = cv and cv:FindFirstChild("Unconscious")
    return u ~= nil and u.Value == true
end

-- rounds spent since the last reload. bumped by every shot (manual + ragebot) and zeroed
-- on reload, so the ragebot knows when the mag is dry and stops firing blanks
local rbShots = 0

-- part still on a live character?
local function targetValid(part)
    if not part or not part.Parent then return false end
    local hum = part.Parent:FindFirstChildOfClass("Humanoid")
    return hum ~= nil and hum.Health > 0
end

-- the expensive scan: closest target to the cursor within fov
local function findBest()
    local camera = workspace.CurrentCamera
    if not camera then return nil end
    local me = Players.LocalPlayer
    -- GetMouseLocation is absolute (incl. inset), WorldToViewportPoint is viewport;
    -- subtract the inset so the compare-center actually sits on the cursor
    local mouse = UserInputService:GetMouseLocation() - GuiService:GetGuiInset()
    local best, bestDist
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= me and plr.Character and not isDowned(plr.Character) then
            if (not (me.Team and plr.Team == me.Team)) or (not cfg.Combat.SilentExcludeTeammates) then
                local part = plr.Character:FindFirstChild(cfg.Combat.SilentTarget)
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                if part and hum and hum.Health > 0 then
                    local sp, onScreen = camera:WorldToViewportPoint(part.Position)
                    if onScreen and sp.Z > 0 then
                        local dist = (Vector2.new(sp.X, sp.Y) - mouse).Magnitude
                        local within = (not cfg.Combat.SilentFovEnabled) or dist <= cfg.Combat.SilentFov
                        if within and (not bestDist or dist < bestDist) then
                            best, bestDist = part, dist
                        end
                    end
                end
            end
        end
    end
    return best
end

-- called by the silent aim hook when firing; verify the cached target (refresh if it died)
util.getTarget = function()
    if not targetValid(util.target) then
        util.target = findBest()
    end
    return util.target
end

-- refresh the cached target every 5 frames (cheap between refreshes = no fps drop)
local targetFrame = 0
RunService.Heartbeat:Connect(function()
    targetFrame = targetFrame + 1
    if targetFrame >= 5 then
        targetFrame = 0
        util.target = findBest()
    end
end)

local functions = {}
functions.getRecoilMult = {func = RecoilController.getRecoilMult, upv = debug.getupvalues(RecoilController.getRecoilMult)}
functions.spreadVector = {func = nil}
functions.fire = {func = nil, upv = nil}
functions.aimtoggle = {func = AimController.toggle, upv = debug.getupvalues(AimController.toggle)}
functions.isaimingavailable = {func = AimController.isAimingAvailable, upv = debug.getupvalues(AimController.isAimingAvailable)}
functions.aimupdate = {func = nil, upv = nil}
functions.firemodestart = {func = FiremodeController.start, upv = debug.getupvalue(FiremodeController.new, 2)}
functions.awaitLength = {func = nil}
functions.movementupdate = {func = nil}
functions.healLimb = {func = nil}         -- bandage module: heals a limb (we read its upvalues for the remote)
functions.canEnterSeat = {func = nil}     -- vehicle controller: gates who can sit in a seat
functions.invEquip = {func = nil}         -- inventory controller: equip(tool)
functions.onVehicleState = {func = nil}   -- inventory controller: holsters your weapon on sit
functions.getAnimLength = {func = nil}    -- animate module: GetAnimationLength (vehicle enter/exit waits)
functions.reloadContext = {func = nil}    -- reload controller: _context (holds the reload timings)
functions.muzzlesConfig = {func = nil}    -- weapon config manager: GetAllMuzzlesConfig (fire rate, ammo, penetration)

for _,v in pairs(gc) do
    if typeof(v) ~= 'function' or (not islclosure(v)) then
        continue
    end

    local info = debug.getinfo(v)
    local constants = debug.getconstants(v)
    local upvalues = debug.getupvalues(v)

    if info.name == 'spreadVector' then
        functions.spreadVector.func = v
    elseif table.find(constants, "config") and string.find(info.source, "Shooter") then
        functions.fire.func = v
        functions.fire.upv = upvalues
    elseif info.name == 'update' and string.find(info.source, "AimController") then
        functions.aimupdate.func = v
        functions.aimupdate.upv = upvalues
    elseif info.name == 'awaitLength' and string.find(info.source, "Inventory") then
        functions.awaitLength.func = v
    elseif info.name == 'update' and table.find(constants, "inertialSpeed") and table.find(constants, "runHeld") then
        functions.movementupdate.func = v
    elseif info.name == 'healLimb' then
        functions.healLimb.func = v
    elseif info.name == 'CanEnterSeat' then
        functions.canEnterSeat.func = v
    elseif info.name == 'equip' and string.find(info.source, "Inventory") then
        functions.invEquip.func = v
    elseif info.name == 'onVehicleState' then
        functions.onVehicleState.func = v
    elseif info.name == 'GetAnimationLength' then
        functions.getAnimLength.func = v
    elseif info.name == '_context' and table.find(constants, "reloadTime") then
        functions.reloadContext.func = v
    elseif info.name == 'GetAllMuzzlesConfig' then
        functions.muzzlesConfig.func = v
    end
end

-- spread changer
functions.spreadVector = hookfunction(functions.spreadVector.func, function(p12, p13)
    local mult = cfg.Combat.SpreadMult
    if type(mult) ~= "number" then mult = 1 end

    if mult == 0 then
        return p12.Unit
    end

    local v14 = p12.Unit
    local v15 = p13 / 3570
    local v16 = math.atan(v15) * mult
    local v17 = math.random() * 2 - 1
    local v18 = math.random() * 2 - 1
    local v19 = math.random() * 2 - 1
    return (v14 + Vector3.new(v17, v18, v19) * v16).Unit
end)

-- recoil change
local function new_getRecoilMult(newMult)
    -- upvalues: (copy) v_u_8, (copy) v_u_5, (copy) v_u_6
    local v_u_8,v_u_5,v_u_6 = unpack(functions.getRecoilMult.upv)
	local v23 = v_u_8
	local v24 = v_u_5:getCharacterValues()
	if v24 then
		v24 = v24:FindFirstChild("Stance")
	end --  v23[  v24.Value, default to "Walk"   ] * ((1 - AimController.GetAlpha(), default to 0) * 0.25)
	return (v23[v24 and v24.Value or "Walk"] or 1) * (1 - (v_u_6.getAlpha() or 0) * 0.25) * cfg.Combat.RecoilMult
end

RecoilController.getRecoilMult = new_getRecoilMult

-- silent aim
functions.fire.func = hookfunction(functions.fire.func, function(p20, p21)
    local v_u_3,v_u_7,v_u_11,v_u_8,v_u_4,spreadVector,v_u_6,v_u_5,v_u_10 = unpack(functions.fire.upv)

    rbShots = rbShots + 1 -- your own shots drain the mag too; keep the ragebot's count honest

    local v22 = p20.config
	local v23 = v_u_3:getCharacter()
	if v23 then
		v23 = v23:FindFirstChild("Right Arm")
	end
	local v24 = (v_u_7.CFrame.Position - v_u_7.Focus.Position).Magnitude <= 0.75
	local v25 = v24 and p20.viewmodelAttachment or p20.attachment
	local v26 = v25.WorldPosition
	local v27 = v25.WorldCFrame.LookVector
	if v23 then
		local v28 = (v26 - v23.CFrame.Position).Magnitude
		local v29 = v26 - v27 * v28
		v_u_11.FilterDescendantsInstances = { v_u_8.Character, workspace.Ignore }
		local v30 = workspace:Raycast(v29, v27 * v28, v_u_11)
		if v30 then
			local v31 = v30.Distance
			local v32 = math.min(0.01, v31)
			v26 = v30.Position - v27 * v32
		end
	end
	local v33 = v22.DefaultAngle or 0
	local v34 = math.rad(v33)
	local v35 = v_u_4.zeroAngle() or v34
	local v36 = (v25.WorldCFrame * CFrame.Angles(v35, 0, 0)).LookVector

	-- redirect toward the aimbot target
	if cfg.Combat.SilentEnabled then
    	local aimTarget = util.getTarget()
    	if aimTarget then
    		v36 = (aimTarget.Position - v26).Unit   -- aim from the muzzle to the part
    	end
	end

	p20.animator:play("GunShoot")
	local v37 = v22.BulletSettings[p21]
	local v38 = v37.ShotAmount or 1
	local v39 = v37.Spread or 1
	local v40 = table.create(v38)
	for v41 = 1, v38 do
		v40[#v40 + 1] = spreadVector(v36, v39)
	end
	local v42 = p20.tool.Sounds:FindFirstChild("Muzzle" .. p20.index)
	if v42 then
		v42 = v42:FindFirstChild("Fire")
	end
	if v42 then
		v_u_6.Play(v42, v25.WorldPosition, v22.SoundRange or 3000)
	end
	local v43 = v24 and p20.viewmodelTool or p20.tool
	v_u_5.replicateRecoil(v_u_8, v43, p20.index)
	v_u_5.muzzleFlash(v43, p20.index)
	v_u_10.fireVolley(p20.tool, p20.index, p21, v26, v40)
	if not p20:isHandAction() then
		v_u_5.casing(v43, p20.index)
	end
end)
-- aiming shi
functions.aimtoggle.func = hookfunction(functions.aimtoggle.func, function(...)
    local orig = functions.aimtoggle.func
    if not cfg.Combat.AimAnywhere then
        return orig(...) -- let the game gate it like normal
    end
    -- flip the real aim state regardless of stance
    local state = debug.getupvalue(orig, 1)
    debug.setupvalue(orig, 1, (state == 0) and 1 or 0)
end)

-- aiming shi
functions.aimupdate.func = hookfunction(functions.aimupdate.func, function(p25)
    local orig = functions.aimupdate.func
    local wantAim = debug.getupvalue(orig, 1) == 1

    -- instant ads: snap alpha to its target before the lerp
    if cfg.Combat.InstantADS then
        debug.setupvalue(orig, 5, debug.getupvalue(orig, 1))
    end

    orig(p25)

    -- aim anywhere: undo the stance force-out so we stay aimed
    if cfg.Combat.AimAnywhere and wantAim then
        debug.setupvalue(orig, 1, 1)
        if cfg.Combat.InstantADS then
            debug.setupvalue(orig, 5, 1)
        end
    end

    -- no ads slowdown: pin the move multiplier back to 1
    if cfg.Combat.NoADSSlowdown then
        local slow = debug.getupvalue(orig, 6)
        if slow then slow.Value = 1 end
    end
end)

-- aiming shi
functions.isaimingavailable.func = hookfunction(functions.isaimingavailable.func, function(...)
    if cfg.Combat.AimAnywhere then
        return true
    end
    return functions.isaimingavailable.func(...)
end)

functions.firemodestart.func = hookfunction(functions.firemodestart.func, function(p18)
    local v_u_6 = functions.firemodestart.upv

	if not p18.isFiring then
		p18.isFiring = true
		local v19 = p18:_current()
		if v19 then
			local strategy = v19.strategy
			if cfg.Combat.ForceAuto then
				strategy = v_u_6.Automatic.strategy
			end
			task.spawn(strategy.fire, p18)
		end
	end
end)

-- instant equip: drawTool/holsterCurrent only wait on the equip anim when awaitLength
-- returns true, so forcing it false makes them EquipTool/UnequipTools instantly
if functions.awaitLength.func then
    functions.awaitLength.func = hookfunction(functions.awaitLength.func, function(...)
        if cfg.Combat.InstantEquip then
            return false
        end
        return functions.awaitLength.func(...)
    end)
end

-- no hurt slowdown: the game scales speed by 0.5 + (legHP%avg)/2 (down to 0.5 when legs
-- are dead). recompute that same factor and divide it back out after the update runs
local function legHealthMult(char)
    local function ratio(name)
        local part = char:FindFirstChild(name)
        local h = part and part:FindFirstChild("Health")
        if h then
            local max = h:GetAttribute("MaxHealth")
            if max and max > 0 then return h.Value / max end
        end
        return nil
    end
    local l, r = ratio("Left Leg"), ratio("Right Leg")
    if l and r then return 0.5 + (l + r) / 4 end
    return nil
end

if functions.movementupdate.func then
    functions.movementupdate.func = hookfunction(functions.movementupdate.func, function(p11)
        -- omni sprint: the run state only kicks in when moving forward in first person.
        -- force firstPerson off so the game treats every direction as sprint-able
        if cfg.Combat.OmniSprint and p11 then
            p11.firstPerson = false
        end

        functions.movementupdate.func(p11)

        -- no hurt slowdown: undo the leg-health speed penalty
        if cfg.Combat.NoHurtSlowdown and p11 and p11.humanoid and p11.character then
            local mult = legHealthMult(p11.character)
            if mult and mult > 0 and mult < 1 then
                p11.humanoid.WalkSpeed = p11.humanoid.WalkSpeed / mult
                if type(p11.inertialSpeed) == "number" then
                    p11.inertialSpeed = p11.inertialSpeed / mult
                end
            end
        end
    end)
end

-- bullet trajectory mods: drop + travel speed all come out of Trajectory.new
local oldTrajNew = Trajectory.new
Trajectory.new = function(params)
    if cfg.Combat.NoBulletDrop then
        params.Gravity = 0
    end
    if cfg.Combat.InstantBullet then
        params.MuzzleSpeed = 1e6 -- covers max distance on the first step = hitscan
        params.K = 0             -- no speed decay
    end
    return oldTrajNew(params)
end

-- infinite magazines
-- the user places an ammo crate manually; we just refill from workspace.Ignore.AmmoBox
local Remotes = RS:WaitForChild("Remotes")
local GetAmmo = Remotes:WaitForChild("GetAmmo")

-- refill every weapon we own so nothing runs dry: the equipped tool (in the character)
-- plus everything sitting in the backpack. throttled a touch since it fires per tool
local magsAcc = 0
local magsConn = RunService.Heartbeat:Connect(function(dt)
    if not cfg.Combat.InfiniteMags then return end
    magsAcc = magsAcc + dt
    if magsAcc < 0.25 then return end
    magsAcc = 0
    local ignore = workspace:FindFirstChild("Ignore")
    local box = ignore and ignore:FindFirstChild("AmmoBox")
    if not box then return end
    local char = LocalPlayer.Character
    if char then
        for _, t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") then GetAmmo:FireServer(t, box, 1, 1) end
        end
    end
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if backpack then
        for _, t in ipairs(backpack:GetChildren()) do
            if t:IsA("Tool") then GetAmmo:FireServer(t, box, 1, 1) end
        end
    end
end)

-- no bandage slowdown: healLimb drops SpeedMultiplier (0 for legs, 0.7 otherwise) while
-- healing. the char gets an "isBandaging" attribute, so force the multiplier back to 1
local bandageConn = RunService.Heartbeat:Connect(function()
    if not cfg.Combat.NoBandageSlowdown then return end
    local char = LocalPlayer.Character
    if char and char:GetAttribute("isBandaging") then
        local cv = Wielder:getCharacterValues()
        local sm = cv and cv:FindFirstChild("SpeedMultiplier")
        if sm then sm.Value = 1 end
    end
end)

-- auto heal: fire the game's HealLimb remote for each damaged limb directly. healLimb
-- (found in gc) captures the bandage remote as upvalue 1 and the currently equipped
-- bandage as upvalue 2, so we heal with whatever bandage is equipped. firing the remote
-- straight skips the local 5s bar + the speed penalty, so there's no slowdown to undo.
-- we fire every damaged limb each pass to see if the server allows simultaneous heals
local healAcc = 0
local healConn = RunService.Heartbeat:Connect(function(dt)
    if not cfg.Combat.AutoHeal or not functions.healLimb.func then return end
    healAcc = healAcc + dt
    -- instant heal removes the throttle so we fire every frame (tests server gating)
    if not cfg.Combat.InstantHeal and healAcc < 0.75 then return end
    healAcc = 0

    local remote = debug.getupvalue(functions.healLimb.func, 1)
    local bandage = debug.getupvalue(functions.healLimb.func, 2)
    local char = LocalPlayer.Character
    if not (remote and char) then return end

    for _, part in ipairs(char:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            local h = part:FindFirstChild("Health")
            if h then
                local max = h:GetAttribute("MaxHealth")
                if max and h.Value < max then
                    remote:FireServer(bandage, "HealLimb", part)
                end
            end
        end
    end
end)

-- fast revive: downed players' RevivePrompts have a hold time; pin them to the 3s floor
local reviveAcc = 0
local reviveConn = RunService.Heartbeat:Connect(function(dt)
    reviveAcc = reviveAcc + dt
    if reviveAcc < 1 then return end -- scan once a second
    reviveAcc = 0

    if not cfg.Combat.FastRevive then return end
    local chars = workspace:FindFirstChild("Characters")
    if not chars then return end
    for _, p in ipairs(chars:GetDescendants()) do
        if p:IsA("ProximityPrompt") and p.Name == "RevivePrompt" then
            p.HoldDuration = 3
        end
    end
end)

-- car mods: overwrite the vehicle Transmission config on any matching gc table (a car
-- config carries Transmission + Damage + ShopInfo). reapplied on a slow timer so newly
-- spawned/entered cars get modded without a per-frame getgc scan
local carTransmission = {
    DriveType = "AWD",
    FinalDrive = 6.80,
    IdleRPM = 1000,
    IdleTorque = 140,
    IdleTorqueCurve = 0.15,
    PeakTorque = 460,
    PeakTorqueRPM = 5200,
    RedlineRPM = 9000,
    RedlineTorque = 280,
    RedlineTorqueCurve = 0.5,
    ShiftRPM = 6500,
    HorsepowerLimit = 850,
    BrakeStrength = 26000,
    Mass = 750,
    WheelMass = 8,
    TurnRadius = 13,
    SuspensionHeight = 1.1,
    StiffnessModifier = 7,
    DampingModifier = 1.3,
    Ratios = {
        [-1] = 7.497,
        [0] = 0,
        4.000,
        2.500,
        1.650,
        1.150,
    },
}
local function applyCarMods()
    for _, v in pairs(getgc(true)) do
        if typeof(v) == 'table' and rawget(v, "Transmission") and rawget(v, "Damage") and rawget(v, "ShopInfo") then
            v.Transmission = carTransmission
        end
    end
end
local carModsAcc = 0
local carModsConn = RunService.Heartbeat:Connect(function(dt)
    if not cfg.Combat.CarMods then return end
    carModsAcc = carModsAcc + dt
    if carModsAcc < 5 then return end
    carModsAcc = 0
    applyCarMods()
end)

-- drive any car: the vehicle controller's CanEnterSeat gates by team/owner/occupancy.
-- force it true so any seat is enterable
if functions.canEnterSeat.func then
    functions.canEnterSeat.func = hookfunction(functions.canEnterSeat.func, function(...)
        if cfg.Combat.DriveAnyCar then return true end
        return functions.canEnterSeat.func(...)
    end)
end

-- quick vehicle enter/exit: the enter/exit sequences task.wait on the animation length.
-- collapsing GetAnimationLength makes those waits near-instant so you climb in/out fast
if functions.getAnimLength.func then
    functions.getAnimLength.func = hookfunction(functions.getAnimLength.func, function(...)
        if cfg.Combat.QuickClimb then return 0.05 end
        return functions.getAnimLength.func(...)
    end)
end

-- shoot in vehicle: the game holsters your weapon when you sit (onVehicleState) and
-- blocks equip while Sit/PlatformStand. skip the auto-holster, and re-run equip's own
-- logic (read live off its upvalues) without the seat gate so you can swap guns in a car
if functions.onVehicleState.func then
    functions.onVehicleState.func = hookfunction(functions.onVehicleState.func, function(...)
        if cfg.Combat.ShootInCar then return end
        return functions.onVehicleState.func(...)
    end)
end
if functions.invEquip.func then
    functions.invEquip.func = hookfunction(functions.invEquip.func, function(p65)
        local orig = functions.invEquip.func
        if not cfg.Combat.ShootInCar then return orig(p65) end
        -- upvalues: 1 equipped, 2 tool list, 3 busy flag, 4 wielder, 6 holsterCurrent, 7 drawTool
        local equipped = debug.getupvalue(orig, 1)
        local list = debug.getupvalue(orig, 2)
        local busy = debug.getupvalue(orig, 3)
        local wielder = debug.getupvalue(orig, 4)
        local holsterCurrent = debug.getupvalue(orig, 6)
        local drawTool = debug.getupvalue(orig, 7)
        if p65 and p65 ~= equipped and list and table.find(list, p65)
           and (not busy) and wielder and wielder:isConscious() then
            debug.setupvalue(orig, 3, true) -- busy = true
            if debug.getupvalue(orig, 1) then holsterCurrent() end
            if wielder:isConscious() and p65.Parent then drawTool(p65) end
            debug.setupvalue(orig, 3, false) -- busy = false
        end
    end)
end

-- instant reload: the reload timings live in the context table _context builds. shrink
-- them so the reload lockout is effectively gone
if functions.reloadContext.func then
    functions.reloadContext.func = hookfunction(functions.reloadContext.func, function(...)
        rbShots = 0 -- a reload (manual or otherwise) refills the mag, so reset the count
        local ctx = functions.reloadContext.func(...)
        if cfg.Combat.InstantReload and type(ctx) == "table" then
            ctx.reloadTime = 0.05
            ctx.insertTime = 0.05
        end
        return ctx
    end)
end

-- ragebot: independent auto-fire, fully separate from silent aim. it fires straight
-- through the client fire module (downstream of the silent aim hook) at any enemy it can
-- actually damage: clear line of sight, or a penetrable wall when wallbang is on.
-- runs in its own thread with a paced while-loop instead of per-frame render/heartbeat
local ClientFire = functions.fire.upv and functions.fire.upv[9] -- the module with fireVolley/fire
local WeaponRemote = Remotes:WaitForChild("Weapon")             -- reload requests go here
-- the config manager keeps every weapon config keyed by tool name; grab that table off
-- GetAllMuzzlesConfig so we get real fire rate / ammo / penetration instead of guessing
local WeaponConfigs = functions.muzzlesConfig.func and debug.getupvalue(functions.muzzlesConfig.func, 1)
local Materials = select(2, pcall(function()
    return require(RS:WaitForChild("Shared"):WaitForChild("Ballistics"):WaitForChild("ProjectileMaterials"))
end))
if type(Materials) ~= "table" then Materials = nil end

-- muzzle config for the held gun (Firerate, Ammo, ReloadTime, BulletSettings[i].Penetration)
local function rbMuzzleConfig(tool, muzzleIndex)
    local wc = WeaponConfigs and WeaponConfigs[tool.Name]
    return wc and wc[muzzleIndex]
end

-- find where a bullet exits a wall, same idea as ProjectileCaster.findExit: cast back
-- through just that part to get its far face
local function rbFindExit(hitPos, dir, inst)
    local p = RaycastParams.new()
    p.FilterType = Enum.RaycastFilterType.Include
    p.FilterDescendantsInstances = { inst }
    local far = hitPos + dir * 60
    local r = workspace:Raycast(far, -dir * 60, p)
    return r and r.Position or nil
end

-- walk the ray toward the target through walls, spending the penetration budget by
-- thickness * material cost (the same maths interactions.resolve uses). true if a bullet
-- would still reach the target character
local function rbPenetrable(origin, targetPos, targetChar, budget, ignore)
    if not budget or budget <= 0 then return false end -- no budget -> can't wallbang
    local remaining = budget
    local pos = origin
    for _ = 1, 8 do
        local delta = targetPos - pos
        local dist = delta.Magnitude
        if dist < 0.1 then return true end
        local dir = delta.Unit
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = ignore
        local hit = workspace:Raycast(pos, dir * dist, params)
        if not hit then return true end
        if hit.Instance:IsDescendantOf(targetChar) then return true end
        local exit = rbFindExit(hit.Position, dir, hit.Instance)
        if not exit then return false end
        local thickness = (exit - hit.Position).Magnitude
        local cost = Materials and Materials.getPenetration(hit.Material) or 1
        remaining = remaining - thickness * cost
        if remaining <= 0 then return false end
        pos = exit + dir * 0.05
    end
    return false
end

-- can we deal damage to this target from origin right now?
local function rbCanDamage(origin, targetPos, targetChar, budget, ignore)
    local delta = targetPos - origin
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = ignore
    local hit = workspace:Raycast(origin, delta, params)
    if not hit then return true end                       -- nothing in the way
    if hit.Instance:IsDescendantOf(targetChar) then return true end -- direct line to the target
    if not cfg.Combat.RagebotWallbang then return false end
    return rbPenetrable(origin, targetPos, targetChar, budget, ignore)
end

-- reload request buffer: {action=Reload(1), muzzleIndex, bulletIndex}
local function rbReloadServer(muzzleIndex, bulletIndex)
    local b = buffer.create(3)
    buffer.writeu8(b, 0, 1)
    buffer.writeu8(b, 1, muzzleIndex)
    buffer.writeu8(b, 2, bulletIndex)
    WeaponRemote:FireServer(b)
end

-- part priority: head and torso deal the most damage, so try them first, then any other
-- limb. scanning every part means we can tag a target the moment any bit of them is exposed
local rbPartOrder = { "Head", "Torso", "HumanoidRootPart", "Left Arm", "Right Arm", "Left Leg", "Right Leg" }
local function rbBestPart(targetChar, origin, budget, ignore)
    for _, name in ipairs(rbPartOrder) do
        local part = targetChar:FindFirstChild(name)
        if part and part:IsA("BasePart") and rbCanDamage(origin, part.Position, targetChar, budget, ignore) then
            return part
        end
    end
    return nil
end

local rbNextFire = 0
local rbReloadUntil = 0    -- hold fire until this time while a reload lands
local rbLastTool = nil
local function ragebotStep()
    local char = LocalPlayer.Character
    if not (char and ClientFire) then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end

    -- shoot from our own head, the game has ping leniency on the origin
    local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
    if not head then return end
    local origin = head.Position

    local muzzleIndex, bulletIndex = 1, 1
    local mc = rbMuzzleConfig(tool, muzzleIndex)
    local firerate = (mc and mc.Firerate) or 600
    local magSize = (mc and mc.Ammo) or 30
    local reloadTime = (mc and mc.ReloadTime) or 3
    local bs = mc and mc.BulletSettings and mc.BulletSettings[bulletIndex]
    local budget = (bs and bs.Penetration) or 0

    -- new gun -> reset the ammo tracker
    if tool ~= rbLastTool then
        rbLastTool = tool
        rbShots = 0
        rbReloadUntil = 0
    end

    -- mid-reload: hold fire until it lands (instant reload cuts the wait to ~0)
    if os.clock() < rbReloadUntil then return end

    -- out of ammo: never fire a dry mag. auto reload if it's on, otherwise wait for the
    -- player to reload (which zeroes rbShots via the reload hook)
    if magSize > 0 and rbShots >= magSize then
        if cfg.Combat.RagebotAutoReload then
            rbReloadServer(muzzleIndex, bulletIndex)
            rbReloadUntil = os.clock() + (cfg.Combat.InstantReload and 0.1 or reloadTime)
            rbShots = 0
        end
        return
    end

    local ignore = { char }
    local ig = workspace:FindFirstChild("Ignore")
    if ig then ignore[#ignore + 1] = ig end

    -- nearest enemy that has any hittable part; aim at their highest-priority part
    local me = LocalPlayer
    local best, bestDist
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= me and plr.Character and not isDowned(plr.Character) then -- skip downed
            if not (me.Team and plr.Team == me.Team) then -- never teammates
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                local ref = plr.Character:FindFirstChild("HumanoidRootPart")
                    or plr.Character:FindFirstChild("Head")
                if hum and hum.Health > 0 and ref then
                    local dist = (ref.Position - origin).Magnitude
                    if not bestDist or dist < bestDist then
                        local part = rbBestPart(plr.Character, origin, budget, ignore)
                        if part then best, bestDist = part, dist end
                    end
                end
            end
        end
    end

    if best and os.clock() >= rbNextFire then
        rbNextFire = os.clock() + 60 / firerate -- respect the weapon's real fire rate
        local dir = (best.Position - origin).Unit
        pcall(function()
            ClientFire.fire(tool, muzzleIndex, bulletIndex, origin, dir, {})
        end)
        rbShots = rbShots + 1
    end
end

local ragebotThread = task.spawn(function()
    while task.wait(0.03) do -- paced loop, cheaper than a render/heartbeat connection
        if cfg.Combat.Ragebot then
            pcall(ragebotStep)
        end
    end
end)





-- load linoria + addons
local LinoriaRepo = "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/"

Library = loadstring(game:HttpGet(LinoriaRepo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(LinoriaRepo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(LinoriaRepo .. "addons/SaveManager.lua"))()

-- window + tabs
local Window = Library:CreateWindow({
    Title = "Cold War - vault.cc",
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2,
})

local Tabs = {
    Combat = Window:AddTab("Combat"),
    ESP = Window:AddTab("ESP"),
    Misc = Window:AddTab("Misc"),
    Settings = Window:AddTab("Settings"),
}

-- load esp lib, pcall so a bad fetch doesnt take the whole ui down
local espCfg
local espOk, ESP = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/ttokennxyz/vaultcc/refs/heads/main/esplibcoldwar.lua"))()
end)

if espOk and type(ESP) == "table" then
    -- start disabled, ui drives everything through applyESP
    pcall(function()
        ESP:Load({ Enabled = false })
        espCfg = ESP:GetConfig()
    end)
else
    ESP = nil
    Library:Notify("Failed to load ESP library.")
end

-- push every control into the live esp config
-- lib re-reads config each frame so mutating espCfg is instant
local function applyESP()
    local c = espCfg
    if not c then return end

    -- core
    c.Enabled = Toggles.ESPMaster.Value
    c.LocalPlayer = false           -- never draw ourselves
    c.MaxDistance = Options.ESPMaxDistance.Value
    c.DynamicBoxes = true           -- always dynamic boxes
    c.DynamicBoxesCheap = false
    c.DynamicBoxesIncludeAll = false
    -- players/directories handled in refreshTeamFilter

    -- boxes
    c.Boxes = Toggles.ESPBoxes.Value
    c.BoxType = Options.ESPBoxType.Value
    c.BoxColor = Options.ESPBoxColor.Value
    c.BoxThickness = Options.ESPBoxThickness.Value
    c.Outlines.Style = Toggles.ESPBoxOutline.Value and "Full" or "None"
    c.Outlines.Color = Options.ESPBoxOutlineColor.Value

    -- box fill
    c.BoxFill.Enabled = Toggles.ESPBoxFill.Value
    c.BoxFill.Color = Options.ESPBoxFillColor.Value
    c.BoxFill.Transparency = Options.ESPBoxFillTransparency.Value

    -- names + info
    c.Names = Toggles.ESPNames.Value
    c.TextColor = Options.ESPNameColor.Value
    c.TextSize = Options.ESPTextSize.Value
    c.TextOutline = Toggles.ESPTextOutline.Value
    c.Distance.Enabled = Toggles.ESPDistance.Value
    c.Distance.Color = Options.ESPDistanceColor.Value
    c.Weapon.Enabled = Toggles.ESPWeapon.Value
    c.Weapon.UseToolFallback = true -- weapons are Tools under the character
    c.TeamIndicator.Enabled = Toggles.ESPTeam.Value
    c.FriendlyIndicator.Enabled = Toggles.ESPFriendly.Value
    c.FriendlyIndicator.CheckTeam = Toggles.ESPFriendly.Value
    c.FriendlyIndicator.CheckFriends = Toggles.ESPFriendly.Value

    -- health (lib reads per-part health via HealthBar.Source; see esp lib)
    c.HealthBar.Enabled = Toggles.ESPHealth.Value
    c.HealthBar.ShowText = true
    c.HealthBar.Source = (Options.ESPHealthMode.Value == "Target part") and "Part" or "Average"
    c.HealthBar.Part = cfg.Combat.SilentTarget

    -- chams. feed the same color/transparency into all 3 modes so the
    -- type dropdown just works without extra pickers
    c.Chams.Enabled = Toggles.ESPChams.Value
    c.Chams.Type = Options.ESPChamsType.Value

    local fill = Options.ESPChamsFill.Value
    local fillT = Options.ESPChamsFillT.Value
    local outline = Options.ESPChamsOutline.Value
    local outlineT = Options.ESPChamsOutlineT.Value
    local visCheck = Toggles.ESPChamsVisible.Value

    c.Chams.Highlight.FillColor = fill
    c.Chams.Highlight.FillTransparency = fillT
    c.Chams.Highlight.OutlineColor = outline
    c.Chams.Highlight.OutlineTransparency = outlineT
    c.Chams.Highlight.VisibleCheck = visCheck

    c.Chams.MeshChams.FillColor = fill
    c.Chams.MeshChams.FillTransparency = fillT
    c.Chams.MeshChams.OutlineColor = outline
    c.Chams.MeshChams.OutlineTransparency = outlineT
    c.Chams.MeshChams.VisibleCheck = visCheck

    c.Chams.Adornment.Color = fill
    c.Chams.Adornment.Transparency = fillT
    c.Chams.Adornment.VisibleCheck = visCheck

    -- flags + arrows
    c.Flags.Enabled = Toggles.ESPFlags.Value
    c.Flags.Options.Idle = Toggles.ESPFlagIdle.Value
    c.Flags.Options.Moving = Toggles.ESPFlagMoving.Value
    c.Flags.Options.Jumping = Toggles.ESPFlagJumping.Value
    c.Flags.Options.Swimming = Toggles.ESPFlagSwimming.Value
    c.OffScreenArrows.Enabled = Toggles.ESPArrows.Value
    c.OffScreenArrows.Color = Options.ESPArrowColor.Value
    c.OffScreenArrows.Size = Options.ESPArrowSize.Value
end

-- player tracking + teammate filter
-- lib has no team filter on its Players scan, so when filter is on we kill that
-- and feed only enemies through the Directories system instead (still tracks the
-- real char models so boxes/chams/health all work)
local function refreshTeamFilter()
    local c = espCfg
    if not c then return end

    local me = LocalPlayer

    if Toggles.ESPFilterTeam.Value then
        c.Players = false
        local dirs = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= me and plr.Character then
                -- same teamcheck as util.getTarget
                if not (me.Team and plr.Team == me.Team) then
                    dirs[#dirs + 1] = { DisplayName = plr.Name, Path = plr.Character:GetFullName() }
                end
            end
        end
        c.Directories = dirs
    else
        -- filter off, just use the built-in scan
        c.Players = true
        c.Directories = {}
    end
end

-- combat tab

--right: gunmods
local gunmods = Tabs.Combat:AddRightGroupbox("Gun Mods")
gunmods:AddSlider("recoilmult", { Text = "Recoil Multiplier", Default = 0, Min = 0, Max = 1, Rounding = 2 })
Options['recoilmult']:OnChanged(function(val)
    cfg.Combat.RecoilMult = val
end)
gunmods:AddSlider("spreadmult", { Text = "Spread Multiplier", Default = 0, Min = 0, Max = 1, Rounding = 2 })
Options['spreadmult']:OnChanged(function(val)
    cfg.Combat.SpreadMult = val
end)
gunmods:AddToggle("forceauto", { Text = "Force Auto", Default = true})
Toggles['forceauto']:OnChanged(function(val)
    cfg.Combat.ForceAuto = val
end)
gunmods:AddToggle("infinitemags", { Text = "Infinite Magazines", Default = false, Tooltip = "Requires an ammo crate to be placed somewhere on the map" })
Toggles['infinitemags']:OnChanged(function(val) -- infinite mags
    cfg.Combat.InfiniteMags = val
end)
gunmods:AddToggle("instantequip", { Text = "Instant Equip", Default = false, Tooltip = "Equip weapons instantly" })
Toggles['instantequip']:OnChanged(function(val) -- instant equip
    cfg.Combat.InstantEquip = val
end)
gunmods:AddToggle("instantreload", { Text = "Instant Reload", Default = false, Tooltip = "Reload instantly" })
Toggles['instantreload']:OnChanged(function(val) -- instant reload
    cfg.Combat.InstantReload = val
end)
gunmods:AddToggle("nodrop", { Text = "No Bullet Drop", Default = false, Tooltip = "Bullets ignore gravity" })
Toggles['nodrop']:OnChanged(function(val) -- no bullet drop
    cfg.Combat.NoBulletDrop = val
end)
gunmods:AddToggle("instantbullet", { Text = "Instant Bullet", Default = false, Tooltip = "Bullets travel instantly" })
Toggles['instantbullet']:OnChanged(function(val) -- instant bullet
    cfg.Combat.InstantBullet = val
end)

--right: aiming
local aiming = Tabs.Combat:AddRightGroupbox("Aiming")
aiming:AddToggle("aimanywhere", { Text = "Aim Anywhere", Default = true, Tooltip = "Aim in any stance" })
Toggles['aimanywhere']:OnChanged(function(val) -- aim anywhere
    cfg.Combat.AimAnywhere = val
end)
aiming:AddToggle("instantads", { Text = "Instant ADS", Default = true, Tooltip = "Aim instantly" })
Toggles['instantads']:OnChanged(function(val) -- instant ads
    cfg.Combat.InstantADS = val
end)
aiming:AddToggle("noadsslowdown", { Text = "No ADS Slowdown", Default = true, Tooltip = "Full speed while aiming" })
Toggles['noadsslowdown']:OnChanged(function(val) -- no ads slowdown
    cfg.Combat.NoADSSlowdown = val
end)

--left: silent
local silent = Tabs.Combat:AddLeftGroupbox("Silent Aim")
silent:AddToggle("silentenabled", { Text = "Enabled", Default = true, Tooltip = "Master switch for Silent Aim" })
Toggles['silentenabled']:OnChanged(function(val) -- silent enabled
    cfg.Combat.SilentEnabled = val
end)
silent:AddDropdown("silenttarget", { Text = "Target part", Values = { "Head", "Torso", "HumanoidRootPart", "Left Arm", "Right Arm", "Left Leg", "Right Leg" }, Default = 1, Multi = false })
Options['silenttarget']:OnChanged(function(val) -- target part
    cfg.Combat.SilentTarget = val
    if espCfg then espCfg.HealthBar.Part = val end -- keep "Target part" health in sync
end)
silent:AddToggle("fovenabled", { Text = "FOV Circle", Default = false})
Toggles['fovenabled']:OnChanged(function(val) -- fov circle enabled
    cfg.Combat.SilentFovEnabled = val
end)
silent:AddSlider("fovsize", { Text = "FOV Circle Size", Default = 100, Min = 5, Max = 500, Rounding = 0 })
Options['fovsize']:OnChanged(function(val) -- fov circle size
    cfg.Combat.SilentFov = val
end)
silent:AddToggle("silentteamcheck", { Text = "Exclude Teammates", Default = true})
Toggles['silentteamcheck']:OnChanged(function(val) -- silent enabled
    cfg.Combat.SilentExcludeTeammates = val
end)
silent:AddToggle("fovdraw", { Text = "Draw FOV Circle", Default = false })
Toggles['fovdraw']:OnChanged(function(val) -- draw fov circle
    cfg.Combat.FovDrawEnabled = val
end)
silent:AddLabel("FOV color"):AddColorPicker("fovcolor", { Default = Color3.fromRGB(255, 255, 255), Title = "FOV color" })
Options['fovcolor']:OnChanged(function(val) -- fov circle color
    cfg.Combat.FovColor = val
end)
silent:AddSlider("fovthickness", { Text = "FOV Thickness", Default = 1, Min = 1, Max = 10, Rounding = 0 })
Options['fovthickness']:OnChanged(function(val) -- fov circle thickness
    cfg.Combat.FovThickness = val
end)
silent:AddToggle("snaplines", { Text = "Snapline", Default = false, Tooltip = "Draw a line to the current target" })
Toggles['snaplines']:OnChanged(function(val) -- snapline
    cfg.Combat.Snaplines = val
end)
silent:AddLabel("Snapline color"):AddColorPicker("snaptargetcolor", { Default = Color3.fromRGB(255, 0, 0), Title = "Snapline color" })
Options['snaptargetcolor']:OnChanged(function(val) -- snapline color
    cfg.Combat.SnapTargetColor = val
end)

--left: ragebot (separate from silent aim, auto-fires on its own)
local ragebot = Tabs.Combat:AddLeftGroupbox("Ragebot")
ragebot:AddToggle("ragebot", { Text = "Enabled", Default = false, Tooltip = "Auto-shoot any enemy you can hit" })
Toggles['ragebot']:OnChanged(function(val) -- ragebot
    cfg.Combat.Ragebot = val
end)
ragebot:AddToggle("ragebotwallbang", { Text = "Wallbang", Default = false, Tooltip = "Also shoot enemies through penetrable walls" })
Toggles['ragebotwallbang']:OnChanged(function(val) -- ragebot wallbang
    cfg.Combat.RagebotWallbang = val
end)
ragebot:AddToggle("ragebotautoreload", { Text = "Auto Reload", Default = false, Tooltip = "Reload automatically when the mag runs dry" })
Toggles['ragebotautoreload']:OnChanged(function(val) -- ragebot auto reload
    cfg.Combat.RagebotAutoReload = val
end)

-- fov circle drawing
-- screengui in gethui() with coregui fallback, same as the esp lib
local fovGui = Instance.new("ScreenGui")
fovGui.Name = "cwfov"
fovGui.IgnoreGuiInset = true -- absolute space, matches GetMouseLocation + WorldToScreenPoint
fovGui.ResetOnSpawn = false
fovGui.DisplayOrder = 100
fovGui.Parent = (gethui and gethui()) or game:GetService("CoreGui")

local fovCircle = Instance.new("Frame")
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.BackgroundTransparency = 1
fovCircle.BorderSizePixel = 0
fovCircle.Visible = false
fovCircle.Parent = fovGui

local fovCorner = Instance.new("UICorner")
fovCorner.CornerRadius = UDim.new(1, 0) -- half of size = perfect circle
fovCorner.Parent = fovCircle

local fovStroke = Instance.new("UIStroke")
fovStroke.Thickness = 1
fovStroke.Color = Color3.fromRGB(255, 255, 255)
fovStroke.Parent = fovCircle

-- camera + 1 so it draws right after the camera, never lags behind the cursor
RunService:BindToRenderStep("cwfov", Enum.RenderPriority.Camera.Value + 1, function()
    if not cfg.Combat.FovDrawEnabled then
        fovCircle.Visible = false
        return
    end

    local m = UserInputService:GetMouseLocation()
    local r = cfg.Combat.SilentFov
    fovCircle.Size = UDim2.fromOffset(r * 2, r * 2)
    fovCircle.Position = UDim2.fromOffset(m.X, m.Y)
    fovStroke.Thickness = cfg.Combat.FovThickness
    fovStroke.Color = cfg.Combat.FovColor
    fovCircle.Visible = true
end)

-- snaplines: one line from the cursor to the cached target (viewport space throughout)
local snapGui = Instance.new("ScreenGui")
snapGui.Name = "cwsnap"
snapGui.IgnoreGuiInset = true -- same space as the esp lib (raw WorldToViewportPoint)
snapGui.ResetOnSpawn = false
snapGui.DisplayOrder = 100
snapGui.Parent = (gethui and gethui()) or game:GetService("CoreGui")

local snapLine = Instance.new("Frame")
snapLine.AnchorPoint = Vector2.new(0.5, 0.5)
snapLine.BorderSizePixel = 0
snapLine.Visible = false
snapLine.Parent = snapGui

RunService:BindToRenderStep("cwsnap", Enum.RenderPriority.Camera.Value + 1, function()
    local part = util.target
    if cfg.Combat.Snaplines and part and part.Parent then
        local camera = workspace.CurrentCamera
        if camera then
            -- same space the multi-snapline version drew in (which lined up): raw
            -- WorldToViewportPoint endpoint (same as the esp lib) + raw GetMouseLocation
            -- origin (same as the fov circle), no inset math
            local vp, on = camera:WorldToViewportPoint(part.Position)
            if on and vp.Z > 0 then
                local origin = UserInputService:GetMouseLocation()
                local p2 = Vector2.new(vp.X, vp.Y)
                local diff = p2 - origin
                snapLine.Size = UDim2.fromOffset(diff.Magnitude, 1)
                snapLine.Position = UDim2.fromOffset((origin.X + p2.X) / 2, (origin.Y + p2.Y) / 2)
                snapLine.Rotation = math.deg(math.atan2(diff.Y, diff.X))
                snapLine.BackgroundColor3 = cfg.Combat.SnapTargetColor
                snapLine.Visible = true
                return
            end
        end
    end
    snapLine.Visible = false
end)

-- esp tab

-- left: main
local espMain = Tabs.ESP:AddLeftGroupbox("Main")
espMain:AddToggle("ESPMaster", { Text = "Enabled", Default = false, Tooltip = "Master switch for all ESP" })
espMain:AddToggle("ESPFilterTeam", { Text = "Filter teammates", Default = false, Tooltip = "Hide players on your team" })
espMain:AddSlider("ESPMaxDistance", { Text = "Max distance", Default = 0, Min = 0, Max = 2000, Rounding = 0, Suffix = " studs", Tooltip = "Hide targets past this range (0 = unlimited)" })

-- left: boxes
local espBox = Tabs.ESP:AddLeftGroupbox("Boxes")
espBox:AddToggle("ESPBoxes", { Text = "Boxes", Default = true })
espBox:AddDropdown("ESPBoxType", { Text = "Box type", Values = { "Normal", "Corner" }, Default = 1, Multi = false })
espBox:AddLabel("Box color"):AddColorPicker("ESPBoxColor", { Default = Color3.fromRGB(255, 255, 255), Title = "Box color" })
espBox:AddSlider("ESPBoxThickness", { Text = "Box thickness", Default = 1, Min = 1, Max = 6, Rounding = 0 })
espBox:AddToggle("ESPBoxOutline", { Text = "Box outline", Default = true })
espBox:AddLabel("Outline color"):AddColorPicker("ESPBoxOutlineColor", { Default = Color3.fromRGB(0, 0, 0), Title = "Outline color" })
espBox:AddDivider()
espBox:AddToggle("ESPBoxFill", { Text = "Box fill", Default = false })
espBox:AddLabel("Fill color"):AddColorPicker("ESPBoxFillColor", { Default = Color3.fromRGB(255, 255, 255), Title = "Fill color" })
espBox:AddSlider("ESPBoxFillTransparency", { Text = "Fill transparency", Default = 0.9, Min = 0, Max = 1, Rounding = 2 })

-- left: chams
local espChams = Tabs.ESP:AddLeftGroupbox("Chams")
espChams:AddToggle("ESPChams", { Text = "Chams", Default = false })
espChams:AddDropdown("ESPChamsType", { Text = "Chams type", Values = { "Highlight", "Adornment", "MeshChams" }, Default = 1, Multi = false, Tooltip = "MeshChams = real players only" })
espChams:AddLabel("Fill color"):AddColorPicker("ESPChamsFill", { Default = Color3.fromRGB(59, 144, 204), Title = "Cham fill" })
espChams:AddSlider("ESPChamsFillT", { Text = "Fill transparency", Default = 0.6, Min = 0, Max = 1, Rounding = 2 })
espChams:AddLabel("Outline color"):AddColorPicker("ESPChamsOutline", { Default = Color3.fromRGB(255, 255, 255), Title = "Cham outline" })
espChams:AddSlider("ESPChamsOutlineT", { Text = "Outline transparency", Default = 0, Min = 0, Max = 1, Rounding = 2 })
espChams:AddToggle("ESPChamsVisible", { Text = "Visible check", Default = false, Tooltip = "On = occluded depth, Off = always on top" })

-- right: names + info
local espInfo = Tabs.ESP:AddRightGroupbox("Names & Info")
espInfo:AddToggle("ESPNames", { Text = "Names", Default = true })
espInfo:AddLabel("Name color"):AddColorPicker("ESPNameColor", { Default = Color3.fromRGB(255, 255, 255), Title = "Name color" })
espInfo:AddSlider("ESPTextSize", { Text = "Text size", Default = 12, Min = 6, Max = 28, Rounding = 0 })
espInfo:AddToggle("ESPTextOutline", { Text = "Text outline", Default = true })
espInfo:AddDivider()
espInfo:AddToggle("ESPDistance", { Text = "Distance", Default = false })
espInfo:AddLabel("Distance color"):AddColorPicker("ESPDistanceColor", { Default = Color3.fromRGB(255, 255, 255), Title = "Distance color" })
espInfo:AddToggle("ESPWeapon", { Text = "Weapon", Default = false })
espInfo:AddToggle("ESPTeam", { Text = "Team indicator", Default = false })
espInfo:AddToggle("ESPFriendly", { Text = "Friendly indicator", Default = false, Tooltip = "Marks teammates & Roblox friends" })

-- right: health
local espHealth = Tabs.ESP:AddRightGroupbox("Health")
espHealth:AddToggle("ESPHealth", { Text = "Health", Default = false, Tooltip = "Show health text on players" })
espHealth:AddDropdown("ESPHealthMode", { Text = "Health mode", Values = { "Average", "Target part" }, Default = 1, Multi = false, Tooltip = "Average of all parts, or just the combat target part" })

-- right: flags + arrows
local espFlags = Tabs.ESP:AddRightGroupbox("Flags & Arrows")
espFlags:AddToggle("ESPFlags", { Text = "Status flags", Default = false })
espFlags:AddToggle("ESPFlagIdle", { Text = "Flag: Idle", Default = false })
espFlags:AddToggle("ESPFlagMoving", { Text = "Flag: Moving", Default = false })
espFlags:AddToggle("ESPFlagJumping", { Text = "Flag: Jumping", Default = false })
espFlags:AddToggle("ESPFlagSwimming", { Text = "Flag: Swimming", Default = false })
espFlags:AddDivider()
espFlags:AddToggle("ESPArrows", { Text = "Off-screen arrows", Default = false })
espFlags:AddLabel("Arrow color"):AddColorPicker("ESPArrowColor", { Default = Color3.fromRGB(255, 255, 255), Title = "Arrow color" })
espFlags:AddSlider("ESPArrowSize", { Text = "Arrow size", Default = 14, Min = 8, Max = 40, Rounding = 0 })

-- hook every control to applyESP. OnChanged fires right away on attach and on
-- every change/config load after
local espToggleKeys = {
    "ESPMaster", "ESPBoxes", "ESPBoxOutline", "ESPBoxFill", "ESPNames", "ESPTextOutline", "ESPDistance",
    "ESPWeapon", "ESPTeam", "ESPFriendly", "ESPHealth", "ESPChams", "ESPChamsVisible",
    "ESPFlags", "ESPFlagIdle", "ESPFlagMoving", "ESPFlagJumping", "ESPFlagSwimming", "ESPArrows",
}
local espOptionKeys = {
    "ESPMaxDistance", "ESPBoxType", "ESPBoxColor", "ESPBoxThickness", "ESPBoxOutlineColor", "ESPBoxFillColor",
    "ESPBoxFillTransparency", "ESPNameColor", "ESPTextSize", "ESPDistanceColor", "ESPHealthMode",
    "ESPChamsType", "ESPChamsFill", "ESPChamsFillT", "ESPChamsOutline", "ESPChamsOutlineT",
    "ESPArrowColor", "ESPArrowSize",
}

for _, key in ipairs(espToggleKeys) do
    Toggles[key]:OnChanged(applyESP)
end
for _, key in ipairs(espOptionKeys) do
    Options[key]:OnChanged(applyESP)
end

-- filter drives player tracking, not applyESP
Toggles.ESPFilterTeam:OnChanged(refreshTeamFilter)

applyESP()
refreshTeamFilter()

-- keep enemy list fresh (joins/leaves, team swaps, respawns)
local teamFilterConn
if ESP then
    local acc = 0
    teamFilterConn = RunService.Heartbeat:Connect(function(dt)
        acc = acc + dt
        if acc < 1 then return end
        acc = 0
        refreshTeamFilter()
    end)
end

-- misc tab
local miscMove = Tabs.Misc:AddLeftGroupbox("Movement")
miscMove:AddToggle("omnisprint", { Text = "Omni Sprint", Default = false, Tooltip = "Sprint in any direction" })
Toggles['omnisprint']:OnChanged(function(val) -- omni sprint
    cfg.Combat.OmniSprint = val
end)
miscMove:AddToggle("nohurtslowdown", { Text = "No Hurt Slowdown", Default = false, Tooltip = "Full speed with injured legs" })
Toggles['nohurtslowdown']:OnChanged(function(val) -- no hurt slowdown
    cfg.Combat.NoHurtSlowdown = val
end)

local miscHeal = Tabs.Misc:AddLeftGroupbox("Healing")
miscHeal:AddToggle("autoheal", { Text = "Auto Heal", Default = false, Tooltip = "Bandage damaged limbs automatically" })
Toggles['autoheal']:OnChanged(function(val) -- auto heal
    cfg.Combat.AutoHeal = val
end)
miscHeal:AddToggle("instantheal", { Text = "Instant Heal", Default = false, Tooltip = "Heal with no delay" })
Toggles['instantheal']:OnChanged(function(val) -- instant heal
    cfg.Combat.InstantHeal = val
end)

local miscBandage = Tabs.Misc:AddRightGroupbox("Bandage")
miscBandage:AddToggle("nobandageslowdown", { Text = "No Bandage Slowdown", Default = false, Tooltip = "Stay at full speed while bandaging" })
Toggles['nobandageslowdown']:OnChanged(function(val) -- no bandage slowdown
    cfg.Combat.NoBandageSlowdown = val
end)

local miscRevive = Tabs.Misc:AddRightGroupbox("Revive")
miscRevive:AddToggle("fastrevive", { Text = "Fast Revive", Default = false, Tooltip = "Revive teammates faster" })
Toggles['fastrevive']:OnChanged(function(val) -- fast revive
    cfg.Combat.FastRevive = val
end)

local miscVehicle = Tabs.Misc:AddRightGroupbox("Vehicles")
miscVehicle:AddToggle("carmods", { Text = "Car Mods", Default = false, Tooltip = "More speed, torque and handling" })
Toggles['carmods']:OnChanged(function(val) -- car mods
    cfg.Combat.CarMods = val
    if val then applyCarMods() end
end)
miscVehicle:AddToggle("driveanycar", { Text = "Drive Any Car", Default = false, Tooltip = "Enter any vehicle" })
Toggles['driveanycar']:OnChanged(function(val) -- drive any car
    cfg.Combat.DriveAnyCar = val
end)
miscVehicle:AddToggle("quickclimb", { Text = "Quick Enter/Exit", Default = false, Tooltip = "Enter and exit vehicles instantly" })
Toggles['quickclimb']:OnChanged(function(val) -- quick climb
    cfg.Combat.QuickClimb = val
end)
miscVehicle:AddToggle("shootincar", { Text = "Shoot In Vehicle", Default = false, Tooltip = "Use weapons while in a vehicle" })
Toggles['shootincar']:OnChanged(function(val) -- shoot in car
    cfg.Combat.ShootInCar = val
end)

-- settings tab (menu + config)
local menuGroup = Tabs.Settings:AddLeftGroupbox("Menu")

local DiscordInvite = "Z7tvDkBUxX"

-- opens an invite straight in the desktop discord client. discord runs a local rpc
-- server on one of ports 6463-6472; the INVITE_BROWSER command pops the invite. the
-- Origin header has to look like discord.com or the rpc rejects it
local function openDiscordInvite(code)
    local request = http_request or request or (syn and syn.request)
        or (fluxus and fluxus.request) or (getgenv and getgenv().request)
    if not request then
        Library:Notify("No HTTP request function on this executor.")
        return
    end
    local body = HttpService:JSONEncode({
        cmd = "INVITE_BROWSER",
        args = { code = code },
        nonce = HttpService:GenerateGUID(false),
    })
    local opened = false
    for port = 6463, 6472 do
        local ok, res = pcall(request, {
            Url = ("http://127.0.0.1:%d/rpc?v=1"):format(port),
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["Origin"] = "https://discord.com",
            },
            Body = body,
        })
        if ok and res and (res.StatusCode == 200 or res.Success) then
            opened = true
            break
        end
    end
    Library:Notify(opened and "Opened the invite in Discord." or "Couldn't reach Discord (is it running?).")
end

menuGroup:AddButton({
    Text = "Join Discord",
    Func = function()
        openDiscordInvite(DiscordInvite)
    end,
})
menuGroup:AddButton({
    Text = "Unload",
    Func = function()
        Library:Unload()
    end,
})
menuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })

-- menu open/close key
Library.ToggleKeybind = Options.MenuKeybind

-- kill esp on unload
Library:OnUnload(function()
    if teamFilterConn then
        teamFilterConn:Disconnect()
        teamFilterConn = nil
    end
    pcall(function() RunService:UnbindFromRenderStep("cwfov") end)
    pcall(function() RunService:UnbindFromRenderStep("cwsnap") end)
    if magsConn then magsConn:Disconnect() magsConn = nil end
    if bandageConn then bandageConn:Disconnect() bandageConn = nil end
    if healConn then healConn:Disconnect() healConn = nil end
    if reviveConn then reviveConn:Disconnect() reviveConn = nil end
    if carModsConn then carModsConn:Disconnect() carModsConn = nil end
    if ragebotThread then pcall(task.cancel, ragebotThread) ragebotThread = nil end
    if fovGui then
        fovGui:Destroy()
        fovGui = nil
    end
    if snapGui then
        snapGui:Destroy()
        snapGui = nil
    end
    if ESP then
        pcall(function() ESP:Unload() end)
    end
end)

-- config + theme
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

ThemeManager:SetFolder("VaultCC")
SaveManager:SetFolder("VaultCC/ColdWar")

-- builds the config save/load ui into settings
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)

-- load autoload cfg last (fires OnChanged -> applyESP)
SaveManager:LoadAutoloadConfig()

Library:Notify("Cold War loaded <3")