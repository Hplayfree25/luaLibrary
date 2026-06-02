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
    btnTgl.BackgroundTransparency = 1
    btnTgl.Text = ""
    btnTgl.Active = true
    btnTgl.Parent = gui

    local bc1 = Instance.new("UICorner")
    bc1.CornerRadius = UDim.new(1, 0)
    bc1.Parent = btnTgl

    local bs1 = Instance.new("UIStroke")
    bs1.Color = Theme.Stroke
    bs1.Transparency = 1
    bs1.Thickness = 1
    bs1.Parent = btnTgl

    local lblTitleTgl = Instance.new("TextLabel")
    lblTitleTgl.Size = UDim2.new(1, 0, 1, 0)
    lblTitleTgl.BackgroundTransparency = 1
    lblTitleTgl.Text = toggleText
    lblTitleTgl.Font = Theme.FontBold
    lblTitleTgl.TextSize = 14
    lblTitleTgl.TextColor3 = Theme.TextSecondary
    lblTitleTgl.TextTransparency = 1
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
    frmMain.Size = UDim2.new(0, windowSize.X.Offset - 20, 0, windowSize.Y.Offset - 20)
    frmMain.Position = UDim2.new(0.5, -(windowSize.X.Offset - 20)/2, 0.5, -(windowSize.Y.Offset - 20)/2)
    frmMain.BackgroundColor3 = Theme.Background
    frmMain.BackgroundTransparency = 1
    frmMain.Visible = false
    frmMain.Active = true
    frmMain.Parent = gui

    local fc1 = Instance.new("UICorner")
    fc1.CornerRadius = Theme.WindowCornerRadius
    fc1.Parent = frmMain

    local fs1 = Instance.new("UIStroke")
    fs1.Color = Theme.Stroke
    fs1.Transparency = 1
    fs1.Thickness = 1
    fs1.Parent = frmMain

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

    -- Loading Card Intro - initially hidden
    local introFrame = Instance.new("Frame")
    introFrame.Size = UDim2.new(0, 220, 0, 80)
    introFrame.Position = UDim2.new(0.5, -110, 0.5, -40)
    introFrame.BackgroundColor3 = Theme.Background
    introFrame.BackgroundTransparency = 1
    introFrame.Visible = false
    introFrame.Parent = gui

    local introCorner = Instance.new("UICorner")
    introCorner.CornerRadius = Theme.WindowCornerRadius
    introCorner.Parent = introFrame

    local introStroke = Instance.new("UIStroke")
    introStroke.Color = Theme.Stroke
    introStroke.Transparency = 1
    introStroke.Parent = introFrame

    local introTitle = Instance.new("TextLabel")
    introTitle.Size = UDim2.new(1, 0, 0, 30)
    introTitle.Position = UDim2.new(0, 0, 0, 10)
    introTitle.BackgroundTransparency = 1
    introTitle.Text = titleText:upper()
    introTitle.TextColor3 = Theme.TextPrimary
    introTitle.Font = Theme.FontBold
    introTitle.TextSize = 13
    introTitle.TextTransparency = 1
    introTitle.Parent = introFrame

    local introBarBg = Instance.new("Frame")
    introBarBg.Size = UDim2.new(0.8, 0, 0, 4)
    introBarBg.Position = UDim2.new(0.1, 0, 0.7, 0)
    introBarBg.BackgroundColor3 = Theme.SecondaryBackground
    introBarBg.BackgroundTransparency = 1
    introBarBg.Parent = introFrame

    local introBarCorner = Instance.new("UICorner")
    introBarCorner.CornerRadius = UDim.new(1, 0)
    introBarCorner.Parent = introBarBg

    local introBarFill = Instance.new("Frame")
    introBarFill.Size = UDim2.new(0, 0, 1, 0)
    introBarFill.BackgroundColor3 = Theme.Accent
    introBarFill.Parent = introBarBg

    local introBarFillCorner = Instance.new("UICorner")
    introBarFillCorner.CornerRadius = UDim.new(1, 0)
    introBarFillCorner.Parent = introBarFill

    -- Hide all descendants of main frame initially for smooth fade in
    local function storeOriginalTrans()
        for _, desc in ipairs(frmMain:GetDescendants()) do
            if desc:IsA("Frame") or desc:IsA("ScrollingFrame") then
                if desc ~= frmMain then
                    desc:SetAttribute("OrigTrans", desc.BackgroundTransparency)
                    desc.BackgroundTransparency = 1
                end
            elseif desc:IsA("UIStroke") then
                if desc ~= fs1 then
                    desc:SetAttribute("OrigTrans", desc.Transparency)
                    desc.Transparency = 1
                end
            elseif desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                desc:SetAttribute("OrigTrans", desc.TextTransparency)
                desc.TextTransparency = 1
            end
        end
    end

    local function openWindow()
        frmMain.Visible = true
        Utils.tween(frmMain, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = windowSize,
            Position = UDim2.new(0.5, -windowSize.X.Offset/2, 0.5, -windowSize.Y.Offset/2),
            BackgroundTransparency = Theme.BackgroundTransparency
        })
        Utils.tween(fs1, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Transparency = Theme.StrokeTransparency
        })

        for _, desc in ipairs(frmMain:GetDescendants()) do
            if desc:IsA("Frame") or desc:IsA("ScrollingFrame") then
                if desc ~= frmMain then
                    local orig = desc:GetAttribute("OrigTrans") or 0
                    Utils.tween(desc, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = orig})
                end
            elseif desc:IsA("UIStroke") then
                if desc ~= fs1 then
                    local orig = desc:GetAttribute("OrigTrans") or 0
                    Utils.tween(desc, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = orig})
                end
            elseif desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                local orig = desc:GetAttribute("OrigTrans") or 0
                Utils.tween(desc, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = orig})
            end
        end

        Utils.tween(btnTgl, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.15})
        Utils.tween(bs1, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 0.90})
        Utils.tween(lblTitleTgl, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0})
    end

    -- Run intro animations in separate thread
    task.spawn(function()
        task.wait(0.2)

        -- ==========================================
        -- ADVANCED BRAND INTRO ("NMZUI") - No Box, No BG
        -- ==========================================
        local brandContainer = Instance.new("Frame")
        brandContainer.Size = UDim2.new(1, 0, 1, 0)
        brandContainer.BackgroundTransparency = 1
        brandContainer.Parent = gui

        local letters = {"N", "M", "Z", "U", "I"}
        local labels = {}
        
        -- Spacing offsets for font size 42 centered
        local offsets = {
            N = -65,
            M = -31,
            Z = 5,
            U = 35,
            I = 61
        }

        for _, char in ipairs(letters) do
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(0, 40, 0, 50)
            lbl.Position = UDim2.new(0.5, -20, 0.5, -25) -- Start overlapping at exact center
            lbl.BackgroundTransparency = 1
            lbl.Text = char
            lbl.Font = Theme.FontBold
            lbl.TextSize = 42
            lbl.TextColor3 = Theme.TextPrimary
            lbl.TextTransparency = 1
            lbl.Parent = brandContainer
            labels[char] = lbl
        end

        -- 1. Fade in 'N' at the center
        Utils.tween(labels["N"], TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            TextTransparency = 0
        })
        task.wait(0.5)

        -- 2. Expand dynamically from center to full "NMZUI" word
        local expandInfo = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        for _, char in ipairs(letters) do
            Utils.tween(labels[char], expandInfo, {
                Position = UDim2.new(0.5, offsets[char], 0.5, -25),
                TextTransparency = 0
            })
        end
        task.wait(0.9)

        -- 3. Collapse back to center and fade out completely
        local collapseInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        for _, char in ipairs(letters) do
            Utils.tween(labels[char], collapseInfo, {
                Position = UDim2.new(0.5, -20, 0.5, -25),
                TextTransparency = 1
            })
        end
        task.wait(0.45)
        brandContainer:Destroy()

        -- ==========================================
        -- SECOND INTRO: LOADING CARD WITH PROGRESS BAR
        -- ==========================================
        task.wait(0.1)
        introFrame.Visible = true
        Utils.tween(introFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = Theme.BackgroundTransparency})
        Utils.tween(introStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = Theme.StrokeTransparency})
        Utils.tween(introTitle, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0})
        Utils.tween(introBarBg, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0})

        task.wait(0.15)
        
        -- Smooth progress bar loading
        local barTween = Utils.tween(introBarFill, TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, 0, 1, 0)
        })
        barTween.Completed:Wait()
        task.wait(0.15)

        -- Fade out Loading Card Frame
        Utils.tween(introFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 200, 0, 60),
            Position = UDim2.new(0.5, -100, 0.5, -30),
            BackgroundTransparency = 1
        })
        Utils.tween(introTitle, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1})
        Utils.tween(introBarBg, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
        Utils.tween(introBarFill, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
        Utils.tween(introStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1})

        task.wait(0.3)
        introFrame:Destroy()

        -- Store and fade out all children
        storeOriginalTrans()

        if type(options.OnIntroCompleted) == "function" then
            task.spawn(options.OnIntroCompleted)
        end

        if options.HideOnStartup then
            return
        end

        openWindow()
    end)

    -- Toggle close/open transition (Collapse / Expand)
    local clickTime = 0
    local isAnimating = false
    
    btnTgl.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            clickTime = tick()
        end
    end)

    btnTgl.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if tick() - clickTime < 0.2 and not isAnimating then
                isAnimating = true
                if frmMain.Visible then
                    -- Collapse Animation (Closing)
                    local targetSize = UDim2.new(windowSize.X.Scale, windowSize.X.Offset - 20, windowSize.Y.Scale, windowSize.Y.Offset - 20)
                    local targetPos = UDim2.new(0.5, -targetSize.X.Offset/2, 0.5, -targetSize.Y.Offset/2)
                    
                    -- Fade out descendants
                    for _, desc in ipairs(frmMain:GetDescendants()) do
                        if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                            Utils.tween(desc, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1})
                        elseif desc:IsA("Frame") or desc:IsA("ScrollingFrame") then
                            if desc ~= frmMain then
                                Utils.tween(desc, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
                            end
                        elseif desc:IsA("UIStroke") then
                            if desc ~= fs1 then
                                Utils.tween(desc, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1})
                            end
                        end
                    end
                    
                    Utils.tween(frmMain, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Size = targetSize,
                        Position = targetPos,
                        BackgroundTransparency = 1
                    })
                    local strokeTween = Utils.tween(fs1, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Transparency = 1
                    })
                    
                    strokeTween.Completed:Wait()
                    frmMain.Visible = false
                    isAnimating = false
                else
                    -- Expand Animation (Opening)
                    frmMain.Visible = true
                    local initialSize = UDim2.new(windowSize.X.Scale, windowSize.X.Offset - 20, windowSize.Y.Scale, windowSize.Y.Offset - 20)
                    local initialPos = UDim2.new(0.5, -initialSize.X.Offset/2, 0.5, -initialSize.Y.Offset/2)
                    
                    frmMain.Size = initialSize
                    frmMain.Position = initialPos
                    frmMain.BackgroundTransparency = 1
                    fs1.Transparency = 1
                    
                    Utils.tween(frmMain, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                        Size = windowSize,
                        Position = UDim2.new(0.5, -windowSize.X.Offset/2, 0.5, -windowSize.Y.Offset/2),
                        BackgroundTransparency = Theme.BackgroundTransparency
                    })
                    Utils.tween(fs1, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Transparency = Theme.StrokeTransparency
                    })
                    
                    -- Fade in descendants
                    for _, desc in ipairs(frmMain:GetDescendants()) do
                        if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                            local orig = desc:GetAttribute("OrigTrans") or 0
                            Utils.tween(desc, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = orig})
                        elseif desc:IsA("Frame") or desc:IsA("ScrollingFrame") then
                            if desc ~= frmMain then
                                local orig = desc:GetAttribute("OrigTrans") or 0
                                Utils.tween(desc, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = orig})
                            end
                        elseif desc:IsA("UIStroke") then
                            if desc ~= fs1 then
                                local orig = desc:GetAttribute("OrigTrans") or 0
                                Utils.tween(desc, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = orig})
                            end
                        end
                    end
                    
                    task.wait(0.3)
                    isAnimating = false
                end
            end
        end
    end)

    Drag.makeDraggable(frmMain)
    
    local self = {
        gui = gui,
        mainFrame = frmMain,
        leftPanel = leftPanel,
        rightPanel = rightPanel,
        tabContainer = tabCont,
        theme = Theme,
        show = openWindow,
        destroy = function()
            gui:Destroy()
        end
    }
    
    return self
end

return Window
