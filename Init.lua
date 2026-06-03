-- Universal UI Library (Bundled)
local _modules = {}

-- Module: Theme
_modules["Theme"] = (function()
    local Theme = {
        -- Fonts
        FontBold = Enum.Font.GothamBold,
        FontMedium = Enum.Font.GothamMedium,
        
        -- Colors (Refined Minimalist Dark)
        Background = Color3.fromRGB(12, 12, 14),             -- Deep obsidian gray
        PanelBackground = Color3.fromRGB(20, 20, 24),        -- Slate panel fill
        Accent = Color3.fromRGB(70, 130, 200),               -- Premium muted steel blue
        AccentHover = Color3.fromRGB(85, 145, 215),          -- Slate blue slightly brighter
        SecondaryBackground = Color3.fromRGB(30, 30, 36),   -- Component container/knob color
        TabInactive = Color3.fromRGB(16, 16, 20),
        TabActive = Color3.fromRGB(28, 28, 34),
        TextPrimary = Color3.fromRGB(255, 255, 255),         -- Pure white
        TextSecondary = Color3.fromRGB(200, 200, 205),       -- Muted light gray
        TextMuted = Color3.fromRGB(120, 120, 125),           -- Darker gray
        Stroke = Color3.fromRGB(255, 255, 255),              -- Thin overlay white stroke
        
        -- Transparencies
        BackgroundTransparency = 0.05,
        PanelTransparency = 0.4,
        StrokeTransparency = 0.94,                           -- Extremely faint white lines
        PanelStrokeTransparency = 0.96,                      -- Barely visible borders for premium feel
        
        -- Misc
        CornerRadius = UDim.new(0, 6),
        WindowCornerRadius = UDim.new(0, 10)
    }
    
    return Theme
end)()

-- Module: Utils
_modules["Utils"] = (function()
    local Utils = {}
    
    function Utils.safeSvc(n)
        local s = game:GetService(n)
        if cloneref then return cloneref(s) end
        return s
    end
    
    function Utils.getSafeGui()
        if gethui then return gethui() end
        local lplr = Utils.safeSvc("Players").LocalPlayer
        local cgOk, cg = pcall(function() return Utils.safeSvc("CoreGui") end)
        if cgOk and cg then return cg end
        return lplr:WaitForChild("PlayerGui")
    end
    
    function Utils.tween(obj, info, props)
        local ts = Utils.safeSvc("TweenService")
        local tw = ts:Create(obj, info, props)
        tw:Play()
        return tw
    end
    
    return Utils
end)()

-- Module: Drag
_modules["Drag"] = (function()
    local Drag = {}
    
    local import = function(name)
        local ok, res = pcall(function() return require(script.Parent[name]) end)
        if ok then return res end
        return _G.UniversalUILib_GetModule(name)
    end
    
    local Utils = _modules["Utils"]
    local uis = Utils.safeSvc("UserInputService")
    
    function Drag.makeDraggable(draggableGui, targetGui)
        targetGui = targetGui or draggableGui
        
        local dragging = false
        local dragStart = nil
        local startPos = nil
        local conns = {}
    
        table.insert(conns, draggableGui.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = targetGui.Position
            end
        end))
    
        table.insert(conns, uis.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                if dragging then
                    local delta = input.Position - dragStart
                    local ti = TweenInfo.new(0.08, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
                    Utils.tween(targetGui, ti, {
                        Position = UDim2.new(
                            startPos.X.Scale, startPos.X.Offset + delta.X, 
                            startPos.Y.Scale, startPos.Y.Offset + delta.Y
                        )
                    })
                end
            end
        end))
    
        table.insert(conns, uis.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end))
        
        return conns
    end
    
    return Drag
end)()

-- Module: Window
_modules["Window"] = (function()
    local Window = {}
    
    local import = function(name)
        local ok, res = pcall(function() return require(script.Parent[name]) end)
        if ok then return res end
        return _G.UniversalUILib_GetModule(name)
    end
    
    local DefaultTheme = _modules["Theme"]
    local Utils = _modules["Utils"]
    local Drag = _modules["Drag"]
    
    function Window.new(options)
        if type(options) == "string" then
            options = { Title = options }
        end
        options = options or {}
        
        local Theme = options.Theme or DefaultTheme
        local titleText = options.Title or "Universal UI"
        local windowSize = options.Size or UDim2.new(0, 600, 0, 380)
        
        local toggleText = options.ToggleText or "UI"
        local uis = Utils.safeSvc("UserInputService")
        local isMobile = uis.TouchEnabled
        local toggleKey = options.Keybind or Enum.KeyCode.LeftAlt
        
        local self = {}
        
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
        btnTgl.Visible = false
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
                task.spawn(function() options.OnIntroCompleted(self) end)
            end
    
            if options.HideOnStartup then
                if isMobile then
                    btnTgl.Visible = true
                    Utils.tween(btnTgl, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.15})
                    Utils.tween(bs1, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 0.90})
                    Utils.tween(lblTitleTgl, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0})
                end
                return
            end
    
            openWindow()
        end)
    
        -- Toggle close/open transition (Collapse / Expand)
        local clickTime = 0
        local isAnimating = false
        
        local function toggleUI()
            if isAnimating then return end
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
                
                if isMobile then
                    btnTgl.Visible = true
                    Utils.tween(btnTgl, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.15})
                    Utils.tween(bs1, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 0.90})
                    Utils.tween(lblTitleTgl, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0})
                else
                    local Notify = _modules["Notify"]
                    if Notify then
                        Notify.show("UI Hidden", "Press " .. toggleKey.Name .. " to open the menu.", 3, Theme)
                    end
                end
                
                isAnimating = false
            else
                -- Expand Animation (Opening)
                if isMobile then
                    Utils.tween(btnTgl, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
                    Utils.tween(bs1, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1})
                    Utils.tween(lblTitleTgl, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1})
                    task.delay(0.2, function() btnTgl.Visible = false end)
                end
                
                openWindow()
                task.wait(0.3)
                isAnimating = false
            end
        end
        
        btnTgl.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                clickTime = tick()
            end
        end)
    
        btnTgl.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                if tick() - clickTime < 0.2 and not isAnimating then
                    toggleUI()
                end
            end
        end)
    
        uis.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.KeyCode == toggleKey then
                toggleUI()
            end
        end)
    
        Drag.makeDraggable(frmMain)
        
        self.gui = gui
        self.mainFrame = frmMain
        self.leftPanel = leftPanel
        self.rightPanel = rightPanel
        self.tabContainer = tabCont
        self.theme = Theme
        self.show = openWindow
        self.destroy = function()
            gui:Destroy()
        end
        
        return self
    end
    
    return Window
