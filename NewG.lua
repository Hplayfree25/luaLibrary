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
local cloneref = cloneref or function(i: Instance) return i; end;
local clonefunction = clonefunction or function(f: (...any) -> (...any)) return f; end;
local newcclosure = newcclosure or clonefunction;
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

if getconnections then
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
local silentAimEnabled = true

local recoilThread = nil
local currentVelocity = nil
local currentTool = nil
local reloadConn = nil
local scriptUnloadedLocal = false

local success, wm = pcall(require, ReplicatedStorage:WaitForChild("WeaponModule", 5))
if success and wm and type(wm) == "table" then
    if rawget(wm, "Equip") then
        local oldEquip
        oldEquip = clonefunction(hookfunction(rawget(wm, "Equip"), newcclosure(function(data, action)
            pcall(function()
                if recoilThread then coroutine.close(recoilThread); recoilThread = nil end
                if reloadConn then reloadConn:Disconnect(); reloadConn = nil end

                if type(action) == "string" and action == "Equip" and type(data) == "table" and data.Tool then
                    currentTool = data.Tool
                    currentVelocity = data.Tool:GetAttribute("Velocity") or 500

                    if noRecoilEnabled then data.Tool:SetAttribute("Recoil", 0) end
                    if noSpreadEnabled then
                        data.Tool:SetAttribute("Spread", 0)
                        data.Tool:SetAttribute("SpreadDefault", 0)
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
                                    data.Tool:SetAttribute("SpreadDefault", 0)
                                    data.Tool:SetAttribute("MinSpread", 0)
                                    data.Tool:SetAttribute("MaxSpread", 0)
                                    local b = data.Tool:FindFirstChild("Bloom")
                                    if b then b:Destroy() end
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
        end)))
    end

    if rawget(wm, "Cycle") or rawget(wm, "boltCycleAction") then
        local targetFunc = rawget(wm, "boltCycleAction") or rawget(wm, "Cycle")
        local oldCycle
        oldCycle = clonefunction(hookfunction(targetFunc, newcclosure(function(data, ...)
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
        end)))
    end

    LocalPlayer.CharacterAdded:Connect(function()
        pcall(function()
            if recoilThread then coroutine.close(recoilThread); recoilThread = nil end
            if reloadConn then reloadConn:Disconnect(); reloadConn = nil end
        end)
    end)
end

local espEnabled = true
local espMode = "Highlight"
local boxColor = Color3.new(1,1,1)
local boxColorIndex = 1
local boxColors = {
    Color3.new(1,1,1), Color3.new(1,0,0), Color3.new(0,1,0),
    Color3.new(0,0,1), Color3.new(1,1,0), Color3.new(1,0,1),
    Color3.new(0,1,1)
}
local boxColorNames = {"White","Red","Green","Blue","Yellow","Pink","Cyan"}

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

local hitboxEnabled = false
local hitboxMultiplier = 2.0
local originalSizes = {}

local antiAfkEnabled = false
local antiAfkConnection = nil
local boostFpsEnabled = false

local scriptUnloaded = false

local fovCircle = nil
local function updateFOVCircle()
    if Drawing and Drawing.new then
        if not fovCircle then
            fovCircle = Drawing.new("Circle")
            fovCircle.NumSides = 64
        end
        fovCircle.Radius = fovSize
        fovCircle.Thickness = 2
        fovCircle.Color = fovColor
        fovCircle.Visible = aimEnabled
    else
        if fovCircle then fovCircle.Visible = false end
    end
end
if fovCircle then fovCircle:Remove() fovCircle = nil end

local predDot = nil
local function updatePredDot(pos)
    if Drawing and Drawing.new then
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
        if predDot then predDot.Visible = false end
    end
end
if predDot then predDot:Remove() predDot = nil end

local function isPointVisible(pos, char)
    local rayIgnore = {LocalPlayer.Character, char}
    local obscuring = Camera:GetPartsObscuringTarget({pos}, rayIgnore)
    for _, part in pairs(obscuring) do
        if part.CanCollide and part.Transparency < 0.9 then
            return false
        end
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
    local lines = {}
    for i=1,4 do
        lines[i] = Drawing.new("Line")
        lines[i].Thickness = 2
        lines[i].Color = boxColor
        lines[i].Visible = false
    end
    boxLines[plr] = lines
end
local function updateBoxes()
    if not espEnabled or espMode ~= "Box" then
        for _, lines in pairs(boxLines) do
            for _, line in pairs(lines) do line.Visible = false end
        end
        return
    end
    for _, plr in pairs(Players:GetPlayers()) do
        local isEnemy = plr ~= LocalPlayer and (not LocalPlayer.Team or plr.Team ~= LocalPlayer.Team)
        if isEnemy and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("Head") then
            createBoxLinesForPlayer(plr)
            local root = plr.Character.HumanoidRootPart
            local head = plr.Character.Head
            local rPos, rVis = Camera:WorldToViewportPoint(root.Position)
            local hPos, hVis = Camera:WorldToViewportPoint(head.Position)
            if rVis and hVis then
                local height = math.abs(hPos.Y - rPos.Y) * 2.2
                local width = height * 0.7
                local cx = rPos.X
                local cy = (hPos.Y + rPos.Y)/2
                local left = cx - width/2
                local right = cx + width/2
                local top = cy - height/2
                local bottom = cy + height/2
                local lines = boxLines[plr]
                lines[1].From = Vector2.new(left, top); lines[1].To = Vector2.new(right, top)
                lines[2].From = Vector2.new(right, top); lines[2].To = Vector2.new(right, bottom)
                lines[3].From = Vector2.new(right, bottom); lines[3].To = Vector2.new(left, bottom)
                lines[4].From = Vector2.new(left, bottom); lines[4].To = Vector2.new(left, top)
                for _, line in pairs(lines) do line.Color = boxColor; line.Visible = true end
            else
                if boxLines[plr] then for _, line in pairs(boxLines[plr]) do line.Visible = false end end
            end
        else
            if boxLines[plr] then for _, line in pairs(boxLines[plr]) do line.Visible = false end end
        end
    end
end
local function refreshESP()
    if not espEnabled then
        removeAllHighlights()
        removeAllBoxes()
        return
    end
    if espMode == "Highlight" then
        removeAllBoxes()
        for _, plr in pairs(Players:GetPlayers()) do
            createHighlightForPlayer(plr)
        end
    else
        removeAllHighlights()
    end
end

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(0.5)
        if espEnabled and espMode == "Highlight" then
            createHighlightForPlayer(plr)
        end
    end)
