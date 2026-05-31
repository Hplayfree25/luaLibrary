local Window = {}

local import = function(name)
    local ok, res = pcall(function() return require(script.Parent[name]) end)
    if ok then return res end
    return _G.UniversalUILib_GetModule(name)
end

local DefaultTheme = import("Theme")
local Utils = import("Utils")
local Drag = import("Drag")

function Window.new(options)
    if type(options) == "string" then
        options = { Title = options }
    end
    options = options or {}
    
    local Theme = options.Theme or DefaultTheme
    local titleText = options.Title or "Universal UI"
    local toggleText = options.ToggleText or "UI"
    local windowSize = options.Size or UDim2.new(0, 600, 0, 380)
    
    local gui = Instance.new("ScreenGui")
    gui.Name = options.GuiName or "UniversalUILib"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = Utils.getSafeGui()

    -- Floating toggle button (Premium Dark Slate Style)
    local btnTgl = Instance.new("TextButton")
    btnTgl.Size = UDim2.new(0, 48, 0, 48)
    btnTgl.Position = UDim2.new(1, -70, 0.5, -24)
    btnTgl.BackgroundColor3 = Theme.PanelBackground
    btnTgl.BackgroundTransparency = 0.15
    btnTgl.Text = ""
    btnTgl.Active = true
    btnTgl.Parent = gui

    local bc1 = Instance.new("UICorner")
    bc1.CornerRadius = UDim.new(1, 0)
    bc1.Parent = btnTgl

    local bs1 = Instance.new("UIStroke")
    bs1.Color = Theme.Stroke
    bs1.Transparency = 0.90
    bs1.Thickness = 1
    bs1.Parent = btnTgl

    local lblTitleTgl = Instance.new("TextLabel")
    lblTitleTgl.Size = UDim2.new(1, 0, 1, 0)
    lblTitleTgl.BackgroundTransparency = 1
    lblTitleTgl.Text = toggleText
    lblTitleTgl.Font = Theme.FontBold
    lblTitleTgl.TextSize = 14
    lblTitleTgl.TextColor3 = Theme.TextSecondary
    lblTitleTgl.Parent = btnTgl
    
    -- Smooth hover transition for floating toggle button
    btnTgl.MouseEnter:Connect(function()
        Utils.tween(btnTgl, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {BackgroundColor3 = Theme.SecondaryBackground})
        Utils.tween(lblTitleTgl, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {TextColor3 = Theme.TextPrimary})
    end)
    btnTgl.MouseLeave:Connect(function()
        Utils.tween(btnTgl, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {BackgroundColor3 = Theme.PanelBackground})
        Utils.tween(lblTitleTgl, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {TextColor3 = Theme.TextSecondary})
    end)

    Drag.makeDraggable(btnTgl)

    -- Main UI Frame
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

    -- Toggle show/hide transition
    local clickTime = 0
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
                    local initialSize = UDim2.new(windowSize.X.Scale, windowSize.X.Offset - 16, windowSize.Y.Scale, windowSize.Y.Offset - 16)
                    frmMain.Size = initialSize
                    frmMain.BackgroundTransparency = 0.5
                    Utils.tween(frmMain, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Size = targetSize,
                        BackgroundTransparency = Theme.BackgroundTransparency
                    })
                end
            end
        end
    end)

    Drag.makeDraggable(frmMain)

    -- Layout panels
    local leftPanel = Instance.new("Frame")
    leftPanel.Size = UDim2.new(0, 155, 1, 0)
    leftPanel.Position = UDim2.new(0, 0, 0, 0)
    leftPanel.BackgroundTransparency = 1
    leftPanel.Parent = frmMain

    local rightPanel = Instance.new("Frame")
    rightPanel.Size = UDim2.new(1, -155, 1, 0)
    rightPanel.Position = UDim2.new(0, 155, 0, 0)
    rightPanel.BackgroundTransparency = 1
    rightPanel.Parent = frmMain

    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(0, 1, 1, -20)
    divider.Position = UDim2.new(0, 154, 0, 10)
    divider.BackgroundColor3 = Theme.Stroke
    divider.BackgroundTransparency = Theme.StrokeTransparency
    divider.Parent = frmMain

    -- Title (Clean Sleek Style)
    local lblTitle = Instance.new("TextLabel")
    lblTitle.Size = UDim2.new(1, 0, 0, 50)
    lblTitle.Position = UDim2.new(0, 0, 0, 12)
    lblTitle.BackgroundTransparency = 1
    lblTitle.Text = titleText
    lblTitle.TextColor3 = Theme.TextPrimary
    lblTitle.Font = Theme.FontBold
    lblTitle.TextSize = 16
    lblTitle.Parent = leftPanel
    
    -- Very subtle gray-to-white gradient for title
    local gradTitle = Instance.new("UIGradient")
    gradTitle.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.TextPrimary),
        ColorSequenceKeypoint.new(1, Theme.TextSecondary)
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
    tl1.Padding = UDim.new(0, 6)
    tl1.Parent = tabCont
    
    local self = {
        gui = gui,
        mainFrame = frmMain,
        leftPanel = leftPanel,
        rightPanel = rightPanel,
        tabContainer = tabCont,
        theme = Theme,
        destroy = function()
            gui:Destroy()
        end
    }
    
    return self
end

return Window
