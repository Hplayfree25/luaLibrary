local cloneref = cloneref or function(i) return i end
local newcclosure = function(f) return f end
local hookfunction = (type(hookfunction) == "function" and hookfunction) or nil
local hookmetamethod = (type(hookmetamethod) == "function" and hookmetamethod) or nil
local checkcaller = checkcaller or function() return false end
local getnamecallmethod = getnamecallmethod or function() return "" end
local getgc = (type(getgc) == "function" and getgc) or nil
local islclosure = islclosure or function() return true end
local gethui = gethui or function()
    local ok, cg = pcall(game.GetService, game, "CoreGui")
    return ok and cg or nil
end

local dbg = debug or {}
local getinfo = dbg.getinfo or getinfo or function() return {} end
local getconstants = dbg.getconstants or getconstants or function() return {} end
local getupvalues = dbg.getupvalues or getupvalues or function() return {} end
local getupvalue = dbg.getupvalue or getupvalue
local setupvalue = dbg.setupvalue or setupvalue

local function safeHook(oldFn, newFn)
    if type(oldFn) ~= "function" or type(newFn) ~= "function" or not hookfunction then
        return oldFn
    end
    local ok, res = pcall(hookfunction, oldFn, newFn)
    if ok and type(res) == "function" then return res end
    if ok then return newFn end
    warn("[CW] hook failed:", res)
    return oldFn
end

