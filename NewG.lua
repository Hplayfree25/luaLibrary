--[[
    ================================================================================
    LICENSE & DISTRIBUTION NOTICE
    ================================================================================
    Developed by NMZ Team (c) 2026

    This software is released under a strict Open-Source, Free-Use License.
    By using, copying, modifying, merging, publishing, distributing, sublicensing,
    or integrating this source code (or any derivative work thereof) in any form,
    you explicitly agree to the following terms:

    1. MANDATORY OPEN-SOURCE REQUIREMENT
       This code and any project derived from it, or containing parts of it, MUST
       remain 100% open source. The complete, unmodified source code must be made
       freely and publicly available at all times to any recipient, user, or
       developer, without exceptions.

    2. ABSOLUTE KEYLESS AND FREE-USE MANDATE
       This script, and any scripts, hubs, or executors that utilize any portion
       of this code, MUST NOT be placed behind any form of gateway, paywall,
       monetization link, or key system (including but not limited to Linkvertise,
       LootLabs, Key-gateways, or custom validation protocols). Access to this
       software MUST be completely keyless, immediate, and direct.

    3. CREDITS AND ATTRIBUTION
       Appropriate credit to the original creators (NMZ Team) must be visible 
       and preserved within the source files and the user interface where applicable.

    ANY VIOLATION OF THESE TERMS CONSTITUTES A DIRECT BREACH OF THIS LICENSE
    AND AN INFRINGEMENT UPON THE WORKS OF THE ORIGINAL DEVELOPERS. KEEP IT FREE,
    KEEP IT OPEN, AND RESPECT THE DEVELOPERS' VISION.
    ================================================================================
--]]
local TARGET_PLACE_ID = 3678761576
if game.PlaceId ~= TARGET_PLACE_ID then
    error("[NMZ] Entrenched WW1 only — PlaceId " .. tostring(TARGET_PLACE_ID) .. " required (got " .. tostring(game.PlaceId) .. ")", 0)
end

local isExecutorSupported = true
if type(hookfunction) ~= "function" then
    isExecutorSupported = false
end
local executorName = (identifyexecutor or getexecutorname or function() return "" end)()
local isVelocityOrSimilar = false
if string.find(string.lower(executorName), "velocity") or string.find(string.lower(executorName), "solara") or string.find(string.lower(executorName), "xeno") then
    isExecutorSupported = false
    isVelocityOrSimilar = true
end

local cloneref = cloneref or function(i: Instance) return i; end;
local clonefunction = clonefunction or function(f: (...any) -> (...any)) return f; end;
local newcclosure = newcclosure or clonefunction;
local hookfunction = hookfunction or function(old, new) return old end;
local gethui = gethui or function()
    local success, coregui = pcall(game.GetService, game, "CoreGui")
    return success and coregui or nil
end;

local parentGui = (gethui and gethui()) or cloneref(game:GetService("CoreGui")) or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

local Players = cloneref(game:GetService("Players"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local RunService = cloneref(game:GetService("RunService"))
local TeleportService = cloneref(game:GetService("TeleportService"))
local TweenService = cloneref(game:GetService("TweenService"))
local VirtualUser = cloneref(game:GetService("VirtualUser"))
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- ponytail: TouchEnabled matches the UI lib's own mobile detection; on touch-laptops the
-- extra AIM button is harmless since right-click aim still works. Upgrade: AND not MouseEnabled.
local isMobile = UserInputService.TouchEnabled
local mobileAimHolding = false
local mobileAimGui = nil
local mobileAimBtn = nil

if getconnections and not isVelocityOrSimilar then
    for _, conn in pairs(getconnections(game:GetService("ScriptContext").Error)) do
        if type(conn) == "table" and conn.Disable then pcall(conn.Disable, conn) end
    end
    for _, conn in pairs(getconnections(game:GetService("LogService").MessageOut)) do
        if type(conn) == "table" and conn.Disable then pcall(conn.Disable, conn) end
    end
end

local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local noRecoilEnabled = true
local noSpreadEnabled = true
local fastBoltEnabled = true
local silentReloadEnabled = false
local silentAimEnabled = false

local recoilThread = nil
local currentVelocity = nil
local currentTool = nil
local reloadConn = nil
local scriptUnloadedLocal = false
local silentHookInstalled = false
local installSilentAimAll -- forward decl (defined after aim helpers / UI)

-- Resolve gun from equip cache OR currently held tool (fixes silent aim after late inject).
local function resolveGunContext()
    local tool = currentTool
    if not tool or not tool.Parent then
        tool = nil
        local char = LocalPlayer.Character
        if char then
            for _, ch in ipairs(char:GetChildren()) do
                if ch:IsA("Tool") then
                    tool = ch
                    break
                end
            end
        end
    end
    local vel = (tool and tool:GetAttribute("Velocity")) or currentVelocity or 500
    if tool then
        currentTool = tool
        currentVelocity = vel
    end
    return tool, vel
end

local function getHeldTool()
    local char = LocalPlayer.Character
    if not char then return nil end
    for _, ch in ipairs(char:GetChildren()) do
        if ch:IsA("Tool") then return ch end
    end
    return nil
end

-- Exact V1.5 attribute set (same values). Used for late inject / Solara when Equip wrap didn't run yet.
-- NEVER call Recoil=0 every frame blindly — that fights recovery and pulls aim down.
local function applyV15GunAttrs(tool)
    if not tool or not tool:IsA("Tool") then return end
    currentTool = tool
    currentVelocity = tool:GetAttribute("Velocity") or currentVelocity or 500
    if noRecoilEnabled then
        pcall(function() tool:SetAttribute("Recoil", 0) end)
    end
    if noSpreadEnabled then
        pcall(function()
            tool:SetAttribute("Spread", 0)
            tool:SetAttribute("SpreadDefault", 99999999)
            tool:SetAttribute("MinSpread", 0)
            tool:SetAttribute("MaxSpread", 0)
            local b = tool:FindFirstChild("Bloom")
            if b then b.Value = 0 end
        end)
    end
end

-- Soft multi-executor support (does not replace V1.5 module path):
-- 1) on equip / late inject: same one-shot attrs as V1.5 Equip
-- 2) heartbeat: keep spread/bloom only (same as V1.5 recoilThread) + re-zero Recoil ONLY if game rewrote it
local softGunConn = nil
local function stopSoftGunSupport()
    if softGunConn then softGunConn:Disconnect(); softGunConn = nil end
end

local function bindSoftGunChar(char)
    if not char then return end
    local function onTool(ch)
        if not ch:IsA("Tool") then return end
        applyV15GunAttrs(ch)
        pcall(function()
            ch.Equipped:Connect(function()
                applyV15GunAttrs(ch)
            end)
        end)
    end
    for _, ch in ipairs(char:GetChildren()) do onTool(ch) end
    char.ChildAdded:Connect(onTool)
end

