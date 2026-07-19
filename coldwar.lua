--[[
    Cold War Hub — ESP / Aimbot / Wall Check
    UI + aim logic aligned with NewG.lua (NMZ)
--]]

local cloneref = cloneref or function(i) return i end
local gethui = gethui or function()
    local ok, cg = pcall(game.GetService, game, "CoreGui")
    return ok and cg or nil
end

local Players = cloneref(game:GetService("Players"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local RunService = cloneref(game:GetService("RunService"))
local TeleportService = cloneref(game:GetService("TeleportService"))
local TweenService = cloneref(game:GetService("TweenService"))
local HttpService = cloneref(game:GetService("HttpService"))
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

local isMobile = UserInputService.TouchEnabled
local mobileAimHolding = false
local mobileAimGui, mobileAimBtn = nil, nil
local scriptUnloaded = false

-- ── state ──────────────────────────────────────────────────────────────────
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

-- ── config ─────────────────────────────────────────────────────────────────
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
            boxColor = boxColors[boxColorIndex] or Color3.new(1,1,1)
        end)
    end
end
LoadConfig()

-- ── FOV circle (GUI fallback, same as NewG) ────────────────────────────────
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
    fovFrame.Visible = aimEnabled
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

-- ── wall check (from NewG) ─────────────────────────────────────────────────
local PENETRABLE_KEYWORDS = {
    "bush", "leaf", "leaves", "foliage", "plant", "plants", "hedge", "shrub",
    "grass", "weed", "weeds", "flower", "fern", "vine", "ivy", "moss", "reed",
    "branch", "branches", "palm", "pine", "bamboo", "cactus",
    "vegetation", "flora", "canopy", "underbrush", "thicket", "shrubbery",
    "garden", "treeleaf", "treetop", "treetops", "crown", "tree", "trees",
    "spawn", "spawns", "respawn", "lobby", "safezone", "safe_zone", "safearea",
    "trigger", "sensor", "checkpoint", "killbrick", "invisible", "nocollide", "nocol",
    "sign", "signs", "billboard", "banner", "flag", "cloth", "curtain",
    "water", "pond", "lake", "river", "waterfall", "puddle",
    "glass", "window", "chainlink", "smoke", "fog", "cloud", "mist",
    "particle", "effect", "fx", "beam", "decal", "scenery", "clutter",
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
        if part.CanCollide == false then return true end
        if part.CanQuery == false then return true end

        local myChar = LocalPlayer.Character
        local myRoot = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChild("Torso") or myChar:FindFirstChild("UpperTorso"))
        if myRoot then
            local collidable = true
            local cgOk = pcall(function()
                local PhysicsService = game:GetService("PhysicsService")
                collidable = PhysicsService:CollisionGroupsAreCollidable(myRoot.CollisionGroup, part.CollisionGroup)
            end)
            if cgOk and collidable == false then return true end
        end

        if (part.Transparency or 0) >= 0.45 then return true end

        local softMats = {
            [Enum.Material.Leaves] = true,
            [Enum.Material.Grass] = true,
            [Enum.Material.Fabric] = true,
            [Enum.Material.ForceField] = true,
            [Enum.Material.Glass] = true,
            [Enum.Material.Foil] = true,
        }
        pcall(function() softMats[Enum.Material.LeafyGrass] = true end)
        if softMats[part.Material] then return true end

        local cg = part.CollisionGroup
        if type(cg) == "string" and cg ~= "" and cg ~= "Default" then
            local cgLower = string.lower(cg)
            for _, kw in ipairs({"foliage","decor","debris","nocollide","nocol","passthrough","transparent","ghost","prop","plant","bush","tree","spawn","effect"}) do
                if string.find(cgLower, kw, 1, true) then return true end
            end
        end

        if nameLooksPenetrable(part.Name) then return true end

        local parent, depth = part.Parent, 0
        while parent and parent ~= workspace and depth < 8 do
            if nameLooksPenetrable(parent.Name) then return true end
            parent = parent.Parent
            depth = depth + 1
        end

        local sx, sy, sz = part.Size.X, part.Size.Y, part.Size.Z
        local minDim = math.min(sx, sy, sz)
        local maxDim = math.max(sx, sy, sz)
        local midDim = sx + sy + sz - minDim - maxDim
        if minDim <= 0.35 and midDim >= 1.0 and maxDim >= 1.5 then return true end

        if part.Massless and (part.Transparency or 0) > 0 then return true end
        return false
    end)

    return ok and result == true