end)
Players.PlayerRemoving:Connect(function(plr)
    if boxLines[plr] then
        for _, line in pairs(boxLines[plr]) do line:Remove() end
        boxLines[plr] = nil
    end
end)
for _, plr in pairs(Players:GetPlayers()) do
    if plr.Character then
        plr.CharacterAdded:Connect(function()
            task.wait(0.5)
            if espEnabled and espMode == "Highlight" then
                createHighlightForPlayer(plr)
            end
        end)
    end
end
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if espEnabled and espMode == "Highlight" then
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
                local targetPos = getBestTargetPos(char)
                if targetPos then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(targetPos)
                    if onScreen then
                        local dist = (center - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                        if dist < closestDist then
                            closestDist = dist
                            closest = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
                            bestPos = targetPos
                        end
                    end
                end
            end
        end
    end
    return closest, bestPos
end

local function getClosestSilentEnemy()
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
    local myChar = LocalPlayer.Character
    local myPos = myChar and myChar:FindFirstChild("HumanoidRootPart") and myChar.HumanoidRootPart.Position
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 and (not LocalPlayer.Team or plr.Team ~= LocalPlayer.Team) then
                local char = plr.Character
                local targetPos = getBestTargetPos(char)
                if targetPos then
                    local physicalDist = myPos and (targetPos - myPos).Magnitude or 0
                    if physicalDist <= silentAimDistance then
                        local screenPos, onScreen = Camera:WorldToViewportPoint(targetPos)
                        if onScreen then
                            local dist = (center - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                            if dist < closestDist then
                                closestDist = dist
                                closest = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
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
            task.wait(0.01)
            vim:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
        end)
    end)