local Players = cloneref(game:GetService("Players"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local RunService = cloneref(game:GetService("RunService"))
local TeleportService = cloneref(game:GetService("TeleportService"))
local TweenService = cloneref(game:GetService("TweenService"))
local HttpService = cloneref(game:GetService("HttpService"))
local GuiService = cloneref(game:GetService("GuiService"))
local RS = cloneref(game:GetService("ReplicatedStorage"))
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

local isMobile = UserInputService.TouchEnabled
local mobileAimHolding = false
local mobileAimGui, mobileAimBtn = nil, nil
local scriptUnloaded = false

local combat = {
    LowRecoil = false,
    LowSpread = false,
    RecoilMult = 0,          
    SpreadMult = 0,          
    SilentEnabled = false,
    SilentTarget = "Head",
    SilentFov = 150,
    SilentFovEnabled = false,
    SilentExcludeTeammates = true,
    InstantReload = false,
    InstantADS = false,
    NoADSSlowdown = false,
    InstantEquip = false,
    NoBulletDrop = false,
    InstantBullet = false,
    DriveAnyCar = false,
    AimAnywhere = false,
    InstantHeal = false,
    ForceAuto = false,      
    InfiniteMags = false,    
    FastRevive = false,      
    CarMods = false,         
    QuickClimb = false,      
}

local status = {
    recoil = false,
    spread = false,
    silent = false,
    ads = false,
    equip = false,
    reload = false,
    traj = false,
    drive = false,
    heal = false,
    forceAuto = false,
    mags = false,
    revive = false,
    carMods = false,
    quickClimb = false,
}

-- ── ESP / aimbot state ─────────────────────────────────────────────────────
local espEnabled = true
local espHighlightEnabled = true
local espBoxEnabled = false
local espTracerEnabled = false
local boxColor = Color3.new(1, 1, 1)
local boxColorIndex = 1
local boxColors = {
    Color3.new(1,1,1), Color3.new(1,0,0), Color3.new(0,1,0),
    Color3.new(0,0,1), Color3.new(1,1,0), Color3.new(1,0,1), Color3.new(0,1,1)
}
local boxColorNames = {"White","Red","Green","Blue","Yellow","Pink","Cyan"}

local aimEnabled = true
local aimKey = Enum.UserInputType.MouseButton2
local aimPart = "Head"
local fovSize = 150
local fovColor = Color3.new(1, 0, 0)
local centerFovEnabled = true
local smoothness = 0.3
local aimModePC = "Camera"
local predEnabled = true
local predStrength = 0.135
local wallCheckEnabled = true

local configFileName = "ColdWar_Config.json"
local boxLines, tracerLines = {}, {}

local function SaveConfig()
    local cfg = {
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
        predEnabled = predEnabled,
        predStrength = predStrength,
        wallCheckEnabled = wallCheckEnabled,
        combat = combat,
    }
    if writefile then
        pcall(function() writefile(configFileName, HttpService:JSONEncode(cfg)) end)
    end
end

local function LoadConfig()
    if isfile and readfile and isfile(configFileName) then
        pcall(function()
            local d = HttpService:JSONDecode(readfile(configFileName))
            if not d then return end
            if d.espEnabled ~= nil then espEnabled = d.espEnabled end
            if d.espHighlightEnabled ~= nil then espHighlightEnabled = d.espHighlightEnabled end
            if d.espBoxEnabled ~= nil then espBoxEnabled = d.espBoxEnabled end
            if d.espTracerEnabled ~= nil then espTracerEnabled = d.espTracerEnabled end
            if d.boxColorIndex ~= nil then boxColorIndex = d.boxColorIndex end
            if d.aimEnabled ~= nil then aimEnabled = d.aimEnabled end
            if d.aimPart ~= nil then aimPart = d.aimPart end
            if d.fovSize ~= nil then fovSize = d.fovSize end
            if d.centerFovEnabled ~= nil then centerFovEnabled = d.centerFovEnabled end
            if d.aimModePC ~= nil then aimModePC = d.aimModePC end
            if d.smoothness ~= nil then smoothness = d.smoothness end
            if d.predEnabled ~= nil then predEnabled = d.predEnabled end
            if d.predStrength ~= nil then predStrength = d.predStrength end
            if d.wallCheckEnabled ~= nil then wallCheckEnabled = d.wallCheckEnabled end
            if type(d.combat) == "table" then
                for k, v in pairs(d.combat) do combat[k] = v end
            end
            boxColor = boxColors[boxColorIndex] or Color3.new(1,1,1)
        end)
    end
end
LoadConfig()

-- ── FOV / pred ─────────────────────────────────────────────────────────────
local guiFov, fovFrame = nil, nil
local guiPredDot, predDotFrame = nil, nil

local function updateFOVCircle()
    if not guiFov then
        guiFov = Instance.new("ScreenGui")
        guiFov.Name = "CW_FOV"
        guiFov.ResetOnSpawn = false
        guiFov.IgnoreGuiInset = true
        local parent = LocalPlayer:WaitForChild("PlayerGui")
        pcall(function()
            if gethui then parent = gethui() else parent = game:GetService("CoreGui") end
        end)
        if parent:FindFirstChild("CW_FOV") then parent.CW_FOV:Destroy() end
        guiFov.Parent = parent
        fovFrame = Instance.new("Frame")
        fovFrame.Parent = guiFov
        fovFrame.BackgroundTransparency = 1
        fovFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        Instance.new("UICorner", fovFrame).CornerRadius = UDim.new(1, 0)
        local stroke = Instance.new("UIStroke")
        stroke.Color = fovColor
        stroke.Thickness = 2
        stroke.Parent = fovFrame
    end
    fovFrame.Size = UDim2.new(0, fovSize * 2, 0, fovSize * 2)
    local str = fovFrame:FindFirstChildOfClass("UIStroke")
    if str then str.Color = fovColor end
    fovFrame.Visible = aimEnabled or combat.SilentEnabled
end
updateFOVCircle()

local function updatePredDot(pos)
    if not guiPredDot then
        guiPredDot = Instance.new("ScreenGui")
        guiPredDot.Name = "CW_PredDot"
        guiPredDot.ResetOnSpawn = false
        guiPredDot.IgnoreGuiInset = true
        local parent = LocalPlayer:WaitForChild("PlayerGui")
        pcall(function()
            if gethui then parent = gethui() else parent = game:GetService("CoreGui") end
        end)
        if parent:FindFirstChild("CW_PredDot") then parent.CW_PredDot:Destroy() end
        guiPredDot.Parent = parent
        predDotFrame = Instance.new("Frame")
        predDotFrame.Parent = guiPredDot
        predDotFrame.Size = UDim2.new(0, 4, 0, 4)
        predDotFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        predDotFrame.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        predDotFrame.BorderSizePixel = 0
        Instance.new("UICorner", predDotFrame).CornerRadius = UDim.new(1, 0)
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

-- ── wallcheck (aimbot LOS) ─────────────────────────────────────────────────
local PENETRABLE_KEYWORDS = {
    "bush","leaf","leaves","foliage","plant","grass","tree","spawn","glass","window","smoke","fog","water",
}
local function nameLooksPenetrable(str)
    if not str or str == "" then return false end
    local lower = string.lower(str)
    for i = 1, #PENETRABLE_KEYWORDS do
        if string.find(lower, PENETRABLE_KEYWORDS[i], 1, true) then return true end
    end
    return false
end
local function isPenetratablePart(part)
    if not part then return true end
    if part:IsA("Terrain") then return false end
    if not part:IsA("BasePart") then return true end
    local ok, result = pcall(function()
        if part.CanCollide == false or part.CanQuery == false then return true end
        if (part.Transparency or 0) >= 0.45 then return true end
        local soft = {
            [Enum.Material.Leaves] = true, [Enum.Material.Grass] = true,
            [Enum.Material.Glass] = true, [Enum.Material.Fabric] = true,
            [Enum.Material.ForceField] = true,
        }
        return soft[part.Material] or nameLooksPenetrable(part.Name)
    end)
    return ok and result == true
end
local function smartRaycast(origin, direction, ignoreListArray)
    local ignoreList = {}
    if ignoreListArray then for _, v in pairs(ignoreListArray) do table.insert(ignoreList, v) end end
    for _ = 1, 16 do
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        rayParams.FilterDescendantsInstances = ignoreList
        rayParams.IgnoreWater = true
        local hit = workspace:Raycast(origin, direction, rayParams)
        if not hit then return nil end
        if isPenetratablePart(hit.Instance) then
            table.insert(ignoreList, hit.Instance)
        else
            return hit
        end
    end
    return nil
end
local function isPointVisible(pos, char)
    local myChar = LocalPlayer.Character
    if not myChar then return false end
    return smartRaycast(Camera.CFrame.Position, pos - Camera.CFrame.Position, {myChar, char, Camera}) == nil
end
local function getBestTargetPos(char)
    if not char then return nil end
    local head = char:FindFirstChild("Head")
    local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart")
    if not wallCheckEnabled then
        if aimPart == "Head" and head then return head.Position end
        if torso then return torso.Position end
        return head and head.Position
    end
    if head and isPointVisible(head.Position, char) then return head.Position end
    if torso and isPointVisible(torso.Position, char) then return torso.Position end
    return nil
end
local function isTargetVisible(target, targetPos)
    if not wallCheckEnabled then return true end
    if not target or not targetPos then return false end
    local char = target.Parent
    return char and isPointVisible(targetPos, char) or false
end

-- ── ESP ────────────────────────────────────────────────────────────────────
local function removeAllHighlights()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr.Character then
            local hl = plr.Character:FindFirstChildOfClass("Highlight")
            if hl then hl:Destroy() end
        end
    end
end
local function removeAllBoxes()
    for _, lines in pairs(boxLines) do for _, line in pairs(lines) do line:Remove() end end
    boxLines = {}
end
local function removeAllTracers()
    for _, line in pairs(tracerLines) do line:Remove() end
    tracerLines = {}
end
local function createHighlightForPlayer(plr)
    if plr == LocalPlayer or not plr.Character then return end
    local old = plr.Character:FindFirstChildOfClass("Highlight")
    if old then old:Destroy() end
    local hl = Instance.new("Highlight")
    hl.Parent = plr.Character
    hl.FillTransparency = 0.6
    hl.OutlineTransparency = 0.2
    if plr.Team == LocalPlayer.Team then
        hl.FillColor = Color3.fromRGB(0, 100, 255)
        hl.OutlineColor = Color3.fromRGB(0, 200, 255)
    else
        hl.FillColor = Color3.fromRGB(255, 50, 50)
        hl.OutlineColor = Color3.fromRGB(255, 150, 150)
    end
end
local function createBoxLinesForPlayer(plr)
    if boxLines[plr] then return end
    if type(Drawing) == "table" and type(Drawing.new) == "function" then
        local lines = {}
        for i = 1, 4 do
            local ok, line = pcall(Drawing.new, "Line")
            if ok and line then
                line.Thickness = 2; line.Color = boxColor; line.Visible = false
                table.insert(lines, line)
            end
        end
        if #lines == 4 then boxLines[plr] = lines end
    end
end
local function createTracerLineForPlayer(plr)
    if tracerLines[plr] then return end
    if type(Drawing) == "table" and type(Drawing.new) == "function" then
        local ok, line = pcall(Drawing.new, "Line")
        if ok and line then
            line.Thickness = 1.5; line.Color = boxColor; line.Visible = false
            tracerLines[plr] = line
        end
    end
end
local function updateESP()
    if not espEnabled then
        for _, lines in pairs(boxLines) do for _, line in pairs(lines) do line.Visible = false end end
        for _, line in pairs(tracerLines) do line.Visible = false end
        return
    end
    for _, plr in pairs(Players:GetPlayers()) do
        local isEnemy = plr ~= LocalPlayer and (not LocalPlayer.Team or plr.Team ~= LocalPlayer.Team)
        if isEnemy and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("Head") then
            local root, head = plr.Character.HumanoidRootPart, plr.Character.Head
            local rPos, rVis = Camera:WorldToViewportPoint(root.Position)
            local hPos, hVis = Camera:WorldToViewportPoint(head.Position)
            if espBoxEnabled and rVis and hVis then
                createBoxLinesForPlayer(plr)
                local lines = boxLines[plr]
                if lines then
                    local height = math.abs(hPos.Y - rPos.Y) * 2.2
                    local width = height * 0.7
                    local cx, cy = rPos.X, (hPos.Y + rPos.Y) / 2
                    local left, right = cx - width/2, cx + width/2
                    local top, bottom = cy - height/2, cy + height/2
                    lines[1].From = Vector2.new(left, top);     lines[1].To = Vector2.new(right, top)
                    lines[2].From = Vector2.new(right, top);    lines[2].To = Vector2.new(right, bottom)
                    lines[3].From = Vector2.new(right, bottom); lines[3].To = Vector2.new(left, bottom)
                    lines[4].From = Vector2.new(left, bottom);  lines[4].To = Vector2.new(left, top)
                    for _, line in pairs(lines) do line.Color = boxColor; line.Visible = true end
                end
            elseif boxLines[plr] then
                for _, line in pairs(boxLines[plr]) do line.Visible = false end
            end
            if espTracerEnabled and rVis then
                createTracerLineForPlayer(plr)
                local line = tracerLines[plr]
                if line then
                    line.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                    line.To = Vector2.new(rPos.X, rPos.Y)
                    line.Color = boxColor; line.Visible = true
                end
            elseif tracerLines[plr] then
                tracerLines[plr].Visible = false
            end
        else
            if boxLines[plr] then for _, line in pairs(boxLines[plr]) do line.Visible = false end end
            if tracerLines[plr] then tracerLines[plr].Visible = false end
        end
    end
end
local function refreshESP()
    if not espEnabled then removeAllHighlights(); removeAllBoxes(); removeAllTracers(); return end
    if espHighlightEnabled then
        for _, plr in pairs(Players:GetPlayers()) do createHighlightForPlayer(plr) end
    else
        removeAllHighlights()
    end
    if not espBoxEnabled then removeAllBoxes() end
    if not espTracerEnabled then removeAllTracers() end
end

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(0.5)
        if espEnabled and espHighlightEnabled then createHighlightForPlayer(plr) end
    end)
end)
Players.PlayerRemoving:Connect(function(plr)
    if boxLines[plr] then for _, line in pairs(boxLines[plr]) do line:Remove() end; boxLines[plr] = nil end
    if tracerLines[plr] then tracerLines[plr]:Remove(); tracerLines[plr] = nil end
end)
for _, plr in pairs(Players:GetPlayers()) do
    plr.CharacterAdded:Connect(function()
        task.wait(0.5)
        if espEnabled and espHighlightEnabled then createHighlightForPlayer(plr) end
    end)