end

local function getPenetrableIgnoreTarget(part)
    if not part then return part end
    local inst, depth = part.Parent, 0
    while inst and inst ~= workspace and depth < 6 do
        if nameLooksPenetrable(inst.Name) then
            local isPlayer = false
            pcall(function()
                if inst:IsA("Model") then isPlayer = Players:GetPlayerFromCharacter(inst) ~= nil end
            end)
            if not isPlayer then return inst end
        end
        inst = inst.Parent
        depth = depth + 1
    end

    local model = part.Parent
    if model and model:IsA("Model") and model ~= workspace then
        local isPlayer = false
        pcall(function() isPlayer = Players:GetPlayerFromCharacter(model) ~= nil end)
        if not isPlayer and not model:FindFirstChildOfClass("Humanoid") then
            local parts, onlyFoliageLike = 0, true
            pcall(function()
                for _, d in ipairs(model:GetChildren()) do
                    if d:IsA("BasePart") then
                        parts = parts + 1
                        if d.CanCollide and d.Transparency < 0.45 and d.Material ~= Enum.Material.Leaves
                            and d.Material ~= Enum.Material.Grass and d.Material ~= Enum.Material.Glass
                            and d.Material ~= Enum.Material.Fabric and not nameLooksPenetrable(d.Name) then
                            local minD = math.min(d.Size.X, d.Size.Y, d.Size.Z)
                            if minD > 0.5 then onlyFoliageLike = false end
                        end
                        if parts > 25 then break end
                    end
                end
            end)
            if onlyFoliageLike and parts >= 2 and parts <= 25 then return model end
        end
    end
    return part
end

local function smartRaycast(origin, direction, ignoreListArray)
    local ignoreList = {}
    if ignoreListArray then
        for _, v in pairs(ignoreListArray) do table.insert(ignoreList, v) end
    end
    for _ = 1, 40 do
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        rayParams.FilterDescendantsInstances = ignoreList
        rayParams.IgnoreWater = true
        local hit = workspace:Raycast(origin, direction, rayParams)
        if not hit then return nil end
        local part = hit.Instance
        if isPenetratablePart(part) then
            local ignoreTarget = getPenetrableIgnoreTarget(part)
            table.insert(ignoreList, ignoreTarget)
            if ignoreTarget ~= part then table.insert(ignoreList, part) end
        else
            return hit
        end
    end
    return nil
end

local function isPointVisible(pos, char)
    local myChar = LocalPlayer.Character
    if not myChar then return false end
    local hit = smartRaycast(Camera.CFrame.Position, pos - Camera.CFrame.Position, {myChar, char, Camera})
    return hit == nil
end

local function getBestTargetPos(char)
    if not char then return nil end
    local head = char:FindFirstChild("Head")
    local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart")

    if not wallCheckEnabled then
        if aimPart == "Head" and head then return head.Position end
        if torso then return torso.Position end
        if head then return head.Position end
        return nil
    end

    if head and isPointVisible(head.Position, char) then return head.Position end
    if head then
        local headTop = head.Position + Vector3.new(0, head.Size.Y * 0.38, 0)
        if isPointVisible(headTop, char) then return headTop end
    end
    if torso and isPointVisible(torso.Position, char) then return torso.Position end
    return nil
end

local function isTargetVisible(target, targetPos)
    if not wallCheckEnabled then return true end
    if not target or not targetPos then return false end
    local char = target.Parent
    if not char then return false end
    return isPointVisible(targetPos, char)
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
    for _, lines in pairs(boxLines) do
        for _, line in pairs(lines) do line:Remove() end
    end
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
                line.Thickness = 2
                line.Color = boxColor
                line.Visible = false
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
            line.Thickness = 1.5
            line.Color = boxColor
            line.Visible = false
            tracerLines[plr] = line
        end
    end
end