end)()

-- Module: Tab
_modules["Tab"] = (function()
    local Tab = {}
    
    local import = function(name)
        local ok, res = pcall(function() return require(script.Parent[name]) end)
        if ok then return res end
        return _G.UniversalUILib_GetModule(name)
    end
    
    local Theme = _modules["Theme"]
    local Utils = _modules["Utils"]
    
    function Tab.new(window, name, order)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -20, 0, 32)
        btn.BackgroundColor3 = Theme.TabInactive
        btn.Text = name
        btn.TextColor3 = Theme.TextMuted
        btn.Font = Theme.FontBold
        btn.TextSize = 11
        btn.LayoutOrder = order or 1
        local c = Instance.new("UICorner")
        c.CornerRadius = Theme.CornerRadius
        c.Parent = btn
        btn.Parent = window.tabContainer
    
        local frm = Instance.new("ScrollingFrame")
        frm.Size = UDim2.new(1, -20, 1, -20)
        frm.Position = UDim2.new(0, 15, 0, 10)
        frm.BackgroundTransparency = 1
        frm.ScrollBarThickness = 2
        frm.ScrollBarImageColor3 = Theme.Accent
        frm.ScrollBarImageTransparency = 0.5
        frm.Visible = false
        frm.Parent = window.rightPanel
        
        local lay = Instance.new("UIListLayout")
        lay.SortOrder = Enum.SortOrder.LayoutOrder
        lay.Padding = UDim.new(0, 6)
        lay.HorizontalAlignment = Enum.HorizontalAlignment.Left
        lay.Parent = frm
        local pad = Instance.new("UIPadding")
        pad.PaddingRight = UDim.new(0, 10)
        pad.Parent = frm
        
        local self = {
            button = btn,
            container = frm,
            name = name,
            window = window
        }
        
        -- Smooth hover transition for Tab button
        btn.MouseEnter:Connect(function()
            if not (btn.BackgroundColor3 == Theme.TabActive) then
                Utils.tween(btn, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
                    BackgroundColor3 = Theme.SecondaryBackground,
                    TextColor3 = Theme.TextSecondary
                })
            end
        end)
        btn.MouseLeave:Connect(function()
            if not (btn.BackgroundColor3 == Theme.TabActive) then
                Utils.tween(btn, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
                    BackgroundColor3 = Theme.TabInactive,
                    TextColor3 = Theme.TextMuted
                })
            end
        end)
        
        btn.MouseButton1Click:Connect(function()
            Tab.switch(window, name)
        end)
        
        if not window.tabs then window.tabs = {} end
        table.insert(window.tabs, self)
        
        if #window.tabs == 1 then
            Tab.switch(window, name)
        end
        
        return self
    end
    
    function Tab.switch(window, tabName)
        local ti = TweenInfo.new(0.2, Enum.EasingStyle.Sine)
        if window.tabs then
            for _, tab in ipairs(window.tabs) do
                local isSelected = (tab.name == tabName)
                if isSelected and not tab.container.Visible then
                    tab.container.Visible = true
                    -- Subtle fade-in slide animation
                    tab.container.Position = UDim2.new(0, 15, 0, 16)
                    Utils.tween(tab.container, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Position = UDim2.new(0, 15, 0, 10)
                    })
                elseif not isSelected then
                    tab.container.Visible = false
                end
                
                Utils.tween(tab.button, ti, {
                    BackgroundColor3 = isSelected and Theme.TabActive or Theme.TabInactive,
                    TextColor3 = isSelected and Theme.TextPrimary or Theme.TextMuted
                })
            end
        end
    end
    
    return Tab
end)()