if LocalPlayer.Character then bindSoftGunChar(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(function(char)
    task.defer(bindSoftGunChar, char)
end)

softGunConn = RunService.Heartbeat:Connect(function()
    if scriptUnloadedLocal then return end
    if not noRecoilEnabled and not noSpreadEnabled then return end
    local tool = getHeldTool()
    if not tool then return end
    pcall(function()
        -- Mirror V1.5 loop spread side only
        if noSpreadEnabled then
            tool:SetAttribute("Spread", 0)
            tool:SetAttribute("SpreadDefault", 99999999)
            tool:SetAttribute("MinSpread", 0)
            tool:SetAttribute("MaxSpread", 0)
            local b = tool:FindFirstChild("Bloom")
            if b then b.Value = 0 end
        end
        -- Recoil: only if game put a non-zero value back (not spam 0→0)
        if noRecoilEnabled then
            local r = tool:GetAttribute("Recoil")
            if r ~= nil and r ~= 0 then
                tool:SetAttribute("Recoil", 0)
            end
        end
    end)
end)

local success, wm = pcall(require, ReplicatedStorage:WaitForChild("WeaponModule", 5))
if success and wm and type(wm) == "table" then
    if not getgenv().NMZ_Originals then
        getgenv().NMZ_Originals = {
            Equip = rawget(wm, "Equip"),
            Cycle = rawget(wm, "Cycle"),
            boltCycleAction = rawget(wm, "boltCycleAction"),
            Reload = rawget(wm, "Reload"),
            Shoot = rawget(wm, "Shoot")
        }
    end

    if getgenv().NMZ_Originals.Equip then
        local oldEquip = getgenv().NMZ_Originals.Equip
        local newEquip = newcclosure(function(data, action)
            pcall(function()
                if recoilThread then coroutine.close(recoilThread); recoilThread = nil end
                if reloadConn then reloadConn:Disconnect(); reloadConn = nil end

                if type(action) == "string" and action == "Equip" and type(data) == "table" and data.Tool then
                    currentTool = data.Tool
                    currentVelocity = data.Tool:GetAttribute("Velocity") or 500
                    
                    isBoltAction = false
                    pcall(function()
                        if data.animationList and data.animationList.boltCycleAnimation then
                            isBoltAction = true
                        end
                    end)

                    if noRecoilEnabled then data.Tool:SetAttribute("Recoil", 0) end
                    if noSpreadEnabled then
                        data.Tool:SetAttribute("Spread", 0)
                        data.Tool:SetAttribute("SpreadDefault", 99999999)
                        data.Tool:SetAttribute("MinSpread", 0)
                        data.Tool:SetAttribute("MaxSpread", 0)
                    end
                    
                    recoilThread = task.spawn(function()
                        while task.wait() do
                            if scriptUnloadedLocal then break end
                            if not data or not data.Tool or not data.Tool.Parent then break end
                            
                            pcall(function()
                                if noRecoilEnabled and data.RecoilPattern then
                                    table.clear(data.RecoilPattern)
                                end
                                if noSpreadEnabled and data.Tool then
                                    data.Tool:SetAttribute("Spread", 0)
                                    data.Tool:SetAttribute("SpreadDefault", 99999999) 
                                    data.Tool:SetAttribute("MinSpread", 0)
                                    data.Tool:SetAttribute("MaxSpread", 0)
                                    local b = data.Tool:FindFirstChild("Bloom")
                                    if b then b.Value = 0 end
                                end
                                if fastBoltEnabled then
                                    pcall(function()
                                        if data.animationList then
                                            if data.animationList.boltCycleAnimation and data.animationList.boltCycleAnimation.IsPlaying then 
                                                data.animationList.boltCycleAnimation:AdjustSpeed(20) 
                                            end
                                            if data.animationList.aimFireAnimation and data.animationList.aimFireAnimation.IsPlaying then 
                                                data.animationList.aimFireAnimation:AdjustSpeed(20) 
                                            end
                                            if data.animationList.hipFireAnimation and data.animationList.hipFireAnimation.IsPlaying then 
                                                data.animationList.hipFireAnimation:AdjustSpeed(20) 
                                            end
                                        end
                                    end)
                                end
                            end)
                        end
                    end)
                end
            end)
            return oldEquip(data, action)
        end)
        rawset(wm, "Equip", newEquip)
    end

    local targetName = rawget(wm, "boltCycleAction") and "boltCycleAction" or "Cycle"
    if getgenv().NMZ_Originals[targetName] then
        local oldCycle = getgenv().NMZ_Originals[targetName]
        local newCycle = newcclosure(function(data, ...)
            if fastBoltEnabled then
                if type(data) == "table" then
                    data.Cycle = false
                    data.clientCanFire = true
                    if data.animationList then
                        if data.animationList.boltCycleAnimation then pcall(function() data.animationList.boltCycleAnimation:Stop() end) end
                        if data.animationList.aimFireAnimation then pcall(function() data.animationList.aimFireAnimation:Stop() end) end
                        if data.animationList.hipFireAnimation then pcall(function() data.animationList.hipFireAnimation:Stop() end) end
                        if data.animationList.equipAnimation and not data.animationList.equipAnimation.IsPlaying then 
                            pcall(function() data.animationList.equipAnimation:Play() end) 
                        end
                    end
                end
                return
            end
            return oldCycle(data, ...)
        end)
        rawset(wm, targetName, newCycle)
    end

    if getgenv().NMZ_Originals.Reload then
        local oldReload = getgenv().NMZ_Originals.Reload
        local newReload = newcclosure(function(data, ...)
            if silentReloadEnabled then
                if type(data) == "table" and data.Tool then
                    task.spawn(function()
                        pcall(function()
                            local ServerEvents = ReplicatedStorage:FindFirstChild("ServerEvents")
                            if ServerEvents and ServerEvents:FindFirstChild("Reload") then
                                ServerEvents.Reload:InvokeServer(data)
                            end
                        end)
                    end)
                end
                return
            end
            return oldReload(data, ...)
        end)
        rawset(wm, "Reload", newReload)
    end

    if getgenv().NMZ_Originals.Shoot then
        local oldShoot = getgenv().NMZ_Originals.Shoot
        local newShoot = newcclosure(function(data, ...)
            if type(data) == "table" and data.Tool then
                currentTool = data.Tool
                currentVelocity = data.Tool:GetAttribute("Velocity") or currentVelocity or 500
            end
            if fastBoltEnabled and type(data) == "table" and data.Tool and data.Tool:GetAttribute("ToolType") == "Bolt Action" then
                local toolName = data.Tool.Name
                local delay = 1.3
                if data.animationList and data.animationList.boltCycleAnimation then
                    delay = data.animationList.boltCycleAnimation.Length
                end
                if not getgenv()._lastShotTime then getgenv()._lastShotTime = {} end
                if getgenv()._lastShotTime[toolName] and tick() - getgenv()._lastShotTime[toolName] < delay then
                    return -- Block ghost bullet
                end
                getgenv()._lastShotTime[toolName] = tick()
            end
            return oldShoot(data, ...)
        end)
        rawset(wm, "Shoot", newShoot)
    end

    LocalPlayer.CharacterAdded:Connect(function()
        pcall(function()
            if recoilThread then coroutine.close(recoilThread); recoilThread = nil end
            if reloadConn then reloadConn:Disconnect(); reloadConn = nil end
        end)
    end)
end

local espEnabled = true
local espHighlightEnabled = true
local espBoxEnabled = false
local espTracerEnabled = false
local boxColor = Color3.new(1,1,1)
local boxColorIndex = 1
local boxColors = {
    Color3.new(1,1,1), Color3.new(1,0,0), Color3.new(0,1,0),
    Color3.new(0,0,1), Color3.new(1,1,0), Color3.new(1,0,1),
    Color3.new(0,1,1)
}
local boxColorNames = {"White","Red","Green","Blue","Yellow","Pink","Cyan"}
local tracerLines = {}

local aimEnabled = true
local aimKey = Enum.UserInputType.MouseButton2
local aimPart = "Head"
local fovSize = 150
local fovColor = Color3.new(1,0,0)
local centerFovEnabled = true

local silentAimDistance = 1000

local smoothness = 0.3
local aimModePC = "Camera"
local predEnabled = true
local predStrength = 0.135
local triggerbotEnabled = false
local wallCheckEnabled = true
local triggerCooldown = 0.05
local lastTriggerTime = 0
local isBoltAction = true
local isHoldingTrigger = false

local hitboxEnabled = false
local hitboxMultiplier = 2.0
local originalSizes = setmetatable({}, {__mode = "k"})

local antiAfkEnabled = false
local antiAfkConnection = nil

local noParticlesEnabled = false
local particleConnection = nil

local fullBrightEnabled = false
local fullBrightConnection = nil

local scriptUnloaded = false

local configFileName = "NMZ_Config.json"
local HttpService = cloneref(game:GetService("HttpService"))

local function SaveConfig()
    local config = {
        espEnabled = espEnabled,
        espHighlightEnabled = espHighlightEnabled,
        espBoxEnabled = espBoxEnabled,
        espTracerEnabled = espTracerEnabled,
        boxColorIndex = boxColorIndex,
        aimEnabled = aimEnabled,
        aimPart = aimPart,
        fovSize = fovSize,
        centerFovEnabled = centerFovEnabled,
        aimModePC = aimModePC,
        smoothness = smoothness,
        silentAimDistance = silentAimDistance,
        predEnabled = predEnabled,
        predStrength = predStrength,
        triggerbotEnabled = triggerbotEnabled,
        wallCheckEnabled = wallCheckEnabled,
        hitboxEnabled = hitboxEnabled,
        hitboxMultiplier = hitboxMultiplier,
        antiAfkEnabled = antiAfkEnabled,
        noParticlesEnabled = noParticlesEnabled,
        silentAimEnabled = silentAimEnabled,
        noRecoilEnabled = noRecoilEnabled,
        noSpreadEnabled = noSpreadEnabled,
        fastBoltEnabled = fastBoltEnabled,
        silentReloadEnabled = silentReloadEnabled,
        fullBrightEnabled = fullBrightEnabled
    }
    if writefile then
        pcall(function()
            writefile(configFileName, HttpService:JSONEncode(config))
        end)
    end
end

local function LoadConfig()
    if isfile and readfile and isfile(configFileName) then
        pcall(function()
            local decoded = HttpService:JSONDecode(readfile(configFileName))
            if decoded then
                if decoded.espEnabled ~= nil then espEnabled = decoded.espEnabled end
                if decoded.espHighlightEnabled ~= nil then espHighlightEnabled = decoded.espHighlightEnabled end
                if decoded.espBoxEnabled ~= nil then espBoxEnabled = decoded.espBoxEnabled end
                if decoded.espTracerEnabled ~= nil then espTracerEnabled = decoded.espTracerEnabled end
                if decoded.boxColorIndex ~= nil then boxColorIndex = decoded.boxColorIndex end
                if decoded.aimEnabled ~= nil then aimEnabled = decoded.aimEnabled end
                if decoded.aimPart ~= nil then aimPart = decoded.aimPart end
                if decoded.fovSize ~= nil then fovSize = decoded.fovSize end
                if decoded.centerFovEnabled ~= nil then centerFovEnabled = decoded.centerFovEnabled end
                if decoded.aimModePC ~= nil then aimModePC = decoded.aimModePC end
                if decoded.smoothness ~= nil then smoothness = decoded.smoothness end
                if decoded.silentAimDistance ~= nil then silentAimDistance = decoded.silentAimDistance end
                if decoded.predEnabled ~= nil then predEnabled = decoded.predEnabled end
                if decoded.predStrength ~= nil then predStrength = decoded.predStrength end
                if decoded.triggerbotEnabled ~= nil then triggerbotEnabled = decoded.triggerbotEnabled end
                if decoded.wallCheckEnabled ~= nil then wallCheckEnabled = decoded.wallCheckEnabled end
                if decoded.hitboxEnabled ~= nil then hitboxEnabled = decoded.hitboxEnabled end
                if decoded.hitboxMultiplier ~= nil then hitboxMultiplier = decoded.hitboxMultiplier end
                if decoded.antiAfkEnabled ~= nil then antiAfkEnabled = decoded.antiAfkEnabled end
                if decoded.noParticlesEnabled ~= nil then noParticlesEnabled = decoded.noParticlesEnabled end
                if decoded.silentAimEnabled ~= nil then silentAimEnabled = decoded.silentAimEnabled end
                if decoded.noRecoilEnabled ~= nil then noRecoilEnabled = decoded.noRecoilEnabled end
                if decoded.noSpreadEnabled ~= nil then noSpreadEnabled = decoded.noSpreadEnabled end
                if decoded.fastBoltEnabled ~= nil then fastBoltEnabled = decoded.fastBoltEnabled end
                if decoded.silentReloadEnabled ~= nil then silentReloadEnabled = decoded.silentReloadEnabled end
                if decoded.fullBrightEnabled ~= nil then fullBrightEnabled = decoded.fullBrightEnabled end
                
                boxColor = boxColors[boxColorIndex] or Color3.new(1,1,1)
            end
        end)
    end
end
LoadConfig()

local fovCircle = nil
local guiFov = nil
local fovFrame = nil

local function updateFOVCircle()
    if false then -- Force GUI fallback for executors with fake Drawing APIs
        if not fovCircle then
            local ok, res = pcall(function() return Drawing.new("Circle") end)
            if ok and res then 
                fovCircle = res 
                fovCircle.NumSides = 64
            else 
                Drawing = nil
                updateFOVCircle() 
                return 
            end
        end
        pcall(function() fovCircle.Radius = fovSize end)
        pcall(function() fovCircle.Thickness = 2 end)
        pcall(function() fovCircle.Color = fovColor end)
        pcall(function() fovCircle.Visible = aimEnabled end)
        pcall(function() fovCircle.Transparency = 1; fovCircle.Filled = false end)
    else
        if not guiFov then
            guiFov = Instance.new("ScreenGui")
            guiFov.Name = "NMZ_FOV"
            guiFov.ResetOnSpawn = false
            guiFov.IgnoreGuiInset = true
            local parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
            pcall(function() if gethui then parent = gethui() else parent = game:GetService("CoreGui") end end)
            if parent:FindFirstChild("NMZ_FOV") then parent.NMZ_FOV:Destroy() end
            guiFov.Parent = parent
            
            fovFrame = Instance.new("Frame")
            fovFrame.Parent = guiFov
            fovFrame.BackgroundTransparency = 1
            fovFrame.AnchorPoint = Vector2.new(0.5, 0.5)
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(1, 0)
            corner.Parent = fovFrame
            
            local stroke = Instance.new("UIStroke")
            stroke.Color = fovColor
            stroke.Thickness = 2
            stroke.Parent = fovFrame
        end
        fovFrame.Size = UDim2.new(0, fovSize * 2, 0, fovSize * 2)
        local str = fovFrame:FindFirstChildOfClass("UIStroke")
        if str then str.Color = fovColor end
        fovFrame.Visible = aimEnabled
    end
end
updateFOVCircle()

local predDot = nil
local guiPredDot = nil
local predDotFrame = nil
local function updatePredDot(pos)
    if false then -- Force GUI fallback
        if not predDot then
            predDot = Drawing.new("Circle")
            predDot.NumSides = 16
            predDot.Radius = 2.0
            predDot.Thickness = 0
            predDot.Filled = true
            predDot.Color = Color3.fromRGB(0, 255, 0)
        end
        if pos then
            local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
            if onScreen then
                predDot.Position = Vector2.new(screenPos.X, screenPos.Y)
                predDot.Visible = true
                return
            end
        end
        predDot.Visible = false
    else
        if not guiPredDot then
            guiPredDot = Instance.new("ScreenGui")
            guiPredDot.Name = "NMZ_PredDot"
            guiPredDot.ResetOnSpawn = false
            guiPredDot.IgnoreGuiInset = true
            local parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
            pcall(function() if gethui then parent = gethui() else parent = game:GetService("CoreGui") end end)
            if parent:FindFirstChild("NMZ_PredDot") then parent.NMZ_PredDot:Destroy() end
            guiPredDot.Parent = parent
            
            predDotFrame = Instance.new("Frame")
            predDotFrame.Parent = guiPredDot
            predDotFrame.Size = UDim2.new(0, 4, 0, 4)
            predDotFrame.AnchorPoint = Vector2.new(0.5, 0.5)
            predDotFrame.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            predDotFrame.BorderSizePixel = 0
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(1, 0)
            corner.Parent = predDotFrame
        end
        if pos then
            local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
            if onScreen then
                predDotFrame.Position = UDim2.new(0, screenPos.X, 0, screenPos.Y)
                predDotFrame.Visible = true
                return
            end
        end
        if predDotFrame then predDotFrame.Visible = false end
    end
end

-- Keywords for foliage / non-solid map props that should NOT block wallcheck LOS.
-- Many maps name these generically (MeshPart) so we also check ancestors + materials.
local PENETRABLE_KEYWORDS = {
    -- Foliage / plants (semak, daun, dll)
    "bush", "leaf", "leaves", "foliage", "plant", "plants", "hedge", "shrub",
    "grass", "weed", "weeds", "flower", "fern", "vine", "ivy", "moss", "reed",
    "branch", "branches", "palm", "pine", "bamboo", "cactus",
    "vegetation", "flora", "canopy", "underbrush", "thicket", "shrubbery",
    "garden", "treeleaf", "treetop", "treetops", "crown",
    -- Tree models often named Tree_01; trunk stays solid if named Trunk alone without these
    "tree", "trees",
    -- Spawn / non-solid volumes
    "spawn", "spawns", "respawn", "lobby", "safezone", "safe_zone", "safearea",
    "trigger", "sensor", "checkpoint", "killbrick", "invisible", "nocollide", "nocol",
    -- Light decor / see-through
    "sign", "signs", "billboard", "banner", "flag", "cloth", "curtain",
    "water", "pond", "lake", "river", "waterfall", "puddle",
    "glass", "window", "chainlink", "smoke", "fog", "cloud", "mist",
    "particle", "effect", "fx", "beam", "decal", "scenery", "clutter",
}

local function nameLooksPenetrable(str)
    if not str or str == "" then return false end
    local lower = string.lower(str)
    for i = 1, #PENETRABLE_KEYWORDS do
        if string.find(lower, PENETRABLE_KEYWORDS[i], 1, true) then
            return true
        end
    end
    return false
end

local function isPenetratablePart(part, hitMaterial)
    if not part then return true end

    -- Terrain always blocks LOS (water already skipped via IgnoreWater)
    if part:IsA("Terrain") then
        return false
    end

    if not part:IsA("BasePart") then
        return true
    end

    local ok, result = pcall(function()
        -- Walk-through parts: always ignore for LOS (even if ray still hits them)
        if part.CanCollide == false then
            return true
        end

        -- CanQuery false should not be hit, but some executors/engines differ
        if part.CanQuery == false then
            return true
        end

        -- If the local player physically does not collide with this part (collision groups),
        -- it is not solid cover — e.g. foliage/spawn volumes you can walk through.
        local myChar = LocalPlayer.Character
        local myRoot = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChild("Torso") or myChar:FindFirstChild("UpperTorso"))
        if myRoot then
            local collidable = true
            local cgOk = pcall(function()
                local PhysicsService = game:GetService("PhysicsService")
                collidable = PhysicsService:CollisionGroupsAreCollidable(myRoot.CollisionGroup, part.CollisionGroup)
            end)
            if cgOk and collidable == false then
                return true
            end
        end

        -- Semi / fully transparent props (bushes, glass planes, spawn volumes)
        if (part.Transparency or 0) >= 0.45 then
            return true
        end

        -- Materials that are visually non-solid or see-through
        local mat = part.Material
        local softMats = {
            [Enum.Material.Leaves] = true,
            [Enum.Material.Grass] = true,
            [Enum.Material.Fabric] = true,
            [Enum.Material.ForceField] = true,
            [Enum.Material.Glass] = true,
            [Enum.Material.Foil] = true,
        }
        -- LeafyGrass may not exist on older clients
        pcall(function()
            softMats[Enum.Material.LeafyGrass] = true
        end)
        if softMats[mat] then
            return true
        end

        -- Collision groups used so players pass through foliage while CanCollide stays true
        local cg = part.CollisionGroup
        if type(cg) == "string" and cg ~= "" and cg ~= "Default" then
            local cgLower = string.lower(cg)
            if string.find(cgLower, "foliage", 1, true)
                or string.find(cgLower, "decor", 1, true)
                or string.find(cgLower, "debris", 1, true)
                or string.find(cgLower, "nocollide", 1, true)
                or string.find(cgLower, "nocol", 1, true)
                or string.find(cgLower, "passthrough", 1, true)
                or string.find(cgLower, "transparent", 1, true)
                or string.find(cgLower, "ghost", 1, true)
                or string.find(cgLower, "prop", 1, true)
                or string.find(cgLower, "plant", 1, true)
                or string.find(cgLower, "bush", 1, true)
                or string.find(cgLower, "tree", 1, true)
                or string.find(cgLower, "spawn", 1, true)
                or string.find(cgLower, "effect", 1, true) then
                return true
            end
        end

        -- Name on part
        if nameLooksPenetrable(part.Name) then
            return true
        end

        -- Ancestors: folders/models like "Bushes", "Foliage", "MapDecor", "Spawns"
        local parent = part.Parent
        local depth = 0
        while parent and parent ~= workspace and depth < 8 do
            if nameLooksPenetrable(parent.Name) then
                return true
            end
            parent = parent.Parent
            depth = depth + 1
        end

        -- Thin billboard-style foliage planes (large + very thin) — not thick walls
        local size = part.Size
        local sx, sy, sz = size.X, size.Y, size.Z
        local minDim = math.min(sx, sy, sz)
        local maxDim = math.max(sx, sy, sz)
        local midDim = sx + sy + sz - minDim - maxDim
        if minDim <= 0.35 and midDim >= 1.0 and maxDim >= 1.5 then
            return true
        end

        -- Massless + any transparency: common for walk-through spawn volumes / effects
        if part.Massless and (part.Transparency or 0) > 0 then
            return true
        end

        return false
    end)

    if ok then
        return result == true
    end
    -- If inspection failed, treat as solid (safer than shooting through real walls)
    return false