end
RunService.RenderStepped:Connect(function()
    if scriptUnloaded then return end

    if fovCircle and fovCircle.Visible then
        if centerFovEnabled then
            fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        else
            local mousePos = UserInputService:GetMouseLocation()
            fovCircle.Position = Vector2.new(mousePos.X, mousePos.Y)
        end
    end

    updateBoxes()
    if not aimEnabled and not triggerbotEnabled then 
        updatePredDot(nil)
        return 
    end

    if triggerbotEnabled and tick() - lastTriggerTime > triggerCooldown then
        local mouseTarget = Mouse.Target
        if mouseTarget then
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.Health > 0 and (not LocalPlayer.Team or plr.Team ~= LocalPlayer.Team) then
                        if mouseTarget:IsDescendantOf(plr.Character) then
                            lastTriggerTime = tick()
                            fireClick()
                            break
                        end
                    end
                end
            end
        end
    end

    local keyPressed = false
    if aimKey.EnumType == Enum.UserInputType then
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

local Window = UI.CreateWindow({
    Title = "NMZ Hub",
    ToggleText = "NMZ",
    Size = UDim2.new(0, 500, 0, 320)
})

getGenv()[scriptId] = function()
    scriptUnloaded = true
    scriptUnloadedLocal = true
    if Window then Window.destroy() end
    if fovCircle then fovCircle:Remove() fovCircle = nil end
    if predDot then predDot:Remove() predDot = nil end
    removeAllHighlights()
    removeAllBoxes()
    restoreAllHitboxes()
    if antiAfkConnection then antiAfkConnection:Disconnect(); antiAfkConnection = nil end
    if recoilThread then coroutine.close(recoilThread); recoilThread = nil end
    if reloadConn then reloadConn:Disconnect(); reloadConn = nil end
    getGenv()[scriptId] = nil
end

local TabESP = UI.CreateTab(Window, "ESP", 1)
local TabAim = UI.CreateTab(Window, "AIMBOT", 2)
local TabSilent = UI.CreateTab(Window, "SILENT AIM", 3)
local TabGun = UI.CreateTab(Window, "GUN MODS", 4)
local TabHitbox = UI.CreateTab(Window, "HITBOX", 5)
local TabMisc = UI.CreateTab(Window, "MISC", 6)

UI.CreateToggle(TabESP, "ESP Toggle", espEnabled, function(Value)
    espEnabled = Value
    refreshESP()
end)
UI.CreateDropdown(TabESP, "ESP Mode", {{name="Highlight",val="Highlight"},{name="Box",val="Box"}}, 1, function(Option)
    espMode = Option
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

UI.CreateToggle(TabSilent, "Silent Aim Toggle", silentAimEnabled, function(Value)
    silentAimEnabled = Value
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

UI.CreateToggle(TabGun, "No Recoil", noRecoilEnabled, function(Value)
    noRecoilEnabled = Value
end)
UI.CreateToggle(TabGun, "No Spread", noSpreadEnabled, function(Value)
    noSpreadEnabled = Value
end)
UI.CreateToggle(TabGun, "Fast Bolt", fastBoltEnabled, function(Value)
    fastBoltEnabled = Value
end)



UI.CreateToggle(TabHitbox, "Hitbox Expander", hitboxEnabled, function(Value)
    hitboxEnabled = Value
    if hitboxEnabled then applyHitboxToAll() else restoreAllHitboxes() end
end)
UI.CreateSlider(TabHitbox, "Hitbox Multiplier", 1, 5, hitboxMultiplier, function(v) return string.format("%.1f", v) end, function(Value)
    hitboxMultiplier = Value
    if hitboxEnabled then applyHitboxToAll() end
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
UI.CreateButton(TabMisc, "Boost FPS (Smooth)", function()
    if boostFpsEnabled then return end
    boostFpsEnabled = true
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
UI.CreateButton(TabMisc, "Unload Script", function()
    if getGenv()[scriptId] then getGenv()[scriptId]() end
end)

refreshESP()

if success and wm and type(wm) == "table" and rawget(wm, "Shoot") then
    pcall(function()
        local anon = debug.getupvalue(rawget(wm, "Shoot"), 3)
        if not anon or typeof(anon) ~= "function" then
            for _, v in pairs(debug.getupvalues(rawget(wm, "Shoot"))) do
                if type(v) == "function" then
                    anon = v
                    break
                end
            end
        end
        if anon then
            for k, v in pairs(getfenv(anon)) do
                if type(v) == "function" then
                    local n = debug.info(v, "n")
                    if n == "Crosshair" or n == "bulletMagnetism" then
                        local oldShootFn
                        oldShootFn = clonefunction(hookfunction(rawget(getfenv(anon), k), newcclosure(function(...)
                            if silentAimEnabled then
                                local ok, res = pcall(function()
                                    local c, _ = getClosestSilentEnemy()
                                    if c and currentVelocity and currentTool and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") then
                                        local pos = c.Position
                                        local tVel = c.AssemblyLinearVelocity or c.Velocity or Vector3.new()
                                        
                                        local r = pos - LocalPlayer.Character.Head.Position
                                        local vVec = tVel - (LocalPlayer.Character.Head.AssemblyLinearVelocity or LocalPlayer.Character.Head.Velocity or Vector3.new())
                                        
                                        local a = vVec:Dot(vVec) - currentVelocity * currentVelocity
                                        local b = 2 * r:Dot(vVec)
                                        local c0 = r:Dot(r)
                                        
                                        local disc = b * b - 4 * a * c0
                                        if disc >= 0 then
                                            local sqrtDisc = math.sqrt(disc)
                                            local t1 = (-b - sqrtDisc) / (2 * a)
                                            local t2 = (-b + sqrtDisc) / (2 * a)
                                            
                                            local tVal
                                            if t1 > 0 and t2 > 0 then
                                                tVal = math.min(t1, t2)
                                            elseif t1 > 0 then
                                                tVal = t1
                                            elseif t2 > 0 then
                                                tVal = t2
                                            end
                                            
                                            if tVal then
                                                local prediction = pos + tVel * tVal
                                                return prediction
                                            end
                                        end
                                        return pos
                                    end
                                end)
                                if ok and res then return res end
                            end
                            
                            if noSpreadEnabled then
                                local ok, res = pcall(function()
                                    local mouse = LocalPlayer:GetMouse()
                                    local rayParams = RaycastParams.new()
                                    rayParams.FilterType = Enum.RaycastFilterType.Exclude
                                    if LocalPlayer.Character then
                                        rayParams.FilterDescendantsInstances = {LocalPlayer.Character, workspace.CurrentCamera}
                                    else
                                        rayParams.FilterDescendantsInstances = {workspace.CurrentCamera}
                                    end
                                    
                                    local cam = workspace.CurrentCamera
                                    local ray = cam:ScreenPointToRay(mouse.X, mouse.Y)
                                    local hit = workspace:Raycast(ray.Origin, ray.Direction * 3000, rayParams)
                                    
                                    if hit then
                                        return hit.Position
                                    else
                                        return ray.Origin + ray.Direction * 3000
                                    end
                                end)
                                if ok and res then return res end
                            end
                            
                            return oldShootFn(...)
                        end)))
                    end
                end
            end
        end
    end)
end

print("MNZ ENTRENCHED WW1 - SCC UI LOADED")