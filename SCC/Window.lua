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
    if type(options) == "string" then options = {Title = options} end
    options = options or {}

    local Theme = options.Theme or DefaultTheme
    local uis = Utils.safeSvc("UserInputService")
    local camera = workspace.CurrentCamera
    local requestedSize = options.Size or UDim2.fromOffset(600, 380)
    local toggleKey = options.Keybind or Enum.KeyCode.LeftAlt
    local gamepadKey = options.GamepadKeybind or Enum.KeyCode.ButtonStart
    local titleText = options.Title or "Universal UI"
    local self = {theme = Theme, tabs = {}, controls = {}}
    local state = "intro"
    local isAnimating = false
    local minimized = false
    local compact = false
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
    btnToggle.BackgroundColor3 = Theme.Surface or Theme.PanelBackground
    btnToggle.BackgroundTransparency = 0.08
    btnToggle.Text = options.ToggleText or "UI"
    btnToggle.TextColor3 = Theme.TextPrimary
    btnToggle.Font = Theme.FontBold
    btnToggle.TextSize = 13
    btnToggle.AutoButtonColor = false
    btnToggle.Active = true
    btnToggle.Selectable = true
    btnToggle.Visible = false
    btnToggle.Parent = gui

    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(1, 0)
    toggleCorner.Parent = btnToggle
    local toggleStroke = Instance.new("UIStroke")
    toggleStroke.Color = Theme.Accent
    toggleStroke.Transparency = 0.35
    toggleStroke.Parent = btnToggle

    local main = Instance.new("Frame")
    main.Name = "Window"
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.Position = UDim2.fromScale(0.5, 0.5)
    main.BackgroundColor3 = Theme.Background
    main.BackgroundTransparency = Theme.BackgroundTransparency
    main.ClipsDescendants = true
    main.Active = true
    main.Visible = false
    main.Parent = gui

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = Theme.WindowCornerRadius
    mainCorner.Parent = main
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Theme.Stroke
    mainStroke.Transparency = Theme.StrokeTransparency
    mainStroke.Parent = main

    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 48)
    titleBar.BackgroundColor3 = Theme.Surface or Theme.PanelBackground
    titleBar.BackgroundTransparency = 0.12
    titleBar.Active = true
    titleBar.Parent = main

    local brand = Instance.new("TextLabel")
    brand.Size = UDim2.new(1, -104, 1, 0)
    brand.Position = UDim2.fromOffset(16, 0)
    brand.BackgroundTransparency = 1
    brand.Text = titleText
    brand.TextColor3 = Theme.TextPrimary
    brand.Font = Theme.FontBold
    brand.TextSize = 15
    brand.TextXAlignment = Enum.TextXAlignment.Left
    brand.TextTruncate = Enum.TextTruncate.AtEnd
    brand.Parent = titleBar

    local minimize = Instance.new("TextButton")
    minimize.Name = "Minimize"
    minimize.Size = UDim2.fromOffset(36, 32)
    minimize.AnchorPoint = Vector2.new(1, 0.5)
    minimize.Position = UDim2.new(1, -48, 0.5, 0)
    minimize.BackgroundColor3 = Theme.SurfaceHover or Theme.SecondaryBackground
    minimize.BackgroundTransparency = 1
    minimize.Text = "—"
    minimize.TextColor3 = Theme.TextSecondary
    minimize.Font = Theme.FontBold
    minimize.TextSize = 14
    minimize.AutoButtonColor = false
    minimize.Selectable = true
    minimize.Parent = titleBar

    local close = minimize:Clone()
    close.Name = "Close"
    close.Position = UDim2.new(1, -8, 0.5, 0)
    close.Text = "×"
    close.TextSize = 18
    close.Parent = titleBar

    for _, button in ipairs({minimize, close}) do
        local corner = Instance.new("UICorner")
        corner.CornerRadius = Theme.CornerRadius
        corner.Parent = button
        connect(button.MouseEnter, function()
            Utils.tween(button, TweenInfo.new(0.15), {BackgroundTransparency = 0, TextColor3 = Theme.TextPrimary})
        end)
        connect(button.MouseLeave, function()
            Utils.tween(button, TweenInfo.new(0.15), {BackgroundTransparency = 1, TextColor3 = Theme.TextSecondary})
        end)
    end

    local leftPanel = Instance.new("Frame")
    leftPanel.Name = "Navigation"
    leftPanel.BackgroundColor3 = Theme.Surface or Theme.PanelBackground
    leftPanel.BackgroundTransparency = 0.5
    leftPanel.Parent = main

    local tabContainer = Instance.new("ScrollingFrame")
    tabContainer.Name = "Tabs"
    tabContainer.BackgroundTransparency = 1
    tabContainer.BorderSizePixel = 0
    tabContainer.ScrollBarThickness = 2
    tabContainer.ScrollBarImageColor3 = Theme.Accent
    tabContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
    tabContainer.CanvasSize = UDim2.new()
    tabContainer.ScrollingDirection = Enum.ScrollingDirection.Y
    tabContainer.Parent = leftPanel

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Vertical
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 6)
    tabLayout.Parent = tabContainer

    local tabPadding = Instance.new("UIPadding")
    tabPadding.PaddingTop = UDim.new(0, 10)
    tabPadding.PaddingBottom = UDim.new(0, 10)
    tabPadding.Parent = tabContainer

    local rightPanel = Instance.new("Frame")
    rightPanel.Name = "Content"
    rightPanel.BackgroundTransparency = 1
    rightPanel.Parent = main

    local divider = Instance.new("Frame")
    divider.Name = "Divider"
    divider.BackgroundColor3 = Theme.Stroke
    divider.BackgroundTransparency = Theme.StrokeTransparency
    divider.Parent = main

    local resolvedSize = Vector2.new(600, 380)
    local function resolveSize()
        camera = workspace.CurrentCamera or camera
        local viewport = camera and camera.ViewportSize or Vector2.new(800, 600)
        local width = requestedSize.X.Scale * viewport.X + requestedSize.X.Offset
        local height = requestedSize.Y.Scale * viewport.Y + requestedSize.Y.Offset
        width = math.clamp(width, math.min(320, viewport.X - 16), math.max(100, viewport.X - 16))
        height = math.clamp(height, math.min(260, viewport.Y - 16), math.max(100, viewport.Y - 16))
        resolvedSize = Vector2.new(width, height)
        compact = width < 520

        if not minimized then main.Size = UDim2.fromOffset(width, height) end
        if compact then
            leftPanel.Position = UDim2.fromOffset(0, 48)
            leftPanel.Size = UDim2.new(1, 0, 0, 48)
            tabContainer.Position = UDim2.fromOffset(8, 0)
            tabContainer.Size = UDim2.new(1, -16, 1, 0)
            tabContainer.AutomaticCanvasSize = Enum.AutomaticSize.X
            tabContainer.ScrollingDirection = Enum.ScrollingDirection.X
            tabLayout.FillDirection = Enum.FillDirection.Horizontal
            tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
            tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
            rightPanel.Position = UDim2.fromOffset(0, 96)
            rightPanel.Size = UDim2.new(1, 0, 1, -96)
            divider.Position = UDim2.fromOffset(10, 95)
            divider.Size = UDim2.new(1, -20, 0, 1)
        else
            leftPanel.Position = UDim2.fromOffset(0, 48)
            leftPanel.Size = UDim2.new(0, 152, 1, -48)
            tabContainer.Position = UDim2.new()
            tabContainer.Size = UDim2.fromScale(1, 1)
            tabContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
            tabContainer.ScrollingDirection = Enum.ScrollingDirection.Y
            tabLayout.FillDirection = Enum.FillDirection.Vertical
            tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            rightPanel.Position = UDim2.fromOffset(152, 48)
            rightPanel.Size = UDim2.new(1, -152, 1, -48)
            divider.Position = UDim2.fromOffset(151, 58)
            divider.Size = UDim2.new(0, 1, 1, -68)
        end

        for _, tab in ipairs(self.tabs) do
            if tab.updateLayout then tab.updateLayout(compact) end
        end
    end
    resolveSize()

    local function showToggle()
        if state ~= "closed" or not uis.TouchEnabled then return end
        btnToggle.Visible = true
        Utils.tween(btnToggle, TweenInfo.new(0.2), {BackgroundTransparency = 0.08})
    end

    local function openWindow()
        if state == "intro" or state == "destroyed" or isAnimating then return false end
        if state == "open" then return true end
        isAnimating = true
        state = "open"
        minimized = false
        resolveSize()
        btnToggle.Visible = false
        main.Visible = true
        main.Size = UDim2.fromOffset(resolvedSize.X - 18, resolvedSize.Y - 18)
        main.BackgroundTransparency = 1
        Utils.tween(main, TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(resolvedSize.X, resolvedSize.Y),
            BackgroundTransparency = Theme.BackgroundTransparency
        }).Completed:Wait()
        isAnimating = false
        return true
    end

    local function hideWindow()
        if state ~= "open" or isAnimating then return false end
        isAnimating = true
        Utils.tween(main, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.fromOffset(math.max(100, main.AbsoluteSize.X - 14), math.max(48, main.AbsoluteSize.Y - 14)),
            BackgroundTransparency = 1
        }).Completed:Wait()
        main.Visible = false
        minimized = false
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
        if state ~= "open" or isAnimating then return end
        minimized = not minimized
        leftPanel.Visible = not minimized
        rightPanel.Visible = not minimized
        divider.Visible = not minimized
        minimize.Text = minimized and "+" or "—"
        local target = minimized and UDim2.fromOffset(resolvedSize.X, 48) or UDim2.fromOffset(resolvedSize.X, resolvedSize.Y)
        Utils.tween(main, TweenInfo.new(0.22, Enum.EasingStyle.Quart), {Size = target})
    end)

    local toggleDragged = false
    for _, connection in ipairs(Drag.makeDraggable(btnToggle, btnToggle, {
        OnEnded = function(moved) toggleDragged = moved end
    })) do table.insert(connections, connection) end
    connect(btnToggle.Activated, function()
        if toggleDragged then toggleDragged = false return end
        toggleWindow()
    end)
    for _, connection in ipairs(Drag.makeDraggable(titleBar, main)) do table.insert(connections, connection) end

    connect(uis.InputBegan, function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == toggleKey or input.KeyCode == gamepadKey then
            toggleWindow()
        end
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
        intro.Size = UDim2.fromOffset(286, 132)
        intro.BackgroundColor3 = Theme.Background
        intro.BackgroundTransparency = 1
        intro.Parent = gui

        local introCorner = Instance.new("UICorner")
        introCorner.CornerRadius = Theme.WindowCornerRadius
        introCorner.Parent = intro
        local introStroke = Instance.new("UIStroke")
        introStroke.Color = Theme.Accent
        introStroke.Transparency = 1
        introStroke.Parent = intro

        local logo = Instance.new("TextLabel")
        logo.Size = UDim2.new(1, -32, 0, 32)
        logo.Position = UDim2.fromOffset(16, 22)
        logo.BackgroundTransparency = 1
        logo.Text = titleText:upper()
        logo.TextColor3 = Theme.TextPrimary
        logo.TextTransparency = 1
        logo.Font = Theme.FontBold
        logo.TextSize = 20
        logo.TextXAlignment = Enum.TextXAlignment.Left
        logo.TextTruncate = Enum.TextTruncate.AtEnd
        logo.Parent = intro

        local status = Instance.new("TextLabel")
        status.Size = UDim2.new(1, -32, 0, 18)
        status.Position = UDim2.fromOffset(16, 58)
        status.BackgroundTransparency = 1
        status.Text = options.IntroText or "Preparing interface"
        status.TextColor3 = Theme.TextMuted
        status.TextTransparency = 1
        status.Font = Theme.FontMedium
        status.TextSize = 12
        status.TextXAlignment = Enum.TextXAlignment.Left
        status.Parent = intro

        local track = Instance.new("Frame")
        track.Size = UDim2.new(1, -32, 0, 4)
        track.Position = UDim2.new(0, 16, 1, -28)
        track.BackgroundColor3 = Theme.SecondaryBackground
        track.BackgroundTransparency = 1
        track.Parent = intro
        local trackCorner = Instance.new("UICorner")
        trackCorner.CornerRadius = UDim.new(1, 0)
        trackCorner.Parent = track
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new(0, 0, 1, 0)
        fill.BackgroundColor3 = Theme.Accent
        fill.Parent = track
        local fillCorner = trackCorner:Clone()
        fillCorner.Parent = fill

        task.wait(0.1)
        if state == "destroyed" then return end
        Utils.tween(intro, TweenInfo.new(0.25), {BackgroundTransparency = Theme.BackgroundTransparency})
        Utils.tween(introStroke, TweenInfo.new(0.25), {Transparency = 0.55})
        Utils.tween(logo, TweenInfo.new(0.25), {TextTransparency = 0})
        Utils.tween(status, TweenInfo.new(0.25), {TextTransparency = 0})
        Utils.tween(track, TweenInfo.new(0.25), {BackgroundTransparency = 0})
        Utils.tween(fill, TweenInfo.new(options.IntroDuration or 1.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = UDim2.fromScale(1, 1)
        }).Completed:Wait()
        if state == "destroyed" then return end
        status.Text = "Ready"
        task.wait(0.18)
        Utils.tween(intro, TweenInfo.new(0.2), {BackgroundTransparency = 1})
        Utils.tween(logo, TweenInfo.new(0.18), {TextTransparency = 1})
        Utils.tween(status, TweenInfo.new(0.18), {TextTransparency = 1})
        task.wait(0.2)
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