-- Module: Button
_modules["Button"] = (function()
    local Button = {}
    
    local import = function(name)
        local ok, res = pcall(function() return require(script.Parent[name]) end)
        if ok then return res end
        return _G.UniversalUILib_GetModule(name)
    end
    
    local Theme = _modules["Theme"]
    local Utils = _modules["Utils"]
    
    function Button.new(parent, name, cb)
        local text = type(name) == "table" and (name.Name or name[1]) or name
        local desc = type(name) == "table" and (name.Desc or name[2]) or nil
    
        local frm = Instance.new("Frame")
        frm.Size = UDim2.new(1, 0, 0, desc and 48 or 36)
        frm.BackgroundColor3 = Theme.PanelBackground
        frm.BackgroundTransparency = Theme.PanelTransparency
        frm.Parent = parent
        
        local c = Instance.new("UICorner")
        c.CornerRadius = Theme.CornerRadius
        c.Parent = frm
        
        local s = Instance.new("UIStroke")
        s.Color = Theme.Stroke
        s.Transparency = Theme.PanelStrokeTransparency
        s.Parent = frm
        
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.Parent = frm
        
        local lbl = Instance.new("TextLabel")
        lbl.Size = desc and UDim2.new(1, 0, 0, 16) or UDim2.new(1, 0, 1, 0)
        lbl.Position = desc and UDim2.new(0, 0, 0, 8) or UDim2.new(0, 0, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = Theme.TextSecondary
        lbl.Font = Theme.FontMedium
        lbl.TextSize = 12
        lbl.Parent = frm
        
        if desc then
            local lblDesc = Instance.new("TextLabel")
            lblDesc.Size = UDim2.new(1, 0, 0, 14)
            lblDesc.Position = UDim2.new(0, 0, 0, 26)
            lblDesc.BackgroundTransparency = 1
            lblDesc.Text = desc
            lblDesc.TextColor3 = Theme.TextSecondary
            lblDesc.TextTransparency = 0.4
            lblDesc.Font = Theme.FontMedium
            lblDesc.TextSize = 11
            lblDesc.Parent = frm
        end
        
        -- Smooth hover transition
        btn.MouseEnter:Connect(function()
            Utils.tween(frm, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
                BackgroundColor3 = Theme.SecondaryBackground
            })
            Utils.tween(lbl, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
                TextColor3 = Theme.TextPrimary
            })
        end)
        btn.MouseLeave:Connect(function()
            Utils.tween(frm, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
                BackgroundColor3 = Theme.PanelBackground
            })
            Utils.tween(lbl, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
                TextColor3 = Theme.TextSecondary
            })
        end)
        
        btn.MouseButton1Click:Connect(function()
            local ti = TweenInfo.new(0.1, Enum.EasingStyle.Sine)
            Utils.tween(frm, ti, {BackgroundColor3 = Theme.Accent})
            task.delay(0.1, function()
                pcall(function() 
                    Utils.tween(frm, ti, {
                        BackgroundColor3 = (btn.Active and Theme.SecondaryBackground) or Theme.PanelBackground
                    }) 
                end)
            end)
            if cb then cb() end
        end)
        
        local self = {
            frame = frm,
            button = btn
        }
        return self
    end
    
    return Button
end)()

-- Module: Toggle
_modules["Toggle"] = (function()
    local Toggle = {}
    
    local import = function(name)
        local ok, res = pcall(function() return require(script.Parent[name]) end)
        if ok then return res end
        return _G.UniversalUILib_GetModule(name)
    end
    
    local Theme = _modules["Theme"]
    local Utils = _modules["Utils"]
    
    function Toggle.new(parent, name, defaultState, cb)
        local text = type(name) == "table" and (name.Name or name[1]) or name
        local desc = type(name) == "table" and (name.Desc or name[2]) or nil
    
        local stateVal = defaultState or false
        
        local frm = Instance.new("Frame")
        frm.Size = UDim2.new(1, 0, 0, desc and 48 or 36)
        frm.BackgroundColor3 = Theme.PanelBackground
        frm.BackgroundTransparency = Theme.PanelTransparency
        frm.Parent = parent
        local c = Instance.new("UICorner")
        c.CornerRadius = Theme.CornerRadius
        c.Parent = frm
        local s = Instance.new("UIStroke")
        s.Color = Theme.Stroke
        s.Transparency = Theme.PanelStrokeTransparency
        s.Parent = frm
        
        local lbl = Instance.new("TextLabel")
        lbl.Size = desc and UDim2.new(0.7, 0, 0, 16) or UDim2.new(0.7, 0, 1, 0)
        lbl.Position = desc and UDim2.new(0, 12, 0, 8) or UDim2.new(0, 12, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = Theme.TextSecondary
        lbl.Font = Theme.FontMedium
        lbl.TextSize = 12
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = frm
        
        if desc then
            local lblDesc = Instance.new("TextLabel")
            lblDesc.Size = UDim2.new(0.7, 0, 0, 14)
            lblDesc.Position = UDim2.new(0, 12, 0, 26)
            lblDesc.BackgroundTransparency = 1
            lblDesc.Text = desc
            lblDesc.TextColor3 = Theme.TextSecondary
            lblDesc.TextTransparency = 0.4
            lblDesc.Font = Theme.FontMedium
            lblDesc.TextSize = 11
            lblDesc.TextXAlignment = Enum.TextXAlignment.Left
            lblDesc.Parent = frm
        end
        
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 34, 0, 18)
        btn.Position = UDim2.new(1, -46, 0.5, -9)
        btn.BackgroundColor3 = stateVal and Theme.Accent or Theme.SecondaryBackground
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.Parent = frm
        local bc = Instance.new("UICorner")
        bc.CornerRadius = UDim.new(1, 0)
        bc.Parent = btn
        
        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 14, 0, 14)
        knob.Position = stateVal and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
        knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        knob.Parent = btn
        local kc = Instance.new("UICorner")
        kc.CornerRadius = UDim.new(1, 0)
        kc.Parent = knob
        
        local function updateVisuals()
            local ti = TweenInfo.new(0.2, Enum.EasingStyle.Sine)
            Utils.tween(btn, ti, {BackgroundColor3 = stateVal and Theme.Accent or Theme.SecondaryBackground})
            Utils.tween(knob, ti, {Position = stateVal and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)})
        end
        
        -- Smooth hover transition
        frm.MouseEnter:Connect(function()
            Utils.tween(frm, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {BackgroundColor3 = Theme.SecondaryBackground})
            Utils.tween(lbl, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {TextColor3 = Theme.TextPrimary})
        end)
        frm.MouseLeave:Connect(function()
            Utils.tween(frm, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {BackgroundColor3 = Theme.PanelBackground})
            Utils.tween(lbl, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {TextColor3 = Theme.TextSecondary})
        end)
        
        btn.MouseButton1Click:Connect(function()
            stateVal = not stateVal
            updateVisuals()
            if cb then cb(stateVal) end
        end)
        
        local self = {
            frame = frm,
            button = btn,
            set = function(val)
                stateVal = val
                updateVisuals()
                if cb then cb(stateVal) end
            end,
            get = function() return stateVal end
        }
        return self
    end
    
    return Toggle
