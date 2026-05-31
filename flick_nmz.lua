local id = "NMZ_DFLICK2"
local getGenv = getgenv or function() return _G end

if getGenv()[id] then
    pcall(getGenv()[id])
end

local conns = {}
local drws = {}

getGenv()[id] = function()
    for i = 1, #conns do pcall(function() conns[i]:Disconnect() end) end
    for i = 1, #drws do pcall(function() drws[i]:Remove() end) end
    
    local sg = game:GetService("CoreGui"):FindFirstChild(id)
    if sg then sg:Destroy() end
    local pg = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild(id)
    if pg then pg:Destroy() end
    if gethui then
        local hg = gethui():FindFirstChild(id)
        if hg then hg:Destroy() end
    end
end

local function addConn(c) table.insert(conns, c) end
local function addDrw(d) table.insert(drws, d); return d end

local safeSvc = function(n)
    local s = game:GetService(n)
    if cloneref then return cloneref(s) end
    return s
end

local plrs = safeSvc("Players")
local rs = safeSvc("RunService")
local uis = safeSvc("UserInputService")
local ws = safeSvc("Workspace")
local ts = safeSvc("TweenService")

local lplr = plrs.LocalPlayer
local cam = ws.CurrentCamera

local stgs = {
    aimOn = false,
    aimMeth = "Camera",
    aimFov = 160,
    aimSmth = 10,
    aimTgt = "Head",
    aimWall = false,
    aimTeam = false,
    aimPred = false,
    aimPredAmt = 0.142,
    espOn = true,
    espBox = true,
    espTr = true,
    espCol = Color3.fromRGB(100, 150, 255),
    espThk = 1.2
}

local fovCir = addDrw(Drawing.new("Circle"))
fovCir.Visible = false
fovCir.Color = Color3.fromRGB(255, 255, 255)
fovCir.Thickness = 1
fovCir.NumSides = 64
fovCir.Radius = stgs.aimFov
fovCir.Filled = false
fovCir.Transparency = 0.5

local getSafeGui = function()
    if gethui then return gethui() end
    local cgOk, cg = pcall(function() return safeSvc("CoreGui") end)
    if cgOk and cg then return cg end
    return lplr:WaitForChild("PlayerGui")
end

local gui = Instance.new("ScreenGui")
gui.Name = id
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = getSafeGui()

local btnTgl = Instance.new("TextButton")
btnTgl.Size = UDim2.new(0, 50, 0, 50)
btnTgl.Position = UDim2.new(1, -70, 0.5, -25)
btnTgl.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
btnTgl.BackgroundTransparency = 0.1
btnTgl.Text = ""
btnTgl.Active = true
btnTgl.Parent = gui

local bc1 = Instance.new("UICorner")
bc1.CornerRadius = UDim.new(1, 0)
bc1.Parent = btnTgl

local bs1 = Instance.new("UIStroke")
bs1.Color = Color3.fromRGB(255, 255, 255)
bs1.Transparency = 0.8
bs1.Thickness = 1
bs1.Parent = btnTgl

local lblNmz = Instance.new("TextLabel")
lblNmz.Size = UDim2.new(1, 0, 1, 0)
lblNmz.BackgroundTransparency = 1
lblNmz.Text = "NMZ"
lblNmz.Font = Enum.Font.GothamBold
lblNmz.TextSize = 16
lblNmz.TextColor3 = Color3.fromRGB(255, 255, 255)
lblNmz.Parent = btnTgl

local gradNmz = Instance.new("UIGradient")
gradNmz.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
    ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 255, 0)),
    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
    ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 0, 255)),
    ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
})
gradNmz.Parent = lblNmz

local btnDragging = false
local btnDragStart = nil
local btnStartPos = nil
local btnClickTime = 0

addConn(btnTgl.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        btnDragging = true
        btnDragStart = input.Position
        btnStartPos = btnTgl.Position
        btnClickTime = tick()
    end
end))
addConn(uis.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        if btnDragging then
            local delta = input.Position - btnDragStart
            local ti = TweenInfo.new(0.08, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
            ts:Create(btnTgl, ti, {Position = UDim2.new(btnStartPos.X.Scale, btnStartPos.X.Offset + delta.X, btnStartPos.Y.Scale, btnStartPos.Y.Offset + delta.Y)}):Play()
        end
    end
end))
addConn(uis.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        btnDragging = false
    end
end))

local frmMain = Instance.new("Frame")
frmMain.Size = UDim2.new(0, 500, 0, 300)
frmMain.Position = UDim2.new(0.5, -250, 0.5, -150)
frmMain.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
frmMain.BackgroundTransparency = 0.1
frmMain.Visible = false
frmMain.Active = true
frmMain.Parent = gui