end
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if espEnabled and espHighlightEnabled then
        for _, plr in pairs(Players:GetPlayers()) do createHighlightForPlayer(plr) end
    end
end)

-- ── camera aimbot ──────────────────────────────────────────────────────────
local function getFovCenter()
    if centerFovEnabled then
        return Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    end
    local m = UserInputService:GetMouseLocation()
    return Vector2.new(m.X, m.Y)
end
local function getClosestEnemy()
    local center = getFovCenter()
    local closest, closestDist, bestPos = nil, fovSize, nil
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
                                closestDist, closest, bestPos = dist, part, targetPos
                            end
                        end
                    end
                end
            end
        end
    end
    return closest, bestPos
end
local function cameraAim(target, targetPos)
    if not target or not targetPos then return end
    local pos = targetPos
    if predEnabled then
        local vel = target.AssemblyLinearVelocity or target.Velocity
        if vel then pos = pos + (vel * predStrength) end
    end
    local currentCF = Camera.CFrame
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
        if vel then pos = pos + (vel * predStrength) end
    end
    local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
    if onScreen then
        local deltaX = (screenPos.X - Mouse.X) * smoothness
        local deltaY = (screenPos.Y - Mouse.Y) * smoothness
        pcall(function() game:GetService("VirtualInputManager"):SendMouseMovement(deltaX, deltaY, nil) end)
        pcall(function() mousemoverel(deltaX, deltaY) end)
    end
end

