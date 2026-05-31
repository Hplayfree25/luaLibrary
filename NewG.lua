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
                                end
                                if fastBoltEnabled then
                                    if data.Cycle then data.Cycle = false end
                                    if data.clientCanFire == false then data.clientCanFire = true end
                                end
                            end)
                        end
                    end)
                end
            end)
            return oldEquip(data, action)
        end)))
    end
    
    if rawget(wm, "Cycle") then
        local oldCycle
        oldCycle = clonefunction(hookfunction(rawget(wm, "Cycle"), newcclosure(function(data, ...)
            if fastBoltEnabled then
                if type(data) == "table" then
                    data.Cycle = false
                    data.clientCanFire = true
                end
                return
            end
            return oldCycle(data, ...)
        end)))
    end

    if rawget(wm, "Action") then
        local oldAction
        oldAction = clonefunction(hookfunction(rawget(wm, "Action"), newcclosure(function(data, ...)
            if fastBoltEnabled then
                if type(data) == "table" then
                    data.Action = false
                    data.clientCanFire = true
                end
                return
            end
            return oldAction(data, ...)
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
local fovColorIndex = 1
local fovColors = {
    Color3.new(1,0,0), Color3.new(0,1,0), Color3.new(0,0,1),
    Color3.new(1,1,0), Color3.new(1,0,1), Color3.new(0,1,1),
    Color3.new(1,1,1)
}
local fovColorNames = {"Red","Green","Blue","Yellow","Pink","Cyan","White"}

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

local menuKey = Enum.KeyCode.LeftAlt
local isSettingMenuKey = false
local isSettingAimKey = false
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

local function createButton(parent, text, yPos, width)
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1, 0, 0, 38)
    container.BackgroundTransparency = 1
    
    local btn = Instance.new("TextButton", container)
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.Text = text
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.TextColor3 = Color3.fromRGB(240, 240, 240)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    btn.AutoButtonColor = false
    btn.ClipsDescendants = true
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = Color3.fromRGB(50, 50, 60)
    stroke.Thickness = 1

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 48)}):Play()
        TweenService:Create(stroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(0, 170, 255)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 35)}):Play()
        TweenService:Create(stroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(50, 50, 60)}):Play()
    end)
    
    btn.MouseButton1Down:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(25, 25, 30)}):Play()
    end)
    btn.MouseButton1Up:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(40, 40, 48)}):Play()
    end)

    return btn
end

local function createSlider(parent, label, minVal, maxVal, defaultValue, yPos, onChange)
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1, 0, 0, 50)
    container.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 6)
    
    local stroke = Instance.new("UIStroke", container)
    stroke.Color = Color3.fromRGB(50, 50, 60)
    stroke.Thickness = 1

    local labelObj = Instance.new("TextLabel", container)
    labelObj.Size = UDim2.new(1, -20, 0, 20)
    labelObj.Position = UDim2.new(0, 10, 0, 5)
    labelObj.BackgroundTransparency = 1
    labelObj.Text = label .. ": " .. defaultValue
    labelObj.Font = Enum.Font.Gotham
    labelObj.TextSize = 12
    labelObj.TextColor3 = Color3.fromRGB(200, 200, 200)
    labelObj.TextXAlignment = Enum.TextXAlignment.Left

    local sliderBg = Instance.new("Frame", container)
    sliderBg.Size = UDim2.new(1, -20, 0, 6)
    sliderBg.Position = UDim2.new(0, 10, 0, 32)
    sliderBg.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame", sliderBg)
    fill.Size = UDim2.new((defaultValue-minVal)/(maxVal-minVal), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame", sliderBg)
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new((defaultValue-minVal)/(maxVal-minVal), -7, 0.5, -7)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local dragging = false
    local value = defaultValue

    local function updateSlider(inp)
        local mousePos = UserInputService:GetMouseLocation()
        local sliderX = sliderBg.AbsolutePosition.X
        local rel = math.clamp(mousePos.X - sliderX, 0, sliderBg.AbsoluteSize.X)
        local newVal = minVal + (rel / sliderBg.AbsoluteSize.X) * (maxVal - minVal)
        newVal = math.floor(newVal * 10) / 10
        value = newVal
        
        TweenService:Create(fill, TweenInfo.new(0.1), {Size = UDim2.new((value-minVal)/(maxVal-minVal), 0, 1, 0)}):Play()
        TweenService:Create(knob, TweenInfo.new(0.1), {Position = UDim2.new((value-minVal)/(maxVal-minVal), -7, 0.5, -7)}):Play()
        
        labelObj.Text = label .. ": " .. value
        onChange(value)
    end

    local inputTrigger = Instance.new("TextButton", container)
    inputTrigger.Size = UDim2.new(1, 0, 1, 0)
    inputTrigger.BackgroundTransparency = 1
    inputTrigger.Text = ""

    inputTrigger.MouseButton1Down:Connect(function() 
        dragging = true 
        updateSlider({UserInputType = Enum.UserInputType.MouseMovement})
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(inp)
        end
    end)
    
    container.MouseEnter:Connect(function()
        TweenService:Create(stroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(0, 170, 255)}):Play()
    end)
    container.MouseLeave:Connect(function()
        TweenService:Create(stroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(50, 50, 60)}):Play()
    end)

    return labelObj
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
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
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
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
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
        local mousePos = UserInputService:GetMouseLocation()
        fovCircle.Position = Vector2.new(mousePos.X, mousePos.Y)
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