local function updateESP()
    if not espEnabled then
        for _, lines in pairs(boxLines) do
            for _, line in pairs(lines) do line.Visible = false end
        end
        for _, line in pairs(tracerLines) do line.Visible = false end
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
                    local cx, cy = rPos.X, (hPos.Y + rPos.Y) / 2
                    local left, right = cx - width/2, cx + width/2
                    local top, bottom = cy - height/2, cy + height/2
                    lines[1].From = Vector2.new(left, top);    lines[1].To = Vector2.new(right, top)
                    lines[2].From = Vector2.new(right, top);   lines[2].To = Vector2.new(right, bottom)
                    lines[3].From = Vector2.new(right, bottom);lines[3].To = Vector2.new(left, bottom)
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
        if espEnabled and espHighlightEnabled then createHighlightForPlayer(plr) end
    end)
end
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if espEnabled and espHighlightEnabled then
        for _, plr in pairs(Players:GetPlayers()) do createHighlightForPlayer(plr) end
    end
end)

-- ── aimbot ─────────────────────────────────────────────────────────────────
local function getClosestEnemy()
    local center
    if centerFovEnabled then
        center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    else
        local mousePos = UserInputService:GetMouseLocation()
        center = Vector2.new(mousePos.X, mousePos.Y)
    end
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
        pcall(function() cloneref(game:GetService("VirtualInputManager")):SendMouseMovement(deltaX, deltaY, nil) end)
        pcall(function() mousemoverel(deltaX, deltaY) end)
    end
end

RunService.RenderStepped:Connect(function()
    if scriptUnloaded then return end

    if fovFrame and fovFrame.Visible then
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
    if not aimEnabled then
        updatePredDot(nil)
        return
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
            if vel then pos = pos + (vel * predStrength) end
        end
        if isTargetVisible(target, targetPos) then
            updatePredDot(pos)
            if keyPressed then
                if aimModePC == "Camera" then
                    cameraAim(target, targetPos)
                else
                    mouseAim(target, targetPos)
                end
            end
        else
            updatePredDot(nil)
        end
    else
        updatePredDot(nil)
    end
end)

-- ── UI (same library as NewG) ──────────────────────────────────────────────
local scriptId = "NMZ_COLDWAR_UI"
local getGenv = getgenv or function() return _G end
if getGenv()[scriptId] then pcall(getGenv()[scriptId]) end

local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Hplayfree25/luaLibrary/refs/heads/master/Init.lua?t=" .. tick()))()

local winSize = UDim2.new(0, 500, 0, 320)
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

task.spawn(function()
    task.wait(1)
    if isMobile then
        UI.Notify({
            Title = "UI Loaded",
            Content = "Tap 'CW' to open menu. Hold floating AIM button to aim.",
            Duration = 7,
        })
    else
        UI.Notify({
            Title = "UI Loaded",
            Content = "Press Left Alt to open/close the menu.",
            Duration = 7,
        })
    end
end)