RunService.RenderStepped:Connect(function()
    if scriptUnloaded then return end
    if fovFrame and fovFrame.Visible then
        local pos = getFovCenter()
        fovFrame.Position = UDim2.new(0, pos.X, 0, pos.Y)
    end
    updateESP()
    if not aimEnabled then updatePredDot(nil); return end
    local keyPressed = false
    if isMobile then
        keyPressed = mobileAimHolding
    elseif aimKey.EnumType == Enum.UserInputType then
        keyPressed = UserInputService:IsMouseButtonPressed(aimKey)
    else
        keyPressed = UserInputService:IsKeyDown(aimKey)
    end
    local target, targetPos = getClosestEnemy()
    if target and targetPos and isTargetVisible(target, targetPos) then
        local pos = targetPos
        if predEnabled then
            local vel = target.AssemblyLinearVelocity or target.Velocity
            if vel then pos = pos + (vel * predStrength) end
        end
        updatePredDot(pos)
        if keyPressed then
            if aimModePC == "Camera" then cameraAim(target, targetPos) else mouseAim(target, targetPos) end
        end
    else
        updatePredDot(nil)
    end
end)

-- ── GUN MODS ─────────────────────────
local util = { target = nil }
local functions = {
    getRecoilMult = { func = nil, upv = nil },
    spreadVector = { func = nil },
    fire = { func = nil, upv = nil },
    aimtoggle = { func = nil },
    isaimingavailable = { func = nil },
    aimupdate = { func = nil },
    awaitLength = { func = nil },
    reloadContext = { func = nil },
    canEnterSeat = { func = nil },
    healLimb = { func = nil },
    firemodestart = { func = nil, upv = nil },
    getAnimLength = { func = nil },
}

local function isDowned(char)
    if not char then return false end
    local cv = char:FindFirstChild("CharacterValues")
    local u = cv and cv:FindFirstChild("Unconscious")
    return u ~= nil and u.Value == true
end

local function targetValid(part)
    if not part or not part.Parent then return false end
    local hum = part.Parent:FindFirstChildOfClass("Humanoid")
    return hum ~= nil and hum.Health > 0
end

local function findBestSilent()
    local cam = workspace.CurrentCamera
    if not cam then return nil end
    local mouse = UserInputService:GetMouseLocation() - GuiService:GetGuiInset()
    local best, bestDist
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and not isDowned(plr.Character) then
            if (not (LocalPlayer.Team and plr.Team == LocalPlayer.Team)) or (not combat.SilentExcludeTeammates) then
                local part = plr.Character:FindFirstChild(combat.SilentTarget)
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                if part and hum and hum.Health > 0 then
                    local sp, onScreen = cam:WorldToViewportPoint(part.Position)
                    if onScreen and sp.Z > 0 then
                        local dist = (Vector2.new(sp.X, sp.Y) - mouse).Magnitude
                        local within = (not combat.SilentFovEnabled) or dist <= combat.SilentFov
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

util.getTarget = function()
    if not targetValid(util.target) then
        util.target = findBestSilent()
    end
    return util.target
end

local targetFrame = 0
RunService.Heartbeat:Connect(function()
    if scriptUnloaded or not combat.SilentEnabled then return end
    targetFrame = targetFrame + 1
    if targetFrame >= 5 then
        targetFrame = 0
        util.target = findBestSilent()
    end
end)

local function softGetgc()
    if not getgc then return {} end
    local ok, res = pcall(function() return getgc() end)
    if ok and type(res) == "table" then return res end
    return {}
end

local GetAmmoRemote = nil
pcall(function()
    GetAmmoRemote = RS:WaitForChild("Remotes", 5) and RS.Remotes:WaitForChild("GetAmmo", 5)
end)

local function installSafeMods()
    print("[CW] safe install start")
    local RecoilController, AimController, Trajectory, FiremodeController
    pcall(function()
        local Client = RS:WaitForChild("Client", 5)
        local Tools = Client and Client:WaitForChild("Tools", 5)
        local Weapon = Tools and Tools:WaitForChild("Weapon", 5)
        local controllers = Weapon and Weapon:WaitForChild("controllers", 5)
        if controllers then
            RecoilController = require(controllers:WaitForChild("RecoilController"))
            AimController = require(controllers:WaitForChild("AimController"))
        end
        local Muzzle = Weapon and Weapon:FindFirstChild("Muzzle")
        local firemodes = Muzzle and Muzzle:FindFirstChild("firemodes")
        if firemodes and firemodes:FindFirstChild("FireController") then
            FiremodeController = require(firemodes.FireController)
        end
    end)
    pcall(function()
        Trajectory = require(RS:WaitForChild("Shared"):WaitForChild("Ballistics"):WaitForChild("Trajectory"))
    end)

    if RecoilController and type(RecoilController.getRecoilMult) == "function" then
        local ups = nil
        pcall(function() ups = getupvalues(RecoilController.getRecoilMult) end)
        functions.getRecoilMult.upv = ups
        RecoilController.getRecoilMult = function()
            local mult = combat.LowRecoil and (combat.RecoilMult or 0) or 1
            if type(mult) ~= "number" then mult = 1 end
            local v_u_8, v_u_5, v_u_6
            if type(functions.getRecoilMult.upv) == "table" then
                v_u_8, v_u_5, v_u_6 = unpack(functions.getRecoilMult.upv)
            end
            if not v_u_8 or not v_u_5 or not v_u_6 then return mult end
            local ok, res = pcall(function()
                local cv = v_u_5:getCharacterValues()
                local stance = cv and cv:FindFirstChild("Stance")
                local alpha = (v_u_6.getAlpha and v_u_6.getAlpha()) or 0
                return (v_u_8[stance and stance.Value or "Walk"] or 1) * (1 - alpha * 0.25) * mult
            end)
            return ok and res or mult
        end
        status.recoil = true
        print("[CW] Low Recoil: OK")
    else
        warn("[CW] Low Recoil: missing")
    end

    task.wait(0.05)

    if Trajectory and type(Trajectory.new) == "function" then
        local oldTrajNew = Trajectory.new
        Trajectory.new = function(params)
            if type(params) == "table" then
                if combat.NoBulletDrop then params.Gravity = 0 end
                if combat.InstantBullet then
                    params.MuzzleSpeed = 1e6
                    params.K = 0
                end
            end
            return oldTrajNew(params)
        end
        status.traj = true
        print("[CW] Instant Bullet / No Drop: OK")
    else
        warn("[CW] Trajectory missing")
    end

    task.wait(0.05)

    if AimController and type(AimController.isAimingAvailable) == "function" then
        local orig = AimController.isAimingAvailable
        functions.isaimingavailable.func = orig
        AimController.isAimingAvailable = function(...)
            if combat.AimAnywhere then return true end
            return orig(...)
        end
        status.ads = true
        print("[CW] AimAnywhere hook ready (flag OFF by default)")
    end

    if FiremodeController and type(FiremodeController.start) == "function" then
        local autoUpv = nil
        pcall(function()
            if getupvalue and type(FiremodeController.new) == "function" then
                autoUpv = getupvalue(FiremodeController.new, 2)
            end
        end)
        functions.firemodestart.func = FiremodeController.start
        functions.firemodestart.upv = autoUpv
        FiremodeController.start = function(p18)
            if not p18.isFiring then
                p18.isFiring = true
                local v19 = p18:_current()
                if v19 then
                    local strategy = v19.strategy
                    if combat.ForceAuto and functions.firemodestart.upv and functions.firemodestart.upv.Automatic then
                        strategy = functions.firemodestart.upv.Automatic.strategy
                    end
                    task.spawn(strategy.fire, p18)
                end
            end
        end
        status.forceAuto = true
        print("[CW] Force Auto: ready")
    else
        warn("[CW] Force Auto: FiremodeController missing")
    end

    if GetAmmoRemote then
        status.mags = true
        print("[CW] Infinite Mags: remote ready (place AmmoBox)")
    else
        warn("[CW] Infinite Mags: GetAmmo remote missing")
    end

    print("[CW] safe install done")