local fc1 = Instance.new("UICorner")
fc1.CornerRadius = UDim.new(0, 12)
fc1.Parent = frmMain

local fs1 = Instance.new("UIStroke")
fs1.Color = Color3.fromRGB(255, 255, 255)
fs1.Transparency = 0.85
fs1.Thickness = 1
fs1.Parent = frmMain

addConn(btnTgl.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if tick() - btnClickTime < 0.2 and (input.Position - btnDragStart).Magnitude < 10 then
            frmMain.Visible = not frmMain.Visible
            if frmMain.Visible then
                frmMain.Size = UDim2.new(0, 480, 0, 280)
                ts:Create(frmMain, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 500, 0, 300)}):Play()
            end
        end
    end
end))

local frmDragging = false
local frmDragStart = nil
local frmStartPos = nil

addConn(frmMain.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        frmDragging = true
        frmDragStart = input.Position
        frmStartPos = frmMain.Position
    end
end))
addConn(uis.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        if frmDragging then
            local delta = input.Position - frmDragStart
            local ti = TweenInfo.new(0.08, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
            ts:Create(frmMain, ti, {Position = UDim2.new(frmStartPos.X.Scale, frmStartPos.X.Offset + delta.X, frmStartPos.Y.Scale, frmStartPos.Y.Offset + delta.Y)}):Play()
        end
    end
end))
addConn(uis.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        frmDragging = false
    end
end))

local leftPanel = Instance.new("Frame")
leftPanel.Size = UDim2.new(0, 140, 1, 0)
leftPanel.Position = UDim2.new(0, 0, 0, 0)
leftPanel.BackgroundTransparency = 1
leftPanel.Parent = frmMain

local rightPanel = Instance.new("Frame")
rightPanel.Size = UDim2.new(1, -140, 1, 0)
rightPanel.Position = UDim2.new(0, 140, 0, 0)
rightPanel.BackgroundTransparency = 1
rightPanel.Parent = frmMain

local divider = Instance.new("Frame")
divider.Size = UDim2.new(0, 1, 1, -20)
divider.Position = UDim2.new(0, 139, 0, 10)
divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
divider.BackgroundTransparency = 0.85
divider.Parent = frmMain

local lblTitle = Instance.new("TextLabel")
lblTitle.Size = UDim2.new(1, 0, 0, 50)
lblTitle.Position = UDim2.new(0, 0, 0, 10)
lblTitle.BackgroundTransparency = 1
lblTitle.Text = "FLICK NMZ"
lblTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
lblTitle.Font = Enum.Font.GothamBold
lblTitle.TextSize = 18
lblTitle.Parent = leftPanel
local gradTitle = Instance.new("UIGradient")
gradTitle.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 150, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 100, 255))
})
gradTitle.Parent = lblTitle

local tabCont = Instance.new("Frame")
tabCont.Size = UDim2.new(1, 0, 1, -60)
tabCont.Position = UDim2.new(0, 0, 0, 60)
tabCont.BackgroundTransparency = 1
tabCont.Parent = leftPanel

local tl1 = Instance.new("UIListLayout")
tl1.FillDirection = Enum.FillDirection.Vertical
tl1.HorizontalAlignment = Enum.HorizontalAlignment.Center
tl1.SortOrder = Enum.SortOrder.LayoutOrder
tl1.Padding = UDim.new(0, 8)
tl1.Parent = tabCont