end)()

-- Module: Slider
_modules["Slider"] = (function()
    local Slider = {}
    
    local import = function(name)
        local ok, res = pcall(function() return require(script.Parent[name]) end)
        if ok then return res end
        return _G.UniversalUILib_GetModule(name)
    end
    
    local Theme = _modules["Theme"]
    local Utils = _modules["Utils"]
    
    function Slider.new(parent, name, minVal, maxVal, defaultVal, formatFunc, cb)
        local uis = Utils.safeSvc("UserInputService")
        local formatVal = formatFunc or function(v) return tostring(v) end
        
        local frm = Instance.new("Frame")
        frm.Size = UDim2.new(1, 0, 0, 48)
        frm.BackgroundColor3 = Theme.PanelBackground
        frm.BackgroundTransparency = Theme.PanelTransparency
        frm.Parent = parent
        local c = Instance.new("UICorner")
        c.CornerRadius = Theme.CornerRadius
        c.Parent = frm
        local s = Instance.new("UIStroke")
        s.Color = Theme.Stroke
        s.Transparency = Theme.PanelStrokeTransparency
        s.Parent = frm
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -24, 0, 20)
        lbl.Position = UDim2.new(0, 12, 0, 6)
        lbl.BackgroundTransparency = 1
        lbl.Text = name .. ": " .. formatVal(defaultVal)
        lbl.TextColor3 = Theme.TextSecondary
        lbl.Font = Theme.FontMedium
        lbl.TextSize = 12
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = frm
        local bg = Instance.new("Frame")
        bg.Size = UDim2.new(1, -24, 0, 5)
        bg.Position = UDim2.new(0, 12, 0, 32)
        bg.BackgroundColor3 = Theme.SecondaryBackground
        bg.Parent = frm
        local bc = Instance.new("UICorner")
        bc.CornerRadius = UDim.new(1, 0)
        bc.Parent = bg
        local fil = Instance.new("Frame")
        local pct = (defaultVal - minVal) / (maxVal - minVal)
        fil.Size = UDim2.new(pct, 0, 1, 0)
        fil.BackgroundColor3 = Theme.Accent
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
        local currentVal = defaultVal
        
        local function updateSlider(inputPos)
            local p = math.clamp(inputPos.X - bg.AbsolutePosition.X, 0, bg.AbsoluteSize.X) / bg.AbsoluteSize.X
            currentVal = minVal + (maxVal - minVal) * p
            fil.Size = UDim2.new(p, 0, 1, 0)
            lbl.Text = name .. ": " .. formatVal(currentVal)
            if cb then cb(currentVal) end
        end
        
        -- Smooth hover transitions
        frm.MouseEnter:Connect(function()
            Utils.tween(frm, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {BackgroundColor3 = Theme.SecondaryBackground})
            Utils.tween(lbl, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {TextColor3 = Theme.TextPrimary})
            Utils.tween(fil, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {BackgroundColor3 = Theme.AccentHover})
        end)
        frm.MouseLeave:Connect(function()
            Utils.tween(frm, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {BackgroundColor3 = Theme.PanelBackground})
            Utils.tween(lbl, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {TextColor3 = Theme.TextSecondary})
            Utils.tween(fil, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {BackgroundColor3 = Theme.Accent})
        end)
        
        btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                sliding = true
                updateSlider(input.Position)
            end
        end)
        uis.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                sliding = false
            end
        end)
        uis.InputChanged:Connect(function(input)
            if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                updateSlider(input.Position)
            end
        end)
        
        local self = {
            frame = frm,
            set = function(val)
                currentVal = math.clamp(val, minVal, maxVal)
                local p = (currentVal - minVal) / (maxVal - minVal)
                fil.Size = UDim2.new(p, 0, 1, 0)
                lbl.Text = name .. ": " .. formatVal(currentVal)
                if cb then cb(currentVal) end
            end,
            get = function() return currentVal end
        }
        return self
    end
    
    return Slider
end)()

-- Module: Dropdown
_modules["Dropdown"] = (function()
    local Dropdown = {}
    
    local import = function(name)
        local ok, res = pcall(function() return require(script.Parent[name]) end)
        if ok then return res end
        return _G.UniversalUILib_GetModule(name)
    end
    
    local Theme = _modules["Theme"]
    local Utils = _modules["Utils"]
    
    function Dropdown.new(parent, name, opts, defaultIdx, cb)
        local frm = Instance.new("Frame")
        frm.Size = UDim2.new(1, 0, 0, 36)
        frm.BackgroundColor3 = Theme.PanelBackground
        frm.BackgroundTransparency = Theme.PanelTransparency
        frm.Parent = parent
        local c = Instance.new("UICorner")
        c.CornerRadius = Theme.CornerRadius
        c.Parent = frm
        local s = Instance.new("UIStroke")
        s.Color = Theme.Stroke
        s.Transparency = Theme.PanelStrokeTransparency
        s.Parent = frm
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.5, 0, 1, 0)
        lbl.Position = UDim2.new(0, 12, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = name
        lbl.TextColor3 = Theme.TextSecondary
        lbl.Font = Theme.FontMedium
        lbl.TextSize = 12
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = frm
        
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 96, 0, 20)
        btn.Position = UDim2.new(1, -108, 0.5, -10)
        btn.BackgroundColor3 = Theme.SecondaryBackground
        btn.Text = opts[defaultIdx].name
        btn.TextColor3 = Theme.TextSecondary
        btn.Font = Theme.FontBold
        btn.TextSize = 10
        btn.Parent = frm
        local bc = Instance.new("UICorner")
        bc.CornerRadius = UDim.new(0, 4)
        bc.Parent = btn
        
        local cur = defaultIdx
        
        -- Smooth hover transitions
        frm.MouseEnter:Connect(function()
            Utils.tween(frm, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {BackgroundColor3 = Theme.SecondaryBackground})
            Utils.tween(lbl, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {TextColor3 = Theme.TextPrimary})
            Utils.tween(btn, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {TextColor3 = Theme.TextPrimary})
        end)
        frm.MouseLeave:Connect(function()
            Utils.tween(frm, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {BackgroundColor3 = Theme.PanelBackground})
            Utils.tween(lbl, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {TextColor3 = Theme.TextSecondary})
            Utils.tween(btn, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {TextColor3 = Theme.TextSecondary})
        end)
        
        btn.MouseButton1Click:Connect(function()
            cur = cur + 1
            if cur > #opts then cur = 1 end
            btn.Text = opts[cur].name
            if cb then cb(opts[cur].val) end
        end)
        
        local self = {
            frame = frm,
            button = btn,
            setOptions = function(newOpts, newDefaultIdx)
                opts = newOpts
                cur = newDefaultIdx or 1
                btn.Text = opts[cur].name
                if cb then cb(opts[cur].val) end
            end,
            get = function() return opts[cur].val end
        }
        return self
    end
    
    return Dropdown