end

local advancedInstalled = false
local function installAdvancedHooks()
    if advancedInstalled then
        print("[CW] advanced already installed")
        return
    end
    print("[CW] advanced install start — if crash, culprit is getgc/hook below")

    print("[CW] step: getgc scan...")
    local gc = softGetgc()
    local n = 0
    for _, v in pairs(gc) do
        n = n + 1
        if n % 400 == 0 then task.wait() end
        if typeof(v) ~= "function" then continue end
        local isL = true
        pcall(function() isL = islclosure(v) end)
        if not isL then continue end

        local info, constants, upvalues
        if not pcall(function() info = getinfo(v) end) or type(info) ~= "table" then continue end
        pcall(function() constants = getconstants(v) end)
        pcall(function() upvalues = getupvalues(v) end)
        constants = constants or {}
        upvalues = upvalues or {}
        local src = tostring(info.source or "")
        local name = info.name or ""

        if name == "spreadVector" and not functions.spreadVector.func then
            functions.spreadVector.func = v
        elseif table.find(constants, "config") and string.find(src, "Shooter") and not functions.fire.func then
            functions.fire.func = v
            functions.fire.upv = upvalues
        elseif name == "update" and string.find(src, "AimController") and not functions.aimupdate.func then
            functions.aimupdate.func = v
        elseif name == "awaitLength" and string.find(src, "Inventory") and not functions.awaitLength.func then
            functions.awaitLength.func = v
        elseif name == "CanEnterSeat" and not functions.canEnterSeat.func then
            functions.canEnterSeat.func = v
        elseif name == "_context" and table.find(constants, "reloadTime") and not functions.reloadContext.func then
            functions.reloadContext.func = v
        elseif name == "healLimb" and not functions.healLimb.func then
            functions.healLimb.func = v
        elseif name == "GetAnimationLength" and not functions.getAnimLength.func then
            functions.getAnimLength.func = v
        end
    end
    print("[CW] step: getgc scan done")
    task.wait(0.1)

    print("[CW] step: spread...")
    if type(functions.spreadVector.func) == "function" then
        functions.spreadVector.func = safeHook(functions.spreadVector.func, function(p12, p13)
            local mult = combat.LowSpread and (combat.SpreadMult or 0) or 1
            if type(mult) ~= "number" then mult = 1 end
            if mult == 0 then return p12.Unit end
            local v14 = p12.Unit
            local v16 = math.atan(p13 / 3570) * mult
            return (v14 + Vector3.new(math.random()*2-1, math.random()*2-1, math.random()*2-1) * v16).Unit
        end)
        status.spread = true
        print("[CW] Low Spread: OK")
    else
        warn("[CW] Low Spread: not found")
    end
    task.wait(0.1)

    print("[CW] step: silent fire...")
    if type(functions.fire.func) == "function" and type(functions.fire.upv) == "table" then
        local fireUpv = functions.fire.upv
        functions.fire.func = safeHook(functions.fire.func, function(p20, p21)
            local v_u_3,v_u_7,v_u_11,v_u_8,v_u_4,spreadVector,v_u_6,v_u_5,v_u_10 = unpack(fireUpv)
            local v22 = p20.config
            local v23 = v_u_3:getCharacter()
            if v23 then v23 = v23:FindFirstChild("Right Arm") end
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
                    local v32 = math.min(0.01, v30.Distance)
                    v26 = v30.Position - v27 * v32
                end
            end
            local v33 = v22.DefaultAngle or 0
            local v35 = v_u_4.zeroAngle() or math.rad(v33)
            local v36 = (v25.WorldCFrame * CFrame.Angles(v35, 0, 0)).LookVector
            if combat.SilentEnabled then
                local aimTarget = util.getTarget()
                if aimTarget then v36 = (aimTarget.Position - v26).Unit end
            end
            p20.animator:play("GunShoot")
            local v37 = v22.BulletSettings[p21]
            local v38 = v37.ShotAmount or 1
            local v39 = v37.Spread or 1
            local v40 = table.create(v38)
            for i = 1, v38 do v40[#v40 + 1] = spreadVector(v36, v39) end
            local v42 = p20.tool.Sounds:FindFirstChild("Muzzle" .. p20.index)
            if v42 then v42 = v42:FindFirstChild("Fire") end
            if v42 then v_u_6.Play(v42, v25.WorldPosition, v22.SoundRange or 3000) end
            local v43 = v24 and p20.viewmodelTool or p20.tool
            v_u_5.replicateRecoil(v_u_8, v43, p20.index)
            v_u_5.muzzleFlash(v43, p20.index)
            v_u_10.fireVolley(p20.tool, p20.index, p21, v26, v40)
            if not p20:isHandAction() then v_u_5.casing(v43, p20.index) end
        end)
        status.silent = true
        print("[CW] Silent Aim: OK")
    else
        warn("[CW] Silent Aim: fire not found")
    end
    task.wait(0.1)

    print("[CW] step: aimupdate...")
    if type(functions.aimupdate.func) == "function" and getupvalue and setupvalue then
        functions.aimupdate.func = safeHook(functions.aimupdate.func, function(p25)
            local orig = functions.aimupdate.func
            local wantAim = getupvalue(orig, 1) == 1
            if combat.InstantADS then setupvalue(orig, 5, getupvalue(orig, 1)) end
            orig(p25)
            if combat.AimAnywhere and wantAim then
                setupvalue(orig, 1, 1)
                if combat.InstantADS then setupvalue(orig, 5, 1) end
            end
            if combat.NoADSSlowdown then
                local slow = getupvalue(orig, 6)
                if slow then slow.Value = 1 end
            end
        end)
        status.ads = true
        print("[CW] Instant ADS: OK")
    else
        warn("[CW] aimupdate not found")
    end
    task.wait(0.1)

    print("[CW] step: equip/reload/drive...")
    if type(functions.awaitLength.func) == "function" then
        functions.awaitLength.func = safeHook(functions.awaitLength.func, function(...)
            if combat.InstantEquip then return false end
            return functions.awaitLength.func(...)
        end)
        status.equip = true
        print("[CW] Instant Equip: OK")
    end
    if type(functions.reloadContext.func) == "function" then
        functions.reloadContext.func = safeHook(functions.reloadContext.func, function(...)
            local ctx = functions.reloadContext.func(...)
            if combat.InstantReload and type(ctx) == "table" then
                ctx.reloadTime = 0.05
                ctx.insertTime = 0.05
            end
            return ctx
        end)
        status.reload = true
        print("[CW] Instant Reload: OK")
    end
    if type(functions.canEnterSeat.func) == "function" then
        functions.canEnterSeat.func = safeHook(functions.canEnterSeat.func, function(...)
            if combat.DriveAnyCar then return true end
            return functions.canEnterSeat.func(...)
        end)
        status.drive = true
        print("[CW] Drive Any Car: OK")
    end

    if type(functions.healLimb.func) == "function" and getupvalue then
        status.heal = true
        print("[CW] Instant Heal: ready (toggle OFF by default)")
    else
        warn("[CW] Instant Heal: healLimb not found")
    end

    if type(functions.getAnimLength.func) == "function" then
        functions.getAnimLength.func = safeHook(functions.getAnimLength.func, function(...)
            if combat.QuickClimb then return 0.05 end
            return functions.getAnimLength.func(...)
        end)
        status.quickClimb = true
        print("[CW] Quick Enter/Exit: OK")
    else
        warn("[CW] Quick Enter/Exit: GetAnimationLength not found")
    end

    advancedInstalled = true
    print("[CW] advanced install done")
end

local healAcc = 0
RunService.Heartbeat:Connect(function(dt)
    if scriptUnloaded or not combat.InstantHeal then return end
    if not functions.healLimb.func or not getupvalue then return end
    healAcc = healAcc + dt
    if healAcc < 0.05 then return end
    healAcc = 0
    local remote, bandage
    pcall(function()
        remote = getupvalue(functions.healLimb.func, 1)
        bandage = getupvalue(functions.healLimb.func, 2)
    end)
    local char = LocalPlayer.Character
    if not (remote and char) then return end
    for _, part in ipairs(char:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            local h = part:FindFirstChild("Health")
            if h then
                local max = h:GetAttribute("MaxHealth")
                if max and h.Value < max then
                    pcall(function() remote:FireServer(bandage, "HealLimb", part) end)
                end
            end
        end
    end
end)

local magsAcc = 0
RunService.Heartbeat:Connect(function(dt)
    if scriptUnloaded or not combat.InfiniteMags or not GetAmmoRemote then return end
    magsAcc = magsAcc + dt
    if magsAcc < 0.25 then return end
    magsAcc = 0
    local ignore = workspace:FindFirstChild("Ignore")
    local box = ignore and ignore:FindFirstChild("AmmoBox")
    if not box then return end
    local char = LocalPlayer.Character
    if char then
        for _, t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") then pcall(function() GetAmmoRemote:FireServer(t, box, 1, 1) end) end
        end
    end
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if backpack then
        for _, t in ipairs(backpack:GetChildren()) do
            if t:IsA("Tool") then pcall(function() GetAmmoRemote:FireServer(t, box, 1, 1) end) end
        end
    end
end)

local reviveAcc = 0
RunService.Heartbeat:Connect(function(dt)
    if scriptUnloaded then return end
    reviveAcc = reviveAcc + dt
    if reviveAcc < 1 then return end
    reviveAcc = 0
    if not combat.FastRevive then return end
    local chars = workspace:FindFirstChild("Characters")
    if not chars then return end
    for _, p in ipairs(chars:GetDescendants()) do
        if p:IsA("ProximityPrompt") and p.Name == "RevivePrompt" then
            p.HoldDuration = 3
        end
    end
    status.revive = true
end)

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
    local ok, objs = pcall(function() return getgc and getgc() or {} end)
    if not ok or type(objs) ~= "table" then return end
    local n, hit = 0, 0
    for _, v in pairs(objs) do
        n = n + 1
        if n % 400 == 0 then task.wait() end
        if typeof(v) == "table" then
            local isCar = false
            pcall(function()
                if rawget(v, "Transmission") and rawget(v, "Damage") and rawget(v, "ShopInfo") then
                    isCar = true
                end
            end)
            if isCar then
                pcall(function() v.Transmission = carTransmission end)
                hit = hit + 1
            end
        end
    end
    if hit > 0 then status.carMods = true end
    print("[CW] Car Mods applied to", hit, "tables")
end
local carModsAcc = 0
RunService.Heartbeat:Connect(function(dt)
    if scriptUnloaded or not combat.CarMods then return end
    carModsAcc = carModsAcc + dt
    if carModsAcc < 5 then return end
    carModsAcc = 0
    task.spawn(function()
        pcall(applyCarMods)
    end)
end)

-- ── UI ─────────────────────────────────────────────────────────────────────
local scriptId = "NMZ_COLDWAR_UI"
local getGenv = getgenv or function() return _G end
if getGenv()[scriptId] then pcall(getGenv()[scriptId]) end

local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Hplayfree25/luaLibrary/refs/heads/master/Init.lua?t=" .. tick()))()

local winSize = UDim2.new(0, 500, 0, 340)
if isMobile then
    local vp = Camera.ViewportSize
    winSize = UDim2.new(0, math.min(vp.X - 24, 460), 0, math.min(vp.Y - 80, 520))
end

local Window = UI.CreateWindow({
    Title = "NMZ Cold War",
    ToggleText = "CW",
    Size = winSize,
    Keybind = Enum.KeyCode.LeftAlt,
    HideOnStartup = true,
})

task.defer(function()
    task.wait(0.4)
    if scriptUnloaded then return end
    local ok, err = pcall(installSafeMods)
    if not ok then warn("[CW] safe install error:", err) end
    task.wait(0.3)
    if scriptUnloaded then return end
    local ok2, err2 = pcall(installAdvancedHooks)
    if not ok2 then warn("[CW] advanced install error:", err2) end
    pcall(function()
        UI.Notify({
            Title = "Hooks ready",
            Content = "All gun mods OFF — enable what you want in GUN MODS.",
            Duration = 6,
        })
    end)
end)

task.spawn(function()
    task.wait(1)
    UI.Notify({
        Title = "UI Loaded",
        Content = isMobile and "Tap CW · hold AIM" or "Left Alt · opt-in gun mods",
        Duration = 4,
    })
end)

if isMobile then
    mobileAimGui = Instance.new("ScreenGui")
    mobileAimGui.Name = "CW_MobileAim"
    mobileAimGui.ResetOnSpawn = false
    mobileAimGui.IgnoreGuiInset = true
    pcall(function()
        if gethui then mobileAimGui.Parent = gethui() else mobileAimGui.Parent = game:GetService("CoreGui") end
    end)
    if not mobileAimGui.Parent then mobileAimGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
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
    mobileAimBtn.Parent = mobileAimGui
    Instance.new("UICorner", mobileAimBtn).CornerRadius = UDim.new(1, 0)
    local dragging, dragStart, startPos = false, nil, nil
    mobileAimBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = input.Position; startPos = mobileAimBtn.Position; mobileAimHolding = true
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local d = input.Position - dragStart
            mobileAimBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) then
            dragging = false; mobileAimHolding = false
        end
    end)
