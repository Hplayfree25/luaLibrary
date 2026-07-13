-- Universal UI Library (Bundled)
local _modules = {}

-- Module: Theme
_modules["Theme"] = (function()
    local Theme = {
        -- Fonts
        FontBold = Enum.Font.GothamBold,
        FontMedium = Enum.Font.GothamMedium,

        -- Colors (Modern Dark)
        Background = Color3.fromRGB(10, 12, 16),
        PanelBackground = Color3.fromRGB(20, 23, 30),
        Accent = Color3.fromRGB(96, 165, 250),
        AccentHover = Color3.fromRGB(125, 184, 255),
        SecondaryBackground = Color3.fromRGB(29, 33, 43),
        TabInactive = Color3.fromRGB(15, 18, 24),
        TabActive = Color3.fromRGB(27, 31, 40),
        TextPrimary = Color3.fromRGB(244, 247, 252),
        TextSecondary = Color3.fromRGB(184, 191, 204),
        TextMuted = Color3.fromRGB(119, 128, 145),
        Stroke = Color3.fromRGB(148, 163, 184),

        -- Additional semantic colors
        Surface = Color3.fromRGB(20, 23, 30),
        SurfaceElevated = Color3.fromRGB(25, 29, 38),
        SurfaceHover = Color3.fromRGB(34, 39, 50),
        Focus = Color3.fromRGB(96, 165, 250),
        Success = Color3.fromRGB(74, 222, 128),
        Error = Color3.fromRGB(248, 113, 113),

        -- Transparencies
        BackgroundTransparency = 0.05,
        PanelTransparency = 0.08,
        StrokeTransparency = 0.72,
        PanelStrokeTransparency = 0.82,

        -- Spacing
        SpacingXS = 4,
        SpacingSM = 8,
        SpacingMD = 12,
        SpacingLG = 16,
        SpacingXL = 24,

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

    function Drag.makeDraggable(draggableGui, targetGui, options)
        targetGui = targetGui or draggableGui
        options = options or {}

        local dragging = false
        local dragStart
        local startPosition
        local activeInput
        local moved = false
        local conns = {}

        local function move(input)
            if not dragging or (activeInput.UserInputType == Enum.UserInputType.Touch and input ~= activeInput) then return end

            local delta = input.Position - dragStart
            if delta.Magnitude >= (options.Threshold or 6) then
                moved = true
            end

            local camera = workspace.CurrentCamera
            local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
            local size = targetGui.AbsoluteSize
            local anchor = targetGui.AnchorPoint
            local startAnchor = Vector2.new(
                startPosition.X.Scale * viewport.X + startPosition.X.Offset,
                startPosition.Y.Scale * viewport.Y + startPosition.Y.Offset
            )
            local margin = options.Margin or 8
            local minAnchor = Vector2.new(margin + size.X * anchor.X, margin + size.Y * anchor.Y)
            local maxAnchor = Vector2.new(
                math.max(minAnchor.X, viewport.X - margin - size.X * (1 - anchor.X)),
                math.max(minAnchor.Y, viewport.Y - margin - size.Y * (1 - anchor.Y))
            )
            local nextAnchor = startAnchor + delta

            targetGui.Position = UDim2.fromOffset(
                math.clamp(nextAnchor.X, minAnchor.X, maxAnchor.X),
                math.clamp(nextAnchor.Y, minAnchor.Y, maxAnchor.Y)
            )
        end

        table.insert(conns, draggableGui.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
            dragging = true
            moved = false
            activeInput = input
            dragStart = input.Position
            startPosition = targetGui.Position
        end))

        table.insert(conns, uis.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                move(input)
            end
        end))

        table.insert(conns, uis.InputEnded:Connect(function(input)
            if input ~= activeInput and input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            if dragging and type(options.OnEnded) == "function" then
                options.OnEnded(moved)
            end
            dragging = false
            activeInput = nil
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
end)()

-- Module: Tab
_modules["Tab"] = (function()
    local Tab = {}

    local import = function(name)
        local ok, res = pcall(function() return require(script.Parent[name]) end)
        if ok then return res end
        return _G.UniversalUILib_GetModule(name)
    end

    local DefaultTheme = _modules["Theme"]
    local Utils = _modules["Utils"]

    function Tab.new(window, name, order)
        local Theme = window.theme or DefaultTheme
        local button = Instance.new("TextButton")
        button.Name = tostring(name)
        button.Size = UDim2.new(1, -20, 0, 38)
        button.BackgroundColor3 = Theme.TabInactive
        button.BackgroundTransparency = 0.2
        button.Text = tostring(name)
        button.TextColor3 = Theme.TextMuted
        button.Font = Theme.FontBold
        button.TextSize = 11
        button.LayoutOrder = order or 1
        button.AutoButtonColor = false
        button.Selectable = true
        button.Parent = window.tabContainer

        local corner = Instance.new("UICorner")
        corner.CornerRadius = Theme.CornerRadius
        corner.Parent = button

        local stroke = Instance.new("UIStroke")
        stroke.Color = Theme.Accent
        stroke.Transparency = 1
        stroke.Parent = button

        local container = Instance.new("ScrollingFrame")
        container.Name = tostring(name) .. "Content"
        container.Size = UDim2.new(1, -20, 1, -16)
        container.Position = UDim2.fromOffset(10, 8)
        container.BackgroundTransparency = 1
        container.BorderSizePixel = 0
        container.ScrollBarThickness = 3
        container.ScrollBarImageColor3 = Theme.Accent
        container.ScrollBarImageTransparency = 0.35
        container.AutomaticCanvasSize = Enum.AutomaticSize.Y
        container.CanvasSize = UDim2.new()
        container.ScrollingDirection = Enum.ScrollingDirection.Y
        container.Visible = false
        container.Parent = window.rightPanel

        local layout = Instance.new("UIListLayout")
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 8)
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        layout.Parent = container

        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0, 2)
        padding.PaddingBottom = UDim.new(0, 10)
        padding.PaddingRight = UDim.new(0, 6)
        padding.Parent = container

        local self = {
            button = button,
            container = container,
            name = name,
            window = window
        }

        self.updateLayout = function(compact)
            if compact then
                button.Size = UDim2.fromOffset(math.clamp(#tostring(name) * 8 + 28, 76, 140), 34)
                container.Size = UDim2.new(1, -16, 1, -12)
                container.Position = UDim2.fromOffset(8, 6)
            else
                button.Size = UDim2.new(1, -20, 0, 38)
                container.Size = UDim2.new(1, -20, 1, -16)
                container.Position = UDim2.fromOffset(10, 8)
            end
        end

        button.MouseEnter:Connect(function()
            if window.activeTab ~= self then
                Utils.tween(button, TweenInfo.new(0.15), {BackgroundColor3 = Theme.SecondaryBackground, TextColor3 = Theme.TextSecondary})
            end
        end)
        button.MouseLeave:Connect(function()
            if window.activeTab ~= self then
                Utils.tween(button, TweenInfo.new(0.15), {BackgroundColor3 = Theme.TabInactive, TextColor3 = Theme.TextMuted})
            end
        end)
        button.SelectionGained:Connect(function()
            Utils.tween(stroke, TweenInfo.new(0.12), {Transparency = 0.2})
        end)
        button.SelectionLost:Connect(function()
            Utils.tween(stroke, TweenInfo.new(0.12), {Transparency = window.activeTab == self and 0.45 or 1})
        end)
        button.Activated:Connect(function()
            Tab.switch(window, name)
        end)

        table.insert(window.tabs, self)
        self.updateLayout(window.mainFrame.AbsoluteSize.X > 0 and window.mainFrame.AbsoluteSize.X < 520)
        if #window.tabs == 1 then Tab.switch(window, name) end
        return self
    end

    function Tab.switch(window, tabName)
        for _, tab in ipairs(window.tabs or {}) do
            local selected = tab.name == tabName
            tab.container.Visible = selected
            Utils.tween(tab.button, TweenInfo.new(0.18), {
                BackgroundColor3 = selected and (window.theme.SurfaceActive or window.theme.TabActive) or window.theme.TabInactive,
                TextColor3 = selected and window.theme.TextPrimary or window.theme.TextMuted
            })
            local stroke = tab.button:FindFirstChildOfClass("UIStroke")
            if stroke then Utils.tween(stroke, TweenInfo.new(0.18), {Transparency = selected and 0.45 or 1}) end
            if selected then
                window.activeTab = tab
                tab.container.CanvasPosition = Vector2.new(0, tab.container.CanvasPosition.Y)
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

    local DefaultTheme = _modules["Theme"]
    local Utils = _modules["Utils"]

    local function context(parent)
        if type(parent) == "table" then
            return parent.container, (parent.window and parent.window.theme) or DefaultTheme
        end
        return parent, DefaultTheme
    end

    function Button.new(parent, name, cb)
        local container, Theme = context(parent)
        local text = type(name) == "table" and (name.Name or name[1]) or name
        local desc = type(name) == "table" and (name.Desc or name[2]) or nil
        local callback = type(name) == "table" and (name.Callback or cb) or cb
        local connections, disabled = {}, false
        local function connect(signal, fn)
            local connection = signal:Connect(fn)
            table.insert(connections, connection)
            return connection
        end

        local frm = Instance.new("Frame")
        frm.Size = UDim2.new(1, 0, 0, desc and 64 or 48)
        frm.BackgroundColor3 = Theme.PanelBackground
        frm.BackgroundTransparency = Theme.PanelTransparency
        frm.Parent = container

        local corner = Instance.new("UICorner")
        corner.CornerRadius = Theme.CornerRadius
        corner.Parent = frm
        local stroke = Instance.new("UIStroke")
        stroke.Color = Theme.Stroke
        stroke.Transparency = Theme.PanelStrokeTransparency
        stroke.Parent = frm

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.fromScale(1, 1)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.Selectable = true
        btn.Parent = frm

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -32, 0, desc and 22 or 28)
        lbl.Position = UDim2.new(0, 16, 0, desc and 10 or 10)
        lbl.BackgroundTransparency = 1
        lbl.Text = tostring(text or "Button")
        lbl.TextColor3 = Theme.TextSecondary
        lbl.Font = Theme.FontMedium
        lbl.TextSize = 13
        lbl.TextWrapped = true
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = frm

        if desc then
            local description = Instance.new("TextLabel")
            description.Size = UDim2.new(1, -32, 0, 22)
            description.Position = UDim2.new(0, 16, 0, 34)
            description.BackgroundTransparency = 1
            description.Text = tostring(desc)
            description.TextColor3 = Theme.TextMuted
            description.Font = Theme.FontMedium
            description.TextSize = 11
            description.TextWrapped = true
            description.TextXAlignment = Enum.TextXAlignment.Left
            description.Parent = frm
        end

        local function focused(on)
            if disabled then return end
            Utils.tween(frm, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {
                BackgroundColor3 = on and Theme.SecondaryBackground or Theme.PanelBackground,
            })
            Utils.tween(lbl, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {
                TextColor3 = on and Theme.TextPrimary or Theme.TextSecondary,
            })
            stroke.Color = on and Theme.Accent or Theme.Stroke
        end

        connect(btn.MouseEnter, function() focused(true) end)
        connect(btn.MouseLeave, function() focused(false) end)
        connect(btn.SelectionGained, function() focused(true) end)
        connect(btn.SelectionLost, function() focused(false) end)
        connect(btn.Activated, function()
            if disabled then return end
            Utils.tween(frm, TweenInfo.new(0.08, Enum.EasingStyle.Sine), { BackgroundColor3 = Theme.Accent })
            task.delay(0.09, function()
                if frm.Parent and not disabled then focused(false) end
            end)
            if callback then callback() end
        end)

        local self = { frame = frm, button = btn }
        function self.setDisabled(value)
            disabled = not not value
            btn.Active = not disabled
            btn.Selectable = not disabled
            lbl.TextColor3 = disabled and Theme.TextMuted or Theme.TextSecondary
            frm.BackgroundColor3 = Theme.PanelBackground
            stroke.Color = Theme.Stroke
        end
        function self.destroy()
            for _, connection in ipairs(connections) do connection:Disconnect() end
            if frm.Parent then frm:Destroy() end
        end
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

    local DefaultTheme = _modules["Theme"]
    local Utils = _modules["Utils"]

    local function context(parent)
        if type(parent) == "table" then
            return parent.container, (parent.window and parent.window.theme) or DefaultTheme
        end
        return parent, DefaultTheme
    end

    function Toggle.new(parent, name, defaultState, cb)
        local container, Theme = context(parent)
        local text = type(name) == "table" and (name.Name or name[1]) or name
        local desc = type(name) == "table" and (name.Desc or name[2]) or nil
        local stateVal = not not defaultState
        local connections, disabled = {}, false
        local function connect(signal, fn)
            local connection = signal:Connect(fn)
            table.insert(connections, connection)
            return connection
        end

        local frm = Instance.new("Frame")
        frm.Size = UDim2.new(1, 0, 0, desc and 64 or 48)
        frm.BackgroundColor3 = Theme.PanelBackground
        frm.BackgroundTransparency = Theme.PanelTransparency
        frm.Parent = container
        local corner = Instance.new("UICorner")
        corner.CornerRadius = Theme.CornerRadius
        corner.Parent = frm
        local stroke = Instance.new("UIStroke")
        stroke.Color = Theme.Stroke
        stroke.Transparency = Theme.PanelStrokeTransparency
        stroke.Parent = frm

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.fromScale(1, 1)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.Selectable = true
        btn.Parent = frm

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -76, 0, desc and 22 or 28)
        lbl.Position = UDim2.new(0, 16, 0, desc and 10 or 10)
        lbl.BackgroundTransparency = 1
        lbl.Text = tostring(text or "Toggle")
        lbl.TextColor3 = Theme.TextSecondary
        lbl.Font = Theme.FontMedium
        lbl.TextSize = 13
        lbl.TextWrapped = true
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = frm

        if desc then
            local description = Instance.new("TextLabel")
            description.Size = UDim2.new(1, -76, 0, 22)
            description.Position = UDim2.new(0, 16, 0, 34)
            description.BackgroundTransparency = 1
            description.Text = tostring(desc)
            description.TextColor3 = Theme.TextMuted
            description.Font = Theme.FontMedium
            description.TextSize = 11
            description.TextWrapped = true
            description.TextXAlignment = Enum.TextXAlignment.Left
            description.Parent = frm
        end

        local track = Instance.new("Frame")
        track.Size = UDim2.new(0, 44, 0, 24)
        track.Position = UDim2.new(1, -60, 0.5, -12)
        track.BackgroundColor3 = Theme.SecondaryBackground
        track.Parent = frm
        local trackCorner = Instance.new("UICorner")
        trackCorner.CornerRadius = UDim.new(1, 0)
        trackCorner.Parent = track
        local knob = Instance.new("Frame")
        knob.Size = UDim2.fromOffset(18, 18)
        knob.BackgroundColor3 = Theme.TextPrimary
        knob.Parent = track
        local knobCorner = Instance.new("UICorner")
        knobCorner.CornerRadius = UDim.new(1, 0)
        knobCorner.Parent = knob

        local function updateVisuals()
            Utils.tween(track, TweenInfo.new(0.16, Enum.EasingStyle.Sine), {
                BackgroundColor3 = stateVal and Theme.Accent or Theme.SecondaryBackground,
            })
            Utils.tween(knob, TweenInfo.new(0.16, Enum.EasingStyle.Sine), {
                Position = stateVal and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9),
            })
        end
        local function focused(on)
            if disabled then return end
            frm.BackgroundColor3 = on and Theme.SecondaryBackground or Theme.PanelBackground
            lbl.TextColor3 = on and Theme.TextPrimary or Theme.TextSecondary
            stroke.Color = on and Theme.Accent or Theme.Stroke
        end
        local function set(value, fire)
            stateVal = not not value
            updateVisuals()
            if fire and cb then cb(stateVal) end
        end

        connect(btn.MouseEnter, function() focused(true) end)
        connect(btn.MouseLeave, function() focused(false) end)
        connect(btn.SelectionGained, function() focused(true) end)
        connect(btn.SelectionLost, function() focused(false) end)
        connect(btn.Activated, function()
            if not disabled then set(not stateVal, true) end
        end)
        updateVisuals()

        local self = { frame = frm, button = btn }
        self.set = function(value) set(value, true) end
        self.get = function() return stateVal end
        function self.setDisabled(value)
            disabled = not not value
            btn.Active = not disabled
            btn.Selectable = not disabled
            lbl.TextColor3 = disabled and Theme.TextMuted or Theme.TextSecondary
            track.BackgroundTransparency = disabled and 0.45 or 0
            stroke.Color = Theme.Stroke
        end
        function self.destroy()
            for _, connection in ipairs(connections) do connection:Disconnect() end
            if frm.Parent then frm:Destroy() end
        end
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

    local DefaultTheme = _modules["Theme"]
    local Utils = _modules["Utils"]

    local function context(parent)
        if type(parent) == "table" then
            return parent.container, (parent.window and parent.window.theme) or DefaultTheme
        end
        return parent, DefaultTheme
    end

    local function validNumber(value)
        return type(value) == "number" and value == value and value > -math.huge and value < math.huge
    end

    function Slider.new(parent, name, minVal, maxVal, defaultVal, formatFunc, cb)
        local container, Theme = context(parent)
        local desc, step
        if type(name) == "table" and (name.Min ~= nil or name.Max ~= nil or name.Default ~= nil or name.Step ~= nil) then
            local config, configCallback = name, minVal
            name = config.Name or config[1] or "Slider"
            desc = config.Desc or config.Description
            minVal = config.Min
            maxVal = config.Max
            defaultVal = config.Default
            step = config.Step
            formatFunc = config.Format or config.FormatFunc
            cb = config.Callback or (type(configCallback) == "function" and configCallback) or cb
        elseif type(name) == "table" then
            desc = name.Desc or name[2]
            step = name.Step
            name = name.Name or name[1] or "Slider"
        end

        assert(validNumber(minVal), "Slider Min must be a finite number")
        assert(validNumber(maxVal) and maxVal > minVal, "Slider Max must be a finite number greater than Min")
        assert(validNumber(defaultVal) and defaultVal >= minVal and defaultVal <= maxVal, "Slider Default must be between Min and Max")
        if step ~= nil then
            assert(validNumber(step) and step > 0, "Slider Step must be a positive finite number")
        end
        step = step or (maxVal - minVal) / 100
        local formatVal = type(formatFunc) == "function" and formatFunc or function(value) return tostring(value) end
        local uis = Utils.safeSvc("UserInputService")
        local connections, disabled, sliding, dragInput = {}, false, false, nil
        local currentVal = defaultVal
        local function connect(signal, fn)
            local connection = signal:Connect(fn)
            table.insert(connections, connection)
            return connection
        end

        local frm = Instance.new("Frame")
        frm.Size = UDim2.new(1, 0, 0, desc and 76 or 62)
        frm.BackgroundColor3 = Theme.PanelBackground
        frm.BackgroundTransparency = Theme.PanelTransparency
        frm.Parent = container
        local corner = Instance.new("UICorner")
        corner.CornerRadius = Theme.CornerRadius
        corner.Parent = frm
        local stroke = Instance.new("UIStroke")
        stroke.Color = Theme.Stroke
        stroke.Transparency = Theme.PanelStrokeTransparency
        stroke.Parent = frm

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -32, 0, 22)
        lbl.Position = UDim2.new(0, 16, 0, 8)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3 = Theme.TextSecondary
        lbl.Font = Theme.FontMedium
        lbl.TextSize = 13
        lbl.TextWrapped = true
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = frm

        if desc then
            local description = Instance.new("TextLabel")
            description.Size = UDim2.new(1, -32, 0, 18)
            description.Position = UDim2.new(0, 16, 0, 29)
            description.BackgroundTransparency = 1
            description.Text = tostring(desc)
            description.TextColor3 = Theme.TextMuted
            description.Font = Theme.FontMedium
            description.TextSize = 11
            description.TextWrapped = true
            description.TextXAlignment = Enum.TextXAlignment.Left
            description.Parent = frm
        end

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, -32, 0, 8)
        bar.Position = UDim2.new(0, 16, 1, -18)
        bar.BackgroundColor3 = Theme.SecondaryBackground
        bar.Parent = frm
        local barCorner = Instance.new("UICorner")
        barCorner.CornerRadius = UDim.new(1, 0)
        barCorner.Parent = bar
        local fill = Instance.new("Frame")
        fill.BackgroundColor3 = Theme.Accent
        fill.Parent = bar
        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(1, 0)
        fillCorner.Parent = fill

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.fromScale(1, 1)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.Selectable = true
        btn.Parent = frm

        local function quantize(value)
            local steps = math.floor((value - minVal) / step + 0.5)
            return math.clamp(minVal + steps * step, minVal, maxVal)
        end
        currentVal = quantize(currentVal)
        local function render()
            fill.Size = UDim2.new((currentVal - minVal) / (maxVal - minVal), 0, 1, 0)
            lbl.Text = tostring(name) .. ": " .. tostring(formatVal(currentVal))
        end
        local function set(value, fire)
            assert(validNumber(value), "Slider value must be a finite number")
            local nextValue = quantize(math.clamp(value, minVal, maxVal))
            if nextValue == currentVal then return end
            currentVal = nextValue
            render()
            if fire and cb then cb(currentVal) end
        end
        local function updateAt(x)
            if disabled or bar.AbsoluteSize.X <= 0 then return end
            local percent = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            set(minVal + (maxVal - minVal) * percent, true)
        end
        local function focused(on)
            if disabled then return end
            frm.BackgroundColor3 = on and Theme.SecondaryBackground or Theme.PanelBackground
            lbl.TextColor3 = on and Theme.TextPrimary or Theme.TextSecondary
            fill.BackgroundColor3 = on and (Theme.AccentHover or Theme.Accent) or Theme.Accent
            stroke.Color = on and Theme.Accent or Theme.Stroke
        end

        connect(btn.MouseEnter, function() focused(true) end)
        connect(btn.MouseLeave, function() focused(false) end)
        connect(btn.SelectionGained, function() focused(true) end)
        connect(btn.SelectionLost, function() focused(false) end)
        connect(btn.InputBegan, function(input)
            if disabled then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                sliding, dragInput = true, input
                updateAt(input.Position.X)
            elseif input.KeyCode == Enum.KeyCode.Left or input.KeyCode == Enum.KeyCode.DPadLeft or input.KeyCode == Enum.KeyCode.Down or input.KeyCode == Enum.KeyCode.DPadDown then
                set(currentVal - step, true)
            elseif input.KeyCode == Enum.KeyCode.Right or input.KeyCode == Enum.KeyCode.DPadRight or input.KeyCode == Enum.KeyCode.Up or input.KeyCode == Enum.KeyCode.DPadUp then
                set(currentVal + step, true)
            end
        end)
        connect(uis.InputChanged, function(input)
            if sliding and (input == dragInput or input.UserInputType == Enum.UserInputType.MouseMovement) then
                updateAt(input.Position.X)
            end
        end)
        connect(uis.InputEnded, function(input)
            if input == dragInput or (sliding and input.UserInputType == Enum.UserInputType.MouseButton1) then
                sliding, dragInput = false, nil
            end
        end)
        render()

        local self = { frame = frm, button = btn }
        self.set = function(value) set(value, true) end
        self.get = function() return currentVal end
        function self.setDisabled(value)
            disabled = not not value
            btn.Active = not disabled
            btn.Selectable = not disabled
            sliding, dragInput = false, nil
            lbl.TextColor3 = disabled and Theme.TextMuted or Theme.TextSecondary
            fill.BackgroundTransparency = disabled and 0.45 or 0
            stroke.Color = Theme.Stroke
        end
        function self.destroy()
            for _, connection in ipairs(connections) do connection:Disconnect() end
            if frm.Parent then frm:Destroy() end
        end
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

    local DefaultTheme = _modules["Theme"]
    local Utils = _modules["Utils"]

    local function context(parent)
        if type(parent) == "table" then
            return parent.container, (parent.window and parent.window.theme) or DefaultTheme
        end
        return parent, DefaultTheme
    end

    local function option(option)
        if type(option) == "table" then
            local label = option.name or option.Name or option.label or option.Label or option[1]
            local value = option.val
            if value == nil then value = option.Value end
            if value == nil then value = option.value end
            if value == nil then value = option[2] end
            if value == nil then value = label end
            return tostring(label or value or "Option"), value
        end
        return tostring(option), option
    end

    function Dropdown.new(parent, name, opts, defaultIdx, cb)
        local container, Theme = context(parent)
        local desc = type(name) == "table" and (name.Desc or name[2]) or nil
        name = type(name) == "table" and (name.Name or name[1]) or name
        local options = type(opts) == "table" and opts or {}
        local cur = math.clamp(tonumber(defaultIdx) or 1, 1, math.max(#options, 1))
        local connections, optionConnections = {}, {}
        local disabled, expanded = false, false
        local function connect(signal, fn, list)
            local connection = signal:Connect(fn)
            table.insert(list or connections, connection)
            return connection
        end
        local function clearOptionConnections()
            for _, connection in ipairs(optionConnections) do connection:Disconnect() end
            table.clear(optionConnections)
        end

        local collapsedHeight = desc and 68 or 52
        local frm = Instance.new("Frame")
        frm.Size = UDim2.new(1, 0, 0, collapsedHeight)
        frm.BackgroundColor3 = Theme.PanelBackground
        frm.BackgroundTransparency = Theme.PanelTransparency
        frm.ClipsDescendants = true
        frm.Parent = container
        local corner = Instance.new("UICorner")
        corner.CornerRadius = Theme.CornerRadius
        corner.Parent = frm
        local stroke = Instance.new("UIStroke")
        stroke.Color = Theme.Stroke
        stroke.Transparency = Theme.PanelStrokeTransparency
        stroke.Parent = frm

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -156, 0, 24)
        lbl.Position = UDim2.new(0, 16, 0, desc and 10 or 14)
        lbl.BackgroundTransparency = 1
        lbl.Text = tostring(name or "Dropdown")
        lbl.TextColor3 = Theme.TextSecondary
        lbl.Font = Theme.FontMedium
        lbl.TextSize = 13
        lbl.TextWrapped = true
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = frm

        if desc then
            local description = Instance.new("TextLabel")
            description.Size = UDim2.new(1, -156, 0, 22)
            description.Position = UDim2.new(0, 16, 0, 34)
            description.BackgroundTransparency = 1
            description.Text = tostring(desc)
            description.TextColor3 = Theme.TextMuted
            description.Font = Theme.FontMedium
            description.TextSize = 11
            description.TextWrapped = true
            description.TextXAlignment = Enum.TextXAlignment.Left
            description.Parent = frm
        end

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 124, 0, 36)
        btn.Position = UDim2.new(1, -140, 0, desc and 16 or 8)
        btn.BackgroundColor3 = Theme.SecondaryBackground
        btn.TextColor3 = Theme.TextSecondary
        btn.Font = Theme.FontMedium
        btn.TextSize = 11
        btn.TextTruncate = Enum.TextTruncate.AtEnd
        btn.AutoButtonColor = false
        btn.Selectable = true
        btn.Parent = frm
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 5)
        btnCorner.Parent = btn

        local list = Instance.new("ScrollingFrame")
        list.Size = UDim2.new(1, -24, 0, 0)
        list.Position = UDim2.new(0, 12, 0, collapsedHeight)
        list.BackgroundColor3 = Theme.SecondaryBackground
        list.BorderSizePixel = 0
        list.CanvasSize = UDim2.new()
        list.AutomaticCanvasSize = Enum.AutomaticSize.Y
        list.ScrollBarThickness = 3
        list.ScrollBarImageColor3 = Theme.Accent
        list.Visible = false
        list.Parent = frm
        local listCorner = Instance.new("UICorner")
        listCorner.CornerRadius = UDim.new(0, 5)
        listCorner.Parent = list
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 4)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = list
        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0, 6)
        padding.PaddingBottom = UDim.new(0, 6)
        padding.PaddingLeft = UDim.new(0, 6)
        padding.PaddingRight = UDim.new(0, 6)
        padding.Parent = list

        local setExpanded, rebuild
        local function updateButton()
            btn.Text = #options > 0 and (option(options[cur])) .. (expanded and "  ▲" or "  ▼") or "No options"
        end
        local function select(index, fire)
            if #options == 0 then return end
            cur = math.clamp(index, 1, #options)
            updateButton()
            if fire and cb then
                local _, value = option(options[cur])
                cb(value)
            end
        end
        setExpanded = function(value)
            expanded = not disabled and #options > 0 and not not value
            local listHeight = expanded and math.min(#options * 40 + 12, 172) or 0
            list.Visible = expanded
            list.Size = UDim2.new(1, -24, 0, listHeight)
            frm.Size = UDim2.new(1, 0, 0, collapsedHeight + listHeight + (expanded and 8 or 0))
            stroke.Color = expanded and Theme.Accent or Theme.Stroke
            updateButton()
        end
        rebuild = function()
            clearOptionConnections()
            for _, child in ipairs(list:GetChildren()) do
                if child:IsA("GuiButton") then child:Destroy() end
            end
            for index, raw in ipairs(options) do
                local label = option(raw)
                local item = Instance.new("TextButton")
                item.Size = UDim2.new(1, -12, 0, 36)
                item.BackgroundColor3 = index == cur and Theme.Accent or Theme.PanelBackground
                item.BackgroundTransparency = index == cur and 0.1 or Theme.PanelTransparency
                item.Text = label
                item.TextColor3 = index == cur and Theme.TextPrimary or Theme.TextSecondary
                item.Font = Theme.FontMedium
                item.TextSize = 12
                item.TextWrapped = true
                item.AutoButtonColor = false
                item.Selectable = true
                item.LayoutOrder = index
                item.Parent = list
                local itemCorner = Instance.new("UICorner")
                itemCorner.CornerRadius = UDim.new(0, 4)
                itemCorner.Parent = item
                connect(item.Activated, function()
                    if disabled then return end
                    select(index, true)
                    setExpanded(false)
                    Utils.safeSvc("GuiService").SelectedObject = btn
                end, optionConnections)
                connect(item.SelectionGained, function()
                    if not disabled then item.BackgroundColor3 = Theme.AccentHover or Theme.Accent end
                end, optionConnections)
                connect(item.SelectionLost, function()
                    item.BackgroundColor3 = index == cur and Theme.Accent or Theme.PanelBackground
                end, optionConnections)
            end
            setExpanded(expanded)
        end

        connect(btn.Activated, function()
            if not disabled then setExpanded(not expanded) end
        end)
        connect(btn.SelectionGained, function()
            if not disabled then
                btn.TextColor3 = Theme.TextPrimary
                stroke.Color = Theme.Accent
            end
        end)
        connect(btn.SelectionLost, function()
            btn.TextColor3 = disabled and Theme.TextMuted or Theme.TextSecondary
            if not expanded then stroke.Color = Theme.Stroke end
        end)
        connect(btn.InputBegan, function(input)
            if disabled or #options == 0 then return end
            if input.KeyCode == Enum.KeyCode.Down or input.KeyCode == Enum.KeyCode.DPadDown then
                select(cur % #options + 1, true)
            elseif input.KeyCode == Enum.KeyCode.Up or input.KeyCode == Enum.KeyCode.DPadUp then
                select((cur - 2) % #options + 1, true)
            elseif input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB then
                setExpanded(false)
            end
        end)
        rebuild()

        local self = { frame = frm, button = btn }
        function self.setOptions(newOpts, newDefaultIdx)
            assert(type(newOpts) == "table", "Dropdown options must be a table")
            options = newOpts
            cur = math.clamp(tonumber(newDefaultIdx) or 1, 1, math.max(#options, 1))
            rebuild()
            if #options > 0 and cb then
                local _, value = option(options[cur])
                cb(value)
            end
        end
        function self.get()
            if #options == 0 then return nil end
            local _, value = option(options[cur])
            return value
        end
        function self.setDisabled(value)
            disabled = not not value
            btn.Active = not disabled
            btn.Selectable = not disabled
            btn.TextColor3 = disabled and Theme.TextMuted or Theme.TextSecondary
            if disabled then setExpanded(false) end
        end
        function self.destroy()
            clearOptionConnections()
            for _, connection in ipairs(connections) do connection:Disconnect() end
            if frm.Parent then frm:Destroy() end
        end
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

    local DefaultTheme = _modules["Theme"]
    local Utils = _modules["Utils"]

    local function context(parent)
        if type(parent) == "table" then
            return parent.container, (parent.window and parent.window.theme) or DefaultTheme
        end
        return parent, DefaultTheme
    end

    function Textbox.new(parent, name, placeholderText, cb)
        local container, Theme = context(parent)
        local desc = type(name) == "table" and (name.Desc or name[2]) or nil
        local callback = type(name) == "table" and (name.Callback or cb) or cb
        placeholderText = type(name) == "table" and (name.Placeholder or placeholderText) or placeholderText
        name = type(name) == "table" and (name.Name or name[1]) or name
        local connections, disabled = {}, false
        local function connect(signal, fn)
            local connection = signal:Connect(fn)
            table.insert(connections, connection)
            return connection
        end

        local frm = Instance.new("Frame")
        frm.Size = UDim2.new(1, 0, 0, desc and 82 or 64)
        frm.BackgroundColor3 = Theme.PanelBackground
        frm.BackgroundTransparency = Theme.PanelTransparency
        frm.Parent = container
        local corner = Instance.new("UICorner")
        corner.CornerRadius = Theme.CornerRadius
        corner.Parent = frm
        local stroke = Instance.new("UIStroke")
        stroke.Color = Theme.Stroke
        stroke.Transparency = Theme.PanelStrokeTransparency
        stroke.Parent = frm

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -32, 0, 22)
        lbl.Position = UDim2.new(0, 16, 0, 8)
        lbl.BackgroundTransparency = 1
        lbl.Text = tostring(name or "Text")
        lbl.TextColor3 = Theme.TextSecondary
        lbl.Font = Theme.FontMedium
        lbl.TextSize = 13
        lbl.TextWrapped = true
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = frm

        if desc then
            local description = Instance.new("TextLabel")
            description.Size = UDim2.new(1, -32, 0, 18)
            description.Position = UDim2.new(0, 16, 0, 28)
            description.BackgroundTransparency = 1
            description.Text = tostring(desc)
            description.TextColor3 = Theme.TextMuted
            description.Font = Theme.FontMedium
            description.TextSize = 11
            description.TextWrapped = true
            description.TextXAlignment = Enum.TextXAlignment.Left
            description.Parent = frm
        end

        local boxBg = Instance.new("Frame")
        boxBg.Size = UDim2.new(1, -32, 0, 36)
        boxBg.Position = UDim2.new(0, 16, 1, -44)
        boxBg.BackgroundColor3 = Theme.SecondaryBackground
        boxBg.Parent = frm
        local boxCorner = Instance.new("UICorner")
        boxCorner.CornerRadius = UDim.new(0, 5)
        boxCorner.Parent = boxBg
        local boxStroke = Instance.new("UIStroke")
        boxStroke.Color = Theme.Stroke
        boxStroke.Transparency = Theme.PanelStrokeTransparency
        boxStroke.Parent = boxBg

        local txt = Instance.new("TextBox")
        txt.Size = UDim2.new(1, -20, 1, 0)
        txt.Position = UDim2.new(0, 10, 0, 0)
        txt.BackgroundTransparency = 1
        txt.Text = ""
        txt.PlaceholderText = placeholderText or "Enter text..."
        txt.PlaceholderColor3 = Theme.TextMuted
        txt.TextColor3 = Theme.TextPrimary
        txt.Font = Theme.FontMedium
        txt.TextSize = 12
        txt.TextXAlignment = Enum.TextXAlignment.Left
        txt.ClearTextOnFocus = false
        txt.Selectable = true
        txt.Parent = boxBg

        local function focused(on)
            if disabled then return end
            boxStroke.Color = on and Theme.Accent or Theme.Stroke
            boxStroke.Transparency = on and 0.25 or Theme.PanelStrokeTransparency
            frm.BackgroundColor3 = on and Theme.SecondaryBackground or Theme.PanelBackground
            lbl.TextColor3 = on and Theme.TextPrimary or Theme.TextSecondary
        end
        connect(txt.Focused, function() focused(true) end)
        connect(txt.FocusLost, function(enterPressed)
            focused(false)
            if not disabled and callback then callback(txt.Text, enterPressed) end
        end)
        connect(txt.SelectionGained, function()
            if not disabled and not txt:IsFocused() then txt:CaptureFocus() end
        end)

        local self = { frame = frm, textbox = txt }
        self.get = function() return txt.Text end
        self.set = function(text) txt.Text = tostring(text or "") end
        function self.setDisabled(value)
            disabled = not not value
            txt.TextEditable = not disabled
            txt.Selectable = not disabled
            if disabled and txt:IsFocused() then txt:ReleaseFocus() end
            lbl.TextColor3 = disabled and Theme.TextMuted or Theme.TextSecondary
            boxBg.BackgroundTransparency = disabled and 0.45 or 0
            boxStroke.Color = Theme.Stroke
        end
        function self.destroy()
            for _, connection in ipairs(connections) do connection:Disconnect() end
            if frm.Parent then frm:Destroy() end
        end
        return self
    end

    return Textbox
end)()

-- Module: Label
_modules["Label"] = (function()
    local Label = {}

    local import = function(name)
        local ok, res = pcall(function() return require(script.Parent[name]) end)
        if ok then return res end
        return _G.UniversalUILib_GetModule(name)
    end

    local DefaultTheme = _modules["Theme"]

    local function context(parent)
        if type(parent) == "table" then
            return parent.container, (parent.window and parent.window.theme) or DefaultTheme
        end
        return parent, DefaultTheme
    end

    function Label.new(parent, text)
        local container, Theme = context(parent)
        local title = type(text) == "table" and (text.Name or text[1]) or text
        local desc = type(text) == "table" and (text.Desc or text[2]) or nil
        local frm = Instance.new("Frame")
        frm.Size = UDim2.new(1, 0, 0, 0)
        frm.AutomaticSize = Enum.AutomaticSize.Y
        frm.BackgroundColor3 = Theme.PanelBackground
        frm.BackgroundTransparency = Theme.PanelTransparency
        frm.Parent = container
        local corner = Instance.new("UICorner")
        corner.CornerRadius = Theme.CornerRadius
        corner.Parent = frm
        local stroke = Instance.new("UIStroke")
        stroke.Color = Theme.Stroke
        stroke.Transparency = Theme.PanelStrokeTransparency
        stroke.Parent = frm
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 5)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = frm
        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0, 12)
        padding.PaddingBottom = UDim.new(0, 12)
        padding.PaddingLeft = UDim.new(0, 16)
        padding.PaddingRight = UDim.new(0, 16)
        padding.Parent = frm

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 0)
        lbl.AutomaticSize = Enum.AutomaticSize.Y
        lbl.BackgroundTransparency = 1
        lbl.Text = tostring(title or "")
        lbl.TextColor3 = Theme.TextPrimary
        lbl.Font = Theme.FontMedium
        lbl.TextSize = 13
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextYAlignment = Enum.TextYAlignment.Top
        lbl.TextWrapped = true
        lbl.LayoutOrder = 1
        lbl.Parent = frm

        local lblDesc
        if desc then
            lblDesc = Instance.new("TextLabel")
            lblDesc.Size = UDim2.new(1, 0, 0, 0)
            lblDesc.AutomaticSize = Enum.AutomaticSize.Y
            lblDesc.BackgroundTransparency = 1
            lblDesc.Text = tostring(desc)
            lblDesc.TextColor3 = Theme.TextMuted
            lblDesc.Font = Theme.FontMedium
            lblDesc.TextSize = 11
            lblDesc.TextXAlignment = Enum.TextXAlignment.Left
            lblDesc.TextYAlignment = Enum.TextYAlignment.Top
            lblDesc.TextWrapped = true
            lblDesc.LayoutOrder = 2
            lblDesc.Parent = frm
        end

        local self = { frame = frm, label = lbl, descLabel = lblDesc }
        function self.set(newText)
            if type(newText) == "table" then
                if newText.Name or newText[1] then lbl.Text = tostring(newText.Name or newText[1]) end
                if lblDesc and (newText.Desc or newText[2]) then lblDesc.Text = tostring(newText.Desc or newText[2]) end
            else
                lbl.Text = tostring(newText or "")
            end
        end
        self.get = function() return lbl.Text end
        function self.destroy()
            if frm.Parent then frm:Destroy() end
        end
        return self
    end

    function Label.section(parent, text)
        local container, Theme = context(parent)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 28)
        lbl.BackgroundTransparency = 1
        lbl.Text = tostring(type(text) == "table" and (text.Name or text[1]) or text or "")
        lbl.TextColor3 = Theme.TextPrimary
        lbl.Font = Theme.FontBold
        lbl.TextSize = 12
        lbl.TextWrapped = true
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = container
        return {
            frame = lbl,
            label = lbl,
            set = function(value) lbl.Text = tostring(value or "") end,
            get = function() return lbl.Text end,
            destroy = function() if lbl.Parent then lbl:Destroy() end end,
        }
    end

    function Label.separator(parent)
        local container, Theme = context(parent)
        local frm = Instance.new("Frame")
        frm.Size = UDim2.new(1, 0, 0, 13)
        frm.BackgroundTransparency = 1
        frm.Parent = container
        local line = Instance.new("Frame")
        line.Size = UDim2.new(1, 0, 0, 1)
        line.Position = UDim2.new(0, 0, 0.5, 0)
        line.BackgroundColor3 = Theme.Stroke
        line.BackgroundTransparency = Theme.StrokeTransparency
        line.BorderSizePixel = 0
        line.Parent = frm
        return { frame = frm, destroy = function() if frm.Parent then frm:Destroy() end end }
    end

    Label.newSection = Label.section
    Label.newSeparator = Label.separator
    Label.Section = Label.section
    Label.Separator = Label.separator

    return Label
end)()