if isMobile then
    mobileAimGui = Instance.new("ScreenGui")
    mobileAimGui.Name = "CW_MobileAim"
    mobileAimGui.ResetOnSpawn = false
    mobileAimGui.IgnoreGuiInset = true
    mobileAimGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function()
        if gethui then mobileAimGui.Parent = gethui() else mobileAimGui.Parent = game:GetService("CoreGui") end
    end)
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
    Instance.new("UICorner", mobileAimBtn).CornerRadius = UDim.new(1, 0)
    local aimStroke = Instance.new("UIStroke")
    aimStroke.Color = Color3.fromRGB(70, 130, 200)
    aimStroke.Thickness = 2
    aimStroke.Transparency = 0.2
    aimStroke.Parent = mobileAimBtn

    local dragging, dragStart, startPos = false, nil, nil
    local function pressAim()
        mobileAimHolding = true
        TweenService:Create(mobileAimBtn, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {
            BackgroundColor3 = Color3.fromRGB(70, 130, 200),
            TextColor3 = Color3.fromRGB(0, 0, 0),
        }):Play()
    end
    local function releaseAim()
        mobileAimHolding = false
        TweenService:Create(mobileAimBtn, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {
            BackgroundColor3 = Color3.fromRGB(20, 20, 24),
            TextColor3 = Color3.fromRGB(255, 255, 255),
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
    if Window then Window.destroy() end
    if guiFov then pcall(function() guiFov:Destroy() end) guiFov = nil end
    if guiPredDot then pcall(function() guiPredDot:Destroy() end) guiPredDot = nil end
    if mobileAimGui then pcall(function() mobileAimGui:Destroy() end) mobileAimGui = nil; mobileAimBtn = nil end
    removeAllHighlights()
    removeAllBoxes()
    removeAllTracers()
    getGenv()[scriptId] = nil
end

local TabESP = UI.CreateTab(Window, "ESP", 1)
local TabAim = UI.CreateTab(Window, "AIMBOT", 2)
local TabMisc = UI.CreateTab(Window, "MISC", 3)

-- ESP
UI.CreateToggle(TabESP, "ESP Toggle", espEnabled, function(v)
    espEnabled = v
    refreshESP()
end)
UI.CreateToggle(TabESP, "ESP Highlight", espHighlightEnabled, function(v)
    espHighlightEnabled = v
    refreshESP()
end)
UI.CreateToggle(TabESP, "ESP Box", espBoxEnabled, function(v)
    espBoxEnabled = v
    refreshESP()
end)
UI.CreateToggle(TabESP, "ESP Tracer", espTracerEnabled, function(v)
    espTracerEnabled = v
    refreshESP()
end)
local colOpts = {}
for _, name in ipairs(boxColorNames) do table.insert(colOpts, {name = name, val = name}) end
UI.CreateDropdown(TabESP, "ESP Color", colOpts, boxColorIndex, function(Option)
    for i, n in ipairs(boxColorNames) do
        if n == Option then
            boxColorIndex = i
            boxColor = boxColors[i]
            for _, lines in pairs(boxLines) do
                for _, l in pairs(lines) do l.Color = boxColor end
            end
            for _, l in pairs(tracerLines) do l.Color = boxColor end
            break
        end
    end
end)

-- Aimbot
UI.CreateToggle(TabAim, "Aimbot Toggle", aimEnabled, function(v)
    aimEnabled = v
    updateFOVCircle()
end)
UI.CreateToggle(TabAim, "Wall Check", wallCheckEnabled, function(v)
    wallCheckEnabled = v
end)
UI.CreateDropdown(TabAim, "Target Part", {
    {name = "Head", val = "Head"},
    {name = "HumanoidRootPart", val = "HumanoidRootPart"},
}, aimPart == "Head" and 1 or 2, function(Option)
    aimPart = Option
end)
UI.CreateDropdown(TabAim, "Aim Mode", {
    {name = "Camera", val = "Camera"},
    {name = "Mouse", val = "Mouse"},
}, aimModePC == "Camera" and 1 or 2, function(Option)
    aimModePC = Option
end)
UI.CreateSlider(TabAim, "Smoothness", 0.1, 1, smoothness, function(v)
    return string.format("%.2f", v)
end, function(v)
    smoothness = v
end)
UI.CreateSlider(TabAim, "FOV Size", 50, 500, fovSize, function(v)
    return tostring(math.floor(v))
end, function(v)
    fovSize = v
    updateFOVCircle()
end)
UI.CreateToggle(TabAim, "Center FOV", centerFovEnabled, function(v)
    centerFovEnabled = v
end)
UI.CreateToggle(TabAim, "Predict Toggle", predEnabled, function(v)
    predEnabled = v
end)
UI.CreateSlider(TabAim, "Predict Strength", 0, 0.3, predStrength, function(v)
    return string.format("%.3f", v)
end, function(v)
    predStrength = v
end)

-- Misc
UI.CreateButton(TabMisc, "Save Config", function()
    SaveConfig()
    UI.Notify({Title = "Config Saved", Content = "Settings saved locally.", Duration = 3})
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
    if ok and res.data then
        for _, s in pairs(res.data) do
            if s.playing < s.maxPlayers and s.id ~= game.JobId then
                table.insert(servers, s.id)
            end
        end
        if #servers > 0 then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)])
        end
    end
end)
UI.CreateButton(TabMisc, "Unload Script", function()
    if getGenv()[scriptId] then getGenv()[scriptId]() end
end)
UI.CreateLabel(TabMisc, "Cold War · ESP / Aimbot / Wall Check")

refreshESP()
