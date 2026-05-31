local Window = {}
local Theme = require(script.Parent.Theme)
local Utils = require(script.Parent.Utils)
local Drag = require(script.Parent.Drag)

function Window.new(options)
    if type(options) == "string" then
        options = { Title = options }
    end
    options = options or {}
    
    local Theme = options.Theme or require(script.Parent.Theme)
    local titleText = options.Title or "Universal UI"
    local toggleText = options.ToggleText or "UI"
    local windowSize = options.Size or UDim2.new(0, 500, 0, 300)
    
    local gui = Instance.new("ScreenGui")
    gui.Name = options.GuiName or "UniversalUILib"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = Utils.getSafeGui()

    local btnTgl = Instance.new("TextButton")
    btnTgl.Size = UDim2.new(0, 50, 0, 50)
    btnTgl.Position = UDim2.new(1, -70, 0.5, -25)
    btnTgl.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    btnTgl.BackgroundTransparency = Theme.BackgroundTransparency
    btnTgl.Text = ""
    btnTgl.Active = true
    btnTgl.Parent = gui

    local bc1 = Instance.new("UICorner")
    bc1.CornerRadius = UDim.new(1, 0)
    bc1.Parent = btnTgl

    local bs1 = Instance.new("UIStroke")
    bs1.Color = Theme.Stroke
    bs1.Transparency = 0.8
    bs1.Thickness = 1
    bs1.Parent = btnTgl

    local lblTitleTgl = Instance.new("TextLabel")
    lblTitleTgl.Size = UDim2.new(1, 0, 1, 0)
    lblTitleTgl.BackgroundTransparency = 1
    lblTitleTgl.Text = toggleText
    lblTitleTgl.Font = Theme.FontBold
    lblTitleTgl.TextSize = 16
    lblTitleTgl.TextColor3 = Theme.TextPrimary
    lblTitleTgl.Parent = btnTgl

    local gradNmz = Instance.new("UIGradient")
    gradNmz.Color = options.ToggleGradient or ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.Accent),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 100, 255))
    })
    gradNmz.Parent = lblTitleTgl

    local rs = Utils.safeSvc("RunService")
    local gradSpin = 0
    local rsConn
    if options.SpinToggleGradient ~= false then
        rsConn = rs.Heartbeat:Connect(function(dt)
            gradSpin = gradSpin + (dt * 150)
            if gradSpin > 360 then gradSpin = gradSpin - 360 end
            gradNmz.Rotation = gradSpin
        end)
    end

    Drag.makeDraggable(btnTgl)

    local frmMain = Instance.new("Frame")
    frmMain.Size = windowSize
    frmMain.Position = UDim2.new(0.5, -windowSize.X.Offset/2, 0.5, -windowSize.Y.Offset/2)
    frmMain.BackgroundColor3 = Theme.Background
    frmMain.BackgroundTransparency = Theme.BackgroundTransparency
    frmMain.Visible = false
    frmMain.Active = true
    frmMain.Parent = gui

    local fc1 = Instance.new("UICorner")
    fc1.CornerRadius = Theme.WindowCornerRadius
    fc1.Parent = frmMain

    local fs1 = Instance.new("UIStroke")
    fs1.Color = Theme.Stroke
    fs1.Transparency = Theme.StrokeTransparency
    fs1.Thickness = 1
    fs1.Parent = frmMain

    local clickTime = 0
    local uis = Utils.safeSvc("UserInputService")
    btnTgl.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            clickTime = tick()
        end
    end)
    btnTgl.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if tick() - clickTime < 0.2 then
                frmMain.Visible = not frmMain.Visible
                if frmMain.Visible then
                    local targetSize = windowSize
                    local initialSize = UDim2.new(windowSize.X.Scale, windowSize.X.Offset - 20, windowSize.Y.Scale, windowSize.Y.Offset - 20)
                    frmMain.Size = initialSize
                    Utils.tween(frmMain, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = targetSize})
                end
            end
        end
    end)

    Drag.makeDraggable(frmMain)

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
    divider.BackgroundColor3 = Theme.Stroke
    divider.BackgroundTransparency = Theme.StrokeTransparency
    divider.Parent = frmMain

    local lblTitle = Instance.new("TextLabel")
    lblTitle.Size = UDim2.new(1, 0, 0, 50)
    lblTitle.Position = UDim2.new(0, 0, 0, 10)
    lblTitle.BackgroundTransparency = 1
    lblTitle.Text = titleText
    lblTitle.TextColor3 = Theme.TextPrimary
    lblTitle.Font = Theme.FontBold
    lblTitle.TextSize = 18
    lblTitle.Parent = leftPanel
    local gradTitle = Instance.new("UIGradient")
    gradTitle.Color = options.TitleGradient or ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.Accent),
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
    
    local self = {
        gui = gui,
        mainFrame = frmMain,
        leftPanel = leftPanel,
        rightPanel = rightPanel,
        tabContainer = tabCont,
        rsConn = rsConn,
        destroy = function()
            if rsConn then rsConn:Disconnect() end
            gui:Destroy()
        end
    }
    
    return self
end

return Window