end

local function getPenetrableIgnoreTarget(part)
    if not part then return part end

    -- Prefer nearest named foliage folder/model only (never wipe whole map containers)
    local inst = part.Parent
    local depth = 0
    while inst and inst ~= workspace and depth < 6 do
        if nameLooksPenetrable(inst.Name) then
            local isPlayer = false
            pcall(function()
                if inst:IsA("Model") then
                    isPlayer = Players:GetPlayerFromCharacter(inst) ~= nil
                end
            end)
            if not isPlayer then
                return inst
            end
        end
        inst = inst.Parent
        depth = depth + 1
    end

    -- Generic multi-mesh bush: only collapse immediate Model if it is small and not a character
    local model = part.Parent
    if model and model:IsA("Model") and model ~= workspace then
        local isPlayer = false
        pcall(function()
            isPlayer = Players:GetPlayerFromCharacter(model) ~= nil
        end)
        if not isPlayer and not model:FindFirstChildOfClass("Humanoid") then
            local parts = 0
            local onlyFoliageLike = true
            pcall(function()
                for _, d in ipairs(model:GetChildren()) do
                    if d:IsA("BasePart") then
                        parts = parts + 1
                        -- If siblings look like solid structure, don't ignore whole model
                        if d.CanCollide and d.Transparency < 0.45 and d.Material ~= Enum.Material.Leaves
                            and d.Material ~= Enum.Material.Grass and d.Material ~= Enum.Material.Glass
                            and d.Material ~= Enum.Material.Fabric and not nameLooksPenetrable(d.Name) then
                            local sz = d.Size
                            local minD = math.min(sz.X, sz.Y, sz.Z)
                            if minD > 0.5 then
                                onlyFoliageLike = false
                            end
                        end
                        if parts > 25 then break end
                    end
                end
            end)
            if onlyFoliageLike and parts >= 2 and parts <= 25 then
                return model
            end
        end
    end

    return part