end)()

-- Module: Textbox
_modules["Textbox"] = (function()
    local Textbox = {}
    
    local import = function(name)
        local ok, res = pcall(function() return require(script.Parent[name]) end)
        if ok then return res end
        return _G.UniversalUILib_GetModule(name)
    end
    
    local Theme = _modules["Theme"]
    local Utils = _modules["Utils"]
    
    function Textbox.new(parent, name, placeholderText, cb)
        local frm = Instance.new("Frame")
        frm.Size = UDim2.new(1, 0, 0, 36)
        frm.BackgroundColor3 = Theme.PanelBackground
        frm.BackgroundTransparency = Theme.PanelTransparency
        frm.Parent = parent
        local c = Instance.new("UICorner")
        c.CornerRadius = Theme.CornerRadius
        c.Parent = frm
        local s = Instance.new("UIStroke")
        s.Color = Theme.Stroke
        s.Transparency = Theme.PanelStrokeTransparency
        s.Parent = frm
        
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.4, 0, 1, 0)
        lbl.Position = UDim2.new(0, 12, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = name
        lbl.TextColor3 = Theme.TextSecondary
        lbl.Font = Theme.FontMedium
        lbl.TextSize = 12
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = frm
        
        local boxBg = Instance.new("Frame")
        boxBg.Size = UDim2.new(0.5, 0, 0, 20)
        boxBg.Position = UDim2.new(1, -boxBg.Size.X.Offset - (boxBg.Size.X.Scale * frm.AbsoluteSize.X) - 12, 0.5, -10)
        boxBg.BackgroundColor3 = Theme.SecondaryBackground
        boxBg.Parent = frm
        local boxCorner = Instance.new("UICorner")
        boxCorner.CornerRadius = UDim.new(0, 4)
        boxCorner.Parent = boxBg
        
        local boxStroke = Instance.new("UIStroke")
        boxStroke.Color = Theme.Stroke
        boxStroke.Transparency = 0.95
        boxStroke.Parent = boxBg
        
        frm:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            boxBg.Position = UDim2.new(1, -boxBg.Size.X.Offset - (boxBg.Size.X.Scale * frm.AbsoluteSize.X) - 12, 0.5, -10)
        end)
        
        local txt = Instance.new("TextBox")
        txt.Size = UDim2.new(1, -10, 1, 0)
        txt.Position = UDim2.new(0, 5, 0, 0)
        txt.BackgroundTransparency = 1
        txt.Text = ""
        txt.PlaceholderText = placeholderText or "Enter text..."
        txt.PlaceholderColor3 = Theme.TextMuted
        txt.TextColor3 = Theme.TextPrimary
        txt.Font = Theme.FontMedium
        txt.TextSize = 11
        txt.TextXAlignment = Enum.TextXAlignment.Left
        txt.ClearTextOnFocus = false
        txt.Parent = boxBg
        
        -- Smooth hover and focus transitions
        frm.MouseEnter:Connect(function()
            Utils.tween(frm, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {BackgroundColor3 = Theme.SecondaryBackground})
            Utils.tween(lbl, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {TextColor3 = Theme.TextPrimary})
        end)
        frm.MouseLeave:Connect(function()
            Utils.tween(frm, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {BackgroundColor3 = Theme.PanelBackground})
            Utils.tween(lbl, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {TextColor3 = Theme.TextSecondary})
        end)
        
        txt.Focused:Connect(function()
            Utils.tween(boxStroke, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {
                Color = Theme.Accent,
                Transparency = 0.5
            })
        end)
        txt.FocusLost:Connect(function(enterPressed)
            Utils.tween(boxStroke, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {
                Color = Theme.Stroke,
                Transparency = 0.95
            })
            if cb then cb(txt.Text, enterPressed) end
        end)
        
        local self = {
            frame = frm,
            textbox = txt,
            get = function() return txt.Text end,
            set = function(text) txt.Text = text end
        }
        return self
    end
    
    return Textbox
end)()

-- Module: Components
_modules["Components"] = (function()
    local Components = {}
    
    local import = function(name)
        local ok, res = pcall(function() return require(script.Parent[name]) end)
        if ok then return res end
        return _G.UniversalUILib_GetModule(name)
    end
    
    Components.Button = _modules["Button"]
    Components.Toggle = _modules["Toggle"]
    Components.Slider = _modules["Slider"]
    Components.Dropdown = _modules["Dropdown"]
    Components.Textbox = _modules["Textbox"]
    Components.Tab = _modules["Tab"]
    
    return Components
end)()

