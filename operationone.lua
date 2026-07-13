local isExecSupp = true
if type(hookfunction) ~= "function" then
    isExecSupp = false
end
local execName = (identifyexecutor or getexecutorname or function() return "" end)()
local isVelOrSim = false
if string.find(string.lower(execName), "velocity") or string.find(string.lower(execName), "solara") or string.find(string.lower(execName), "xeno") then
    isExecSupp = false
    isVelOrSim = true
end

local cloneref = cloneref or function(i: Instance) return i; end;
local clonefunction = clonefunction or function(f: (...any) -> (...any)) return f; end;
local newcclosure = newcclosure or clonefunction;
local hookfunction = hookfunction or function(old, new) return old end;
local gethui = gethui or function()
    local success, coregui = pcall(game.GetService, game, "CoreGui")
    return success and coregui or nil
end;

local pGui = (gethui and gethui()) or cloneref(game:GetService("CoreGui")) or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

local Plrs = cloneref(game:GetService("Players"))
local UIS = cloneref(game:GetService("UserInputService"))
local RunS = cloneref(game:GetService("RunService"))
local TeleportS = cloneref(game:GetService("TeleportService"))
local LocalPlr = Plrs.LocalPlayer
local Cam = workspace.CurrentCamera
local Mouse = LocalPlr:GetMouse()
local RepS = cloneref(game:GetService("ReplicatedStorage"))

if getconnections and not isVelOrSim then
    for _, c in pairs(getconnections(game:GetService("ScriptContext").Error)) do
        if type(c) == "table" and c.Disable then pcall(c.Disable, c) end
    end
    for _, c in pairs(getconnections(game:GetService("LogService").MessageOut)) do
        if type(c) == "table" and c.Disable then pcall(c.Disable, c) end
    end
end

local espEn = true
local espHlEn = true
local espBxEn = false
local espTrEn = false
local boxCol = Color3.new(1, 1, 1)
local colIdx = 1
local colList = {
    Color3.new(1, 1, 1), Color3.new(1, 0, 0), Color3.new(0, 1, 0),
    Color3.new(0, 0, 1), Color3.new(1, 1, 0), Color3.new(1, 0, 1),
    Color3.new(0, 1, 1)
}
local colNames = {"White", "Red", "Green", "Blue", "Yellow", "Pink", "Cyan"}
local trLines = {}
local bxLines = {}

local aimEn = true
local aimKey = Enum.UserInputType.MouseButton2
local aimPart = "Head"
local fovSz = 150
local fovCol = Color3.new(1, 0, 0)
local cntrFov = true

local silentEn = false
local silentDist = 1000

local smoothness = 0.3
local aimModePC = "Camera"
local predEn = true
local predStr = 0.135
local trigEn = false
local wallChEn = true
local trigCd = 0.05
local lastTrig = 0
local isBolt = true
local isHoldTrig = false

local scrUnloaded = false
local cfgFile = "NMZ_Config.json"
local HttpS = cloneref(game:GetService("HttpService"))

local currVel = nil
local currTool = nil

local function saveCfg()
    local cfg = {
        espEn = espEn,
        espHlEn = espHlEn,
        espBxEn = espBxEn,
        espTrEn = espTrEn,
        colIdx = colIdx,
        aimEn = aimEn,
        aimPart = aimPart,
        fovSz = fovSz,
        cntrFov = cntrFov,
        smoothness = smoothness,
        silentEn = silentEn,
        silentDist = silentDist,
        predEn = predEn,
        predStr = predStr,
        trigEn = trigEn,
        wallChEn = wallChEn
    }
    if writefile then
        pcall(function()
            writefile(cfgFile, HttpS:JSONEncode(cfg))
        end)
    end
end