end

local function smartRaycast(origin, direction, ignoreListArray)
    local ignoreList = {}
    if ignoreListArray then
        for _, v in pairs(ignoreListArray) do
            table.insert(ignoreList, v)
        end
    end
    -- Dense foliage maps need more multi-hit iterations
    local maxCasts = 40

    for _ = 1, maxCasts do
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        rayParams.FilterDescendantsInstances = ignoreList
        rayParams.IgnoreWater = true

        local hit = workspace:Raycast(origin, direction, rayParams)
        if not hit then
            return nil
        end

        local part = hit.Instance
        local penetrable = isPenetratablePart(part, hit.Material)

        if penetrable then
            local ignoreTarget = getPenetrableIgnoreTarget(part)
            table.insert(ignoreList, ignoreTarget)
            -- Also always exclude the exact hit instance (in case ignoreTarget is a distant ancestor miss)
            if ignoreTarget ~= part then
                table.insert(ignoreList, part)
            end
        else
            return hit
        end
    end
    -- Exhausted casts through non-solid clutter: treat as clear LOS
    return nil
end

local function isPointVisible(pos, char)
    local myChar = LocalPlayer.Character
    if not myChar then return false end
    
    local origin = Camera.CFrame.Position
    local direction = pos - origin
    
    local hit = smartRaycast(origin, direction, {myChar, char, Camera})
    
    if hit then
        return false
    end
    return true
end

local function getBestTargetPos(char)
    if not char then return nil end
    local head = char:FindFirstChild("Head")
    local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart")
    
    if not wallCheckEnabled then
        if aimPart == "Head" and head then
            return head.Position
        elseif torso then
            return torso.Position
        elseif head then
            return head.Position
        end
        return nil
    end
    
    if head and isPointVisible(head.Position, char) then
        return head.Position
    end
    
    if head then
        local headTop = head.Position + Vector3.new(0, head.Size.Y * 0.38, 0)
        if isPointVisible(headTop, char) then
            return headTop
        end
    end
    
    if torso and isPointVisible(torso.Position, char) then
        return torso.Position
    end
    
    return nil
end

local function isTargetVisible(target, targetPos)
    if not wallCheckEnabled then return true end
    if not target or not targetPos then return false end
    local char = target.Parent
    if not char then return false end
    return isPointVisible(targetPos, char)
end

local boxLines = {}
local function removeAllHighlights()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr.Character then
            local hl = plr.Character:FindFirstChildOfClass("Highlight")
            if hl then hl:Destroy() end
        end
    end
end
local function removeAllBoxes()
    for plr, lines in pairs(boxLines) do
        for _, line in pairs(lines) do line:Remove() end
    end
    boxLines = {}
end
local function removeAllTracers()
    for plr, line in pairs(tracerLines) do
        line:Remove()
    end
    tracerLines = {}
end
local function createHighlightForPlayer(plr)
    if plr == LocalPlayer then return end
    if not plr.Character then return end
    local old = plr.Character:FindFirstChildOfClass("Highlight")
    if old then old:Destroy() end
    local hl = Instance.new("Highlight")
    hl.Parent = plr.Character
    hl.FillTransparency = 0.6
    hl.OutlineTransparency = 0.2
    if plr.Team == LocalPlayer.Team then
        hl.FillColor = Color3.fromRGB(0,100,255)
        hl.OutlineColor = Color3.fromRGB(0,200,255)
    else
        hl.FillColor = Color3.fromRGB(255,50,50)
        hl.OutlineColor = Color3.fromRGB(255,150,150)
    end
end
local function createBoxLinesForPlayer(plr)
    if boxLines[plr] then return end
    if type(Drawing) == "table" and type(Drawing.new) == "function" then
        local lines = {}
        for i = 1, 4 do
            local success, line = pcall(Drawing.new, "Line")
            if success and line then
                line.Thickness = 2
                line.Color = boxColor
                line.Visible = false
                table.insert(lines, line)
            end
        end
        if #lines == 4 then
            boxLines[plr] = lines
        end
    end
end
local function createTracerLineForPlayer(plr)
    if tracerLines[plr] then return end
    if type(Drawing) == "table" and type(Drawing.new) == "function" then
        local success, line = pcall(Drawing.new, "Line")
        if success and line then
            line.Thickness = 1.5
            line.Color = boxColor
            line.Visible = false
            tracerLines[plr] = line
        end
    end
end

-- ESP
local function updateESP()
    if not espEnabled then
        for _, lines in pairs(boxLines) do
            for _, line in pairs(lines) do line.Visible = false end
        end
        for _, line in pairs(tracerLines) do
            line.Visible = false
        end
        return
    end
    for _, plr in pairs(Players:GetPlayers()) do
        local isEnemy = plr ~= LocalPlayer and (not LocalPlayer.Team or plr.Team ~= LocalPlayer.Team)
        if isEnemy and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("Head") then
            local root = plr.Character.HumanoidRootPart
            local head = plr.Character.Head
            local rPos, rVis = Camera:WorldToViewportPoint(root.Position)
            local hPos, hVis = Camera:WorldToViewportPoint(head.Position)
            if espBoxEnabled and rVis and hVis then
                createBoxLinesForPlayer(plr)
                local lines = boxLines[plr]
                if lines then
                    local height = math.abs(hPos.Y - rPos.Y) * 2.2
                    local width = height * 0.7
                    local cx = rPos.X
                    local cy = (hPos.Y + rPos.Y)/2
                    local left = cx - width/2
                    local right = cx + width/2
                    local top = cy - height/2
                    local bottom = cy + height/2
                    lines[1].From = Vector2.new(left, top); lines[1].To = Vector2.new(right, top)
                    lines[2].From = Vector2.new(right, top); lines[2].To = Vector2.new(right, bottom)
                    lines[3].From = Vector2.new(right, bottom); lines[3].To = Vector2.new(left, bottom)
                    lines[4].From = Vector2.new(left, bottom); lines[4].To = Vector2.new(left, top)
                    for _, line in pairs(lines) do line.Color = boxColor; line.Visible = true end
                end
            else
                if boxLines[plr] then for _, line in pairs(boxLines[plr]) do line.Visible = false end end
            end
            if espTracerEnabled and rVis then
                createTracerLineForPlayer(plr)
                local line = tracerLines[plr]
                if line then
                    line.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                    line.To = Vector2.new(rPos.X, rPos.Y)
                    line.Color = boxColor
                    line.Visible = true
                end
            else
                if tracerLines[plr] then tracerLines[plr].Visible = false end
            end
        else
            if boxLines[plr] then for _, line in pairs(boxLines[plr]) do line.Visible = false end end
            if tracerLines[plr] then tracerLines[plr].Visible = false end
        end
    end
end
local function refreshESP()
    if not espEnabled then
        removeAllHighlights()
        removeAllBoxes()
        removeAllTracers()
        return
    end
    if espHighlightEnabled then
        for _, plr in pairs(Players:GetPlayers()) do
            createHighlightForPlayer(plr)
        end
    else
        removeAllHighlights()
    end
    if not espBoxEnabled then
        removeAllBoxes()
    end
    if not espTracerEnabled then
        removeAllTracers()
    end
end

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(0.5)
        if espEnabled and espHighlightEnabled then
            createHighlightForPlayer(plr)
        end
    end)
end)
Players.PlayerRemoving:Connect(function(plr)
    if boxLines[plr] then
        for _, line in pairs(boxLines[plr]) do line:Remove() end
        boxLines[plr] = nil
    end
    if tracerLines[plr] then
        tracerLines[plr]:Remove()
        tracerLines[plr] = nil
    end
end)
for _, plr in pairs(Players:GetPlayers()) do
    plr.CharacterAdded:Connect(function()
        task.wait(0.5)
        if espEnabled and espHighlightEnabled then
            createHighlightForPlayer(plr)
        end
    end)
end
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if espEnabled and espHighlightEnabled then
        for _, plr in pairs(Players:GetPlayers()) do
            createHighlightForPlayer(plr)
        end
    end
end)