-- Module: Keybind
_modules["Keybind"] = (function()
    local Keybind = {}

    local import = function(name)
        local ok, res = pcall(function() return require(script.Parent[name]) end)
        if ok then return res end
        return _G.UniversalUILib_GetModule(name)
    end

    local DefaultTheme = _modules["Theme"]
    local Utils = _modules["Utils"]
    local uis = Utils.safeSvc("UserInputService")

    local function context(parent)
        if type(parent) == "table" then
            return parent.container, (parent.window and parent.window.theme) or DefaultTheme
        end
        return parent, DefaultTheme
    end

    local function keyName(key)
        local name = key and key.Name or "None"
        return ({ MouseButton1 = "MB1", MouseButton2 = "MB2", MouseButton3 = "MB3" })[name] or name
    end

    function Keybind.new(parent, name, defaultKey, cb)
        local container, Theme = context(parent)
        local text = type(name) == "table" and (name.Name or name[1]) or name
        local desc = type(name) == "table" and (name.Desc or name[2]) or nil
        local callback = type(name) == "table" and (name.Callback or cb) or cb
        local currentKey = defaultKey or Enum.KeyCode.E
        local isBinding, disabled, lastCapture = false, false, 0
        local connections = {}
        local function connect(signal, fn)
            local connection = signal:Connect(fn)
            table.insert(connections, connection)
            return connection
        end

        local frm = Instance.new("Frame")
        frm.Size = UDim2.new(1, 0, 0, desc and 64 or 48)
        frm.BackgroundColor3 = Theme.PanelBackground
        frm.BackgroundTransparency = Theme.PanelTransparency
        frm.Parent = container
        local corner = Instance.new("UICorner")
        corner.CornerRadius = Theme.CornerRadius
        corner.Parent = frm
        local stroke = Instance.new("UIStroke")
        stroke.Color = Theme.Stroke
        stroke.Transparency = Theme.PanelStrokeTransparency
        stroke.Parent = frm

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -124, 0, desc and 22 or 28)
        lbl.Position = UDim2.new(0, 16, 0, desc and 10 or 10)
        lbl.BackgroundTransparency = 1
        lbl.Text = tostring(text or "Keybind")
        lbl.TextColor3 = Theme.TextSecondary
        lbl.Font = Theme.FontMedium
        lbl.TextSize = 13
        lbl.TextWrapped = true
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = frm

        if desc then
            local description = Instance.new("TextLabel")
            description.Size = UDim2.new(1, -124, 0, 22)
            description.Position = UDim2.new(0, 16, 0, 34)
            description.BackgroundTransparency = 1
            description.Text = tostring(desc)
            description.TextColor3 = Theme.TextMuted
            description.Font = Theme.FontMedium
            description.TextSize = 11
            description.TextWrapped = true
            description.TextXAlignment = Enum.TextXAlignment.Left
            description.Parent = frm
        end

        local bindBtn = Instance.new("TextButton")
        bindBtn.Size = UDim2.new(0, 92, 0, 36)
        bindBtn.Position = UDim2.new(1, -108, 0.5, -18)
        bindBtn.BackgroundColor3 = Theme.SecondaryBackground
        bindBtn.Text = keyName(currentKey)
        bindBtn.TextColor3 = Theme.TextPrimary
        bindBtn.Font = Theme.FontMedium
        bindBtn.TextSize = 11
        bindBtn.AutoButtonColor = false
        bindBtn.Selectable = true
        bindBtn.Parent = frm
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 5)
        btnCorner.Parent = bindBtn
        local btnStroke = Instance.new("UIStroke")
        btnStroke.Color = Theme.Stroke
        btnStroke.Transparency = Theme.PanelStrokeTransparency
        btnStroke.Parent = bindBtn

        local function render()
            bindBtn.Text = isBinding and "Press a key..." or keyName(currentKey)
            bindBtn.BackgroundColor3 = isBinding and Theme.Accent or Theme.SecondaryBackground
            bindBtn.TextColor3 = disabled and Theme.TextMuted or Theme.TextPrimary
            btnStroke.Color = isBinding and Theme.Accent or Theme.Stroke
        end
        local function beginBinding()
            if disabled or isBinding then return end
            isBinding = true
            render()
        end
        local function finishBinding(key)
            if key then
                currentKey = key
                lastCapture = os.clock()
            end
            isBinding = false
            render()
        end
        local function focused(on)
            if disabled then return end
            frm.BackgroundColor3 = on and Theme.SecondaryBackground or Theme.PanelBackground
            lbl.TextColor3 = on and Theme.TextPrimary or Theme.TextSecondary
            stroke.Color = on and Theme.Accent or Theme.Stroke
        end

        connect(bindBtn.Activated, beginBinding)
        connect(bindBtn.MouseEnter, function() focused(true) end)
        connect(bindBtn.MouseLeave, function() focused(false) end)
        connect(bindBtn.SelectionGained, function() focused(true) end)
        connect(bindBtn.SelectionLost, function() focused(false) end)
        connect(uis.InputBegan, function(input, gameProcessed)
            if disabled then return end
            if isBinding then
                if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB then
                    finishBinding()
                elseif input.UserInputType == Enum.UserInputType.Keyboard then
                    finishBinding(input.KeyCode)
                elseif input.UserInputType == Enum.UserInputType.Gamepad1 then
                    finishBinding(input.KeyCode)
                elseif input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.MouseButton2
                    or input.UserInputType == Enum.UserInputType.MouseButton3 then
                    finishBinding(input.UserInputType)
                end
            elseif not gameProcessed and os.clock() - lastCapture > 0.1
                and (input.KeyCode == currentKey or input.UserInputType == currentKey) then
                if callback then callback() end
            end
        end)

        local self = { frame = frm, button = bindBtn }
        self.set = function(newKey)
            assert(newKey ~= nil and newKey.Name ~= nil, "Keybind value must be an EnumItem")
            finishBinding(newKey)
        end
        self.get = function() return currentKey end
        function self.setDisabled(value)
            disabled = not not value
            bindBtn.Active = not disabled
            bindBtn.Selectable = not disabled
            if disabled then isBinding = false end
            lbl.TextColor3 = disabled and Theme.TextMuted or Theme.TextSecondary
            stroke.Color = Theme.Stroke
            render()
        end
        function self.destroy()
            for _, connection in ipairs(connections) do connection:Disconnect() end
            if frm.Parent then frm:Destroy() end
        end
        return self
    end

    return Keybind
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
    Components.Label = _modules["Label"]
    Components.Keybind = _modules["Keybind"]
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
        containerGui.DisplayOrder = 100
        containerGui.Parent = Utils.getSafeGui()

        listFrame = Instance.new("Frame")
        listFrame.Size = UDim2.new(1, -24, 1, -24)
        listFrame.Position = UDim2.new(0, 12, 0, 12)
        listFrame.BackgroundTransparency = 1
        listFrame.Parent = containerGui

        local layout = Instance.new("UIListLayout")
        layout.FillDirection = Enum.FillDirection.Vertical
        layout.VerticalAlignment = Enum.VerticalAlignment.Top
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        layout.Padding = UDim.new(0, Theme.SpacingSM)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = listFrame

        return listFrame
    end

    function Notification.show(config)
        if type(config) == "string" then
            config = { Title = "Notification", Content = config }
        elseif type(config) ~= "table" then
            config = {}
        end

        local title = tostring(config.Title or config.title or "Notification")
        local content = tostring(config.Content or config.content or "")
        local duration = math.max(0, tonumber(config.Duration or config.duration) or 4)
        local parent = getContainer()

        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, 0, 0, 0)
        card.AutomaticSize = Enum.AutomaticSize.Y
        card.BackgroundColor3 = Theme.SurfaceElevated
        card.BackgroundTransparency = 1
        card.BorderSizePixel = 0
        card.ClipsDescendants = true
        card.Parent = parent

        local sizeConstraint = Instance.new("UISizeConstraint")
        sizeConstraint.MaxSize = Vector2.new(320, 10000)
        sizeConstraint.Parent = card

        local cardLayout = Instance.new("UIListLayout")
        cardLayout.SortOrder = Enum.SortOrder.LayoutOrder
        cardLayout.Padding = UDim.new(0, Theme.SpacingXS)
        cardLayout.Parent = card

        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0, Theme.SpacingMD)
        padding.PaddingBottom = UDim.new(0, Theme.SpacingSM)
        padding.PaddingLeft = UDim.new(0, Theme.SpacingMD)
        padding.PaddingRight = UDim.new(0, Theme.SpacingMD)
        padding.Parent = card

        local corner = Instance.new("UICorner")
        corner.CornerRadius = Theme.CornerRadius
        corner.Parent = card

        local stroke = Instance.new("UIStroke")
        stroke.Color = Theme.Stroke
        stroke.Transparency = 1
        stroke.Parent = card

        local titleLabel = Instance.new("TextLabel")
        titleLabel.Size = UDim2.new(1, -28, 0, 0)
        titleLabel.AutomaticSize = Enum.AutomaticSize.Y
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = title
        titleLabel.TextColor3 = Theme.TextPrimary
        titleLabel.TextTransparency = 1
        titleLabel.Font = Theme.FontBold
        titleLabel.TextSize = 13
        titleLabel.TextWrapped = true
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.LayoutOrder = 1
        titleLabel.Parent = card

        local dismiss = Instance.new("TextButton")
        dismiss.Size = UDim2.new(0, 24, 0, 24)
        dismiss.Position = UDim2.new(1, -32, 0, 6)
        dismiss.BackgroundTransparency = 1
        dismiss.Text = "×"
        dismiss.TextColor3 = Theme.TextMuted
        dismiss.TextTransparency = 1
        dismiss.Font = Theme.FontMedium
        dismiss.TextSize = 18
        dismiss.AutoButtonColor = false
        dismiss.ZIndex = 2
        dismiss.Parent = card

        local description = Instance.new("TextLabel")
        description.Size = UDim2.new(1, 0, 0, 0)
        description.AutomaticSize = Enum.AutomaticSize.Y
        description.BackgroundTransparency = 1
        description.Text = content
        description.TextColor3 = Theme.TextSecondary
        description.TextTransparency = 1
        description.Font = Theme.FontMedium
        description.TextSize = 11
        description.TextWrapped = true
        description.TextXAlignment = Enum.TextXAlignment.Left
        description.TextYAlignment = Enum.TextYAlignment.Top
        description.LayoutOrder = 2
        description.Visible = content ~= ""
        description.Parent = card

        local progressBackground = Instance.new("Frame")
        progressBackground.Size = UDim2.new(1, 0, 0, 2)
        progressBackground.BackgroundColor3 = Theme.SecondaryBackground
        progressBackground.BackgroundTransparency = 1
        progressBackground.BorderSizePixel = 0
        progressBackground.LayoutOrder = 3
        progressBackground.Parent = card

        local progressFill = Instance.new("Frame")
        progressFill.Size = UDim2.new(1, 0, 1, 0)
        progressFill.BackgroundColor3 = Theme.Accent
        progressFill.BackgroundTransparency = 1
        progressFill.BorderSizePixel = 0
        progressFill.Parent = progressBackground

        for _, item in ipairs({ progressBackground, progressFill }) do
            local progressCorner = Instance.new("UICorner")
            progressCorner.CornerRadius = UDim.new(1, 0)
            progressCorner.Parent = item
        end

        local closed = false
        local countdown

        local function close()
            if closed then return end
            closed = true
            if countdown then countdown:Cancel() end

            Utils.tween(card, TweenInfo.new(0.2), { BackgroundTransparency = 1 })
            Utils.tween(stroke, TweenInfo.new(0.2), { Transparency = 1 })
            Utils.tween(titleLabel, TweenInfo.new(0.2), { TextTransparency = 1 })
            Utils.tween(description, TweenInfo.new(0.2), { TextTransparency = 1 })
            Utils.tween(dismiss, TweenInfo.new(0.2), { TextTransparency = 1 })
            Utils.tween(progressBackground, TweenInfo.new(0.2), { BackgroundTransparency = 1 })
            Utils.tween(progressFill, TweenInfo.new(0.2), { BackgroundTransparency = 1 })
            task.delay(0.2, function()
                if card.Parent then card:Destroy() end
            end)
        end

        dismiss.Activated:Connect(close)
        dismiss.MouseEnter:Connect(function() dismiss.TextColor3 = Theme.TextPrimary end)
        dismiss.MouseLeave:Connect(function() dismiss.TextColor3 = Theme.TextMuted end)

        Utils.tween(card, TweenInfo.new(0.25), { BackgroundTransparency = Theme.PanelTransparency })
        Utils.tween(stroke, TweenInfo.new(0.25), { Transparency = Theme.PanelStrokeTransparency })
        Utils.tween(titleLabel, TweenInfo.new(0.25), { TextTransparency = 0 })
        Utils.tween(description, TweenInfo.new(0.25), { TextTransparency = 0 })
        Utils.tween(dismiss, TweenInfo.new(0.25), { TextTransparency = 0 })
        Utils.tween(progressBackground, TweenInfo.new(0.25), { BackgroundTransparency = 0 })
        Utils.tween(progressFill, TweenInfo.new(0.25), { BackgroundTransparency = 0 })

        task.delay(0.25, function()
            if closed then return end
            countdown = Utils.tween(progressFill, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
                Size = UDim2.new(0, 0, 1, 0)
            })
            countdown.Completed:Connect(close)
        end)

        return { Close = close }
    end

    return Notification