local function loadCfg()
    if isfile and readfile and isfile(cfgFile) then
        pcall(function()
            local dec = HttpS:JSONDecode(readfile(cfgFile))
            if dec then
                if dec.espEn ~= nil then espEn = dec.espEn end
                if dec.espHlEn ~= nil then espHlEn = dec.espHlEn end
                if dec.espBxEn ~= nil then espBxEn = dec.espBxEn end
                if dec.espTrEn ~= nil then espTrEn = dec.espTrEn end
                if dec.colIdx ~= nil then colIdx = dec.colIdx end
                if dec.aimEn ~= nil then aimEn = dec.aimEn end
                if dec.aimPart ~= nil then aimPart = dec.aimPart end
                if dec.fovSz ~= nil then fovSz = dec.fovSz end
                if dec.cntrFov ~= nil then cntrFov = dec.cntrFov end
                if dec.smoothness ~= nil then smoothness = dec.smoothness end
                if dec.silentEn ~= nil then silentEn = dec.silentEn end
                if dec.silentDist ~= nil then silentDist = dec.silentDist end
                if dec.predEn ~= nil then predEn = dec.predEn end
                if dec.predStr ~= nil then predStr = dec.predStr end
                if dec.trigEn ~= nil then trigEn = dec.trigEn end
                if dec.wallChEn ~= nil then wallChEn = dec.wallChEn end
                
                boxCol = colList[colIdx] or Color3.new(1, 1, 1)
            end
        end)
    end
end
loadCfg()

local guiFov = nil
local fovFrame = nil

local function updFov()
    if not guiFov then
        guiFov = Instance.new("ScreenGui")
        guiFov.Name = "NMZ_FOV"
        guiFov.ResetOnSpawn = false
        guiFov.IgnoreGuiInset = true
        local parent = LocalPlr:WaitForChild("PlayerGui")
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
        stroke.Color = fovCol
        stroke.Thickness = 2
        stroke.Parent = fovFrame
    end
    fovFrame.Size = UDim2.new(0, fovSz * 2, 0, fovSz * 2)
    local str = fovFrame:FindFirstChildOfClass("UIStroke")
    if str then str.Color = fovCol end
    fovFrame.Visible = aimEn
end
updFov()

local guiPred = nil
local predFrame = nil

local function updPred(pos)
    if not guiPred then
        guiPred = Instance.new("ScreenGui")
        guiPred.Name = "NMZ_PredDot"
        guiPred.ResetOnSpawn = false
        guiPred.IgnoreGuiInset = true
        local parent = LocalPlr:WaitForChild("PlayerGui")
        pcall(function() if gethui then parent = gethui() else parent = game:GetService("CoreGui") end end)
        if parent:FindFirstChild("NMZ_PredDot") then parent.NMZ_PredDot:Destroy() end
        guiPred.Parent = parent
        
        predFrame = Instance.new("Frame")
        predFrame.Parent = guiPred
        predFrame.Size = UDim2.new(0, 4, 0, 4)
        predFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        predFrame.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        predFrame.BorderSizePixel = 0
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = predFrame
    end
    if pos then
        local sPos, onScr = Cam:WorldToViewportPoint(pos)
        if onScr then
            predFrame.Position = UDim2.new(0, sPos.X, 0, sPos.Y)
            predFrame.Visible = true
            return
        end
    end
    if predFrame then predFrame.Visible = false end
end

local function smartRaycast(orig, dir, ignore)
    local list = {}
    if ignore then for _, v in pairs(ignore) do table.insert(list, v) end end
    local maxC = 15
    
    for i = 1, maxC do
        local p = RaycastParams.new()
        p.FilterType = Enum.RaycastFilterType.Exclude
        p.FilterDescendantsInstances = list
        p.IgnoreWater = true
        
        local hit = workspace:Raycast(orig, dir, p)
        if not hit then return nil end
        
        local part = hit.Instance
        local isPen = false
        pcall(function()
            local name = (part.Name or ""):lower()
            if part.Transparency >= 0.9 or not part.CanCollide then isPen = true end
            local mat = part.Material
            if mat == Enum.Material.Leaves or mat == Enum.Material.Fabric or mat == Enum.Material.ForceField then isPen = true end
            if name:match("bush") or name:match("leaf") or name:match("tree") or name:match("spawn") or name:match("sign") or name:match("grass") or name:match("water") then
                isPen = true
            end
        end)
        
        if isPen then
            table.insert(list, part)
        else
            return hit
        end
    end
    return nil
end