local function getClosestEnemy()
    local center
    if centerFovEnabled then
        center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    else
        local mousePos = UserInputService:GetMouseLocation()
        center = Vector2.new(mousePos.X, mousePos.Y)
    end
    local closest = nil
    local closestDist = fovSize
    local bestPos = nil
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 and (not LocalPlayer.Team or plr.Team ~= LocalPlayer.Team) then
                local char = plr.Character
                local part = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
                if part then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local dist = (center - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                        if dist < closestDist then
                            local targetPos = getBestTargetPos(char)
                            if targetPos then
                                closestDist = dist
                                closest = part
                                bestPos = targetPos
                            end
                        end
                    end
                end
            end
        end
    end
    return closest, bestPos
end

local silentCachedPart, silentCachedPos = nil, nil

local function getClosestSilentEnemy()
    local cam = workspace.CurrentCamera or Camera
    if not cam then return nil, nil end
    local center
    if centerFovEnabled then
        center = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
    else
        local mousePos = UserInputService:GetMouseLocation()
        center = Vector2.new(mousePos.X, mousePos.Y)
    end
    local closest = nil
    local closestDist = fovSize
    local bestPos = nil
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myPos = myRoot and myRoot.Position
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 and (not LocalPlayer.Team or plr.Team ~= LocalPlayer.Team) then
                local char = plr.Character
                local part = char:FindFirstChild(aimPart)
                    or char:FindFirstChild("Head")
                    or char:FindFirstChild("HumanoidRootPart")
                if part then
                    local physicalDist = myPos and (part.Position - myPos).Magnitude or 0
                    if physicalDist <= silentAimDistance then
                        local screenPos, onScreen = cam:WorldToViewportPoint(part.Position)
                        if onScreen and screenPos.Z > 0 then
                            local dist = (center - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                            if dist < closestDist then
                                -- Prefer wall-checked bone; still lock if blocked (silent = through cover OK)
                                local targetPos = getBestTargetPos(char)
                                if not targetPos then
                                    if aimPart == "Head" and char:FindFirstChild("Head") then
                                        targetPos = char.Head.Position
                                    else
                                        local torso = char:FindFirstChild("Torso")
                                            or char:FindFirstChild("UpperTorso")
                                            or char:FindFirstChild("HumanoidRootPart")
                                        targetPos = (torso and torso.Position) or part.Position
                                    end
                                end
                                closestDist = dist
                                closest = part
                                bestPos = targetPos
                            end
                        end
                    end
                end
            end
        end
    end
    return closest, bestPos
end

local function computeSilentAimPos()
    local part, pos = getClosestSilentEnemy()
    if not part then
        silentCachedPart, silentCachedPos = nil, nil
        return nil, nil
    end
    local aimPos = pos or part.Position
    if predEnabled then
        local tool, vel = resolveGunContext()
        local originPart = LocalPlayer.Character
            and (LocalPlayer.Character:FindFirstChild("Head") or LocalPlayer.Character:FindFirstChild("HumanoidRootPart"))
        local tVel = part.AssemblyLinearVelocity or part.Velocity or Vector3.zero
        if originPart and vel and vel > 1 then
            local r = aimPos - originPart.Position
            local vVec = tVel - (originPart.AssemblyLinearVelocity or originPart.Velocity or Vector3.zero)
            local a = vVec:Dot(vVec) - (vel * vel)
            local b = 2 * r:Dot(vVec)
            local c0 = r:Dot(r)
            local disc = b * b - 4 * a * c0
            if disc >= 0 and math.abs(a) > 1e-6 then
                local sqrtDisc = math.sqrt(disc)
                local t1 = (-b - sqrtDisc) / (2 * a)
                local t2 = (-b + sqrtDisc) / (2 * a)
                local tVal
                if t1 > 0 and t2 > 0 then tVal = math.min(t1, t2)
                elseif t1 > 0 then tVal = t1
                elseif t2 > 0 then tVal = t2 end
                if tVal then
                    aimPos = aimPos + tVel * tVal + Vector3.new(0, 0.5 * workspace.Gravity * tVal * tVal, 0)
                end
            else
                aimPos = aimPos + tVel * predStrength
            end
        else
            aimPos = aimPos + tVel * predStrength
        end
    end
    silentCachedPart, silentCachedPos = part, aimPos
    return aimPos, part
end

-- Keep silent target warm so hooks only read cache (no heavy work mid-fire)
do
    local frame = 0
    RunService.Heartbeat:Connect(function()
        if scriptUnloadedLocal or not silentAimEnabled then
            if not silentAimEnabled then silentCachedPart, silentCachedPos = nil, nil end
            return
        end
        frame = frame + 1
        if frame >= 2 then
            frame = 0
            pcall(computeSilentAimPos)
        end
    end)
end

local function cameraAim(target, targetPos)
    if not target or not targetPos then return end
    local currentCF = Camera.CFrame
    local pos = targetPos
    if predEnabled then
        local vel = target.AssemblyLinearVelocity or target.Velocity
        if vel then
            pos = pos + (vel * predStrength)
        end
    end
    local targetCF = CFrame.new(currentCF.Position, pos)
    if smoothness > 0 and smoothness < 1 then
        Camera.CFrame = currentCF:Lerp(targetCF, smoothness)
    else
        Camera.CFrame = targetCF
    end
end

local function mouseAim(target, targetPos)
    if not target or not targetPos then return end
    local pos = targetPos
    if predEnabled then
        local vel = target.AssemblyLinearVelocity or target.Velocity
        if vel then
            pos = pos + (vel * predStrength)
        end
    end
    local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
    if onScreen then
        local deltaX = (screenPos.X - Mouse.X) * smoothness
        local deltaY = (screenPos.Y - Mouse.Y) * smoothness
        pcall(function() cloneref(game:GetService("VirtualInputManager")):SendMouseMovement(deltaX, deltaY, nil) end)
        pcall(function() mousemoverel(deltaX, deltaY) end)
    end
end

local function fireClick()
    task.spawn(function()
        pcall(mouse1click)
        pcall(function()
            mouse1press()
            task.wait(0.01)
            mouse1release()
        end)
        pcall(function()
            local vim = cloneref(game:GetService("VirtualInputManager"))
            local pos = UserInputService:GetMouseLocation()
            vim:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
            task.wait(0.035) -- Slightly longer hold to ensure the game registers the click
            vim:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
        end)
    end)
end
RunService.RenderStepped:Connect(function()
    if scriptUnloaded then return end

    if fovCircle and fovCircle.Visible then
        local pos
        if centerFovEnabled then
            pos = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        else
            local mousePos = UserInputService:GetMouseLocation()
            pos = Vector2.new(mousePos.X, mousePos.Y)
        end
        pcall(function() fovCircle.Position = pos end)
    elseif fovFrame and fovFrame.Visible then
        local pos
        if centerFovEnabled then
            pos = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        else
            local mousePos = UserInputService:GetMouseLocation()
            pos = Vector2.new(mousePos.X, mousePos.Y)
        end
        fovFrame.Position = UDim2.new(0, pos.X, 0, pos.Y)
    end

    updateESP()
    if not aimEnabled and not triggerbotEnabled then 
        updatePredDot(nil)
        return 
    end

    if triggerbotEnabled then
        local mousePos = UserInputService:GetMouseLocation()
        local ray = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)
        local ignore = {Camera}
        if LocalPlayer.Character then table.insert(ignore, LocalPlayer.Character) end
        local hit = smartRaycast(ray.Origin, ray.Direction * 1500, ignore)
        
        local targetInCrosshair = false
        if hit and hit.Instance then
            local model = hit.Instance:FindFirstAncestorOfClass("Model")
            if model then
                local plr = Players:GetPlayerFromCharacter(model)
                if plr and plr ~= LocalPlayer and plr.Team ~= LocalPlayer.Team then
                    local humanoid = model:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        targetInCrosshair = true
                    end
                end
            end
        end

        if isBoltAction then
            if targetInCrosshair and tick() - lastTriggerTime > triggerCooldown then
                lastTriggerTime = tick()
                fireClick()
            end
        else
            if targetInCrosshair then
                if not isHoldingTrigger then
                    isHoldingTrigger = true
                    pcall(function()
                        cloneref(game:GetService("VirtualInputManager")):SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, true, game, 1)
                    end)
                end
            else
                if isHoldingTrigger then
                    isHoldingTrigger = false
                    pcall(function()
                        cloneref(game:GetService("VirtualInputManager")):SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, false, game, 1)
                    end)
                end
            end
        end
    elseif isHoldingTrigger then
        isHoldingTrigger = false
        pcall(function()
            local mousePos = UserInputService:GetMouseLocation()
            cloneref(game:GetService("VirtualInputManager")):SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, false, game, 1)
        end)
    end

    local keyPressed = false
    if isMobile then
        keyPressed = mobileAimHolding
    elseif aimKey.EnumType == Enum.UserInputType then
        keyPressed = UserInputService:IsMouseButtonPressed(aimKey)
    else
        keyPressed = UserInputService:IsKeyDown(aimKey)
    end
    local target, targetPos = getClosestEnemy()
    if target and targetPos then
        local pos = targetPos
        if predEnabled then
            local vel = target.AssemblyLinearVelocity or target.Velocity
            if vel then
                pos = pos + (vel * predStrength)
            end
        end
        local isVis = isTargetVisible(target, targetPos)
        if isVis then
            if aimEnabled then updatePredDot(pos) else updatePredDot(nil) end
            if aimEnabled and keyPressed then
                if aimModePC == "Camera" then cameraAim(target, targetPos) else mouseAim(target, targetPos) end
            end
        else
            updatePredDot(nil)
        end
    else
        updatePredDot(nil)
    end
end)

local function applyHitboxToCharacter(character)
    if not character then return end
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            if not originalSizes[part] then originalSizes[part] = part.Size end
            part.Size = originalSizes[part] * hitboxMultiplier
        end
    end
end
local function restoreHitboxForCharacter(character)
    if not character then return end
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") and originalSizes[part] then
            part.Size = originalSizes[part]
            originalSizes[part] = nil
        end
    end
end
local function applyHitboxToAll()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then applyHitboxToCharacter(plr.Character) end
    end
end
local function restoreAllHitboxes()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then restoreHitboxForCharacter(plr.Character) end
    end
    originalSizes = {}
end
local function onCharacterAdded(char)
    task.wait(0.5)
    if hitboxEnabled and char then applyHitboxToCharacter(char) end
end
Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(onCharacterAdded)
    if plr.Character then onCharacterAdded(plr.Character) end
end)
for _, plr in pairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer and plr.Character then plr.CharacterAdded:Connect(onCharacterAdded) end
end

local function toggleAntiAfk()
    if antiAfkEnabled then
        if not antiAfkConnection then
            antiAfkConnection = LocalPlayer.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
    else
        if antiAfkConnection then antiAfkConnection:Disconnect(); antiAfkConnection = nil end
    end
end

updateFOVCircle()

local scriptId = "NMZ_ENTRENCHED_UI"
local getGenv = getgenv or function() return _G end

