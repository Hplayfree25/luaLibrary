local Window = {}

local import = function(name)
    local ok, res = pcall(function() return require(script.Parent[name]) end)
    if ok then return res end
    return _G.UniversalUILib_GetModule(name)
end

local DefaultTheme = import("Theme")
local Utils = import("Utils")
local Drag = import("Drag")

local function corner(parent, radius)
    local value = Instance.new("UICorner")
    value.CornerRadius = radius
    value.Parent = parent
    return value
end

local function stroke(parent, theme, transparency)
    local value = Instance.new("UIStroke")
    value.Color = theme.Stroke
    value.Transparency = transparency or theme.StrokeTransparency
    value.Thickness = 1
    value.Parent = parent
    return value
end

function Window.new(options)
    if type(options) == "string" then options = {Title = options} end
    options = options or {}

    local Theme = options.Theme or DefaultTheme
    local uis = Utils.safeSvc("UserInputService")
    local camera = workspace.CurrentCamera
    local requestedSize = options.Size or UDim2.fromOffset(600, 380)
    local toggleKey = options.Keybind or Enum.KeyCode.LeftAlt
    local gamepadKey = options.GamepadKeybind or Enum.KeyCode.ButtonStart
    local titleText = tostring(options.Title or "Universal UI")
    local windowRadius = Theme.WindowCornerRadius or UDim.new(0, 18)
    local cardRadius = Theme.CardCornerRadius or Theme.CornerRadius
    local fieldRadius = Theme.FieldCornerRadius or Theme.CornerRadius
    local self = {theme = Theme, tabs = {}, controls = {}, compact = false}
    local state = "intro"
    local isAnimating = false
    local minimized = false
    local resolvedSize = Vector2.new(600, 380)
    local connections = {}

    local function connect(signal, callback)
        local connection = signal:Connect(callback)
        table.insert(connections, connection)
        return connection
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = options.GuiName or "UniversalUILib"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = options.DisplayOrder or 20
    gui.IgnoreGuiInset = true
    gui.Parent = Utils.getSafeGui()

    local btnToggle = Instance.new("TextButton")
    btnToggle.Name = "MenuToggle"
    btnToggle.Size = UDim2.fromOffset(52, 52)
    btnToggle.AnchorPoint = Vector2.new(1, 0.5)
    btnToggle.Position = UDim2.new(1, -16, 0.5, 0)
    btnToggle.BackgroundColor3 = Theme.SurfaceElevated or Theme.PanelBackground
    btnToggle.BackgroundTransparency = Theme.GlassTransparency or 0.12
    btnToggle.BorderSizePixel = 0
    btnToggle.Text = options.ToggleText or "UI"
    btnToggle.TextColor3 = Theme.TextPrimary
    btnToggle.Font = Theme.FontBold
    btnToggle.TextSize = 13
    btnToggle.AutoButtonColor = false
    btnToggle.Active = true
    btnToggle.Selectable = true
    btnToggle.Visible = false
    btnToggle.Parent = gui
    corner(btnToggle, UDim.new(1, 0))
    local toggleStroke = stroke(btnToggle, Theme, Theme.BorderTransparency or 0.82)

    local main = Instance.new("Frame")
    main.Name = "Window"
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.Position = UDim2.fromScale(0.5, 0.5)
    main.BackgroundColor3 = Theme.Background
    main.BackgroundTransparency = Theme.BackgroundTransparency
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.Active = true
    main.Visible = false
    main.Parent = gui
    corner(main, windowRadius)
    local mainStroke = stroke(main, Theme, Theme.StrokeTransparency)

    local scale = Instance.new("UIScale")
    scale.Scale = 1
    scale.Parent = main

    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Position = UDim2.fromOffset(10, 10)
    titleBar.Size = UDim2.new(1, -20, 0, 42)
    titleBar.BackgroundColor3 = Theme.SurfaceElevated or Theme.PanelBackground
    titleBar.BackgroundTransparency = Theme.GlassTransparency or 0.18
    titleBar.BorderSizePixel = 0
    titleBar.Active = true
    titleBar.Parent = main
    corner(titleBar, cardRadius)
    stroke(titleBar, Theme, Theme.PanelStrokeTransparency)

    local brand = Instance.new("TextLabel")
    brand.Size = UDim2.new(1, -100, 1, 0)
    brand.Position = UDim2.fromOffset(14, 0)
    brand.BackgroundTransparency = 1
    brand.Text = titleText
    brand.TextColor3 = Theme.TextPrimary
    brand.Font = Theme.FontBold
    brand.TextSize = 14
    brand.TextXAlignment = Enum.TextXAlignment.Left
    brand.TextTruncate = Enum.TextTruncate.AtEnd
    brand.Active = true
    brand.Parent = titleBar

    local function titleButton(name, text, offset, textSize)
        local button = Instance.new("TextButton")
        button.Name = name
        button.Size = UDim2.fromOffset(38, 34)
        button.AnchorPoint = Vector2.new(1, 0.5)
        button.Position = UDim2.new(1, offset, 0.5, 0)
        button.BackgroundColor3 = Theme.SurfaceHover or Theme.SecondaryBackground
        button.BackgroundTransparency = 1
        button.BorderSizePixel = 0
        button.Text = text
        button.TextColor3 = Theme.TextSecondary
        button.Font = Theme.FontBold
        button.TextSize = textSize
        button.AutoButtonColor = false
        button.Selectable = true
        button.Parent = titleBar
        corner(button, fieldRadius)

        local function focus(active)
            Utils.tween(button, TweenInfo.new(0.14), {
                BackgroundTransparency = active and (Theme.HoverTransparency or 0.18) or 1,
                TextColor3 = active and Theme.TextPrimary or Theme.TextSecondary
            })
        end
        connect(button.MouseEnter, function() focus(true) end)
        connect(button.MouseLeave, function() focus(false) end)
        connect(button.SelectionGained, function() focus(true) end)
        connect(button.SelectionLost, function() focus(false) end)
        return button
    end

    local minimize = titleButton("Minimize", "—", -44, 14)
    local close = titleButton("Close", "×", -4, 18)

    local leftPanel = Instance.new("Frame")
    leftPanel.Name = "Navigation"
    leftPanel.BackgroundColor3 = Theme.Surface or Theme.PanelBackground
    leftPanel.BackgroundTransparency = Theme.GlassTransparency or 0.2
    leftPanel.BorderSizePixel = 0
    leftPanel.ClipsDescendants = true
    leftPanel.Parent = main
    corner(leftPanel, cardRadius)
    stroke(leftPanel, Theme, Theme.PanelStrokeTransparency)

    local tabContainer = Instance.new("ScrollingFrame")
    tabContainer.Name = "Tabs"
    tabContainer.BackgroundTransparency = 1
    tabContainer.BorderSizePixel = 0
    tabContainer.ScrollBarThickness = 2
    tabContainer.ScrollBarImageColor3 = Theme.TextMuted
    tabContainer.ScrollBarImageTransparency = Theme.ScrollBarTransparency or 0.55
    tabContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
    tabContainer.CanvasSize = UDim2.new()
    tabContainer.ScrollingDirection = Enum.ScrollingDirection.Y
    tabContainer.Parent = leftPanel

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Vertical
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 6)
    tabLayout.Parent = tabContainer

    local tabPadding = Instance.new("UIPadding")
    tabPadding.PaddingTop = UDim.new(0, 8)
    tabPadding.PaddingBottom = UDim.new(0, 8)
    tabPadding.Parent = tabContainer

    local rightPanel = Instance.new("Frame")
    rightPanel.Name = "Content"
    rightPanel.BackgroundColor3 = Theme.Surface or Theme.PanelBackground
    rightPanel.BackgroundTransparency = Theme.ContentTransparency or 0.42
    rightPanel.BorderSizePixel = 0
    rightPanel.ClipsDescendants = true
    rightPanel.Parent = main
    corner(rightPanel, cardRadius)
    stroke(rightPanel, Theme, Theme.PanelStrokeTransparency)

    local function applyMinimized(value, animate)
        minimized = value
        minimize.Text = minimized and "+" or "—"
        if not minimized then
            leftPanel.Visible = true
            rightPanel.Visible = true
        end
        local target = minimized and UDim2.fromOffset(resolvedSize.X, 62) or UDim2.fromOffset(resolvedSize.X, resolvedSize.Y)
        if animate then
            Utils.tween(main, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = target})
            if minimized then
                task.delay(0.2, function()
                    if minimized and main.Parent then
                        leftPanel.Visible = false
                        rightPanel.Visible = false
                    end
                end)
            end
        else
            main.Size = target
            leftPanel.Visible = not minimized
            rightPanel.Visible = not minimized
        end
    end

    local function resolveSize()
        camera = workspace.CurrentCamera or camera
        local viewport = camera and camera.ViewportSize or Vector2.new(800, 600)
        local availableWidth = math.max(100, viewport.X - 24)
        local availableHeight = math.max(100, viewport.Y - 24)
        local desiredWidth = requestedSize.X.Scale * viewport.X + requestedSize.X.Offset
        local desiredHeight = requestedSize.Y.Scale * viewport.Y + requestedSize.Y.Offset
        local width = math.clamp(desiredWidth, math.min(320, availableWidth), availableWidth)
        local height = math.clamp(desiredHeight, math.min(250, availableHeight), availableHeight)
        resolvedSize = Vector2.new(width, height)
        self.compact = width < (options.CompactBreakpoint or 430)

        main.Size = minimized and UDim2.fromOffset(width, 62) or UDim2.fromOffset(width, height)
        if self.compact then
            leftPanel.Position = UDim2.fromOffset(10, 60)
            leftPanel.Size = UDim2.new(1, -20, 0, 50)
            tabContainer.Position = UDim2.fromOffset(6, 0)
            tabContainer.Size = UDim2.new(1, -12, 1, 0)
            tabContainer.AutomaticCanvasSize = Enum.AutomaticSize.X
            tabContainer.ScrollingDirection = Enum.ScrollingDirection.X
            tabLayout.FillDirection = Enum.FillDirection.Horizontal
            tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
            tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
            tabPadding.PaddingTop = UDim.new(0, 0)
            tabPadding.PaddingBottom = UDim.new(0, 0)
            rightPanel.Position = UDim2.fromOffset(10, 118)
            rightPanel.Size = UDim2.new(1, -20, 1, -128)
        else
            leftPanel.Position = UDim2.fromOffset(10, 60)
            leftPanel.Size = UDim2.new(0, 138, 1, -70)
            tabContainer.Position = UDim2.new()
            tabContainer.Size = UDim2.fromScale(1, 1)
            tabContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
            tabContainer.ScrollingDirection = Enum.ScrollingDirection.Y
            tabLayout.FillDirection = Enum.FillDirection.Vertical
            tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            tabLayout.VerticalAlignment = Enum.VerticalAlignment.Top
            tabPadding.PaddingTop = UDim.new(0, 8)
            tabPadding.PaddingBottom = UDim.new(0, 8)
            rightPanel.Position = UDim2.fromOffset(156, 60)
            rightPanel.Size = UDim2.new(1, -166, 1, -70)
        end

        for _, tab in ipairs(self.tabs) do
            if tab.updateLayout then tab.updateLayout(self.compact) end
        end
        task.defer(function()
            if main.Parent then Drag.clampToViewport(main, 12) end
        end)
    end
    resolveSize()

    local function showToggle()
        if state ~= "closed" or not uis.TouchEnabled then return end
        btnToggle.Visible = true
        Utils.tween(btnToggle, TweenInfo.new(0.18), {BackgroundTransparency = Theme.GlassTransparency or 0.12})
    end

    local function openWindow()
        if state == "intro" or state == "destroyed" or isAnimating then return false end
        if state == "open" then return true end
        isAnimating = true
        state = "open"
        applyMinimized(false, false)
        resolveSize()
        btnToggle.Visible = false
        main.Visible = true
        scale.Scale = 0.96
        main.BackgroundTransparency = 1
        Utils.tween(scale, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Scale = 1})
        Utils.tween(main, TweenInfo.new(0.2), {BackgroundTransparency = Theme.BackgroundTransparency}).Completed:Wait()
        isAnimating = false
        return true
    end

    local function hideWindow()
        if state ~= "open" or isAnimating then return false end
        isAnimating = true
        Utils.tween(scale, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 0.96})
        Utils.tween(main, TweenInfo.new(0.16), {BackgroundTransparency = 1}).Completed:Wait()
        main.Visible = false
        applyMinimized(false, false)
        state = "closed"
        isAnimating = false
        showToggle()
        return true
    end

    local function toggleWindow()
        if state == "intro" or state == "destroyed" then return false end
        if state == "open" then return hideWindow() end
        return openWindow()
    end

    connect(close.Activated, hideWindow)
    connect(minimize.Activated, function()
        if state == "open" and not isAnimating then applyMinimized(not minimized, true) end
    end)

    connect(btnToggle.MouseEnter, function()
        Utils.tween(toggleStroke, TweenInfo.new(0.14), {Transparency = Theme.FocusStrokeTransparency or 0.35})
    end)
    connect(btnToggle.MouseLeave, function()
        Utils.tween(toggleStroke, TweenInfo.new(0.14), {Transparency = Theme.BorderTransparency or 0.82})
    end)
    connect(btnToggle.SelectionGained, function()
        Utils.tween(toggleStroke, TweenInfo.new(0.14), {Transparency = Theme.FocusStrokeTransparency or 0.35})
    end)
    connect(btnToggle.SelectionLost, function()
        Utils.tween(toggleStroke, TweenInfo.new(0.14), {Transparency = Theme.BorderTransparency or 0.82})
    end)

    local toggleDragged = false
    for _, connection in ipairs(Drag.makeDraggable(btnToggle, btnToggle, {
        OnEnded = function(moved) toggleDragged = moved end
    })) do table.insert(connections, connection) end
    connect(btnToggle.Activated, function()
        if toggleDragged then toggleDragged = false return end
        toggleWindow()
    end)
    for _, connection in ipairs(Drag.makeDraggable(brand, main)) do table.insert(connections, connection) end

    connect(uis.InputBegan, function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == toggleKey or input.KeyCode == gamepadKey then toggleWindow() end
    end)

    local viewportConnection
    local function watchViewport()
        if viewportConnection then viewportConnection:Disconnect() end
        camera = workspace.CurrentCamera
        if camera then
            viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(resolveSize)
            table.insert(connections, viewportConnection)
        end
    end
    watchViewport()
    connect(workspace:GetPropertyChangedSignal("CurrentCamera"), function()
        watchViewport()
        resolveSize()
    end)

    self.gui = gui
    self.mainFrame = main
    self.leftPanel = leftPanel
    self.rightPanel = rightPanel
    self.tabContainer = tabContainer
    self.show = openWindow
    self.hide = hideWindow
    self.toggle = toggleWindow
    self.isReady = function() return state ~= "intro" and state ~= "destroyed" end
    self.isOpen = function() return state == "open" end
    self.destroy = function()
        if state == "destroyed" then return end
        state = "destroyed"
        for _, control in ipairs(self.controls) do
            if control.destroy then pcall(control.destroy) end
        end
        for _, connection in ipairs(connections) do connection:Disconnect() end
        gui:Destroy()
    end

    task.spawn(function()
        local intro = Instance.new("Frame")
        intro.Name = "Intro"
        intro.AnchorPoint = Vector2.new(0.5, 0.5)
        intro.Position = UDim2.fromScale(0.5, 0.5)
        intro.Size = UDim2.new(1, -32, 0, 124)
        intro.BackgroundColor3 = Theme.Background
        intro.BackgroundTransparency = 1
        intro.BorderSizePixel = 0
        intro.Parent = gui
        corner(intro, windowRadius)
        local introConstraint = Instance.new("UISizeConstraint")
        introConstraint.MaxSize = Vector2.new(310, 124)
        introConstraint.Parent = intro
        local introStroke = stroke(intro, Theme, 1)

        local logo = Instance.new("TextLabel")
        logo.Size = UDim2.new(1, -32, 0, 28)
        logo.Position = UDim2.fromOffset(16, 20)
        logo.BackgroundTransparency = 1
        logo.Text = titleText:upper()
        logo.TextColor3 = Theme.TextPrimary
        logo.TextTransparency = 1
        logo.Font = Theme.FontBold
        logo.TextSize = 18
        logo.TextXAlignment = Enum.TextXAlignment.Left
        logo.TextTruncate = Enum.TextTruncate.AtEnd
        logo.Parent = intro

        local status = Instance.new("TextLabel")
        status.Size = UDim2.new(1, -32, 0, 18)
        status.Position = UDim2.fromOffset(16, 52)
        status.BackgroundTransparency = 1
        status.Text = options.IntroText or "Preparing interface"
        status.TextColor3 = Theme.TextMuted
        status.TextTransparency = 1
        status.Font = Theme.FontMedium
        status.TextSize = 11
        status.TextXAlignment = Enum.TextXAlignment.Left
        status.TextTruncate = Enum.TextTruncate.AtEnd
        status.Parent = intro

        local track = Instance.new("Frame")
        track.Size = UDim2.new(1, -32, 0, 4)
        track.Position = UDim2.new(0, 16, 1, -24)
        track.BackgroundColor3 = Theme.SecondaryBackground
        track.BackgroundTransparency = 1
        track.BorderSizePixel = 0
        track.Parent = intro
        corner(track, UDim.new(1, 0))

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new(0, 0, 1, 0)
        fill.BackgroundColor3 = Theme.Accent
        fill.BackgroundTransparency = 1
        fill.BorderSizePixel = 0
        fill.Parent = track
        corner(fill, UDim.new(1, 0))

        task.wait(0.1)
        if state == "destroyed" then return end
        Utils.tween(intro, TweenInfo.new(0.22), {BackgroundTransparency = Theme.BackgroundTransparency})
        Utils.tween(introStroke, TweenInfo.new(0.22), {Transparency = Theme.StrokeTransparency})
        Utils.tween(logo, TweenInfo.new(0.22), {TextTransparency = 0})
        Utils.tween(status, TweenInfo.new(0.22), {TextTransparency = 0})
        Utils.tween(track, TweenInfo.new(0.22), {BackgroundTransparency = 0})
        Utils.tween(fill, TweenInfo.new(0.18), {BackgroundTransparency = 0})
        Utils.tween(fill, TweenInfo.new(options.IntroDuration or 1.1, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = UDim2.fromScale(1, 1)
        }).Completed:Wait()
        if state == "destroyed" then return end
        status.Text = "Ready"
        task.wait(0.2)
        Utils.tween(intro, TweenInfo.new(0.18), {BackgroundTransparency = 1})
        Utils.tween(introStroke, TweenInfo.new(0.18), {Transparency = 1})
        Utils.tween(logo, TweenInfo.new(0.18), {TextTransparency = 1})
        Utils.tween(status, TweenInfo.new(0.18), {TextTransparency = 1})
        Utils.tween(track, TweenInfo.new(0.18), {BackgroundTransparency = 1})
        Utils.tween(fill, TweenInfo.new(0.18), {BackgroundTransparency = 1})
        task.wait(0.18)
        intro:Destroy()

        state = "closed"
        if not options.HideOnStartup then openWindow() else showToggle() end
        if type(options.OnIntroCompleted) == "function" then
            task.spawn(function() options.OnIntroCompleted(self) end)
        end
    end)

    return self
end

return Window