end

getGenv()[scriptId] = function()
    scriptUnloaded = true
    if Window then Window.destroy() end
    if guiFov then pcall(function() guiFov:Destroy() end) end
    if guiPredDot then pcall(function() guiPredDot:Destroy() end) end
    if mobileAimGui then pcall(function() mobileAimGui:Destroy() end) end
    removeAllHighlights(); removeAllBoxes(); removeAllTracers()
    getGenv()[scriptId] = nil
end

local TabESP = UI.CreateTab(Window, "ESP", 1)
local TabAim = UI.CreateTab(Window, "AIMBOT", 2)
local TabSilent = UI.CreateTab(Window, "SILENT", 3)
local TabGun = UI.CreateTab(Window, "GUN", 4)
local TabPlayer = UI.CreateTab(Window, "PLAYER", 5)
local TabCar = UI.CreateTab(Window, "CAR", 6)
local TabMisc = UI.CreateTab(Window, "MISC", 7)

-- ESP
UI.CreateToggle(TabESP, "ESP Toggle", espEnabled, function(v) espEnabled = v; refreshESP() end)
UI.CreateToggle(TabESP, "ESP Highlight", espHighlightEnabled, function(v) espHighlightEnabled = v; refreshESP() end)
UI.CreateToggle(TabESP, "ESP Box", espBoxEnabled, function(v) espBoxEnabled = v; refreshESP() end)
UI.CreateToggle(TabESP, "ESP Tracer", espTracerEnabled, function(v) espTracerEnabled = v; refreshESP() end)
local colOpts = {}
for _, name in ipairs(boxColorNames) do table.insert(colOpts, {name = name, val = name}) end
UI.CreateDropdown(TabESP, "ESP Color", colOpts, boxColorIndex, function(Option)
    for i, n in ipairs(boxColorNames) do
        if n == Option then
            boxColorIndex = i; boxColor = boxColors[i]
            for _, lines in pairs(boxLines) do for _, l in pairs(lines) do l.Color = boxColor end end
            for _, l in pairs(tracerLines) do l.Color = boxColor end
            break
        end
    end
end)