if getGenv()[scriptId] then
    pcall(getGenv()[scriptId])
end

local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Hplayfree25/luaLibrary/refs/heads/master/Init.lua?t=" .. tick()))()

-- ponytail: window sized to viewport; mobile uses scale so it fits small screens,
-- PC keeps fixed offsets. Upgrade: clamp to a min absolute size if very large tablets appear.
local winSize = UDim2.new(0, 500, 0, 320)
if isMobile then
    local vp = Camera.ViewportSize
    local w = math.min(vp.X - 24, 460)
    local h = math.min(vp.Y - 80, 520)
    winSize = UDim2.new(0, w, 0, h)
end

local Window = UI.CreateWindow({
    Title = "NMZ Hub",
    ToggleText = "NMZ",
    Size = winSize,
    Keybind = Enum.KeyCode.LeftAlt,
    HideOnStartup = true
})

task.spawn(function()
    task.wait(1)
    if isMobile then
        UI.Notify({
            Title = "UI Loaded",
            Content = "Tap the 'NMZ' button to open the menu. Hold the floating AIM button to aim.",
            Duration = 7
        })
    else
        UI.Notify({
            Title = "UI Loaded",
            Content = "Press 'Left Alt' on your keyboard to open or close the menu.",
            Duration = 7
        })
    end
end)

-- Mobile floating AIM button (hold-to-aim, draggable). PC skips this; right-click still works.
if isMobile then
    mobileAimGui = Instance.new("ScreenGui")
    mobileAimGui.Name = "NMZ_MobileAim"
    mobileAimGui.ResetOnSpawn = false
    mobileAimGui.IgnoreGuiInset = true
    mobileAimGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() if gethui then mobileAimGui.Parent = gethui() else mobileAimGui.Parent = game:GetService("CoreGui") end end)
    if mobileAimGui.Parent == nil then
        mobileAimGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    mobileAimBtn = Instance.new("TextButton")
    mobileAimBtn.Size = UDim2.new(0, 64, 0, 64)
    mobileAimBtn.Position = UDim2.new(0, 24, 0.5, -32)
    mobileAimBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
    mobileAimBtn.BackgroundTransparency = 0.15
    mobileAimBtn.Text = "AIM"
    mobileAimBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    mobileAimBtn.Font = Enum.Font.GothamBold
    mobileAimBtn.TextSize = 16
    mobileAimBtn.AutoButtonColor = false
    mobileAimBtn.Active = true
    mobileAimBtn.Parent = mobileAimGui

    local aimCorner = Instance.new("UICorner")
    aimCorner.CornerRadius = UDim.new(1, 0)
    aimCorner.Parent = mobileAimBtn

    local aimStroke = Instance.new("UIStroke")
    aimStroke.Color = Color3.fromRGB(70, 130, 200)
    aimStroke.Thickness = 2
    aimStroke.Transparency = 0.2
    aimStroke.Parent = mobileAimBtn

    -- Hold-to-aim (finger down = aim on, up = off) + draggable to reposition.
    -- Aim stays active even while dragging — dragging just moves the button.
    local dragging = false
    local dragStart = nil
    local startPos = nil

    local function pressAim()
        mobileAimHolding = true
        TweenService:Create(mobileAimBtn, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {
            BackgroundColor3 = Color3.fromRGB(70, 130, 200),
            TextColor3 = Color3.fromRGB(0, 0, 0)
        }):Play()
    end
    local function releaseAim()
        mobileAimHolding = false
        TweenService:Create(mobileAimBtn, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {
            BackgroundColor3 = Color3.fromRGB(20, 20, 24),
            TextColor3 = Color3.fromRGB(255, 255, 255)
        }):Play()
    end

    mobileAimBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mobileAimBtn.Position
            pressAim()
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - dragStart
            mobileAimBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) then
            dragging = false
            releaseAim()
        end
    end)
end

getGenv()[scriptId] = function()
    scriptUnloaded = true
    scriptUnloadedLocal = true
    if Window then Window.destroy() end
    if fovCircle then fovCircle:Remove() fovCircle = nil end
    if predDot then predDot:Remove() predDot = nil end
    if guiFov then pcall(function() guiFov:Destroy() end) guiFov = nil end
    if guiPredDot then pcall(function() guiPredDot:Destroy() end) guiPredDot = nil end
    if mobileAimGui then pcall(function() mobileAimGui:Destroy() end) mobileAimGui = nil; mobileAimBtn = nil end
    removeAllHighlights()
    removeAllBoxes()
    removeAllTracers()
    restoreAllHitboxes()
    if antiAfkConnection then antiAfkConnection:Disconnect(); antiAfkConnection = nil end
    if particleConnection then particleConnection:Disconnect(); particleConnection = nil end
    if fullBrightConnection then fullBrightConnection:Disconnect(); fullBrightConnection = nil end
    stopSoftGunSupport()
    if recoilThread then coroutine.close(recoilThread); recoilThread = nil end
    if reloadConn then reloadConn:Disconnect(); reloadConn = nil end
    if success and wm and type(wm) == "table" and getgenv().NMZ_Originals then
        if getgenv().NMZ_Originals.Equip then rawset(wm, "Equip", getgenv().NMZ_Originals.Equip) end
        if getgenv().NMZ_Originals.Cycle then rawset(wm, "Cycle", getgenv().NMZ_Originals.Cycle) end
        if getgenv().NMZ_Originals.boltCycleAction then rawset(wm, "boltCycleAction", getgenv().NMZ_Originals.boltCycleAction) end
        if getgenv().NMZ_Originals.Reload then rawset(wm, "Reload", getgenv().NMZ_Originals.Reload) end
        if getgenv().NMZ_Originals.Shoot then rawset(wm, "Shoot", getgenv().NMZ_Originals.Shoot) end
        local inner = getgenv().NMZ_Originals.InnerShoot
        if inner and inner.Func then
            if inner.Method == "upvalue" and inner.Owner and inner.Key and debug.setupvalue then
                pcall(debug.setupvalue, inner.Owner, inner.Key, inner.Func)
            elseif inner.Method == "env" and inner.Env and inner.Key then
                pcall(rawset, inner.Env, inner.Key, inner.Func)
            elseif type(hookfunction) == "function" then
                pcall(function()
                    if inner.Live then
                        hookfunction(inner.Live, inner.Func)
                    end
                end)
            end
        end
        -- meta hooks stay installed but silentAimEnabled is forced off above
        getgenv().NMZ_Originals.MetaSilent = nil
        getgenv().NMZ_Originals.InnerShoot = nil
    end
    silentAimEnabled = false
    silentHookInstalled = false
    silentCachedPart, silentCachedPos = nil, nil
    getGenv()[scriptId] = nil
end

local TabESP = UI.CreateTab(Window, "ESP", 1)
local TabAim = UI.CreateTab(Window, "AIMBOT", 2)
local TabSilent = UI.CreateTab(Window, "SILENT AIM", 3)
local TabGun = UI.CreateTab(Window, "GUN MODS", 4)
local TabHitbox = UI.CreateTab(Window, "HITBOX", 5)
local TabVisuals = UI.CreateTab(Window, "VISUALS", 6)
local TabMisc = UI.CreateTab(Window, "MISC", 7)

UI.CreateToggle(TabESP, "ESP Toggle", espEnabled, function(Value)
    espEnabled = Value
    refreshESP()
end)
UI.CreateToggle(TabESP, "ESP Highlight", espHighlightEnabled, function(Value)
    espHighlightEnabled = Value
    refreshESP()
end)
UI.CreateToggle(TabESP, "ESP Box", espBoxEnabled, function(Value)
    espBoxEnabled = Value
    refreshESP()
end)
UI.CreateToggle(TabESP, "ESP Tracer", espTracerEnabled, function(Value)
    espTracerEnabled = Value
    refreshESP()
end)

local colOpts = {}
for i, name in ipairs(boxColorNames) do table.insert(colOpts, {name=name, val=name}) end
UI.CreateDropdown(TabESP, "ESP Color", colOpts, 1, function(Option)
    for i, n in ipairs(boxColorNames) do
        if n == Option then
            boxColorIndex = i
            boxColor = boxColors[i]
            for plr, lines in pairs(boxLines) do for _, l in pairs(lines) do l.Color = boxColor end end
            for plr, l in pairs(tracerLines) do l.Color = boxColor end
            break
        end
    end
end)

UI.CreateToggle(TabAim, "Aimbot Toggle", aimEnabled, function(Value)
    aimEnabled = Value
    updateFOVCircle()
end)
UI.CreateDropdown(TabAim, "Target Part", {{name="Head",val="Head"},{name="HumanoidRootPart",val="HumanoidRootPart"}}, 1, function(Option)
    aimPart = Option
end)
UI.CreateDropdown(TabAim, "Aim Mode", {{name="Camera",val="Camera"},{name="Mouse",val="Mouse"}}, 1, function(Option)
    aimModePC = Option
end)
UI.CreateSlider(TabAim, "Smoothness", 0.1, 1, smoothness, function(v) return string.format("%.2f", v) end, function(Value)
    smoothness = Value
end)
UI.CreateSlider(TabAim, "FOV Size", 50, 500, fovSize, function(v) return tostring(math.floor(v)) end, function(Value)
    fovSize = Value
    updateFOVCircle()
end)
UI.CreateToggle(TabAim, "Center FOV", centerFovEnabled, function(Value)
    centerFovEnabled = Value
end)