end)()

-- Module: Auth
_modules["Auth"] = (function()
    local Auth = {}

    local import = function(name)
        local ok, res = pcall(function() return require(script.Parent[name]) end)
        if ok then return res end
        return _G.UniversalUILib_GetModule(name)
    end

    local Theme = _modules["Theme"]
    local Utils = _modules["Utils"]
    local Drag = _modules["Drag"]

    function Auth.show(config)
        config = type(config) == "table" and config or {}
        local titleText = tostring(config.Title or "AUTH")
        local subtitleText = tostring(config.Subtitle or "Please enter your key.")
        local placeholder = tostring(config.KeyPlaceholder or "Enter Key...")
        local submitText = tostring(config.SubmitText or "Verify Key")
        local onSubmit = config.OnSubmit
        local links = type(config.Links) == "table" and config.Links or {}

        local ts = Utils.safeSvc("TweenService")
        local uis = Utils.safeSvc("UserInputService")
        local guiService = Utils.safeSvc("GuiService")
        local parent = Utils.getSafeGui()
        if not parent then return end

        local previousSelection = guiService.SelectedObject
        local gui = Instance.new("ScreenGui")
        gui.Name = "NMZUI_AUTH"
        gui.ResetOnSpawn = false
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        gui.IgnoreGuiInset = true
        gui.DisplayOrder = 200
        gui.Parent = parent

        local overlay = Instance.new("TextButton")
        overlay.Name = "ModalOverlay"
        overlay.Size = UDim2.new(1, 0, 1, 0)
        overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        overlay.BackgroundTransparency = 1
        overlay.BorderSizePixel = 0
        overlay.Text = ""
        overlay.AutoButtonColor = false
        overlay.Active = true
        overlay.Modal = true
        overlay.Selectable = false
        overlay.Parent = gui

        local main = Instance.new("Frame")
        main.Size = UDim2.new(1, -32, 0, 0)
        main.Position = UDim2.new(0.5, 0, 0.5, 0)
        main.AnchorPoint = Vector2.new(0.5, 0.5)
        main.AutomaticSize = Enum.AutomaticSize.Y
        main.BackgroundColor3 = Theme.Background
        main.BackgroundTransparency = Theme.BackgroundTransparency
        main.BorderSizePixel = 0
        main.ClipsDescendants = true
        main.Parent = overlay

        local sizeConstraint = Instance.new("UISizeConstraint")
        sizeConstraint.MaxSize = Vector2.new(400, 10000)
        sizeConstraint.Parent = main

        local scale = Instance.new("UIScale")
        scale.Scale = 0.92
        scale.Parent = main

        local stroke = Instance.new("UIStroke")
        stroke.Color = Theme.Stroke
        stroke.Thickness = 1
        stroke.Transparency = Theme.PanelStrokeTransparency
        stroke.Parent = main

        local corner = Instance.new("UICorner")
        corner.CornerRadius = Theme.WindowCornerRadius
        corner.Parent = main

        local mainLayout = Instance.new("UIListLayout")
        mainLayout.SortOrder = Enum.SortOrder.LayoutOrder
        mainLayout.Padding = UDim.new(0, Theme.SpacingMD)
        mainLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        mainLayout.Parent = main

        local mainPad = Instance.new("UIPadding")
        mainPad.PaddingTop = UDim.new(0, Theme.SpacingXL)
        mainPad.PaddingBottom = UDim.new(0, Theme.SpacingXL)
        mainPad.PaddingLeft = UDim.new(0, Theme.SpacingLG)
        mainPad.PaddingRight = UDim.new(0, Theme.SpacingLG)
        mainPad.Parent = main

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, 0, 0, 0)
        title.AutomaticSize = Enum.AutomaticSize.Y
        title.BackgroundTransparency = 1
        title.Text = titleText
        title.TextColor3 = Theme.TextPrimary
        title.Font = Theme.FontBold
        title.TextSize = 18
        title.TextWrapped = true
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.LayoutOrder = 1
        title.Parent = main

        local subtitle = Instance.new("TextLabel")
        subtitle.Size = UDim2.new(1, 0, 0, 0)
        subtitle.AutomaticSize = Enum.AutomaticSize.Y
        subtitle.BackgroundTransparency = 1
        subtitle.Text = subtitleText
        subtitle.TextColor3 = Theme.TextSecondary
        subtitle.Font = Theme.FontMedium
        subtitle.TextSize = 13
        subtitle.TextWrapped = true
        subtitle.TextXAlignment = Enum.TextXAlignment.Left
        subtitle.TextYAlignment = Enum.TextYAlignment.Top
        subtitle.LayoutOrder = 2
        subtitle.Parent = main

        local inputContainer = Instance.new("Frame")
        inputContainer.Size = UDim2.new(1, 0, 0, 42)
        inputContainer.BackgroundColor3 = Theme.Surface
        inputContainer.BorderSizePixel = 0
        inputContainer.LayoutOrder = 3
        inputContainer.Parent = main

        local inputCorner = Instance.new("UICorner")
        inputCorner.CornerRadius = Theme.CornerRadius
        inputCorner.Parent = inputContainer

        local inputStroke = Instance.new("UIStroke")
        inputStroke.Color = Theme.Focus
        inputStroke.Thickness = 1
        inputStroke.Transparency = 0.75
        inputStroke.Parent = inputContainer

        local textBox = Instance.new("TextBox")
        textBox.Size = UDim2.new(1, -Theme.SpacingLG * 2, 1, 0)
        textBox.Position = UDim2.new(0, Theme.SpacingLG, 0, 0)
        textBox.BackgroundTransparency = 1
        textBox.Text = ""
        textBox.PlaceholderText = placeholder
        textBox.PlaceholderColor3 = Theme.TextMuted
        textBox.TextColor3 = Theme.TextPrimary
        textBox.Font = Theme.FontMedium
        textBox.TextSize = 14
        textBox.TextXAlignment = Enum.TextXAlignment.Left
        textBox.ClearTextOnFocus = false
        textBox.Selectable = true
        textBox.Parent = inputContainer

        local submitBtn = Instance.new("TextButton")
        submitBtn.Size = UDim2.new(1, 0, 0, 42)
        submitBtn.BackgroundColor3 = Theme.Accent
        submitBtn.BorderSizePixel = 0
        submitBtn.Text = submitText
        submitBtn.TextColor3 = Theme.Background
        submitBtn.Font = Theme.FontBold
        submitBtn.TextSize = 14
        submitBtn.AutoButtonColor = false
        submitBtn.Selectable = true
        submitBtn.LayoutOrder = 4
        submitBtn.Parent = main

        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = Theme.CornerRadius
        buttonCorner.Parent = submitBtn

        submitBtn.MouseEnter:Connect(function()
            ts:Create(submitBtn, TweenInfo.new(0.2), { BackgroundColor3 = Theme.AccentHover }):Play()
        end)
        submitBtn.MouseLeave:Connect(function()
            ts:Create(submitBtn, TweenInfo.new(0.2), { BackgroundColor3 = Theme.Accent }):Play()
        end)

        local selectionObjects = { textBox, submitBtn }

        if #links > 0 then
            local linkContainer = Instance.new("Frame")
            linkContainer.Size = UDim2.new(1, 0, 0, 0)
            linkContainer.AutomaticSize = Enum.AutomaticSize.Y
            linkContainer.BackgroundTransparency = 1
            linkContainer.LayoutOrder = 5
            linkContainer.Parent = main

            local linkLayout = Instance.new("UIGridLayout")
            linkLayout.CellSize = #links == 1 and UDim2.new(1, 0, 0, 34) or UDim2.new(0.5, -Theme.SpacingXS, 0, 34)
            linkLayout.CellPadding = UDim2.new(0, Theme.SpacingSM, 0, Theme.SpacingSM)
            linkLayout.SortOrder = Enum.SortOrder.LayoutOrder
            linkLayout.Parent = linkContainer

            for i, linkData in ipairs(links) do
                if type(linkData) == "table" then
                    local linkBtn = Instance.new("TextButton")
                    linkBtn.Size = UDim2.new(1, 0, 1, 0)
                    linkBtn.BackgroundColor3 = Theme.Surface
                    linkBtn.BorderSizePixel = 0
                    linkBtn.Text = ""
                    linkBtn.AutoButtonColor = false
                    linkBtn.Selectable = true
                    linkBtn.LayoutOrder = i
                    linkBtn.Parent = linkContainer
                    table.insert(selectionObjects, linkBtn)

                    local linkCorner = Instance.new("UICorner")
                    linkCorner.CornerRadius = Theme.CornerRadius
                    linkCorner.Parent = linkBtn

                    local linkStroke = Instance.new("UIStroke")
                    linkStroke.Color = Theme.Stroke
                    linkStroke.Transparency = Theme.PanelStrokeTransparency
                    linkStroke.Parent = linkBtn

                    local icon
                    local textXOffset = Theme.SpacingSM
                    if linkData.Icon then
                        icon = Instance.new("ImageLabel")
                        icon.Size = UDim2.new(0, 14, 0, 14)
                        icon.Position = UDim2.new(0, Theme.SpacingMD, 0.5, -7)
                        icon.BackgroundTransparency = 1
                        icon.Image = linkData.Icon
                        icon.ImageColor3 = Theme.TextSecondary
                        icon.Parent = linkBtn
                        textXOffset = 32
                    end

                    local linkLabel = Instance.new("TextLabel")
                    linkLabel.Size = UDim2.new(1, -textXOffset - Theme.SpacingSM, 1, 0)
                    linkLabel.Position = UDim2.new(0, textXOffset, 0, 0)
                    linkLabel.BackgroundTransparency = 1
                    linkLabel.Text = tostring(linkData.Name or "Link")
                    linkLabel.TextColor3 = Theme.TextSecondary
                    linkLabel.Font = Theme.FontMedium
                    linkLabel.TextSize = 11
                    linkLabel.TextTruncate = Enum.TextTruncate.AtEnd
                    linkLabel.Parent = linkBtn

                    linkBtn.MouseEnter:Connect(function()
                        ts:Create(linkBtn, TweenInfo.new(0.2), { BackgroundColor3 = Theme.SurfaceHover }):Play()
                        ts:Create(linkLabel, TweenInfo.new(0.2), { TextColor3 = Theme.TextPrimary }):Play()
                        if icon then ts:Create(icon, TweenInfo.new(0.2), { ImageColor3 = Theme.TextPrimary }):Play() end
                    end)
                    linkBtn.MouseLeave:Connect(function()
                        ts:Create(linkBtn, TweenInfo.new(0.2), { BackgroundColor3 = Theme.Surface }):Play()
                        ts:Create(linkLabel, TweenInfo.new(0.2), { TextColor3 = Theme.TextSecondary }):Play()
                        if icon then ts:Create(icon, TweenInfo.new(0.2), { ImageColor3 = Theme.TextSecondary }):Play() end
                    end)
                    linkBtn.Activated:Connect(function()
                        if type(linkData.OnClick) == "function" then
                            local ok, err = pcall(linkData.OnClick, linkLabel)
                            if not ok then warn("Auth link failed: " .. tostring(err)) end
                        end
                    end)
                end
            end
        end

        for i, object in ipairs(selectionObjects) do
            local previous = selectionObjects[i - 1] or selectionObjects[#selectionObjects]
            local nextObject = selectionObjects[i + 1] or selectionObjects[1]
            object.NextSelectionUp = previous
            object.NextSelectionLeft = previous
            object.NextSelectionDown = nextObject
            object.NextSelectionRight = nextObject
        end

        local isLoading = false
        local closing = false

        local function closeAuth()
            if closing then return end
            closing = true
            local selected = guiService.SelectedObject
            if selected and selected:IsDescendantOf(gui) then
                guiService.SelectedObject = previousSelection and previousSelection.Parent and previousSelection or nil
            end
            ts:Create(overlay, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
            local tween = ts:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.92 })
            tween:Play()
            tween.Completed:Connect(function()
                if gui.Parent then gui:Destroy() end
            end)
        end

        local function resetSubmit(failed)
            if closing then return end
            isLoading = false
            submitBtn.Text = submitText
            submitBtn.BackgroundColor3 = Theme.Accent
            submitBtn.TextColor3 = Theme.Background
            textBox.TextEditable = true
            if failed then
                inputStroke.Color = Theme.Error
                inputStroke.Transparency = 0
                task.delay(0.6, function()
                    if inputStroke.Parent and not textBox:IsFocused() then
                        Utils.tween(inputStroke, TweenInfo.new(0.2), { Color = Theme.Focus, Transparency = 0.75 })
                    end
                end)
            end
        end

        local function doSubmit()
            if isLoading or closing then return end
            isLoading = true
            submitBtn.Text = "Verifying..."
            submitBtn.BackgroundColor3 = Theme.Surface
            submitBtn.TextColor3 = Theme.TextSecondary
            textBox.TextEditable = false

            if type(onSubmit) ~= "function" then
                closeAuth()
                return
            end

            local settled = false
            local function finish(success)
                if settled or closing then return end
                settled = true
                task.defer(function()
                    if closing then return end
                    if success then
                        submitBtn.Text = "Success"
                        submitBtn.BackgroundColor3 = Theme.Success
                        submitBtn.TextColor3 = Theme.Background
                        task.delay(0.5, closeAuth)
                    else
                        resetSubmit(true)
                    end
                end)
            end

            task.spawn(function()
                local ok, result = pcall(onSubmit, textBox.Text, finish)
                if not ok then
                    warn("Auth submit failed: " .. tostring(result))
                    finish(false)
                elseif type(result) == "boolean" then
                    finish(result)
                end
            end)
        end

        submitBtn.Activated:Connect(doSubmit)

        textBox.Focused:Connect(function()
            ts:Create(inputStroke, TweenInfo.new(0.2), { Color = Theme.Focus, Transparency = 0 }):Play()
        end)
        textBox.FocusLost:Connect(function(enterPressed)
            ts:Create(inputStroke, TweenInfo.new(0.2), { Color = Theme.Focus, Transparency = 0.75 }):Play()
            if enterPressed then doSubmit() end
        end)

        ts:Create(overlay, TweenInfo.new(0.35), { BackgroundTransparency = 0.28 }):Play()
        ts:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 }):Play()

        Drag.makeDraggable(main)
        if uis.GamepadEnabled then
            task.defer(function()
                if gui.Parent then guiService.SelectedObject = submitBtn end
            end)
        end

        return { Close = closeAuth }
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