-- AIMBOT (camera / mouse)
UI.CreateToggle(TabAim, "Aimbot Toggle", aimEnabled, function(v) aimEnabled = v; updateFOVCircle() end)
UI.CreateToggle(TabAim, "Wall Check", wallCheckEnabled, function(v) wallCheckEnabled = v end)
UI.CreateDropdown(TabAim, "Target Part", {
    {name = "Head", val = "Head"}, {name = "HumanoidRootPart", val = "HumanoidRootPart"},
}, aimPart == "Head" and 1 or 2, function(Option) aimPart = Option end)
UI.CreateDropdown(TabAim, "Aim Mode", {
    {name = "Camera", val = "Camera"}, {name = "Mouse", val = "Mouse"},
}, aimModePC == "Camera" and 1 or 2, function(Option) aimModePC = Option end)
UI.CreateSlider(TabAim, "Smoothness", 0.1, 1, smoothness, function(v) return string.format("%.2f", v) end, function(v) smoothness = v end)
UI.CreateSlider(TabAim, "FOV Size", 50, 500, fovSize, function(v) return tostring(math.floor(v)) end, function(v) fovSize = v; updateFOVCircle() end)
UI.CreateToggle(TabAim, "Center FOV", centerFovEnabled, function(v) centerFovEnabled = v end)
UI.CreateToggle(TabAim, "Predict Toggle", predEnabled, function(v) predEnabled = v end)
UI.CreateSlider(TabAim, "Predict Strength", 0, 0.3, predStrength, function(v) return string.format("%.3f", v) end, function(v) predStrength = v end)