UI.CreateLabel(TabSilent, "Silent Aim: multi-hook (WeaponModule + Mouse.Hit + Raycast). FOV shared with Aimbot.")
UI.CreateToggle(TabSilent, "Silent Aim Toggle", silentAimEnabled, function(Value)
    silentAimEnabled = Value
    if Value then
        if not silentHookInstalled then
            pcall(installSilentAimAll)
        end
        if not silentHookInstalled then
            UI.Notify({
                Title = "Silent Aim Inactive",
                Content = "Hook not installed yet. Equip a gun, wait ~2s, toggle again. Check F9 for [NMZ] logs.",
                Duration = 4
            })
        else
            pcall(computeSilentAimPos)
        end
    else
        silentCachedPart, silentCachedPos = nil, nil
    end
end)
UI.CreateSlider(TabSilent, "Silent Max Distance", 100, 3000, silentAimDistance, function(v) return tostring(math.floor(v)) end, function(Value)
    silentAimDistance = Value
end)
UI.CreateToggle(TabSilent, "Predict Toggle", predEnabled, function(Value)
    predEnabled = Value
end)
UI.CreateSlider(TabSilent, "Predict Strength", 0, 0.3, predStrength, function(v) return string.format("%.3f", v) end, function(Value)
    predStrength = Value
end)
UI.CreateToggle(TabSilent, "Triggerbot", triggerbotEnabled, function(Value)
    triggerbotEnabled = Value
end)
UI.CreateToggle(TabSilent, "Wall Check", wallCheckEnabled, function(Value)
    wallCheckEnabled = Value
end)

UI.CreateLabel(TabGun, "V1.5 module path (full) + soft equip support (Solara). Fast Bolt may be limited.")
UI.CreateToggle(TabGun, "No Recoil", noRecoilEnabled, function(Value)
    noRecoilEnabled = Value
    local t = getHeldTool()
    if t and Value then applyV15GunAttrs(t) end
end)
UI.CreateToggle(TabGun, "No Spread", noSpreadEnabled, function(Value)
    noSpreadEnabled = Value
    local t = getHeldTool()
    if t and Value then applyV15GunAttrs(t) end
end)
UI.CreateToggle(TabGun, "Fast Bolt", fastBoltEnabled, function(Value)
    fastBoltEnabled = Value
end)
UI.CreateToggle(TabGun, "Silent Auto Reload", silentReloadEnabled, function(Value)
    silentReloadEnabled = Value
end)



UI.CreateToggle(TabHitbox, "Hitbox Expander", hitboxEnabled, function(Value)
    hitboxEnabled = Value
    if hitboxEnabled then applyHitboxToAll() else restoreAllHitboxes() end
end)
UI.CreateSlider(TabHitbox, "Hitbox Multiplier", 1, 5, hitboxMultiplier, function(v) return string.format("%.1f", v) end, function(Value)
    hitboxMultiplier = Value
    if hitboxEnabled then applyHitboxToAll() end
end)

UI.CreateButton(TabMisc, "Save Config", function()
    SaveConfig()
    UI.Notify({Title = "Config Saved", Content = "Your settings have been saved locally.", Duration = 3})
end)
UI.CreateToggle(TabMisc, "Anti-AFK", antiAfkEnabled, function(Value)
    antiAfkEnabled = Value
    toggleAntiAfk()
end)
UI.CreateButton(TabMisc, "Rejoin", function()
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)
UI.CreateButton(TabMisc, "Server Hop", function()
    local servers = {}
    local success, res = pcall(function() return cloneref(game:GetService("HttpService")):JSONDecode(game:HttpGetAsync("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")) end)
    if success and res.data then
        for _, s in pairs(res.data) do
            if s.playing < s.maxPlayers and s.id ~= game.JobId then table.insert(servers, s.id) end
        end
        if #servers > 0 then TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1,#servers)]) end
    end
end)
UI.CreateToggle(TabVisuals, "Full Bright", fullBrightEnabled, function(Value)
    fullBrightEnabled = Value
    if fullBrightEnabled then
        if not fullBrightConnection then
            fullBrightConnection = RunService.RenderStepped:Connect(function()
                local Lighting = game:GetService("Lighting")
                Lighting.Ambient = Color3.new(1, 1, 1)
                Lighting.ColorShift_Bottom = Color3.new(1, 1, 1)
                Lighting.ColorShift_Top = Color3.new(1, 1, 1)
                Lighting.GlobalShadows = false
            end)
        end
    else
        if fullBrightConnection then
            fullBrightConnection:Disconnect()
            fullBrightConnection = nil
        end
    end
end)
UI.CreateButton(TabVisuals, "Boost FPS (Smooth)", function()
    pcall(function()
        local Lighting = game:GetService("Lighting")
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.ShadowSoftness = 0
        if sethiddenproperty then
            pcall(sethiddenproperty, Lighting, "Technology", 2)
        end
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") then
                v.Material = Enum.Material.SmoothPlastic
                v.Reflectance = 0
                v.CastShadow = false
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                v.Lifetime = NumberRange.new(0)
            end
        end
        local Terrain = game:GetService("Workspace").Terrain
        Terrain.WaterWaveSize = 0
        Terrain.WaterWaveSpeed = 0
        Terrain.WaterReflectance = 0
        Terrain.WaterTransparency = 0
    end)
end)
UI.CreateToggle(TabVisuals, "Anti-Particle (No Lag)", noParticlesEnabled, function(Value)
    noParticlesEnabled = Value
    if noParticlesEnabled then
        local function isLaggy(obj)
            return obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Explosion") or obj:IsA("Fire") or obj:IsA("Sparkles")
        end
        for _, v in pairs(workspace:GetDescendants()) do
            if isLaggy(v) then
                v:Destroy()
            end
        end
        particleConnection = workspace.DescendantAdded:Connect(function(v)
            if isLaggy(v) then
                task.defer(function()
                    if v and v.Parent then v:Destroy() end
                end)
            end
        end)
    else
        if particleConnection then
            particleConnection:Disconnect()
            particleConnection = nil
        end
    end
end)
UI.CreateButton(TabMisc, "Unload Script", function()
    if getGenv()[scriptId] then getGenv()[scriptId]() end
end)
UI.CreateLabel(TabMisc, "Script Version: V1.5.2")

refreshESP()

-- Silent Aim multi-path installer.
-- Bug: old code scanned wrapped wm.Shoot (fast-bolt wrapper) so aim-calc never found.
-- Fix: always scan original Shoot + nested upvalues/env/getgc + Mouse.Hit/namecall fallbacks.
local getnamecallmethod = getnamecallmethod or function() return "" end
local hookmetamethod = hookmetamethod
local checkcaller = checkcaller or function() return false end

local function getFnName(fn)
    local n = ""
    pcall(function() n = debug.info(fn, "n") or "" end)
    if n == "" then pcall(function() local i = debug.getinfo(fn); n = (i and (i.name or i.namewhat)) or "" end) end
    return n or ""
end

local function iterUpvalues(fn)
    local list = {}
    if type(fn) ~= "function" then return list end
    for i = 1, 80 do
        local ok, name, val = pcall(debug.getupvalue, fn, i)
        if not ok then break end
        if name == nil and val == nil then break end
        table.insert(list, { index = i, name = name, value = val, owner = fn })
    end
    if #list == 0 then
        pcall(function()
            local ups = debug.getupvalues(fn)
            if type(ups) == "table" then
                for k, v in pairs(ups) do
                    local idx = type(k) == "number" and k or (#list + 1)
                    table.insert(list, { index = idx, name = tostring(k), value = v, owner = fn })
                end
            end
        end)
    end
    return list
end

local aimNameSet = {
    Crosshair = true, crosshair = true, GetCrosshair = true,
    bulletMagnetism = true, BulletMagnetism = true, magnetism = true,
    GetAim = true, getAim = true, AimPos = true, GetHitPosition = true,
    hitPosition = true, GetTarget = true, GetBulletTarget = true,
    bulletTarget = true, CalculateHit = true, getHit = true,
    GetHitPos = true, hitPos = true, AimPoint = true, GetAimPoint = true,
    muzzlePoint = true, GetMuzzle = true, GetShootPos = true, shootPos = true,
    GetDirection = true, getDirection = true, BulletDirection = true,
}

local function isAimName(n)
    if not n or n == "" then return false end
    if aimNameSet[n] then return true end
    local low = string.lower(tostring(n))
    return low:find("crosshair", 1, true)
        or low:find("magnet", 1, true)
        or low:find("aimpos", 1, true)
        or low:find("aimpoint", 1, true)
        or low:find("hittarget", 1, true)
        or low:find("hitpos", 1, true)
        or low:find("bullettarget", 1, true)
        or low:find("shootpos", 1, true)
        or low:find("muzzle", 1, true)
end

local function silentAimWorldPos()
    if silentCachedPos then return silentCachedPos end
    local pos = select(1, computeSilentAimPos())
    return pos
end

local function makeAimRedirect(oldFn)
    return newcclosure(function(...)
        if noSpreadEnabled then
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local oldALV = hrp.AssemblyLinearVelocity
                hrp.AssemblyLinearVelocity = Vector3.zero
                task.defer(function()
                    if hrp and hrp.Parent then hrp.AssemblyLinearVelocity = oldALV end
                end)
            end
        end

        if silentAimEnabled then
            local pos = silentAimWorldPos()
            if pos then return pos end
        end

        if noSpreadEnabled then
            local ok, res = pcall(function()
                local mouse = LocalPlayer:GetMouse()
                local rayParams = RaycastParams.new()
                rayParams.FilterType = Enum.RaycastFilterType.Exclude
                local ignore = {workspace.CurrentCamera}
                if LocalPlayer.Character then table.insert(ignore, LocalPlayer.Character) end
                rayParams.FilterDescendantsInstances = ignore
                local cam = workspace.CurrentCamera
                if not cam then return nil end
                local ray = cam:ScreenPointToRay(mouse.X, mouse.Y)
                local hit = workspace:Raycast(ray.Origin, ray.Direction * 3000, rayParams)
                if hit then return hit.Position end
                return ray.Origin + ray.Direction * 3000
            end)
            if ok and res then return res end
        end

        return oldFn(...)
    end)
end

local function tryInstallOnFn(oldFn, method, owner, idxOrKey, foundName, dump)
    if type(oldFn) ~= "function" then return false end
    if not getgenv().NMZ_Originals then getgenv().NMZ_Originals = {} end

    local oldShootFn = oldFn
    if getgenv().NMZ_Originals.InnerShoot and getgenv().NMZ_Originals.InnerShoot.Func then
        oldShootFn = getgenv().NMZ_Originals.InnerShoot.Func
    end

    local newShootFn = makeAimRedirect(function(...)
        return oldShootFn(...)
    end)

    local installed = false
    local usedMethod = method
    -- real hookfunction only (stub returns old without replacing — would fake success)
    local canHookFn = isExecutorSupported and type(hookfunction) == "function"

    -- 1) hookfunction (strongest)
    if canHookFn then
        local okHook, ret = pcall(hookfunction, oldFn, newShootFn)
        if okHook and type(ret) == "function" and ret ~= newShootFn then
            oldShootFn = ret
            installed = true
            usedMethod = "hookfn"
        end
    end

    -- 2) upvalue replace (works on many limited executors)
    if not installed and owner and idxOrKey and debug.setupvalue then
        if pcall(debug.setupvalue, owner, idxOrKey, newShootFn) then
            installed = true
            usedMethod = "upvalue"
        end
    end

    -- 3) env replace
    if not installed and owner and idxOrKey and type(owner) == "table" then
        if pcall(rawset, owner, idxOrKey, newShootFn) then
            installed = true
            usedMethod = "env"
        end
    end

    if not installed then return false end

    getgenv().NMZ_Originals.InnerShoot = {
        Method = usedMethod,
        Owner = owner,
        Key = idxOrKey,
        Func = oldShootFn,
        Live = oldFn,
        Env = usedMethod == "env" and owner or nil,
        Name = foundName,
    }
    silentHookInstalled = true
    print("[NMZ] Silent Aim hooked via: " .. tostring(foundName) .. " (" .. tostring(usedMethod) .. ")")
    if dump then
        for _, line in ipairs(dump) do print("  " .. line) end
    end
    return true