local function isPtVis(pos, char)
    local myChar = LocalPlr.Character
    if not myChar then return false end
    
    local orig = Cam.CFrame.Position
    local dir = pos - orig
    
    local hit = smartRaycast(orig, dir, {myChar, char, Cam})
    if hit then
        return false
    end
    return true
end

local function getBestTargetPos(char)
    if not char then return nil end
    local head = char:FindFirstChild("Head")
    local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart")
    
    if not wallChEn then
        if aimPart == "Head" and head then
            return head.Position
        elseif torso then
            return torso.Position
        elseif head then
            return head.Position
        end
        return nil
    end
    
    if head and isPtVis(head.Position, char) then
        return head.Position
    end
    
    if head then
        local headTop = head.Position + Vector3.new(0, head.Size.Y * 0.38, 0)
        if isPtVis(headTop, char) then
            return headTop
        end
    end
    
    if torso and isPtVis(torso.Position, char) then
        return torso.Position
    end
    
    return nil
end

local function isTargVis(targ, targPos)
    if not wallChEn then return true end
    if not targ or not targPos then return false end
    local char = targ.Parent
    if not char then return false end
    return isPtVis(targPos, char)
end

local function remHl()
    for _, plr in pairs(Plrs:GetPlayers()) do
        if plr.Character then
            local hl = plr.Character:FindFirstChildOfClass("Highlight")
            if hl then hl:Destroy() end
        end
    end
end

local function remBx()
    for plr, lines in pairs(bxLines) do
        for _, l in pairs(lines) do pcall(function() l:Remove() end) end
    end
    bxLines = {}
end

local function remTr()
    for plr, l in pairs(trLines) do
        pcall(function() l:Remove() end)
    end
    trLines = {}
end

local function createHl(plr)
    if plr == LocalPlr then return end
    if not plr.Character then return end
    local old = plr.Character:FindFirstChildOfClass("Highlight")
    if old then old:Destroy() end
    local hl = Instance.new("Highlight")
    hl.Parent = plr.Character
    hl.FillTransparency = 0.6
    hl.OutlineTransparency = 0.2
    if plr.Team == LocalPlr.Team then
        hl.FillColor = Color3.fromRGB(0, 100, 255)
        hl.OutlineColor = Color3.fromRGB(0, 200, 255)
    else
        hl.FillColor = Color3.fromRGB(255, 50, 50)
        hl.OutlineColor = Color3.fromRGB(255, 150, 150)
    end
end

local function createBx(plr)
    if bxLines[plr] then return end
    if type(Drawing) == "table" and type(Drawing.new) == "function" then
        local lines = {}
        for i = 1, 4 do
            local success, line = pcall(Drawing.new, "Line")
            if success and line then
                line.Thickness = 2
                line.Color = boxCol
                line.Visible = false
                table.insert(lines, line)
            end
        end
        if #lines == 4 then
            bxLines[plr] = lines
        end
    end
end

local function createTr(plr)
    if trLines[plr] then return end
    if type(Drawing) == "table" and type(Drawing.new) == "function" then
        local success, line = pcall(Drawing.new, "Line")
        if success and line then
            line.Thickness = 1.5
            line.Color = boxCol
            line.Visible = false
            trLines[plr] = line
        end
    end
end

local function updEsp()
    if not espEn then
        for _, lines in pairs(bxLines) do
            for _, l in pairs(lines) do l.Visible = false end
        end
        for _, l in pairs(trLines) do
            l.Visible = false
        end
        return
    end
    for _, plr in pairs(Plrs:GetPlayers()) do
        local isEnemy = plr ~= LocalPlr and (not LocalPlr.Team or plr.Team ~= LocalPlr.Team)
        if isEnemy and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("Head") then
            local root = plr.Character.HumanoidRootPart
            local head = plr.Character.Head
            local rPos, rVis = Cam:WorldToViewportPoint(root.Position)
            local hPos, hVis = Cam:WorldToViewportPoint(head.Position)
            if espBxEn and rVis and hVis then
                createBx(plr)
                local lines = bxLines[plr]
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
                    for _, l in pairs(lines) do l.Color = boxCol; l.Visible = true end
                end
            else
                if bxLines[plr] then for _, l in pairs(bxLines[plr]) do l.Visible = false end end
            end
            if espTrEn and rVis then
                createTr(plr)
                local line = trLines[plr]
                if line then
                    line.From = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y)
                    line.To = Vector2.new(rPos.X, rPos.Y)
                    line.Color = boxCol
                    line.Visible = true
                end
            else
                if trLines[plr] then trLines[plr].Visible = false end
            end
        else
            if bxLines[plr] then for _, l in pairs(bxLines[plr]) do l.Visible = false end end
            if trLines[plr] then trLines[plr].Visible = false end
        end
    end