local function makeTabBtn(name, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(150, 150, 150)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.LayoutOrder = order
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = btn
    return btn
end

local btnAim = makeTabBtn("AIMBOT", 1)
btnAim.Parent = tabCont
local btnEsp = makeTabBtn("ESP", 2)
btnEsp.Parent = tabCont
local btnMisc = makeTabBtn("MISC", 3)
btnMisc.Parent = tabCont

local function makeScr()
    local frm = Instance.new("ScrollingFrame")
    frm.Size = UDim2.new(1, -15, 1, -20)
    frm.Position = UDim2.new(0, 15, 0, 10)
    frm.BackgroundTransparency = 1
    frm.ScrollBarThickness = 3
    frm.ScrollBarImageColor3 = Color3.fromRGB(100, 150, 255)
    frm.Visible = false
    local lay = Instance.new("UIListLayout")
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.Padding = UDim.new(0, 8)
    lay.HorizontalAlignment = Enum.HorizontalAlignment.Left
    lay.Parent = frm
    local pad = Instance.new("UIPadding")
    pad.PaddingRight = UDim.new(0, 10)
    pad.Parent = frm
    return frm
end

local scrAim = makeScr()
scrAim.Parent = rightPanel
local scrEsp = makeScr()
scrEsp.Parent = rightPanel
local scrMisc = makeScr()
scrMisc.Parent = rightPanel

local function switchTab(tabName)
    local ti = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    scrAim.Visible = (tabName == "AIMBOT")
    scrEsp.Visible = (tabName == "ESP")
    scrMisc.Visible = (tabName == "MISC")
    
    ts:Create(btnAim, ti, {BackgroundColor3 = (tabName == "AIMBOT") and Color3.fromRGB(40, 40, 50) or Color3.fromRGB(20, 20, 25), TextColor3 = (tabName == "AIMBOT") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150)}):Play()
    ts:Create(btnEsp, ti, {BackgroundColor3 = (tabName == "ESP") and Color3.fromRGB(40, 40, 50) or Color3.fromRGB(20, 20, 25), TextColor3 = (tabName == "ESP") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150)}):Play()
    ts:Create(btnMisc, ti, {BackgroundColor3 = (tabName == "MISC") and Color3.fromRGB(40, 40, 50) or Color3.fromRGB(20, 20, 25), TextColor3 = (tabName == "MISC") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150)}):Play()
end

addConn(btnAim.MouseButton1Click:Connect(function() switchTab("AIMBOT") end))
addConn(btnEsp.MouseButton1Click:Connect(function() switchTab("ESP") end))
addConn(btnMisc.MouseButton1Click:Connect(function() switchTab("MISC") end))
switchTab("AIMBOT")

local function makeTgl(name, parent, stateVal, cb)
    local frm = Instance.new("Frame")
    frm.Size = UDim2.new(1, 0, 0, 40)
    frm.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    frm.BackgroundTransparency = 0.6
    frm.Parent = parent
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = frm
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(255, 255, 255)
    s.Transparency = 0.92
    s.Parent = frm
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.7, 0, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = Color3.fromRGB(240, 240, 240)
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frm
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 40, 0, 20)
    btn.Position = UDim2.new(1, -52, 0.5, -10)
    btn.BackgroundColor3 = stateVal and Color3.fromRGB(100, 150, 255) or Color3.fromRGB(40, 40, 45)
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = frm
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(1, 0)
    bc.Parent = btn
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = stateVal and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Parent = btn
    local kc = Instance.new("UICorner")
    kc.CornerRadius = UDim.new(1, 0)
    kc.Parent = knob
    
    addConn(btn.MouseButton1Click:Connect(function()
        stateVal = not stateVal
        local ti = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        ts:Create(btn, ti, {BackgroundColor3 = stateVal and Color3.fromRGB(100, 150, 255) or Color3.fromRGB(40, 40, 45)}):Play()
        ts:Create(knob, ti, {Position = stateVal and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}):Play()
        cb(stateVal)
    end))
end

local function makeSld(name, parent, minVal, maxVal, defaultVal, formatFunc, cb)
    local frm = Instance.new("Frame")
    frm.Size = UDim2.new(1, 0, 0, 50)
    frm.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    frm.BackgroundTransparency = 0.6
    frm.Parent = parent
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = frm
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(255, 255, 255)
    s.Transparency = 0.92
    s.Parent = frm
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -24, 0, 20)
    lbl.Position = UDim2.new(0, 12, 0, 6)
    lbl.BackgroundTransparency = 1
    lbl.Text = name .. ": " .. formatFunc(defaultVal)
    lbl.TextColor3 = Color3.fromRGB(240, 240, 240)
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frm
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, -24, 0, 6)
    bg.Position = UDim2.new(0, 12, 0, 32)
    bg.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    bg.Parent = frm
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(1, 0)
    bc.Parent = bg
    local fil = Instance.new("Frame")
    local pct = (defaultVal - minVal) / (maxVal - minVal)
    fil.Size = UDim2.new(pct, 0, 1, 0)
    fil.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    fil.Parent = bg
    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(1, 0)
    fc.Parent = fil
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = bg
    
    local sliding = false
    addConn(btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = true
        end
    end))
    addConn(uis.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = false
        end
    end))
    addConn(uis.InputChanged:Connect(function(input)
        if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local p = math.clamp(input.Position.X - bg.AbsolutePosition.X, 0, bg.AbsoluteSize.X) / bg.AbsoluteSize.X
            local val = minVal + (maxVal - minVal) * p
            fil.Size = UDim2.new(p, 0, 1, 0)
            lbl.Text = name .. ": " .. formatFunc(val)
            cb(val)
        end
    end))
end