-- Module: Notification
_modules["Notification"] = (function()
    local Notification = {}
    
    local import = function(name)
        local ok, res = pcall(function() return require(script.Parent[name]) end)
        if ok then return res end
        return _G.UniversalUILib_GetModule(name)
    end
    
    local Theme = _modules["Theme"]
    local Utils = _modules["Utils"]
    
    local containerGui = nil
    local listFrame = nil
    
    local function getContainer()
        if containerGui and containerGui.Parent then
            return listFrame
        end
        
        containerGui = Instance.new("ScreenGui")
        containerGui.Name = "UniversalUINotify"
        containerGui.ResetOnSpawn = false
        containerGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        containerGui.Parent = Utils.getSafeGui()
        
        listFrame = Instance.new("Frame")
        listFrame.Size = UDim2.new(0, 280, 1, -40)
        listFrame.Position = UDim2.new(1, -20, 0, 20)
        listFrame.AnchorPoint = Vector2.new(1, 0)
        listFrame.BackgroundTransparency = 1
        listFrame.Parent = containerGui
        
        local layout = Instance.new("UIListLayout")
        layout.FillDirection = Enum.FillDirection.Vertical
        layout.VerticalAlignment = Enum.VerticalAlignment.Top
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        layout.Padding = UDim.new(0, 10)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = listFrame
        
        return listFrame
    end
    
    function Notification.show(config)
        if type(config) == "string" then
            config = { Title = "Notification", Content = config }
        end
        config = config or {}
        
        local title = config.Title or config.title or "Notification"
        local content = config.Content or config.content or ""
        local duration = config.Duration or config.duration or 4
        
        local parent = getContainer()
        
        -- Main Toast Card
        local card = Instance.new("Frame")
        card.Size = UDim2.new(0, 260, 0, 56)
        card.BackgroundColor3 = Theme.PanelBackground
        card.BackgroundTransparency = Theme.PanelTransparency
        card.Parent = parent
        
        local c = Instance.new("UICorner")
        c.CornerRadius = Theme.CornerRadius
        c.Parent = card
        
        local s = Instance.new("UIStroke")
        s.Color = Theme.Stroke
        s.Transparency = Theme.PanelStrokeTransparency
        s.Parent = card
        
        local lblTitle = Instance.new("TextLabel")
        lblTitle.Size = UDim2.new(1, -24, 0, 20)
        lblTitle.Position = UDim2.new(0, 12, 0, 6)
        lblTitle.BackgroundTransparency = 1
        lblTitle.Text = title
        lblTitle.TextColor3 = Theme.TextPrimary
        lblTitle.Font = Theme.FontBold
        lblTitle.TextSize = 11
        lblTitle.TextXAlignment = Enum.TextXAlignment.Left
        lblTitle.Parent = card
        
        local lblDesc = Instance.new("TextLabel")
        lblDesc.Size = UDim2.new(1, -24, 0, 24)
        lblDesc.Position = UDim2.new(0, 12, 0, 24)
        lblDesc.BackgroundTransparency = 1
        lblDesc.Text = content
        lblDesc.TextColor3 = Theme.TextSecondary
        lblDesc.Font = Theme.FontMedium
        lblDesc.TextSize = 10
        lblDesc.TextXAlignment = Enum.TextXAlignment.Left
        lblDesc.TextYAlignment = Enum.TextYAlignment.Top
        lblDesc.TextWrapped = true
        lblDesc.Parent = card
        
        -- Progress bar showing time left (Universal styling)
        local progressBg = Instance.new("Frame")
        progressBg.Size = UDim2.new(1, -24, 0, 2)
        progressBg.Position = UDim2.new(0, 12, 1, -5)
        progressBg.BackgroundColor3 = Theme.SecondaryBackground
        progressBg.BackgroundTransparency = 0.5
        progressBg.Parent = card
        
        local progressFill = Instance.new("Frame")
        progressFill.Size = UDim2.new(1, 0, 1, 0)
        progressFill.BackgroundColor3 = Theme.Accent
        progressFill.Parent = progressBg
        
        local pCorner = Instance.new("UICorner")
        pCorner.CornerRadius = UDim.new(1, 0)
        pCorner.Parent = progressBg
        local fCorner = Instance.new("UICorner")
        fCorner.CornerRadius = UDim.new(1, 0)
        fCorner.Parent = progressFill
    
        -- Hide initially for animate-in
        card.Size = UDim2.new(0, 260, 0, 0)
        card.BackgroundTransparency = 1
        s.Transparency = 1
        lblTitle.TextTransparency = 1
        lblDesc.TextTransparency = 1
        progressBg.BackgroundTransparency = 1
        progressFill.BackgroundTransparency = 1
        
        task.spawn(function()
            -- Animate In (Fade + Expand Height)
            Utils.tween(card, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 260, 0, 56),
                BackgroundTransparency = Theme.PanelTransparency
            })
            Utils.tween(s, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = Theme.PanelStrokeTransparency})
            Utils.tween(lblTitle, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0})
            Utils.tween(lblDesc, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0})
            Utils.tween(progressBg, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.5})
            Utils.tween(progressFill, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0})
            
            task.wait(0.3)
            
            -- Smooth progress bar countdown
            local shrinkTween = Utils.tween(progressFill, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
                Size = UDim2.new(0, 0, 1, 0)
            })
            shrinkTween.Completed:Wait()
            
            -- Animate Out (Fade + Collapse Height)
            Utils.tween(card, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 260, 0, 0),
                BackgroundTransparency = 1
            })
            Utils.tween(s, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1})
            Utils.tween(lblTitle, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1})
            Utils.tween(lblDesc, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1})
            Utils.tween(progressBg, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
            Utils.tween(progressFill, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
            
            task.wait(0.3)
            card:Destroy()
        end)
    end
    
    return Notification
end)()