end

local function refreshEsp()
    if not espEn then
        remHl()
        remBx()
        remTr()
        return
    end
    if espHlEn then
        for _, plr in pairs(Plrs:GetPlayers()) do
            createHl(plr)
        end
    else
        remHl()
    end
    if not espBxEn then
        remBx()
    end
    if not espTrEn then
        remTr()
    end
end

Plrs.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(0.5)
        if espEn and espHlEn then
            createHl(plr)
        end
    end)
end)
Plrs.PlayerRemoving:Connect(function(plr)
    if bxLines[plr] then
        for _, l in pairs(bxLines[plr]) do pcall(function() l:Remove() end) end
        bxLines[plr] = nil
    end
    if trLines[plr] then
        pcall(function() trLines[plr]:Remove() end)
        trLines[plr] = nil
    end
end)
for _, plr in pairs(Plrs:GetPlayers()) do
    plr.CharacterAdded:Connect(function()
        task.wait(0.5)
        if espEn and espHlEn then
            createHl(plr)
        end
    end)
end
LocalPlr.CharacterAdded:Connect(function()
    task.wait(1)
    if espEn and espHlEn then
        for _, plr in pairs(Plrs:GetPlayers()) do
            createHl(plr)
        end
    end
end)

local function getClosestEnemy()
    local center
    if cntrFov then
        center = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y/2)
    else
        local mousePos = UIS:GetMouseLocation()
        center = Vector2.new(mousePos.X, mousePos.Y)
    end
    local closest = nil
    local closestDist = fovSz
    local bestPos = nil
    for _, plr in pairs(Plrs:GetPlayers()) do
        if plr ~= LocalPlr and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 and (not LocalPlr.Team or plr.Team ~= LocalPlr.Team) then
                local char = plr.Character
                local part = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
                if part then
                    local sPos, onScr = Cam:WorldToViewportPoint(part.Position)
                    if onScr then
                        local dist = (center - Vector2.new(sPos.X, sPos.Y)).Magnitude
                        if dist < closestDist then
                            local targPos = getBestTargetPos(char)
                            if targPos then
                                closestDist = dist
                                closest = part
                                bestPos = targPos
                            end
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
    if cntrFov then
        center = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y/2)
    else
        local mousePos = UIS:GetMouseLocation()
        center = Vector2.new(mousePos.X, mousePos.Y)
    end
    local closest = nil
    local closestDist = fovSz
    local bestPos = nil
    local myChar = LocalPlr.Character
    local myPos = myChar and myChar:FindFirstChild("HumanoidRootPart") and myChar.HumanoidRootPart.Position
    for _, plr in pairs(Plrs:GetPlayers()) do
        if plr ~= LocalPlr and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 and (not LocalPlr.Team or plr.Team ~= LocalPlr.Team) then
                local char = plr.Character
                local part = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
                if part then
                    local physDist = myPos and (part.Position - myPos).Magnitude or 0
                    if physDist <= silentDist then
                        local sPos, onScr = Cam:WorldToViewportPoint(part.Position)
                        if onScr then
                            local dist = (center - Vector2.new(sPos.X, sPos.Y)).Magnitude
                            if dist < closestDist then
                                local targPos = getBestTargetPos(char)
                                if targPos then
                                    closestDist = dist
                                    closest = part
                                    bestPos = targPos
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return closest, bestPos
end

local function cameraAim(targ, targPos)
    if not targ or not targPos then return end
    local currCF = Cam.CFrame
    local pos = targPos
    if predEn then
        local vel = targ.AssemblyLinearVelocity or targ.Velocity
        if vel then
            pos = pos + (vel * predStr)
        end
    end
    local targCF = CFrame.new(currCF.Position, pos)
    if smoothness > 0 and smoothness < 1 then
        Cam.CFrame = currCF:Lerp(targCF, smoothness)
    else
        Cam.CFrame = targCF
    end