local function makeOpt(name, parent, opts, defaultIdx, cb)
    local frm = Instance.new("Frame")
    frm.Size = UDim2.new(1, 0, 0, 40)
    frm.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    frm.BackgroundTransparency = 0.6
    frm.Parent = parent
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = frm
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(255, 255, 255)
    s.Transparency = 0.92
    s.Parent = frm
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.5, 0, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = Color3.fromRGB(240, 240, 240)
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frm
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 100, 0, 22)
    btn.Position = UDim2.new(1, -112, 0.5, -11)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    btn.Text = opts[defaultIdx].name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.Parent = frm
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 6)
    bc.Parent = btn
    
    local cur = defaultIdx
    addConn(btn.MouseButton1Click:Connect(function()
        cur = cur + 1
        if cur > #opts then cur = 1 end
        btn.Text = opts[cur].name
        cb(opts[cur].val)
    end))
end

local function makeBtn(name, parent, cb)
    local frm = Instance.new("Frame")
    frm.Size = UDim2.new(1, 0, 0, 40)
    frm.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    frm.BackgroundTransparency = 0.6
    frm.Parent = parent
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = frm
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(255, 255, 255)
    s.Transparency = 0.92
    s.Parent = frm
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(240, 240, 240)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 14
    btn.Parent = frm
    
    addConn(btn.MouseButton1Click:Connect(function()
        local ti = TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
        ts:Create(frm, ti, {BackgroundColor3 = Color3.fromRGB(100, 150, 255)}):Play()
        task.delay(0.1, function()
            pcall(function() ts:Create(frm, ti, {BackgroundColor3 = Color3.fromRGB(25, 25, 30)}):Play() end)
        end)
        cb()
    end))
end

makeTgl("Aimbot Enabled", scrAim, stgs.aimOn, function(v) stgs.aimOn = v; fovCir.Visible = v end)
makeOpt("Aimbot Method", scrAim, {{name="CAMERA", val="Camera"}, {name="MOUSE", val="Mouse"}}, 1, function(v) stgs.aimMeth = v end)
makeSld("FOV Size", scrAim, 10, 600, stgs.aimFov, function(v) return math.floor(v) end, function(v) stgs.aimFov = v; fovCir.Radius = v end)
makeSld("Smoothness", scrAim, 1, 50, stgs.aimSmth, function(v) return math.floor(v) end, function(v) stgs.aimSmth = v end)
makeOpt("Target Part", scrAim, {{name="HEAD", val="Head"}, {name="BODY", val="HumanoidRootPart"}}, 1, function(v) stgs.aimTgt = v end)
makeTgl("Team Check", scrAim, stgs.aimTeam, function(v) stgs.aimTeam = v end)
makeTgl("Wall Check", scrAim, stgs.aimWall, function(v) stgs.aimWall = v end)
makeTgl("Prediction", scrAim, stgs.aimPred, function(v) stgs.aimPred = v end)
makeSld("Pred Amount", scrAim, 0.05, 0.3, stgs.aimPredAmt, function(v) return string.format("%.3f", v) end, function(v) stgs.aimPredAmt = v end)

makeTgl("ESP Enabled", scrEsp, stgs.espOn, function(v) stgs.espOn = v end)
makeTgl("ESP Boxes", scrEsp, stgs.espBox, function(v) stgs.espBox = v end)
makeTgl("ESP Tracers", scrEsp, stgs.espTr, function(v) stgs.espTr = v end)

makeBtn("Boost FPS", scrMisc, function()
    local ter = safeSvc("Workspace").Terrain
    local lig = safeSvc("Lighting")
    pcall(function()
        ter.WaterWaveSize = 0
        ter.WaterWaveSpeed = 0
        ter.WaterReflectance = 0
        ter.WaterTransparency = 0
        lig.GlobalShadows = false
        lig.FogEnd = 9e9
        lig.Brightness = 0
    end)
    for _, v in pairs(lig:GetDescendants()) do
        if v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") then
            v.Enabled = false
        end
    end
    for _, v in pairs(ws:GetDescendants()) do
        if v:IsA("BasePart") and not v:IsA("MeshPart") then
            v.Material = Enum.Material.Plastic
            v.Reflectance = 0
        elseif v:IsA("Decal") or (v:IsA("Texture") and v.Texture ~= "rbxassetid://1813137837") then
            v.Transparency = 1
        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
            v.Lifetime = NumberRange.new(0)
        elseif v:IsA("Explosion") then
            v.BlastPressure = 1
            v.BlastRadius = 1
        elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") or v:IsA("Sparkles") then
            v.Enabled = false
        elseif v:IsA("MeshPart") then
            v.Material = Enum.Material.Plastic
            v.Reflectance = 0
        end
    end
end)