-- Module: Auth
_modules["Auth"] = (function()
    local Auth = {}
    local Theme = _modules["Theme"]
    local Utils = _modules["Utils"]
    local Drag = _modules["Drag"]
    
    function Auth.show(config)
        config = config or {}
        local titleText = config.Title or "AUTH"
        local subtitleText = config.Subtitle or "Please enter your key."
        local placeholder = config.KeyPlaceholder or "Enter Key..."
        local submitText = config.SubmitText or "Verify Key"
        local onSubmit = config.OnSubmit
        local links = config.Links or {}
    
        local ts = Utils.safeSvc("TweenService")
        
        local gui = Instance.new("ScreenGui")
        gui.Name = "NMZUI_AUTH"
        gui.ResetOnSpawn = false
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        gui.IgnoreGuiInset = true
        
        local parent = Utils.getSafeGui()
        if not parent then return end
        gui.Parent = parent
    
        local overlay = Instance.new("Frame")
        overlay.Size = UDim2.new(1, 0, 1, 0)
        overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        overlay.BackgroundTransparency = 1
        overlay.BorderSizePixel = 0
        overlay.Parent = gui
    
        local main = Instance.new("Frame")
        main.Size = UDim2.new(0, 320, 0, 0)
        main.Position = UDim2.new(0.5, 0, 0.5, 0)
        main.AnchorPoint = Vector2.new(0.5, 0.5)
        main.BackgroundColor3 = Theme.Background
        main.BackgroundTransparency = Theme.BackgroundTransparency
        main.ClipsDescendants = true
        main.AutomaticSize = Enum.AutomaticSize.Y
        main.Parent = gui
    
        local scale = Instance.new("UIScale")
        scale.Scale = 0
        scale.Parent = main
    
        local stroke = Instance.new("UIStroke")
        stroke.Color = Theme.Accent
        stroke.Thickness = 1
        stroke.Transparency = 0.8
        stroke.Parent = main
    
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = main
        
        local mainLayout = Instance.new("UIListLayout")
        mainLayout.SortOrder = Enum.SortOrder.LayoutOrder
        mainLayout.Padding = UDim.new(0, 10)
        mainLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        mainLayout.Parent = main
        
        local mainPad = Instance.new("UIPadding")
        mainPad.PaddingTop = UDim.new(0, 20)
        mainPad.PaddingBottom = UDim.new(0, 20)
        mainPad.Parent = main
    
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -40, 0, 25)
        title.BackgroundTransparency = 1
        title.Text = titleText
        title.TextColor3 = Theme.TextPrimary
        title.Font = Theme.FontBold
        title.TextSize = 18
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.LayoutOrder = 1
        title.Parent = main
    
        local subtitle = Instance.new("TextLabel")
        subtitle.Size = UDim2.new(1, -40, 0, 15)
        subtitle.BackgroundTransparency = 1
        subtitle.Text = subtitleText
        subtitle.TextColor3 = Theme.TextSecondary
        subtitle.Font = Theme.FontMedium
        subtitle.TextSize = 13
        subtitle.TextWrapped = true
        subtitle.TextXAlignment = Enum.TextXAlignment.Left
        subtitle.LayoutOrder = 2
        subtitle.Parent = main
    
        local inputContainer = Instance.new("Frame")
        inputContainer.Size = UDim2.new(1, -40, 0, 40)
        inputContainer.BackgroundColor3 = Theme.PanelBackground
        inputContainer.LayoutOrder = 3
        inputContainer.Parent = main
        
        local inputCorner = Instance.new("UICorner")
        inputCorner.CornerRadius = UDim.new(0, 6)
        inputCorner.Parent = inputContainer
        
        local inputStroke = Instance.new("UIStroke")
        inputStroke.Color = Theme.Accent
        inputStroke.Thickness = 1
        inputStroke.Transparency = 0.9
        inputStroke.Parent = inputContainer
    
        local textBox = Instance.new("TextBox")
        textBox.Size = UDim2.new(1, -20, 1, 0)
        textBox.Position = UDim2.new(0, 10, 0, 0)
        textBox.BackgroundTransparency = 1
        textBox.Text = ""
        textBox.PlaceholderText = placeholder
        textBox.PlaceholderColor3 = Theme.TextSecondary
        textBox.TextColor3 = Theme.TextPrimary
        textBox.Font = Theme.FontMedium
        textBox.TextSize = 14
        textBox.TextXAlignment = Enum.TextXAlignment.Left
        textBox.ClearTextOnFocus = false
        textBox.Parent = inputContainer
    
        local submitBtn = Instance.new("TextButton")
        submitBtn.Size = UDim2.new(1, -40, 0, 40)
        submitBtn.BackgroundColor3 = Theme.Accent
        submitBtn.Text = submitText
        submitBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
        submitBtn.Font = Theme.FontBold
        submitBtn.TextSize = 14
        submitBtn.AutoButtonColor = false
        submitBtn.LayoutOrder = 4
        submitBtn.Parent = main
    
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = submitBtn
    
        submitBtn.MouseEnter:Connect(function()
            ts:Create(submitBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.AccentHover}):Play()
        end)
        submitBtn.MouseLeave:Connect(function()
            ts:Create(submitBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Accent}):Play()
        end)
    
        if #links > 0 then
            local linkContainer = Instance.new("Frame")
            linkContainer.Size = UDim2.new(1, -40, 0, 26)
            linkContainer.BackgroundTransparency = 1
            linkContainer.LayoutOrder = 5
            linkContainer.Parent = main
            
            local linkLayout = Instance.new("UIListLayout")
            linkLayout.FillDirection = Enum.FillDirection.Horizontal
            linkLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            linkLayout.SortOrder = Enum.SortOrder.LayoutOrder
            linkLayout.Padding = UDim.new(0, 15)
            linkLayout.Parent = linkContainer
            
            for i, linkData in ipairs(links) do
                local linkBtn = Instance.new("TextButton")
                linkBtn.Size = UDim2.new(0, 110, 0, 26)
                linkBtn.BackgroundColor3 = Theme.PanelBackground
                linkBtn.Text = ""
                linkBtn.AutoButtonColor = false
                linkBtn.Parent = linkContainer
                
                local linkCorner = Instance.new("UICorner")
                linkCorner.CornerRadius = UDim.new(0, 4)
                linkCorner.Parent = linkBtn
                
                local linkStroke = Instance.new("UIStroke")
                linkStroke.Color = Theme.Stroke
                linkStroke.Transparency = 0.8
                linkStroke.Parent = linkBtn
    
                local icon
                local textXOffset = 0
                if linkData.Icon then
                    icon = Instance.new("ImageLabel")
                    icon.Size = UDim2.new(0, 14, 0, 14)
                    icon.Position = UDim2.new(0, 10, 0.5, -7)
                    icon.BackgroundTransparency = 1
                    icon.Image = linkData.Icon
                    icon.ImageColor3 = Theme.TextSecondary
                    icon.Parent = linkBtn
                    textXOffset = 28
                end
                
                local linkLbl = Instance.new("TextLabel")
                linkLbl.Size = UDim2.new(1, -textXOffset, 1, 0)
                linkLbl.Position = UDim2.new(0, textXOffset, 0, 0)
                linkLbl.BackgroundTransparency = 1
                linkLbl.Text = linkData.Name or "Link"
                linkLbl.TextColor3 = Theme.TextSecondary
                linkLbl.Font = Theme.FontMedium
                linkLbl.TextSize = 11
                linkLbl.Parent = linkBtn
                
                linkBtn.MouseEnter:Connect(function()
                    ts:Create(linkBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.SecondaryBackground}):Play()
                    ts:Create(linkLbl, TweenInfo.new(0.2), {TextColor3 = Theme.TextPrimary}):Play()
                    if icon then ts:Create(icon, TweenInfo.new(0.2), {ImageColor3 = Theme.TextPrimary}):Play() end
                end)
                linkBtn.MouseLeave:Connect(function()
                    ts:Create(linkBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.PanelBackground}):Play()
                    ts:Create(linkLbl, TweenInfo.new(0.2), {TextColor3 = Theme.TextSecondary}):Play()
                    if icon then ts:Create(icon, TweenInfo.new(0.2), {ImageColor3 = Theme.TextSecondary}):Play() end
                end)
                
                linkBtn.MouseButton1Click:Connect(function()
                    if linkData.OnClick then
                        linkData.OnClick(linkLbl)
                    end
                end)
            end
        end
    
        local isLoading = false
        
        local function closeAuth()
            ts:Create(overlay, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
            local t = ts:Create(scale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Scale = 0})
            t:Play()
            t.Completed:Wait()
            gui:Destroy()
        end
    
        local function doSubmit()
            if isLoading then return end
            local key = textBox.Text
            
            isLoading = true
            submitBtn.Text = "Verifying..."
            submitBtn.BackgroundColor3 = Theme.PanelBackground
            submitBtn.TextColor3 = Theme.TextSecondary
            textBox.TextEditable = false
            
            if onSubmit then
                onSubmit(key, function(success)
                    if success then
                        submitBtn.Text = "Success"
                        submitBtn.TextColor3 = Theme.Accent
                        task.wait(0.5)
                        closeAuth()
                    else
                        isLoading = false
                        submitBtn.Text = submitText
                        submitBtn.BackgroundColor3 = Theme.Accent
                        submitBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
                        textBox.TextEditable = true
                    end
                end)
            else
                closeAuth()
            end
        end
    
        submitBtn.MouseButton1Click:Connect(doSubmit)
    
        textBox.Focused:Connect(function()
            ts:Create(inputStroke, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Transparency = 0}):Play()
        end)
        textBox.FocusLost:Connect(function(enterPressed)
            ts:Create(inputStroke, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Transparency = 0.9}):Play()
            if enterPressed then
                doSubmit()
            end
        end)
    
        ts:Create(overlay, TweenInfo.new(0.5), {BackgroundTransparency = 0.3}):Play()
        ts:Create(scale, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
        
        Drag.makeDraggable(main)
    
        return {
            Close = closeAuth
        }
    end
    
    return Auth
end)()