end

local function mouseAim(targ, targPos)
    if not targ or not targPos then return end
    local pos = targPos
    if predEn then
        local vel = targ.AssemblyLinearVelocity or targ.Velocity
        if vel then
            pos = pos + (vel * predStr)
        end
    end
    local sPos, onScr = Cam:WorldToViewportPoint(pos)
    if onScr then
        local deltaX = (sPos.X - Mouse.X) * smoothness
        local deltaY = (sPos.Y - Mouse.Y) * smoothness
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
            local pos = UIS:GetMouseLocation()
            vim:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
            task.wait(0.035)
            vim:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
        end)
    end)
end

RunS.RenderStepped:Connect(function()
    if scrUnloaded then return end

    if fovFrame and fovFrame.Visible then
        local pos
        if cntrFov then
            pos = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y/2)
        else
            local mousePos = UIS:GetMouseLocation()
            pos = Vector2.new(mousePos.X, mousePos.Y)
        end
        fovFrame.Position = UDim2.new(0, pos.X, 0, pos.Y)
    end

    updEsp()
    if not aimEn and not trigEn then 
        updPred(nil)
        return 
    end

    if trigEn then
        local mousePos = UIS:GetMouseLocation()
        local ray = Cam:ViewportPointToRay(mousePos.X, mousePos.Y)
        local ignore = {Cam}
        if LocalPlr.Character then table.insert(ignore, LocalPlr.Character) end
        local hit = smartRaycast(ray.Origin, ray.Direction * 1500, ignore)
        
        local targInCross = false
        if hit and hit.Instance then
            local model = hit.Instance:FindFirstAncestorOfClass("Model")
            if model then
                local plr = Plrs:GetPlayerFromCharacter(model)
                if plr and plr ~= LocalPlr and plr.Team ~= LocalPlr.Team then
                    local hum = model:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        targInCross = true
                    end
                end
            end
        end

        if isBolt then
            if targInCross and tick() - lastTrig > trigCd then
                lastTrig = tick()
                fireClick()
            end
        else
            if targInCross then
                if not isHoldTrig then
                    isHoldTrig = true
                    pcall(function()
                        cloneref(game:GetService("VirtualInputManager")):SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, true, game, 1)
                    end)
                end
            else
                if isHoldTrig then
                    isHoldTrig = false
                    pcall(function()
                        cloneref(game:GetService("VirtualInputManager")):SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, false, game, 1)
                    end)
                end
            end
        end
    elseif isHoldTrig then
        isHoldTrig = false
        pcall(function()
            local mousePos = UIS:GetMouseLocation()
            cloneref(game:GetService("VirtualInputManager")):SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, false, game, 1)
        end)
    end

    local keyPres = false
    if aimKey.EnumType == Enum.UserInputType then
        keyPres = UIS:IsMouseButtonPressed(aimKey)
    else
        keyPres = UIS:IsKeyDown(aimKey)
    end
    local targ, targPos = getClosestEnemy()
    if targ and targPos then
        local pos = targPos
        if predEn then
            local vel = targ.AssemblyLinearVelocity or targ.Velocity
            if vel then
                pos = pos + (vel * predStr)
            end
        end
        local isVis = isTargVis(targ, targPos)
        if isVis then
            if aimEn then updPred(pos) else updPred(nil) end
            if aimEn and keyPres then
                if aimModePC == "Camera" then cameraAim(targ, targPos) else mouseAim(targ, targPos) end
            end
        else
            updPred(nil)
        end
    else
        updPred(nil)
    end
end)