makeBtn("Unload Script", scrMisc, function()
    getGenv()[id]()
end)

local function GetTarget()
    local closest = nil
    local bestDist = stgs.aimFov

    for _, plr in ipairs(plrs:GetPlayers()) do
        if plr == lplr or not plr.Character or not plr.Character:FindFirstChild("Humanoid") or plr.Character.Humanoid.Health <= 0 then continue end
        if stgs.aimTeam and plr.Team == lplr.Team then continue end

        local part = plr.Character:FindFirstChild(stgs.aimTgt) or plr.Character:FindFirstChild("HumanoidRootPart")
        if not part then continue end

        local pos = part.Position
        if stgs.aimPred then
            pos = pos + (part.Velocity * stgs.aimPredAmt)
        end

        local screenPos, onScreen = cam:WorldToViewportPoint(pos)
        if not onScreen then continue end

        local center = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
        if stgs.aimMeth == "Mouse" then center = uis:GetMouseLocation() end
        
        local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
        if dist >= bestDist then continue end

        if stgs.aimWall then
            local rayParams = RaycastParams.new()
            local ignores = {cam}
            if lplr.Character then table.insert(ignores, lplr.Character) end
            rayParams.FilterDescendantsInstances = ignores
            rayParams.FilterType = Enum.RaycastFilterType.Blacklist
            local result = ws:Raycast(cam.CFrame.Position, pos - cam.CFrame.Position, rayParams)
            if result and not result.Instance:IsDescendantOf(plr.Character) then continue end
        end

        bestDist = dist
        closest = pos
    end
    return closest
end

local function drawEsp(plr)
    local box = addDrw(Drawing.new("Square"))
    local trc = addDrw(Drawing.new("Line"))
    local conn
    conn = rs.RenderStepped:Connect(function()
        if not plr or not plr.Parent then
            box.Visible = false
            trc.Visible = false
            if conn then conn:Disconnect() end
            return
        end
        local ok, err = pcall(function()
            if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 and plr ~= lplr then
                local hPos, onScr = cam:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position)
                if onScr and stgs.espOn then
                    if stgs.espBox then
                        local sx = 1000 / hPos.Z
                        local sy = 2000 / hPos.Z
                        box.Visible = true
                        box.Size = Vector2.new(sx, sy)
                        box.Position = Vector2.new(hPos.X - sx / 2, hPos.Y - sy / 2)
                        box.Color = stgs.espCol
                        box.Thickness = stgs.espThk
                    else
                        box.Visible = false
                    end
                    if stgs.espTr then
                        trc.Visible = true
                        trc.From = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
                        trc.To = Vector2.new(hPos.X, hPos.Y)
                        trc.Color = stgs.espCol
                        trc.Thickness = stgs.espThk
                    else
                        trc.Visible = false
                    end
                else
                    box.Visible = false
                    trc.Visible = false
                end
            else
                box.Visible = false
                trc.Visible = false
            end
        end)
        if not ok then
            box.Visible = false
            trc.Visible = false
        end
    end)
    addConn(conn)
end

local curPlrs = plrs:GetPlayers()
for i = 1, #curPlrs do
    drawEsp(curPlrs[i])
end
addConn(plrs.PlayerAdded:Connect(drawEsp))

local gradSpin = 0
local function aimStep(dt)
    gradSpin = gradSpin + (dt * 150)
    if gradSpin > 360 then gradSpin = gradSpin - 360 end
    gradNmz.Rotation = gradSpin

    fovCir.Radius = stgs.aimFov
    local mPos = uis:GetMouseLocation()
    local centerPos = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
    if stgs.aimMeth == "Mouse" then
        fovCir.Position = mPos
    else
        fovCir.Position = centerPos
    end

    if not stgs.aimOn then
        fovCir.Color = Color3.fromRGB(255, 255, 255)
        return
    end

    local targetPos = GetTarget()
    if targetPos then
        fovCir.Color = Color3.fromRGB(0, 255, 0)
        if stgs.aimMeth == "Camera" then
            local look = CFrame.lookAt(cam.CFrame.Position, targetPos)
            cam.CFrame = cam.CFrame:Lerp(look, 1 / stgs.aimSmth)
        else
            if mousemoverel then
                local sPos = cam:WorldToScreenPoint(targetPos)
                local dx = sPos.X - mPos.X
                local dy = sPos.Y - mPos.Y
                mousemoverel(dx * (1 / stgs.aimSmth), dy * (1 / stgs.aimSmth))
            end
        end
    else
        fovCir.Color = Color3.fromRGB(255, 255, 255)
    end
end

addConn(rs.Heartbeat:Connect(aimStep))