local function register(tab, control)
    if tab and tab.window and control then
        table.insert(tab.window.controls, control)
    end
    return control
end

function Lib.CreateWindow(options)
    return Lib.Window.new(options)
end

function Lib.CreateTab(window, name, order)
    return Lib.Components.Tab.new(window, name, order)
end

function Lib.CreateButton(tab, name, cb)
    return register(tab, Lib.Components.Button.new(tab, name, cb))
end

function Lib.CreateToggle(tab, name, defaultState, cb)
    return register(tab, Lib.Components.Toggle.new(tab, name, defaultState, cb))
end

function Lib.CreateSlider(tab, name, minVal, maxVal, defaultVal, formatFunc, cb)
    return register(tab, Lib.Components.Slider.new(tab, name, minVal, maxVal, defaultVal, formatFunc, cb))
end

function Lib.CreateDropdown(tab, name, opts, defaultIdx, cb)
    return register(tab, Lib.Components.Dropdown.new(tab, name, opts, defaultIdx, cb))
end

function Lib.CreateTextbox(tab, name, placeholderText, cb)
    return register(tab, Lib.Components.Textbox.new(tab, name, placeholderText, cb))
end

function Lib.CreateLabel(tab, name)
    return register(tab, Lib.Components.Label.new(tab, name))
end

function Lib.CreateSection(tab, name)
    return register(tab, Lib.Components.Label.section(tab, name))
end

function Lib.CreateSeparator(tab)
    return register(tab, Lib.Components.Label.separator(tab))
end

function Lib.CreateKeybind(tab, name, defaultKey, cb)
    return register(tab, Lib.Components.Keybind.new(tab, name, defaultKey, cb))
end

function Lib.Notify(config)
    return Lib.Notification.show(config)
end

function Lib.CreateAuth(config)
    return Lib.Auth.show(config)
end

return Lib