-- Entry Point: Init
local Lib = {}

Lib.Theme = _modules["Theme"]
Lib.Utils = _modules["Utils"]
Lib.Drag = _modules["Drag"]
Lib.Window = _modules["Window"]
Lib.Components = _modules["Components"]
Lib.Notification = _modules["Notification"]
Lib.Auth = _modules["Auth"]

function Lib.CreateWindow(options)
    return Lib.Window.new(options)
end

function Lib.CreateTab(window, name, order)
    return Lib.Components.Tab.new(window, name, order)
end

function Lib.CreateButton(tab, name, cb)
    return Lib.Components.Button.new(tab.container, name, cb)
end

function Lib.CreateToggle(tab, name, defaultState, cb)
    return Lib.Components.Toggle.new(tab.container, name, defaultState, cb)
end

function Lib.CreateSlider(tab, name, minVal, maxVal, defaultVal, formatFunc, cb)
    return Lib.Components.Slider.new(tab.container, name, minVal, maxVal, defaultVal, formatFunc, cb)
end

function Lib.CreateDropdown(tab, name, opts, defaultIdx, cb)
    return Lib.Components.Dropdown.new(tab.container, name, opts, defaultIdx, cb)
end

function Lib.CreateTextbox(tab, name, placeholderText, cb)
    return Lib.Components.Textbox.new(tab.container, name, placeholderText, cb)
end

function Lib.Notify(config)
    return Lib.Notification.show(config)
end

function Lib.CreateAuth(config)
    return Lib.Auth.show(config)
end

return Lib