local success, wm = pcall(require, RepS:WaitForChild("WeaponModule", 5))
if success and wm and type(wm) == "table" then
    if not getgenv().NMZ_Originals then
        getgenv().NMZ_Originals = {}
    end
    if not getgenv().NMZ_Originals.Equip then
        getgenv().NMZ_Originals.Equip = rawget(wm, "Equip")
    end
    if not getgenv().NMZ_Originals.Shoot then
        getgenv().NMZ_Originals.Shoot = rawget(wm, "Shoot")
    end

    if getgenv().NMZ_Originals.Equip then
        local oldEquip = getgenv().NMZ_Originals.Equip
        local newEquip = newcclosure(function(data, action)
            pcall(function()
                if type(action) == "string" and action == "Equip" and type(data) == "table" and data.Tool then
                    currTool = data.Tool
                    currVel = data.Tool:GetAttribute("Velocity") or 500
                    isBolt = false
                    pcall(function()
                        if data.animationList and data.animationList.boltCycleAnimation then
                            isBolt = true
                        end
                    end)
                end
            end)
            return oldEquip(data, action)
        end)
        rawset(wm, "Equip", newEquip)
    end

    if getgenv().NMZ_Originals.Shoot then
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
                            local oldShootFn = rawget(getfenv(anon), k)
                            if not getgenv().NMZ_Originals.InnerShoot then
                                getgenv().NMZ_Originals.InnerShoot = {
                                    Env = getfenv(anon),
                                    Key = k,
                                    Func = oldShootFn
                                }
                            end
                            local newShootFn = newcclosure(function(...)
                                if silentEn then
                                    local ok, res = pcall(function()
                                        local c, bestPos = getClosestSilentEnemy()
                                        if c and currVel and currTool and LocalPlr.Character and LocalPlr.Character:FindFirstChild("Head") then
                                            local pos = bestPos or c.Position
                                            local tVel = c.AssemblyLinearVelocity or c.Velocity or Vector3.new()
                                            
                                            local r = pos - LocalPlr.Character.Head.Position
                                            local vVec = tVel - (LocalPlr.Character.Head.AssemblyLinearVelocity or LocalPlr.Character.Head.Velocity or Vector3.new())
                                            
                                            local a = vVec:Dot(vVec) - (currVel * currVel)
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
                                                    local drop = 0.5 * workspace.Gravity * (tVal * tVal)
                                                    prediction = prediction + Vector3.new(0, drop, 0)
                                                    return prediction
                                                end
                                            end
                                            return pos
                                        end
                                    end)
                                    if ok and res then return res end
                                end
                                return oldShootFn(...)
                            end)
                            if isExecSupp then
                                oldShootFn = clonefunction(hookfunction(rawget(getfenv(anon), k), newShootFn))
                            else
                                rawset(getfenv(anon), k, newShootFn)
                            end
                        end
                    end
                end
            end
        end)
    end
end

local scriptId = "NMZ_ENTRENCHED_UI"
local getGenv = getgenv or function() return _G end

if getGenv()[scriptId] then
    pcall(getGenv()[scriptId])
end

local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Hplayfree25/luaLibrary/refs/heads/master/Init.lua?t=" .. tick()))()

local Window = UI.CreateWindow({
    Title = "NMZ Hub - Light",
    ToggleText = "NMZ",
    Size = UDim2.new(0, 500, 0, 320),
    Keybind = Enum.KeyCode.LeftAlt,
    HideOnStartup = true
})

task.spawn(function()
    task.wait(1)
    UI.Notify({
        Title = "UI Loaded",
        Content = "Press 'Left Alt' on your keyboard to open or close the menu.",
        Duration = 7
    })
end)

getGenv()[scriptId] = function()
    scrUnloaded = true
    if Window then Window.destroy() end
    if guiFov then pcall(function() guiFov:Destroy() end) guiFov = nil end
    if guiPred then pcall(function() guiPred:Destroy() end) guiPred = nil end
    remHl()
    remBx()
    remTr()
    if success and wm and type(wm) == "table" and getgenv().NMZ_Originals then
        if getgenv().NMZ_Originals.Equip then rawset(wm, "Equip", getgenv().NMZ_Originals.Equip) end
        local inner = getgenv().NMZ_Originals.InnerShoot
        if inner then
            if isExecSupp then
                pcall(hookfunction, rawget(inner.Env, inner.Key), inner.Func)
            else
                pcall(rawset, inner.Env, inner.Key, inner.Func)
            end
        end
    end
    getGenv()[scriptId] = nil
end