local function setupTracers()
    local cp = workspace:FindFirstChild("CosmeticProjectiles")
    if cp then
        cp.ChildAdded:Connect(function(child)
            if scriptUnloaded or not tracerEnabled then return end
            if not child:IsA("BasePart") then return end
            task.wait()
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Head") then
                if (child.Position - char.Head.Position).Magnitude < 15 then
                    local att0 = Instance.new("Attachment", child)
                    att0.Position = Vector3.new(0, 0, -0.5)
                    local att1 = Instance.new("Attachment", child)
                    att1.Position = Vector3.new(0, 0, 0.5)
                    local trail = Instance.new("Trail", child)
                    trail.Attachment0 = att0
                    trail.Attachment1 = att1
                    trail.Color = ColorSequence.new(Color3.new(1, 0.2, 0.2))
                    trail.FaceCamera = true
                    trail.Lifetime = 0.5
                    trail.MinLength = 0
                    trail.WidthScale = NumberSequence.new(0.3, 0)
                end
            end
        end)
    end
end
task.spawn(setupTracers)

updateFOVCircle()

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
   Name = "NMZ Hub",
   LoadingTitle = "NMZ",
   LoadingSubtitle = "by NMZ Team",
   ConfigurationSaving = { Enabled = false },
   Discord = { Enabled = false },
   KeySystem = false,
})

local TabESP = Window:CreateTab("ESP", nil)
local TabAim = Window:CreateTab("Aimbot", nil)
local TabSilent = Window:CreateTab("Silent Aim", nil)
local TabGun = Window:CreateTab("Gun Mods", nil)
local TabHitbox = Window:CreateTab("Hitbox", nil)
local TabMisc = Window:CreateTab("Misc", nil)

TabESP:CreateToggle({
    Name = "ESP Toggle",
    CurrentValue = espEnabled,
    Callback = function(Value)
        espEnabled = Value
        refreshESP()
    end
})
TabESP:CreateDropdown({
    Name = "ESP Mode",
    Options = {"Highlight", "Box"},
    CurrentOption = espMode,
    Callback = function(Option)
        espMode = Option[1] or Option
        refreshESP()
    end
})
TabESP:CreateDropdown({
    Name = "ESP Color",
    Options = boxColorNames,
    CurrentOption = "White",
    Callback = function(Option)
        local opt = Option[1] or Option
        for i, n in ipairs(boxColorNames) do
            if n == opt then
                boxColorIndex = i
                boxColor = boxColors[i]
                for plr, lines in pairs(boxLines) do for _, l in pairs(lines) do l.Color = boxColor end end
                break
            end
        end
    end
})

TabAim:CreateToggle({
    Name = "Aimbot Toggle",
    CurrentValue = aimEnabled,
    Callback = function(Value)
        aimEnabled = Value
        updateFOVCircle()
    end
})
TabAim:CreateDropdown({
    Name = "Target Part",
    Options = {"Head", "HumanoidRootPart"},
    CurrentOption = aimPart,
    Callback = function(Option)
        aimPart = Option[1] or Option
    end
})
TabAim:CreateDropdown({
    Name = "Aim Mode",
    Options = {"Camera", "Mouse"},
    CurrentOption = aimModePC,
    Callback = function(Option)
        aimModePC = Option[1] or Option
    end
})
TabAim:CreateSlider({
    Name = "Smoothness",
    Range = {0.1, 1},
    Increment = 0.1,
    CurrentValue = smoothness,
    Callback = function(Value)
        smoothness = Value
    end
})
TabAim:CreateSlider({
    Name = "FOV Size",
    Range = {50, 500},
    Increment = 10,
    CurrentValue = fovSize,
    Callback = function(Value)
        fovSize = Value
        updateFOVCircle()
    end
})