end

local function findAndHookAimCalc()
    -- ALWAYS prefer original Shoot (before fast-bolt wrap)
    local shootFn = (getgenv().NMZ_Originals and getgenv().NMZ_Originals.Shoot)
        or (wm and rawget(wm, "Shoot"))
    if type(shootFn) ~= "function" then
        return false, { "no Shoot function" }
    end

    local dump = {}
    local function dumpFn(tag, fn)
        local n = getFnName(fn)
        local line = tag .. " name=" .. (n ~= "" and n or "?")
        pcall(function()
            local info = debug.getinfo(fn)
            if type(info) == "table" then
                line = line .. " nups=" .. tostring(info.nups or "?")
                if info.short_src then line = line .. " src=" .. tostring(info.short_src) end
            end
        end)
        table.insert(dump, line)
    end

    dumpFn("Shoot(orig)", shootFn)

    local candidates = {} -- {method, owner, key, fn, name}

    local function pushCandidate(method, owner, key, fn, name)
        if type(fn) ~= "function" then return end
        table.insert(candidates, {
            method = method, owner = owner, key = key, fn = fn,
            name = name or getFnName(fn) or "?",
        })
    end

    local function scanEnv(fn)
        local okEnv, env = pcall(getfenv, fn)
        if not okEnv or type(env) ~= "table" then return end
        for k, v in pairs(env) do
            if type(v) == "function" then
                local n = getFnName(v)
                if isAimName(k) or isAimName(n) then
                    pushCandidate("env", env, k, v, n ~= "" and n or tostring(k))
                end
            end
        end
    end

    local function scanUps(fn, depth, prefix)
        depth = depth or 0
        if depth > 3 then return end
        for _, u in ipairs(iterUpvalues(fn)) do
            if type(u.value) == "function" then
                local n = getFnName(u.value)
                dumpFn((prefix or "") .. "uv#" .. u.index .. "(" .. tostring(u.name) .. ")", u.value)
                if isAimName(u.name) or isAimName(n) then
                    pushCandidate("upvalue", u.owner, u.index, u.value, n ~= "" and n or tostring(u.name))
                end
                scanEnv(u.value)
                scanUps(u.value, depth + 1, (prefix or "") .. "  ")
            elseif type(u.value) == "table" then
                -- table of helpers
                for k, v in pairs(u.value) do
                    if type(v) == "function" and (isAimName(k) or isAimName(getFnName(v))) then
                        pushCandidate("env", u.value, k, v, getFnName(v) ~= "" and getFnName(v) or tostring(k))
                    end
                end
            end
        end
    end

    scanEnv(shootFn)
    scanUps(shootFn, 0, "  ")

    -- Prefer Crosshair / bulletMagnetism first
    table.sort(candidates, function(a, b)
        local function rank(c)
            local n = string.lower(tostring(c.name))
            if n:find("crosshair", 1, true) then return 0 end
            if n:find("magnet", 1, true) then return 1 end
            if n:find("aim", 1, true) then return 2 end
            return 5
        end
        return rank(a) < rank(b)
    end)

    for _, c in ipairs(candidates) do
        if tryInstallOnFn(c.fn, c.method, c.owner, c.key, c.name, dump) then
            return true, dump
        end
    end

    -- getgc fallback by name
    if getgc then
        local okGc, gcList = pcall(getgc, true)
        if not okGc or type(gcList) ~= "table" then
            okGc, gcList = pcall(getgc)
        end
        if okGc and type(gcList) == "table" then
            for _, obj in ipairs(gcList) do
                if type(obj) == "function" then
                    local n = getFnName(obj)
                    if isAimName(n) then
                        dumpFn("getgc", obj)
                        if tryInstallOnFn(obj, "hookfn", nil, nil, n, dump) then
                            return true, dump
                        end
                    end
                end
            end
        end
    end

    return false, dump
end

-- Mouse.Hit / namecall fallbacks — work even if WeaponModule aim-calc not found
local metaHookInstalled = false
local function installMetaSilentHooks()
    if metaHookInstalled then return true end
    if type(hookmetamethod) ~= "function" then return false end

    local okAll = false

    -- __index Mouse.Hit / Mouse.Target
    pcall(function()
        local oldIndex
        oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
            if silentAimEnabled and not checkcaller() then
                local k = key
                if type(k) == "string" then
                    if self == Mouse and (k == "Hit" or k == "hit") then
                        local pos = silentAimWorldPos()
                        if pos then
                            local cam = workspace.CurrentCamera
                            local origin = (cam and cam.CFrame.Position)
                                or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") and LocalPlayer.Character.Head.Position)
                                or pos
                            return CFrame.new(pos, pos + (pos - origin))
                        end
                    elseif self == Mouse and (k == "Target" or k == "target") then
                        if silentCachedPart then return silentCachedPart end
                    end
                end
            end
            return oldIndex(self, key)
        end))
        okAll = true
        print("[NMZ] Silent Aim meta: __index Mouse.Hit")
    end)

    -- __namecall: legacy FindPartOnRay* only (do NOT blanket-hook Raycast — breaks wallcheck/game)
    pcall(function()
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            if silentAimEnabled and not checkcaller() then
                local method = getnamecallmethod()
                if method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist" then
                    local pos = silentAimWorldPos()
                    if pos then
                        local origin = (workspace.CurrentCamera and workspace.CurrentCamera.CFrame.Position)
                            or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") and LocalPlayer.Character.Head.Position)
                        if origin then
                            local dist = (pos - origin).Magnitude
                            local ray = Ray.new(origin, (pos - origin).Unit * math.max(dist, 1))
                            return oldNamecall(self, ray, select(2, ...))
                        end
                    end
                end
            end
            return oldNamecall(self, ...)
        end))
        okAll = true
        print("[NMZ] Silent Aim meta: __namecall FindPartOnRay")
    end)

    if okAll then
        metaHookInstalled = true
        silentHookInstalled = true -- treat as installed so UI doesn't spam fail
        if not getgenv().NMZ_Originals then getgenv().NMZ_Originals = {} end
        getgenv().NMZ_Originals.MetaSilent = true
    end
    return okAll
end

installSilentAimAll = function()
    local hasInner = getgenv().NMZ_Originals and getgenv().NMZ_Originals.InnerShoot
    local hasMeta = metaHookInstalled or (getgenv().NMZ_Originals and getgenv().NMZ_Originals.MetaSilent)
    if hasInner and hasMeta then
        silentHookInstalled = true
        return true
    end

    local okMod = hasInner and true or false
    local dump = nil
    if not hasInner and success and wm and type(wm) == "table" then
        local ok, d = findAndHookAimCalc()
        okMod, dump = ok, d
        if dump and not ok then
            print("[NMZ] WeaponModule.Shoot dump (no aim calc yet):")
            for _, line in ipairs(dump) do print("  " .. line) end
        end
    end

    local okMeta = hasMeta or installMetaSilentHooks()

    if okMod or okMeta then
        silentHookInstalled = true
        return true
    end
    return false
end

-- Install now + retry (module/upvalues sometimes not ready at inject)
do
    local ok = false
    pcall(function() ok = installSilentAimAll() end)
    if not ok then
        task.spawn(function()
            for i = 1, 8 do
                if scriptUnloadedLocal or silentHookInstalled then break end
                task.wait(1.25)
                pcall(function()
                    if installSilentAimAll() then
                        print("[NMZ] Silent Aim installed on retry #" .. i)
                    end
                end)
            end
            if not silentHookInstalled then
                warn("[NMZ] Silent Aim hook NOT installed after retries — check F9 dump")
            end
        end)
    end
end

print("MNZ ENTRENCHED WW1 - SCC UI LOADED")

task.spawn(function()
    task.wait(2.5)
    if not isExecutorSupported and not silentHookInstalled then
        UI.Notify({
            Title = "Limited Executor",
            Content = "Silent Aim may need hookfunction/hookmetamethod. Prefer Camera aim if hooks fail.",
            Duration = 6
        })
    elseif silentHookInstalled then
        UI.Notify({
            Title = "Silent Aim Ready",
            Content = "Hook active. Toggle Silent Aim + keep enemy in FOV then fire.",
            Duration = 4
        })
    else
        UI.Notify({
            Title = "Silent Aim Hook Failed",
            Content = "Aim calc not found. Open F9, copy [NMZ] dump lines, re-execute after equipping a gun.",
            Duration = 7
        })
    end
end)