local TabESP = UI.CreateTab(Window, "ESP", 1)
local TabAim = UI.CreateTab(Window, "AIMBOT", 2)
local TabSilent = UI.CreateTab(Window, "SILENT AIM", 3)
local TabMisc = UI.CreateTab(Window, "MISC", 4)

UI.CreateToggle(TabESP, "ESP Toggle", espEn, function(Value)
    espEn = Value
    refreshEsp()
end)
UI.CreateToggle(TabESP, "ESP Highlight", espHlEn, function(Value)
    espHlEn = Value
    refreshEsp()
end)
UI.CreateToggle(TabESP, "ESP Box", espBxEn, function(Value)
    espBxEn = Value
    refreshEsp()
end)
UI.CreateToggle(TabESP, "ESP Tracer", espTrEn, function(Value)
    espTrEn = Value
    refreshEsp()
end)

local colOpts = {}
for i, name in ipairs(colNames) do table.insert(colOpts, {name=name, val=name}) end
UI.CreateDropdown(TabESP, "ESP Color", colOpts, 1, function(Option)
    for i, n in ipairs(colNames) do
        if n == Option then
            colIdx = i
            boxCol = colList[i]
            for plr, lines in pairs(bxLines) do for _, l in pairs(lines) do l.Color = boxCol end end
            for plr, l in pairs(trLines) do l.Color = boxCol end
            break
        end
    end
end)

UI.CreateToggle(TabAim, "Aimbot Toggle", aimEn, function(Value)
    aimEn = Value
    updFov()
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
UI.CreateSlider(TabAim, "FOV Size", 50, 500, fovSz, function(v) return tostring(math.floor(v)) end, function(Value)
    fovSz = Value
    updFov()
end)
UI.CreateToggle(TabAim, "Center FOV", cntrFov, function(Value)
    cntrFov = Value
end)

UI.CreateLabel(TabSilent, "⚠️ Note: Silent Aim & Wall Check may be unstable on Solara and Xeno")
UI.CreateToggle(TabSilent, "Silent Aim Toggle", silentEn, function(Value)
    silentEn = Value
end)
UI.CreateSlider(TabSilent, "Silent Max Distance", 100, 3000, silentDist, function(v) return tostring(math.floor(v)) end, function(Value)
    silentDist = Value
end)
UI.CreateToggle(TabSilent, "Predict Toggle", predEn, function(Value)
    predEn = Value
end)
UI.CreateSlider(TabSilent, "Predict Strength", 0, 0.3, predStr, function(v) return string.format("%.3f", v) end, function(Value)
    predStr = Value
end)
UI.CreateToggle(TabSilent, "Triggerbot", trigEn, function(Value)
    trigEn = Value
end)
UI.CreateToggle(TabSilent, "Wall Check", wallChEn, function(Value)
    wallChEn = Value
end)

UI.CreateButton(TabMisc, "Save Config", function()
    saveCfg()
    UI.Notify({Title = "Config Saved", Content = "Your settings have been saved locally.", Duration = 3})
end)
UI.CreateButton(TabMisc, "Rejoin", function()
    TeleportS:Teleport(game.PlaceId, LocalPlr)
end)
UI.CreateButton(TabMisc, "Server Hop", function()
    local servers = {}
    local success, res = pcall(function() return cloneref(game:GetService("HttpService")):JSONDecode(game:HttpGetAsync("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")) end)
    if success and res.data then
        for _, s in pairs(res.data) do
            if s.playing < s.maxPlayers and s.id ~= game.JobId then table.insert(servers, s.id) end
        end
        if #servers > 0 then TeleportS:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1,#servers)]) end
    end
end)
UI.CreateButton(TabMisc, "Unload Script", function()
    if getGenv()[scriptId] then getGenv()[scriptId]() end
end)
UI.CreateLabel(TabMisc, "Script Version: V1.5-Light")

refreshEsp()

if not isExecSupp then
    task.spawn(function()
        task.wait(1.5)
        UI.Notify({
            Title = "Executor Not Supported",
            Content = "Unsupported Executor. Aimbot, Silent Aim, and Triggerbot will NOT work.",
            Duration = 5
        })
    end)
end