TabSilent:CreateToggle({
    Name = "Silent Aim Toggle",
    CurrentValue = silentAimEnabled,
    Callback = function(Value)
        silentAimEnabled = Value
    end
})
TabSilent:CreateSlider({
    Name = "Silent Max Distance",
    Range = {100, 3000},
    Increment = 50,
    CurrentValue = silentAimDistance,
    Callback = function(Value)
        silentAimDistance = Value
    end
})
TabSilent:CreateToggle({
    Name = "Predict Toggle",
    CurrentValue = predEnabled,
    Callback = function(Value)
        predEnabled = Value
    end
})
TabSilent:CreateSlider({
    Name = "Predict Strength",
    Range = {0, 0.3},
    Increment = 0.01,
    CurrentValue = predStrength,
    Callback = function(Value)
        predStrength = Value
    end
})
TabSilent:CreateToggle({
    Name = "Triggerbot",
    CurrentValue = triggerbotEnabled,
    Callback = function(Value)
        triggerbotEnabled = Value
    end
})
TabSilent:CreateToggle({
    Name = "Wall Check",
    CurrentValue = wallCheckEnabled,
    Callback = function(Value)
        wallCheckEnabled = Value
    end
})

TabGun:CreateToggle({
    Name = "No Recoil",
    CurrentValue = noRecoilEnabled,
    Callback = function(Value)
        noRecoilEnabled = Value
    end
})
TabGun:CreateToggle({
    Name = "No Spread",
    CurrentValue = noSpreadEnabled,
    Callback = function(Value)
        noSpreadEnabled = Value
    end
})
TabGun:CreateToggle({
    Name = "Fast Bolt",
    CurrentValue = fastBoltEnabled,
    Callback = function(Value)
        fastBoltEnabled = Value
    end
})

TabHitbox:CreateToggle({
    Name = "Hitbox Expander",
    CurrentValue = hitboxEnabled,
    Callback = function(Value)
        hitboxEnabled = Value
        if hitboxEnabled then applyHitboxToAll() else restoreAllHitboxes() end
    end
})
TabHitbox:CreateSlider({
    Name = "Hitbox Multiplier",
    Range = {1, 5},
    Increment = 0.1,
    CurrentValue = hitboxMultiplier,
    Callback = function(Value)
        hitboxMultiplier = Value
        if hitboxEnabled then applyHitboxToAll() end
    end
})

TabMisc:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = antiAfkEnabled,
    Callback = function(Value)
        antiAfkEnabled = Value
        toggleAntiAfk()
    end
})
TabMisc:CreateButton({
    Name = "Rejoin",
    Callback = function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
})
TabMisc:CreateButton({
    Name = "Server Hop",
    Callback = function()
        local servers = {}
        local success, res = pcall(function() return cloneref(game:GetService("HttpService")):JSONDecode(game:HttpGetAsync("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")) end)
        if success and res.data then
            for _, s in pairs(res.data) do
                if s.playing < s.maxPlayers and s.id ~= game.JobId then table.insert(servers, s.id) end
            end
            if #servers > 0 then TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1,#servers)]) end
        end
    end
})
TabMisc:CreateButton({
    Name = "Boost FPS (Smooth)",
    Callback = function()
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
    end
})
TabMisc:CreateButton({
    Name = "Unload Script",
    Callback = function()
        scriptUnloaded = true
        scriptUnloadedLocal = true
        Rayfield:Destroy()
        if fovCircle then fovCircle:Remove() fovCircle = nil end
        if predDot then predDot:Remove() predDot = nil end
        removeAllHighlights()
        removeAllBoxes()
        restoreAllHitboxes()
        if antiAfkConnection then antiAfkConnection:Disconnect(); antiAfkConnection = nil end
        if recoilThread then coroutine.close(recoilThread); recoilThread = nil end
        if reloadConn then reloadConn:Disconnect(); reloadConn = nil end
    end
})

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
                                                local spread = currentTool:GetAttribute("SpreadDefault") or 0
                                                return prediction + (prediction - LocalPlayer.Character.Head.Position).Unit * spread * 0.1
                                            end
                                        end
                                        return pos
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

print("MNZ ENTRENCHED WW1")