-- SILENT
UI.CreateLabel(TabSilent, "Bullet redirect · OFF by default")
UI.CreateToggle(TabSilent, "Silent Aim", combat.SilentEnabled, function(v)
    combat.SilentEnabled = v; updateFOVCircle()
end)
UI.CreateToggle(TabSilent, "Silent FOV Limit", combat.SilentFovEnabled, function(v) combat.SilentFovEnabled = v end)
UI.CreateSlider(TabSilent, "Silent FOV", 50, 500, combat.SilentFov, function(v) return tostring(math.floor(v)) end, function(v)
    combat.SilentFov = v
end)
UI.CreateDropdown(TabSilent, "Silent Part", {
    {name = "Head", val = "Head"}, {name = "Torso", val = "Torso"}, {name = "HumanoidRootPart", val = "HumanoidRootPart"},
}, 1, function(Option) combat.SilentTarget = Option end)
UI.CreateToggle(TabSilent, "Exclude Teammates", combat.SilentExcludeTeammates, function(v)
    combat.SilentExcludeTeammates = v
end)

-- GUN
UI.CreateLabel(TabGun, "Weapon mods · OFF by default")
UI.CreateToggle(TabGun, "Low Recoil", combat.LowRecoil, function(v) combat.LowRecoil = v end)
UI.CreateSlider(TabGun, "Recoil Mult", 0, 1, combat.RecoilMult, function(v) return string.format("%.2f", v) end, function(v)
    combat.RecoilMult = v
end)
UI.CreateToggle(TabGun, "Low Spread", combat.LowSpread, function(v) combat.LowSpread = v end)
UI.CreateSlider(TabGun, "Spread Mult", 0, 1, combat.SpreadMult, function(v) return string.format("%.2f", v) end, function(v)
    combat.SpreadMult = v
end)
UI.CreateToggle(TabGun, "Instant Reload", combat.InstantReload, function(v) combat.InstantReload = v end)
UI.CreateToggle(TabGun, "Instant Bullet", combat.InstantBullet, function(v) combat.InstantBullet = v end)
UI.CreateToggle(TabGun, "No Bullet Drop", combat.NoBulletDrop, function(v) combat.NoBulletDrop = v end)
UI.CreateToggle(TabGun, "Instant ADS", combat.InstantADS, function(v) combat.InstantADS = v end)
UI.CreateToggle(TabGun, "No ADS Slowdown", combat.NoADSSlowdown, function(v) combat.NoADSSlowdown = v end)
UI.CreateToggle(TabGun, "Aim Anywhere", combat.AimAnywhere, function(v) combat.AimAnywhere = v end)
UI.CreateToggle(TabGun, "Instant Equip", combat.InstantEquip, function(v) combat.InstantEquip = v end)
UI.CreateToggle(TabGun, "Force Auto", combat.ForceAuto, function(v)
    combat.ForceAuto = v
    if v and not status.forceAuto then
        UI.Notify({Title = "Force Auto", Content = "FiremodeController not hooked.", Duration = 4})
    end
end)
UI.CreateToggle(TabGun, "Infinite Magazines", combat.InfiniteMags, function(v)
    combat.InfiniteMags = v
    if v then
        if not GetAmmoRemote then
            UI.Notify({Title = "Infinite Mags", Content = "GetAmmo remote missing.", Duration = 4})
        else
            UI.Notify({Title = "Infinite Mags", Content = "Place/keep AmmoBox under workspace.Ignore", Duration = 4})
        end
    end
end)

-- PLAYER
UI.CreateLabel(TabPlayer, "Character / utility · OFF by default")
UI.CreateToggle(TabPlayer, "Instant Heal", combat.InstantHeal, function(v)
    combat.InstantHeal = v
    if v and not status.heal then
        UI.Notify({Title = "Instant Heal", Content = "healLimb not found — equip bandage first.", Duration = 4})
    end
end)
UI.CreateToggle(TabPlayer, "Fast Revive", combat.FastRevive, function(v)
    combat.FastRevive = v
end)

-- CAR
UI.CreateLabel(TabCar, "Vehicle · OFF by default")
UI.CreateToggle(TabCar, "Drive Any Car", combat.DriveAnyCar, function(v)
    combat.DriveAnyCar = v
    if v and not status.drive then
        UI.Notify({Title = "Drive Any Car", Content = "CanEnterSeat not hooked.", Duration = 4})
    end
end)
UI.CreateToggle(TabCar, "Car Mods", combat.CarMods, function(v)
    combat.CarMods = v
    if v then
        task.spawn(function()
            pcall(applyCarMods)
            UI.Notify({Title = "Car Mods", Content = "Transmission patched (soft getgc).", Duration = 4})
        end)
    end
end)
UI.CreateToggle(TabCar, "Quick Enter/Exit", combat.QuickClimb, function(v)
    combat.QuickClimb = v
    if v and not status.quickClimb then
        UI.Notify({Title = "Quick Climb", Content = "GetAnimationLength not found.", Duration = 4})
    end
end)

-- MISC
UI.CreateButton(TabMisc, "Save Config", function()
    SaveConfig()
    UI.Notify({Title = "Saved", Content = "Settings saved.", Duration = 3})
end)
UI.CreateButton(TabMisc, "Rejoin", function()
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)
UI.CreateButton(TabMisc, "Server Hop", function()
    local servers = {}
    local ok, res = pcall(function()
        return HttpService:JSONDecode(game:HttpGetAsync(
            "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        ))
    end)
    if ok and res and res.data then
        for _, s in pairs(res.data) do
            if s.playing < s.maxPlayers and s.id ~= game.JobId then table.insert(servers, s.id) end
        end
        if #servers > 0 then TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)]) end
    end
end)
UI.CreateButton(TabMisc, "Unload Script", function()
    if getGenv()[scriptId] then getGenv()[scriptId]() end
end)
UI.CreateLabel(TabMisc, "ESP · Aim · Silent · Gun · Player · Car")

refreshESP()
