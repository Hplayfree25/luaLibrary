-- Universal UI Library (Bundled)
local _modules = {}

-- Module: Theme
_modules["Theme"] = (function()
    local Theme = {
        -- Fonts
        FontBold = Enum.Font.GothamBold,
        FontMedium = Enum.Font.GothamMedium,

        -- Monochrome glass palette. Existing keys remain public for custom themes.
        Background = Color3.fromRGB(8, 9, 11),
        PanelBackground = Color3.fromRGB(22, 23, 27),
        Accent = Color3.fromRGB(238, 239, 242),
        AccentHover = Color3.fromRGB(255, 255, 255),
        SecondaryBackground = Color3.fromRGB(31, 32, 37),
        TabInactive = Color3.fromRGB(18, 19, 22),
        TabActive = Color3.fromRGB(37, 38, 43),
        TextPrimary = Color3.fromRGB(246, 246, 248),
        TextSecondary = Color3.fromRGB(194, 195, 200),
        TextMuted = Color3.fromRGB(126, 128, 136),
        Stroke = Color3.fromRGB(235, 236, 240),

        -- Semantic aliases
        Surface = Color3.fromRGB(22, 23, 27),
        SurfaceElevated = Color3.fromRGB(28, 29, 34),
        SurfaceHover = Color3.fromRGB(38, 39, 45),
        SurfaceActive = Color3.fromRGB(43, 44, 50),
        Focus = Color3.fromRGB(250, 250, 252),
        Success = Color3.fromRGB(205, 207, 211),
        Error = Color3.fromRGB(225, 226, 230),

        -- Transparencies
        BackgroundTransparency = 0.08,
        PanelTransparency = 0.22,
        StrokeTransparency = 0.88,
        PanelStrokeTransparency = 0.91,
        HoverStrokeTransparency = 0.5,
        FocusStrokeTransparency = 0.28,
        ActiveStrokeTransparency = 0.62,
        BorderTransparency = 0.9,
        GlassTransparency = 0.18,
        ContentTransparency = 0.42,
        TabTransparency = 0.38,
        HoverTransparency = 0.22,
        ActiveTransparency = 0.12,
        ScrollBarTransparency = 0.55,

        -- Spacing
        SpacingXS = 4,
        SpacingSM = 8,
        SpacingMD = 12,
        SpacingLG = 16,
        SpacingXL = 24,

        -- Radii
        CornerRadius = UDim.new(0, 12),
        WindowCornerRadius = UDim.new(0, 18),
        CardCornerRadius = UDim.new(0, 14),
        FieldCornerRadius = UDim.new(0, 12),
        PillCornerRadius = UDim.new(1, 0)
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

    function Drag.clampToViewport(targetGui, margin)
        local camera = workspace.CurrentCamera
        if not camera or targetGui.AbsoluteSize.X <= 0 then return end
        local viewport = camera.ViewportSize
        local size = targetGui.AbsoluteSize
        local anchor = targetGui.AnchorPoint
        local current = Vector2.new(
            targetGui.Position.X.Scale * viewport.X + targetGui.Position.X.Offset,
            targetGui.Position.Y.Scale * viewport.Y + targetGui.Position.Y.Offset
        )
        margin = margin or 8
        local minimum = Vector2.new(margin + size.X * anchor.X, margin + size.Y * anchor.Y)
        local maximum = Vector2.new(
            math.max(minimum.X, viewport.X - margin - size.X * (1 - anchor.X)),
            math.max(minimum.Y, viewport.Y - margin - size.Y * (1 - anchor.Y))
        )
        targetGui.Position = UDim2.fromOffset(
            math.clamp(current.X, minimum.X, maximum.X),
            math.clamp(current.Y, minimum.Y, maximum.Y)
        )
    end

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
        local radius = Theme.FieldCornerRadius or Theme.CornerRadius

        local button = Instance.new("TextButton")
        button.Name = tostring(name)
        button.Size = UDim2.new(1, -16, 0, 36)
        button.BackgroundColor3 = Theme.TabInactive
        button.BackgroundTransparency = Theme.TabTransparency or 0.38
        button.BorderSizePixel = 0
        button.Text = tostring(name)
        button.TextColor3 = Theme.TextMuted
        button.Font = Theme.FontBold
        button.TextSize = 11
        button.LayoutOrder = order or 1
        button.AutoButtonColor = false
        button.Selectable = true
        button.Parent = window.tabContainer

        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = radius
        buttonCorner.Parent = button

        local buttonStroke = Instance.new("UIStroke")
        buttonStroke.Color = Theme.Stroke
        buttonStroke.Transparency = Theme.BorderTransparency or 0.9
        buttonStroke.Parent = button

        local container = Instance.new("ScrollingFrame")
        container.Name = tostring(name) .. "Content"
        container.Size = UDim2.new(1, -12, 1, -12)
        container.Position = UDim2.fromOffset(6, 6)
        container.BackgroundTransparency = 1
        container.BorderSizePixel = 0
        container.ScrollBarThickness = 2
        container.ScrollBarImageColor3 = Theme.TextMuted
        container.ScrollBarImageTransparency = Theme.ScrollBarTransparency or 0.55
        container.AutomaticCanvasSize = Enum.AutomaticSize.Y
        container.CanvasSize = UDim2.new()
        container.ScrollingDirection = Enum.ScrollingDirection.Y
        container.Visible = false
        container.Parent = window.rightPanel

        local layout = Instance.new("UIListLayout")
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 7)
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        layout.Parent = container

        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0, 2)
        padding.PaddingBottom = UDim.new(0, 8)
        padding.PaddingLeft = UDim.new(0, 2)
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
                local measured = math.max(button.TextBounds.X, #tostring(name) * 7)
                button.Size = UDim2.fromOffset(math.clamp(measured + 28, 76, 144), 36)
                container.Size = UDim2.new(1, -10, 1, -10)
                container.Position = UDim2.fromOffset(5, 5)
            else
                button.Size = UDim2.new(1, -16, 0, 36)
                container.Size = UDim2.new(1, -12, 1, -12)
                container.Position = UDim2.fromOffset(6, 6)
            end
        end

        local function render(active, focused)
            local selected = window.activeTab == self
            Utils.tween(button, TweenInfo.new(0.14), {
                BackgroundColor3 = selected and (Theme.SurfaceActive or Theme.TabActive) or (active and Theme.SurfaceHover or Theme.TabInactive),
                BackgroundTransparency = selected and (Theme.ActiveTransparency or 0.12) or (active and (Theme.HoverTransparency or 0.22) or (Theme.TabTransparency or 0.38)),
                TextColor3 = selected and Theme.TextPrimary or (active and Theme.TextSecondary or Theme.TextMuted)
            })
            Utils.tween(buttonStroke, TweenInfo.new(0.14), {
                Color = focused and Theme.Focus or Theme.Stroke,
                Transparency = focused and (Theme.FocusStrokeTransparency or 0.35) or (selected and (Theme.ActiveStrokeTransparency or 0.62) or (Theme.BorderTransparency or 0.9))
            })
        end

        button.MouseEnter:Connect(function() render(true, false) end)
        button.MouseLeave:Connect(function() render(false, false) end)
        button.SelectionGained:Connect(function() render(true, true) end)
        button.SelectionLost:Connect(function() render(false, false) end)
        button.Activated:Connect(function() Tab.switch(window, name) end)

        table.insert(window.tabs, self)
        self.updateLayout(window.compact)
        if #window.tabs == 1 then Tab.switch(window, name) end
        return self
    end

    function Tab.switch(window, tabName)
        for _, tab in ipairs(window.tabs or {}) do
            local selected = tab.name == tabName
            tab.container.Visible = selected
            Utils.tween(tab.button, TweenInfo.new(0.16), {
                BackgroundColor3 = selected and (window.theme.SurfaceActive or window.theme.TabActive) or window.theme.TabInactive,
                BackgroundTransparency = selected and (window.theme.ActiveTransparency or 0.12) or (window.theme.TabTransparency or 0.38),
                TextColor3 = selected and window.theme.TextPrimary or window.theme.TextMuted
            })
            local outline = tab.button:FindFirstChildOfClass("UIStroke")
            if outline then
                Utils.tween(outline, TweenInfo.new(0.16), {
                    Color = window.theme.Stroke,
                    Transparency = selected and (window.theme.ActiveStrokeTransparency or 0.62) or (window.theme.BorderTransparency or 0.9)
                })
            end
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
        local connections, disabled, hovered, selected = {}, false, false, false
        local function connect(signal, fn)
            local connection = signal:Connect(fn)
            table.insert(connections, connection)
            return connection
        end

        local frm = Instance.new("Frame")
        frm.Size = UDim2.new(1, 0, 0, 44)
        frm.AutomaticSize = Enum.AutomaticSize.Y
        frm.BackgroundColor3 = Theme.Surface or Theme.PanelBackground
        frm.BackgroundTransparency = Theme.PanelTransparency
        frm.BorderSizePixel = 0
        frm.Parent = container

        local corner = Instance.new("UICorner")
        corner.CornerRadius = Theme.CardCornerRadius or UDim.new(0, 14)
        corner.Parent = frm
        local stroke = Instance.new("UIStroke")
        stroke.Color = Theme.Stroke
        stroke.Transparency = Theme.PanelStrokeTransparency
        stroke.Parent = frm

        local content = Instance.new("Frame")
        content.Size = UDim2.new(1, 0, 0, 44)
        content.AutomaticSize = Enum.AutomaticSize.Y
        content.BackgroundTransparency = 1
        content.BorderSizePixel = 0
        content.Parent = frm
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 3)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = content
        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0, desc and 11 or 14)
        padding.PaddingBottom = UDim.new(0, desc and 11 or 14)
        padding.PaddingLeft = UDim.new(0, 14)
        padding.PaddingRight = UDim.new(0, 14)
        padding.Parent = content

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 0)
        lbl.AutomaticSize = Enum.AutomaticSize.Y
        lbl.BackgroundTransparency = 1
        lbl.BorderSizePixel = 0
        lbl.Text = tostring(text or "Button")
        lbl.TextColor3 = Theme.TextSecondary
        lbl.Font = Theme.FontMedium
        lbl.TextSize = 13
        lbl.TextWrapped = true
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextYAlignment = Enum.TextYAlignment.Top
        lbl.LayoutOrder = 1
        lbl.Parent = content

        if desc then
            local description = Instance.new("TextLabel")
            description.Size = UDim2.new(1, 0, 0, 0)
            description.AutomaticSize = Enum.AutomaticSize.Y
            description.BackgroundTransparency = 1
            description.BorderSizePixel = 0
            description.Text = tostring(desc)
            description.TextColor3 = Theme.TextMuted
            description.Font = Theme.FontMedium
            description.TextSize = 11
            description.TextWrapped = true
            description.TextXAlignment = Enum.TextXAlignment.Left
            description.TextYAlignment = Enum.TextYAlignment.Top
            description.LayoutOrder = 2
            description.Parent = content
        end

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.fromScale(1, 1)
        btn.BackgroundTransparency = 1
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.Selectable = true
        btn.Parent = frm

        local function refresh()
            local on = not disabled and (hovered or selected)
            Utils.tween(frm, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {
                BackgroundColor3 = on and (Theme.SurfaceHover or Theme.SecondaryBackground) or (Theme.Surface or Theme.PanelBackground),
            })
            Utils.tween(lbl, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {
                TextColor3 = disabled and Theme.TextMuted or (on and Theme.TextPrimary or Theme.TextSecondary),
            })
            Utils.tween(stroke, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {
                Transparency = on and (Theme.HoverStrokeTransparency or 0.5) or Theme.PanelStrokeTransparency,
            })
        end

        connect(btn.MouseEnter, function() hovered = true refresh() end)
        connect(btn.MouseLeave, function() hovered = false refresh() end)
        connect(btn.SelectionGained, function() selected = true refresh() end)
        connect(btn.SelectionLost, function() selected = false refresh() end)
        connect(btn.Activated, function()
            if disabled then return end
            Utils.tween(frm, TweenInfo.new(0.08, Enum.EasingStyle.Sine), {
                BackgroundColor3 = Theme.SurfaceActive or Theme.SecondaryBackground,
            })
            task.delay(0.09, function()
                if frm.Parent and not disabled then refresh() end
            end)
            if callback then callback() end
        end)

        local self = { frame = frm, button = btn }
        function self.setDisabled(value)
            disabled = not not value
            btn.Active = not disabled
            btn.Selectable = not disabled
            refresh()
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
        local connections, disabled, hovered, selected = {}, false, false, false
        local function connect(signal, fn)
            local connection = signal:Connect(fn)
            table.insert(connections, connection)
            return connection
        end

        local frm = Instance.new("Frame")
        frm.Size = UDim2.new(1, 0, 0, 44)
        frm.AutomaticSize = Enum.AutomaticSize.Y
        frm.BackgroundColor3 = Theme.Surface or Theme.PanelBackground
        frm.BackgroundTransparency = Theme.PanelTransparency
        frm.BorderSizePixel = 0
        frm.Parent = container
        local corner = Instance.new("UICorner")
        corner.CornerRadius = Theme.CardCornerRadius or UDim.new(0, 14)
        corner.Parent = frm
        local stroke = Instance.new("UIStroke")
        stroke.Color = Theme.Stroke
        stroke.Transparency = Theme.PanelStrokeTransparency
        stroke.Parent = frm

        local content = Instance.new("Frame")
        content.Size = UDim2.new(1, -58, 0, 44)
        content.AutomaticSize = Enum.AutomaticSize.Y
        content.BackgroundTransparency = 1
        content.BorderSizePixel = 0
        content.Parent = frm
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 3)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = content
        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0, desc and 11 or 14)
        padding.PaddingBottom = UDim.new(0, desc and 11 or 14)
        padding.PaddingLeft = UDim.new(0, 14)
        padding.PaddingRight = UDim.new(0, 0)
        padding.Parent = content

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 0)
        lbl.AutomaticSize = Enum.AutomaticSize.Y
        lbl.BackgroundTransparency = 1
        lbl.BorderSizePixel = 0
        lbl.Text = tostring(text or "Toggle")
        lbl.TextColor3 = Theme.TextSecondary
        lbl.Font = Theme.FontMedium
        lbl.TextSize = 13
        lbl.TextWrapped = true
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextYAlignment = Enum.TextYAlignment.Top
        lbl.LayoutOrder = 1
        lbl.Parent = content

        if desc then
            local description = Instance.new("TextLabel")
            description.Size = UDim2.new(1, 0, 0, 0)
            description.AutomaticSize = Enum.AutomaticSize.Y
            description.BackgroundTransparency = 1
            description.BorderSizePixel = 0
            description.Text = tostring(desc)
            description.TextColor3 = Theme.TextMuted
            description.Font = Theme.FontMedium
            description.TextSize = 11
            description.TextWrapped = true
            description.TextXAlignment = Enum.TextXAlignment.Left
            description.TextYAlignment = Enum.TextYAlignment.Top
            description.LayoutOrder = 2
            description.Parent = content
        end

        local track = Instance.new("Frame")
        track.Size = UDim2.fromOffset(38, 22)
        track.AnchorPoint = Vector2.new(1, 0.5)
        track.Position = UDim2.new(1, -14, 0.5, 0)
        track.BackgroundColor3 = stateVal and Theme.Accent or Theme.SecondaryBackground
        track.BorderSizePixel = 0
        track.Parent = frm
        local trackCorner = Instance.new("UICorner")
        trackCorner.CornerRadius = Theme.PillCornerRadius or UDim.new(1, 0)
        trackCorner.Parent = track
        local trackStroke = Instance.new("UIStroke")
        trackStroke.Color = Theme.Stroke
        trackStroke.Transparency = stateVal and (Theme.HoverStrokeTransparency or 0.5) or Theme.PanelStrokeTransparency
        trackStroke.Parent = track
        local knob = Instance.new("Frame")
        knob.Size = UDim2.fromOffset(16, 16)
        knob.Position = stateVal and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        knob.BackgroundColor3 = stateVal and Theme.Background or Theme.TextSecondary
        knob.BorderSizePixel = 0
        knob.Parent = track
        local knobCorner = Instance.new("UICorner")
        knobCorner.CornerRadius = Theme.PillCornerRadius or UDim.new(1, 0)
        knobCorner.Parent = knob

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.fromScale(1, 1)
        btn.BackgroundTransparency = 1
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.Selectable = true
        btn.Parent = frm

        local function updateVisuals(immediate)
            local info = TweenInfo.new(immediate and 0 or 0.16, Enum.EasingStyle.Sine)
            Utils.tween(track, info, { BackgroundColor3 = stateVal and Theme.Accent or Theme.SecondaryBackground })
            Utils.tween(knob, info, {
                Position = stateVal and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
                BackgroundColor3 = stateVal and Theme.Background or Theme.TextSecondary,
            })
            trackStroke.Transparency = stateVal and (Theme.HoverStrokeTransparency or 0.5) or Theme.PanelStrokeTransparency
        end
        local function refresh()
            local on = not disabled and (hovered or selected)
            frm.BackgroundColor3 = on and (Theme.SurfaceHover or Theme.SecondaryBackground) or (Theme.Surface or Theme.PanelBackground)
            lbl.TextColor3 = disabled and Theme.TextMuted or (on and Theme.TextPrimary or Theme.TextSecondary)
            stroke.Transparency = on and (Theme.HoverStrokeTransparency or 0.5) or Theme.PanelStrokeTransparency
        end
        local function set(value, fire)
            stateVal = not not value
            updateVisuals(false)
            if fire and cb then cb(stateVal) end
        end

        connect(btn.MouseEnter, function() hovered = true refresh() end)
        connect(btn.MouseLeave, function() hovered = false refresh() end)
        connect(btn.SelectionGained, function() selected = true refresh() end)
        connect(btn.SelectionLost, function() selected = false refresh() end)
        connect(btn.Activated, function()
            if not disabled then set(not stateVal, true) end
        end)
        updateVisuals(true)

        local self = { frame = frm, button = btn }
        self.set = function(value) set(value, true) end
        self.get = function() return stateVal end
        function self.setDisabled(value)
            disabled = not not value
            btn.Active = not disabled
            btn.Selectable = not disabled
            track.BackgroundTransparency = disabled and 0.45 or 0
            knob.BackgroundTransparency = disabled and 0.25 or 0
            refresh()
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
        local hovered, selected, currentVal = false, false, defaultVal
        local function connect(signal, fn)
            local connection = signal:Connect(fn)
            table.insert(connections, connection)
            return connection
        end

        local frm = Instance.new("Frame")
        frm.Size = UDim2.new(1, 0, 0, 58)
        frm.AutomaticSize = Enum.AutomaticSize.Y
        frm.BackgroundColor3 = Theme.Surface or Theme.PanelBackground
        frm.BackgroundTransparency = Theme.PanelTransparency
        frm.BorderSizePixel = 0
        frm.Parent = container
        local corner = Instance.new("UICorner")
        corner.CornerRadius = Theme.CardCornerRadius or UDim.new(0, 14)
        corner.Parent = frm
        local stroke = Instance.new("UIStroke")
        stroke.Color = Theme.Stroke
        stroke.Transparency = Theme.PanelStrokeTransparency
        stroke.Parent = frm

        local content = Instance.new("Frame")
        content.Size = UDim2.new(1, 0, 0, 58)
        content.AutomaticSize = Enum.AutomaticSize.Y
        content.BackgroundTransparency = 1
        content.BorderSizePixel = 0
        content.Parent = frm
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 3)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = content
        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0, 10)
        padding.PaddingBottom = UDim.new(0, 9)
        padding.PaddingLeft = UDim.new(0, 14)
        padding.PaddingRight = UDim.new(0, 14)
        padding.Parent = content

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 0)
        lbl.AutomaticSize = Enum.AutomaticSize.Y
        lbl.BackgroundTransparency = 1
        lbl.BorderSizePixel = 0
        lbl.TextColor3 = Theme.TextSecondary
        lbl.Font = Theme.FontMedium
        lbl.TextSize = 13
        lbl.TextWrapped = true
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextYAlignment = Enum.TextYAlignment.Top
        lbl.LayoutOrder = 1
        lbl.Parent = content

        if desc then
            local description = Instance.new("TextLabel")
            description.Size = UDim2.new(1, 0, 0, 0)
            description.AutomaticSize = Enum.AutomaticSize.Y
            description.BackgroundTransparency = 1
            description.BorderSizePixel = 0
            description.Text = tostring(desc)
            description.TextColor3 = Theme.TextMuted
            description.Font = Theme.FontMedium
            description.TextSize = 11
            description.TextWrapped = true
            description.TextXAlignment = Enum.TextXAlignment.Left
            description.TextYAlignment = Enum.TextYAlignment.Top
            description.LayoutOrder = 2
            description.Parent = content
        end

        local rail = Instance.new("Frame")
        rail.Size = UDim2.new(1, 0, 0, 20)
        rail.BackgroundTransparency = 1
        rail.BorderSizePixel = 0
        rail.LayoutOrder = 3
        rail.Parent = content
        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, -8, 0, 6)
        bar.AnchorPoint = Vector2.new(0.5, 0.5)
        bar.Position = UDim2.fromScale(0.5, 0.5)
        bar.BackgroundColor3 = Theme.SecondaryBackground
        bar.BorderSizePixel = 0
        bar.Parent = rail
        local barCorner = Instance.new("UICorner")
        barCorner.CornerRadius = Theme.PillCornerRadius or UDim.new(1, 0)
        barCorner.Parent = bar
        local fill = Instance.new("Frame")
        fill.BackgroundColor3 = Theme.Accent
        fill.BorderSizePixel = 0
        fill.Parent = bar
        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = Theme.PillCornerRadius or UDim.new(1, 0)
        fillCorner.Parent = fill
        local thumb = Instance.new("Frame")
        thumb.Size = UDim2.fromOffset(14, 14)
        thumb.AnchorPoint = Vector2.new(0.5, 0.5)
        thumb.BackgroundColor3 = Theme.Accent
        thumb.BorderSizePixel = 0
        thumb.Parent = bar
        local thumbCorner = Instance.new("UICorner")
        thumbCorner.CornerRadius = Theme.PillCornerRadius or UDim.new(1, 0)
        thumbCorner.Parent = thumb
        local thumbStroke = Instance.new("UIStroke")
        thumbStroke.Color = Theme.Background
        thumbStroke.Transparency = 0.35
        thumbStroke.Parent = thumb

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.fromScale(1, 1)
        btn.BackgroundTransparency = 1
        btn.BorderSizePixel = 0
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
            local ratio = (currentVal - minVal) / (maxVal - minVal)
            fill.Size = UDim2.new(ratio, 0, 1, 0)
            thumb.Position = UDim2.new(ratio, 0, 0.5, 0)
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
        local function refresh()
            local on = not disabled and (hovered or selected or sliding)
            frm.BackgroundColor3 = on and (Theme.SurfaceHover or Theme.SecondaryBackground) or (Theme.Surface or Theme.PanelBackground)
            lbl.TextColor3 = disabled and Theme.TextMuted or (on and Theme.TextPrimary or Theme.TextSecondary)
            fill.BackgroundColor3 = on and (Theme.AccentHover or Theme.Accent) or Theme.Accent
            thumb.BackgroundColor3 = on and (Theme.AccentHover or Theme.Accent) or Theme.Accent
            stroke.Transparency = on and (Theme.HoverStrokeTransparency or 0.5) or Theme.PanelStrokeTransparency
        end

        connect(btn.MouseEnter, function() hovered = true refresh() end)
        connect(btn.MouseLeave, function() hovered = false refresh() end)
        connect(btn.SelectionGained, function() selected = true refresh() end)
        connect(btn.SelectionLost, function() selected = false refresh() end)
        connect(btn.InputBegan, function(input)
            if disabled then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                sliding, dragInput = true, input
                updateAt(input.Position.X)
                refresh()
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
                refresh()
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
            fill.BackgroundTransparency = disabled and 0.45 or 0
            thumb.BackgroundTransparency = disabled and 0.35 or 0
            refresh()
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

    local function option(raw)
        if type(raw) == "table" then
            local label = raw.name or raw.Name or raw.label or raw.Label or raw[1]
            local value = raw.val
            if value == nil then value = raw.Value end
            if value == nil then value = raw.value end
            if value == nil then value = raw[2] end
            if value == nil then value = label end
            return tostring(label or value or "Option"), value
        end
        return tostring(raw), raw
    end

    function Dropdown.new(parent, name, opts, defaultIdx, cb)
        local container, Theme = context(parent)
        local desc = type(name) == "table" and (name.Desc or name[2]) or nil
        name = type(name) == "table" and (name.Name or name[1]) or name
        local options = type(opts) == "table" and opts or {}
        local cur = math.clamp(tonumber(defaultIdx) or 1, 1, math.max(#options, 1))
        local connections, optionConnections, items = {}, {}, {}
        local disabled, expanded, triggerHover, triggerFocus = false, false, false, false
        local function connect(signal, fn, list)
            local connection = signal:Connect(fn)
            table.insert(list or connections, connection)
            return connection
        end
        local function clearOptionConnections()
            for _, connection in ipairs(optionConnections) do connection:Disconnect() end
            table.clear(optionConnections)
            table.clear(items)
        end

        local frm = Instance.new("Frame")
        frm.Size = UDim2.new(1, 0, 0, 0)
        frm.AutomaticSize = Enum.AutomaticSize.Y
        frm.BackgroundTransparency = 1
        frm.BorderSizePixel = 0
        frm.Parent = container
        local rootLayout = Instance.new("UIListLayout")
        rootLayout.Padding = UDim.new(0, 6)
        rootLayout.SortOrder = Enum.SortOrder.LayoutOrder
        rootLayout.Parent = frm

        local header = Instance.new("Frame")
        header.Size = UDim2.new(1, 0, 0, 48)
        header.AutomaticSize = Enum.AutomaticSize.Y
        header.BackgroundColor3 = Theme.Surface or Theme.PanelBackground
        header.BackgroundTransparency = Theme.PanelTransparency
        header.BorderSizePixel = 0
        header.LayoutOrder = 1
        header.Parent = frm
        local headerCorner = Instance.new("UICorner")
        headerCorner.CornerRadius = Theme.CardCornerRadius or UDim.new(0, 14)
        headerCorner.Parent = header
        local headerStroke = Instance.new("UIStroke")
        headerStroke.Color = Theme.Stroke
        headerStroke.Transparency = Theme.PanelStrokeTransparency
        headerStroke.Parent = header

        local content = Instance.new("Frame")
        content.Size = UDim2.new(1, -150, 0, 48)
        content.AutomaticSize = Enum.AutomaticSize.Y
        content.BackgroundTransparency = 1
        content.BorderSizePixel = 0
        content.Parent = header
        local contentLayout = Instance.new("UIListLayout")
        contentLayout.Padding = UDim.new(0, 3)
        contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        contentLayout.Parent = content
        local contentPadding = Instance.new("UIPadding")
        contentPadding.PaddingTop = UDim.new(0, desc and 10 or 15)
        contentPadding.PaddingBottom = UDim.new(0, desc and 10 or 15)
        contentPadding.PaddingLeft = UDim.new(0, 14)
        contentPadding.Parent = content

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 0)
        lbl.AutomaticSize = Enum.AutomaticSize.Y
        lbl.BackgroundTransparency = 1
        lbl.BorderSizePixel = 0
        lbl.Text = tostring(name or "Dropdown")
        lbl.TextColor3 = Theme.TextSecondary
        lbl.Font = Theme.FontMedium
        lbl.TextSize = 13
        lbl.TextWrapped = true
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextYAlignment = Enum.TextYAlignment.Top
        lbl.LayoutOrder = 1
        lbl.Parent = content

        if desc then
            local description = Instance.new("TextLabel")
            description.Size = UDim2.new(1, 0, 0, 0)
            description.AutomaticSize = Enum.AutomaticSize.Y
            description.BackgroundTransparency = 1
            description.BorderSizePixel = 0
            description.Text = tostring(desc)
            description.TextColor3 = Theme.TextMuted
            description.Font = Theme.FontMedium
            description.TextSize = 11
            description.TextWrapped = true
            description.TextXAlignment = Enum.TextXAlignment.Left
            description.TextYAlignment = Enum.TextYAlignment.Top
            description.LayoutOrder = 2
            description.Parent = content
        end

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.fromOffset(124, 34)
        btn.AnchorPoint = Vector2.new(1, 0.5)
        btn.Position = UDim2.new(1, -14, 0.5, 0)
        btn.BackgroundColor3 = Theme.SecondaryBackground
        btn.BorderSizePixel = 0
        btn.TextColor3 = Theme.TextSecondary
        btn.Font = Theme.FontMedium
        btn.TextSize = 11
        btn.TextTruncate = Enum.TextTruncate.AtEnd
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.AutoButtonColor = false
        btn.Selectable = true
        btn.Parent = header
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = Theme.FieldCornerRadius or Theme.CornerRadius
        btnCorner.Parent = btn
        local btnStroke = Instance.new("UIStroke")
        btnStroke.Color = Theme.Stroke
        btnStroke.Transparency = Theme.PanelStrokeTransparency
        btnStroke.Parent = btn
        local btnPadding = Instance.new("UIPadding")
        btnPadding.PaddingLeft = UDim.new(0, 11)
        btnPadding.PaddingRight = UDim.new(0, 30)
        btnPadding.Parent = btn

        local chevron = Instance.new("TextLabel")
        chevron.Size = UDim2.fromOffset(22, 22)
        chevron.AnchorPoint = Vector2.new(1, 0.5)
        chevron.Position = UDim2.new(1, -6, 0.5, 0)
        chevron.BackgroundTransparency = 1
        chevron.BorderSizePixel = 0
        chevron.Text = "⌄"
        chevron.TextColor3 = Theme.TextMuted
        chevron.Font = Theme.FontBold
        chevron.TextSize = 14
        chevron.Parent = btn

        local list = Instance.new("ScrollingFrame")
        list.Size = UDim2.new(1, 0, 0, 0)
        list.BackgroundColor3 = Theme.SurfaceElevated or Theme.SecondaryBackground
        list.BackgroundTransparency = Theme.PanelTransparency
        list.BorderSizePixel = 0
        list.CanvasSize = UDim2.new()
        list.AutomaticCanvasSize = Enum.AutomaticSize.Y
        list.ScrollBarThickness = 2
        list.ScrollBarImageColor3 = Theme.TextMuted
        list.Visible = false
        list.LayoutOrder = 2
        list.Parent = frm
        local listCorner = Instance.new("UICorner")
        listCorner.CornerRadius = Theme.CardCornerRadius or UDim.new(0, 14)
        listCorner.Parent = list
        local listStroke = Instance.new("UIStroke")
        listStroke.Color = Theme.Stroke
        listStroke.Transparency = Theme.PanelStrokeTransparency
        listStroke.Parent = list
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
            btn.Text = #options > 0 and (option(options[cur])) or "No options"
            chevron.Text = expanded and "⌃" or "⌄"
        end
        local function paint(index, hot)
            local item = items[index]
            if not item then return end
            local chosen = index == cur
            item.BackgroundColor3 = chosen and Theme.Accent
                or (hot and (Theme.SurfaceHover or Theme.SecondaryBackground) or (Theme.Surface or Theme.PanelBackground))
            item.BackgroundTransparency = chosen and 0 or (hot and 0 or Theme.PanelTransparency)
            item.TextColor3 = chosen and Theme.Background or (hot and Theme.TextPrimary or Theme.TextSecondary)
        end
        local function select(index, fire)
            if #options == 0 then return end
            local old = cur
            cur = math.clamp(index, 1, #options)
            paint(old, false)
            paint(cur, false)
            updateButton()
            if fire and cb then
                local _, value = option(options[cur])
                cb(value)
            end
        end
        local function refreshTrigger()
            local on = not disabled and (triggerHover or triggerFocus or expanded)
            header.BackgroundColor3 = on and (Theme.SurfaceHover or Theme.SecondaryBackground) or (Theme.Surface or Theme.PanelBackground)
            lbl.TextColor3 = disabled and Theme.TextMuted or (on and Theme.TextPrimary or Theme.TextSecondary)
            btn.TextColor3 = disabled and Theme.TextMuted or (on and Theme.TextPrimary or Theme.TextSecondary)
            chevron.TextColor3 = disabled and Theme.TextMuted or (on and Theme.TextPrimary or Theme.TextMuted)
            headerStroke.Transparency = on and (Theme.HoverStrokeTransparency or 0.5) or Theme.PanelStrokeTransparency
            btnStroke.Transparency = on and (Theme.FocusStrokeTransparency or 0.28) or Theme.PanelStrokeTransparency
        end
        setExpanded = function(value)
            expanded = not disabled and #options > 0 and not not value
            local count = #options
            local listHeight = expanded and math.min(count * 36 + 8, 160) or 0
            list.Visible = expanded
            list.Size = UDim2.new(1, 0, 0, listHeight)
            updateButton()
            refreshTrigger()
        end
        rebuild = function()
            clearOptionConnections()
            for _, child in ipairs(list:GetChildren()) do
                if child:IsA("GuiButton") then child:Destroy() end
            end
            for index, raw in ipairs(options) do
                local label = option(raw)
                local item = Instance.new("TextButton")
                item.Size = UDim2.new(1, 0, 0, 32)
                item.BorderSizePixel = 0
                item.Text = label
                item.Font = Theme.FontMedium
                item.TextSize = 12
                item.TextWrapped = true
                item.AutoButtonColor = false
                item.Selectable = not disabled
                item.Active = not disabled
                item.LayoutOrder = index
                item.Parent = list
                items[index] = item
                local itemCorner = Instance.new("UICorner")
                itemCorner.CornerRadius = Theme.FieldCornerRadius or Theme.CornerRadius
                itemCorner.Parent = item
                paint(index, false)
                local pointer, focus = false, false
                local function refreshItem() paint(index, not disabled and (pointer or focus)) end
                connect(item.MouseEnter, function() pointer = true refreshItem() end, optionConnections)
                connect(item.MouseLeave, function() pointer = false refreshItem() end, optionConnections)
                connect(item.SelectionGained, function() focus = true refreshItem() end, optionConnections)
                connect(item.SelectionLost, function() focus = false refreshItem() end, optionConnections)
                connect(item.Activated, function()
                    if disabled then return end
                    select(index, true)
                    setExpanded(false)
                    Utils.safeSvc("GuiService").SelectedObject = btn
                end, optionConnections)
            end
            setExpanded(expanded)
        end

        connect(btn.Activated, function()
            if not disabled then setExpanded(not expanded) end
        end)
        connect(btn.MouseEnter, function() triggerHover = true refreshTrigger() end)
        connect(btn.MouseLeave, function() triggerHover = false refreshTrigger() end)
        connect(btn.SelectionGained, function() triggerFocus = true refreshTrigger() end)
        connect(btn.SelectionLost, function() triggerFocus = false refreshTrigger() end)
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
            if disabled then setExpanded(false) end
            for _, item in ipairs(items) do
                item.Active = not disabled
                item.Selectable = not disabled
            end
            refreshTrigger()
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
        local connections, disabled, hovered, focused = {}, false, false, false
        local function connect(signal, fn)
            local connection = signal:Connect(fn)
            table.insert(connections, connection)
            return connection
        end

        local frm = Instance.new("Frame")
        frm.Size = UDim2.new(1, 0, 0, 0)
        frm.AutomaticSize = Enum.AutomaticSize.Y
        frm.BackgroundColor3 = Theme.Surface or Theme.PanelBackground
        frm.BackgroundTransparency = Theme.PanelTransparency
        frm.BorderSizePixel = 0
        frm.Parent = container
        local corner = Instance.new("UICorner")
        corner.CornerRadius = Theme.CardCornerRadius or UDim.new(0, 14)
        corner.Parent = frm
        local stroke = Instance.new("UIStroke")
        stroke.Color = Theme.Stroke
        stroke.Transparency = Theme.PanelStrokeTransparency
        stroke.Parent = frm
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 4)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = frm
        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0, 10)
        padding.PaddingBottom = UDim.new(0, 10)
        padding.PaddingLeft = UDim.new(0, 14)
        padding.PaddingRight = UDim.new(0, 14)
        padding.Parent = frm

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 0)
        lbl.AutomaticSize = Enum.AutomaticSize.Y
        lbl.BackgroundTransparency = 1
        lbl.BorderSizePixel = 0
        lbl.Text = tostring(name or "Text")
        lbl.TextColor3 = Theme.TextSecondary
        lbl.Font = Theme.FontMedium
        lbl.TextSize = 13
        lbl.TextWrapped = true
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextYAlignment = Enum.TextYAlignment.Top
        lbl.LayoutOrder = 1
        lbl.Parent = frm

        if desc then
            local description = Instance.new("TextLabel")
            description.Size = UDim2.new(1, 0, 0, 0)
            description.AutomaticSize = Enum.AutomaticSize.Y
            description.BackgroundTransparency = 1
            description.BorderSizePixel = 0
            description.Text = tostring(desc)
            description.TextColor3 = Theme.TextMuted
            description.Font = Theme.FontMedium
            description.TextSize = 11
            description.TextWrapped = true
            description.TextXAlignment = Enum.TextXAlignment.Left
            description.TextYAlignment = Enum.TextYAlignment.Top
            description.LayoutOrder = 2
            description.Parent = frm
        end

        local boxBg = Instance.new("Frame")
        boxBg.Size = UDim2.new(1, 0, 0, 34)
        boxBg.BackgroundColor3 = Theme.SecondaryBackground
        boxBg.BorderSizePixel = 0
        boxBg.LayoutOrder = 3
        boxBg.Parent = frm
        local boxCorner = Instance.new("UICorner")
        boxCorner.CornerRadius = Theme.FieldCornerRadius or Theme.CornerRadius
        boxCorner.Parent = boxBg
        local boxStroke = Instance.new("UIStroke")
        boxStroke.Color = Theme.Stroke
        boxStroke.Transparency = Theme.PanelStrokeTransparency
        boxStroke.Parent = boxBg

        local txt = Instance.new("TextBox")
        txt.Size = UDim2.new(1, -20, 1, 0)
        txt.Position = UDim2.new(0, 10, 0, 0)
        txt.BackgroundTransparency = 1
        txt.BorderSizePixel = 0
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

        local function refresh()
            local on = not disabled and (hovered or focused)
            frm.BackgroundColor3 = on and (Theme.SurfaceHover or Theme.SecondaryBackground) or (Theme.Surface or Theme.PanelBackground)
            lbl.TextColor3 = disabled and Theme.TextMuted or (on and Theme.TextPrimary or Theme.TextSecondary)
            stroke.Transparency = on and (Theme.HoverStrokeTransparency or 0.5) or Theme.PanelStrokeTransparency
            boxStroke.Transparency = focused and (Theme.FocusStrokeTransparency or 0.28)
                or (on and (Theme.HoverStrokeTransparency or 0.5) or Theme.PanelStrokeTransparency)
        end
        connect(boxBg.MouseEnter, function() hovered = true refresh() end)
        connect(boxBg.MouseLeave, function() hovered = false refresh() end)
        connect(txt.Focused, function() focused = true refresh() end)
        connect(txt.FocusLost, function(enterPressed)
            focused = false
            refresh()
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
            boxBg.BackgroundTransparency = disabled and 0.45 or 0
            refresh()
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
        frm.BackgroundColor3 = Theme.Surface or Theme.PanelBackground
        frm.BackgroundTransparency = Theme.PanelTransparency
        frm.BorderSizePixel = 0
        frm.Parent = container
        local corner = Instance.new("UICorner")
        corner.CornerRadius = Theme.CardCornerRadius or UDim.new(0, 14)
        corner.Parent = frm
        local stroke = Instance.new("UIStroke")
        stroke.Color = Theme.Stroke
        stroke.Transparency = Theme.PanelStrokeTransparency
        stroke.Parent = frm
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 4)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = frm
        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0, 11)
        padding.PaddingBottom = UDim.new(0, 11)
        padding.PaddingLeft = UDim.new(0, 14)
        padding.PaddingRight = UDim.new(0, 14)
        padding.Parent = frm

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 0)
        lbl.AutomaticSize = Enum.AutomaticSize.Y
        lbl.BackgroundTransparency = 1
        lbl.BorderSizePixel = 0
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
            lblDesc.BorderSizePixel = 0
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
        lbl.Size = UDim2.new(1, 0, 0, 0)
        lbl.AutomaticSize = Enum.AutomaticSize.Y
        lbl.BackgroundTransparency = 1
        lbl.BorderSizePixel = 0
        lbl.Text = tostring(type(text) == "table" and (text.Name or text[1]) or text or "")
        lbl.TextColor3 = Theme.TextPrimary
        lbl.Font = Theme.FontBold
        lbl.TextSize = 12
        lbl.TextWrapped = true
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextYAlignment = Enum.TextYAlignment.Top
        lbl.Parent = container
        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0, 6)
        padding.PaddingBottom = UDim.new(0, 4)
        padding.Parent = lbl
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
        frm.Size = UDim2.new(1, 0, 0, 11)
        frm.BackgroundTransparency = 1
        frm.BorderSizePixel = 0
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
        local hovered, selected, connections = false, false, {}
        local function connect(signal, fn)
            local connection = signal:Connect(fn)
            table.insert(connections, connection)
            return connection
        end

        local frm = Instance.new("Frame")
        frm.Size = UDim2.new(1, 0, 0, 44)
        frm.AutomaticSize = Enum.AutomaticSize.Y
        frm.BackgroundColor3 = Theme.Surface or Theme.PanelBackground
        frm.BackgroundTransparency = Theme.PanelTransparency
        frm.BorderSizePixel = 0
        frm.Parent = container
        local corner = Instance.new("UICorner")
        corner.CornerRadius = Theme.CardCornerRadius or UDim.new(0, 14)
        corner.Parent = frm
        local stroke = Instance.new("UIStroke")
        stroke.Color = Theme.Stroke
        stroke.Transparency = Theme.PanelStrokeTransparency
        stroke.Parent = frm

        local content = Instance.new("Frame")
        content.Size = UDim2.new(1, -116, 0, 44)
        content.AutomaticSize = Enum.AutomaticSize.Y
        content.BackgroundTransparency = 1
        content.BorderSizePixel = 0
        content.Parent = frm
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 3)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = content
        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0, desc and 11 or 14)
        padding.PaddingBottom = UDim.new(0, desc and 11 or 14)
        padding.PaddingLeft = UDim.new(0, 14)
        padding.Parent = content

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 0)
        lbl.AutomaticSize = Enum.AutomaticSize.Y
        lbl.BackgroundTransparency = 1
        lbl.BorderSizePixel = 0
        lbl.Text = tostring(text or "Keybind")
        lbl.TextColor3 = Theme.TextSecondary
        lbl.Font = Theme.FontMedium
        lbl.TextSize = 13
        lbl.TextWrapped = true
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextYAlignment = Enum.TextYAlignment.Top
        lbl.LayoutOrder = 1
        lbl.Parent = content

        if desc then
            local description = Instance.new("TextLabel")
            description.Size = UDim2.new(1, 0, 0, 0)
            description.AutomaticSize = Enum.AutomaticSize.Y
            description.BackgroundTransparency = 1
            description.BorderSizePixel = 0
            description.Text = tostring(desc)
            description.TextColor3 = Theme.TextMuted
            description.Font = Theme.FontMedium
            description.TextSize = 11
            description.TextWrapped = true
            description.TextXAlignment = Enum.TextXAlignment.Left
            description.TextYAlignment = Enum.TextYAlignment.Top
            description.LayoutOrder = 2
            description.Parent = content
        end

        local bindBtn = Instance.new("TextButton")
        bindBtn.Size = UDim2.fromOffset(88, 34)
        bindBtn.AnchorPoint = Vector2.new(1, 0.5)
        bindBtn.Position = UDim2.new(1, -14, 0.5, 0)
        bindBtn.BackgroundColor3 = Theme.SecondaryBackground
        bindBtn.BorderSizePixel = 0
        bindBtn.Text = keyName(currentKey)
        bindBtn.TextColor3 = Theme.TextPrimary
        bindBtn.Font = Theme.FontMedium
        bindBtn.TextSize = 11
        bindBtn.TextTruncate = Enum.TextTruncate.AtEnd
        bindBtn.AutoButtonColor = false
        bindBtn.Selectable = true
        bindBtn.Parent = frm
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = Theme.FieldCornerRadius or Theme.CornerRadius
        btnCorner.Parent = bindBtn
        local btnStroke = Instance.new("UIStroke")
        btnStroke.Color = Theme.Stroke
        btnStroke.Transparency = Theme.PanelStrokeTransparency
        btnStroke.Parent = bindBtn

        local function render()
            bindBtn.Text = isBinding and "Press a key..." or keyName(currentKey)
            bindBtn.BackgroundColor3 = isBinding and Theme.Accent or Theme.SecondaryBackground
            bindBtn.TextColor3 = disabled and Theme.TextMuted or (isBinding and Theme.Background or Theme.TextPrimary)
            btnStroke.Transparency = isBinding and (Theme.FocusStrokeTransparency or 0.28) or Theme.PanelStrokeTransparency
        end
        local function refresh()
            local on = not disabled and (hovered or selected or isBinding)
            frm.BackgroundColor3 = on and (Theme.SurfaceHover or Theme.SecondaryBackground) or (Theme.Surface or Theme.PanelBackground)
            lbl.TextColor3 = disabled and Theme.TextMuted or (on and Theme.TextPrimary or Theme.TextSecondary)
            stroke.Transparency = on and (Theme.HoverStrokeTransparency or 0.5) or Theme.PanelStrokeTransparency
            if not isBinding then
                btnStroke.Transparency = on and (Theme.HoverStrokeTransparency or 0.5) or Theme.PanelStrokeTransparency
            end
        end
        local function beginBinding()
            if disabled or isBinding then return end
            isBinding = true
            render()
            refresh()
        end
        local function finishBinding(key)
            if key then
                currentKey = key
                lastCapture = os.clock()
            end
            isBinding = false
            render()
            refresh()
        end

        connect(bindBtn.Activated, beginBinding)
        connect(bindBtn.MouseEnter, function() hovered = true refresh() end)
        connect(bindBtn.MouseLeave, function() hovered = false refresh() end)
        connect(bindBtn.SelectionGained, function() selected = true refresh() end)
        connect(bindBtn.SelectionLost, function() selected = false refresh() end)
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
            render()
            refresh()
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

    local DefaultTheme = _modules["Theme"]
    local Utils = _modules["Utils"]

    local SAFE_MARGIN = 12
    local MAX_WIDTH = 360
    local containerGui = nil
    local listFrame = nil

    local function getContainer()
        if containerGui and containerGui.Parent and listFrame and listFrame.Parent then
            return listFrame
        end

        containerGui = Instance.new("ScreenGui")
        containerGui.Name = "UniversalUINotify"
        containerGui.ResetOnSpawn = false
        containerGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        containerGui.DisplayOrder = 100
        containerGui.IgnoreGuiInset = true
        containerGui.Parent = Utils.getSafeGui()

        listFrame = Instance.new("Frame")
        listFrame.Size = UDim2.new(1, -SAFE_MARGIN * 2, 1, -SAFE_MARGIN * 2)
        listFrame.Position = UDim2.fromOffset(SAFE_MARGIN, SAFE_MARGIN)
        listFrame.BackgroundTransparency = 1
        listFrame.BorderSizePixel = 0
        listFrame.Parent = containerGui

        local layout = Instance.new("UIListLayout")
        layout.FillDirection = Enum.FillDirection.Vertical
        layout.VerticalAlignment = Enum.VerticalAlignment.Top
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        layout.Padding = UDim.new(0, DefaultTheme.SpacingSM)
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

        local Theme = type(config.Theme) == "table" and config.Theme or DefaultTheme
        local titleText = tostring(config.Title or config.title or "Notification")
        local contentText = tostring(config.Content or config.content or "")
        local duration = math.max(0, tonumber(config.Duration or config.duration) or 4)
        local parent = getContainer()
        local textService = Utils.safeSvc("TextService")
        local guiService = Utils.safeSvc("GuiService")
        local previousSelection = guiService.SelectedObject
        local connections = {}
        local closed = false
        local countdown
        local viewportConnection

        local function connect(signal, callback)
            local connection = signal:Connect(callback)
            table.insert(connections, connection)
            return connection
        end

        local card = Instance.new("Frame")
        card.Name = "Notification"
        card.BackgroundColor3 = Theme.SurfaceElevated or Theme.PanelBackground
        card.BackgroundTransparency = 1
        card.BorderSizePixel = 0
        card.ClipsDescendants = true
        card.Parent = parent

        local corner = Instance.new("UICorner")
        corner.CornerRadius = Theme.WindowCornerRadius or Theme.CornerRadius
        corner.Parent = card

        local stroke = Instance.new("UIStroke")
        stroke.Color = Theme.Stroke
        stroke.Thickness = 1
        stroke.Transparency = 1
        stroke.Parent = card

        local header = Instance.new("Frame")
        header.Name = "Header"
        header.BackgroundTransparency = 1
        header.BorderSizePixel = 0
        header.Parent = card

        local titleLabel = Instance.new("TextLabel")
        titleLabel.Size = UDim2.new(1, -42, 1, 0)
        titleLabel.BackgroundTransparency = 1
        titleLabel.BorderSizePixel = 0
        titleLabel.Text = titleText
        titleLabel.TextColor3 = Theme.TextPrimary
        titleLabel.TextTransparency = 1
        titleLabel.Font = Theme.FontBold
        titleLabel.TextSize = 13
        titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Parent = header

        local dismiss = Instance.new("TextButton")
        dismiss.Name = "Close"
        dismiss.Size = UDim2.fromOffset(32, 32)
        dismiss.Position = UDim2.new(1, -32, 0, 0)
        dismiss.BackgroundColor3 = Theme.SurfaceHover or Theme.SecondaryBackground
        dismiss.BackgroundTransparency = 1
        dismiss.BorderSizePixel = 0
        dismiss.Text = "×"
        dismiss.TextColor3 = Theme.TextMuted
        dismiss.TextTransparency = 1
        dismiss.Font = Theme.FontMedium
        dismiss.TextSize = 18
        dismiss.AutoButtonColor = false
        dismiss.Selectable = true
        dismiss.ZIndex = 2
        dismiss.Parent = header

        local dismissCorner = Instance.new("UICorner")
        dismissCorner.CornerRadius = UDim.new(1, 0)
        dismissCorner.Parent = dismiss

        local body = Instance.new("ScrollingFrame")
        body.Name = "Body"
        body.BackgroundTransparency = 1
        body.BorderSizePixel = 0
        body.CanvasSize = UDim2.new()
        body.AutomaticCanvasSize = Enum.AutomaticSize.Y
        body.ScrollingDirection = Enum.ScrollingDirection.Y
        body.ElasticBehavior = Enum.ElasticBehavior.Never
        body.ScrollBarThickness = 0
        body.ScrollBarImageColor3 = Theme.TextMuted
        body.ScrollBarImageTransparency = 0.35
        body.ClipsDescendants = true
        body.Visible = contentText ~= ""
        body.Parent = card

        local description = Instance.new("TextLabel")
        description.Size = UDim2.new(1, -6, 0, 0)
        description.AutomaticSize = Enum.AutomaticSize.Y
        description.BackgroundTransparency = 1
        description.BorderSizePixel = 0
        description.Text = contentText
        description.TextColor3 = Theme.TextSecondary
        description.TextTransparency = 1
        description.Font = Theme.FontMedium
        description.TextSize = 12
        description.TextWrapped = true
        description.TextXAlignment = Enum.TextXAlignment.Left
        description.TextYAlignment = Enum.TextYAlignment.Top
        description.Parent = body

        local progressBackground = Instance.new("Frame")
        progressBackground.Name = "Progress"
        progressBackground.BackgroundColor3 = Theme.SurfaceHover or Theme.SecondaryBackground
        progressBackground.BackgroundTransparency = 1
        progressBackground.BorderSizePixel = 0
        progressBackground.Parent = card

        local progressFill = Instance.new("Frame")
        progressFill.Size = UDim2.fromScale(1, 1)
        progressFill.BackgroundColor3 = Theme.TextSecondary
        progressFill.BackgroundTransparency = 1
        progressFill.BorderSizePixel = 0
        progressFill.Parent = progressBackground

        for _, item in ipairs({ progressBackground, progressFill }) do
            local progressCorner = Instance.new("UICorner")
            progressCorner.CornerRadius = UDim.new(1, 0)
            progressCorner.Parent = item
        end

        local function updateLayout()
            if closed then return end
            local camera = workspace.CurrentCamera
            local viewport = camera and camera.ViewportSize or Vector2.new(800, 600)
            local availableWidth = math.max(1, viewport.X - SAFE_MARGIN * 2)
            local availableHeight = math.max(1, viewport.Y - SAFE_MARGIN * 2)
            local width = math.min(MAX_WIDTH, availableWidth)
            local horizontalPadding = 14
            local headerHeight = 32
            local bodyGap = contentText ~= "" and 8 or 0
            local bodyY = 10 + headerHeight + bodyGap
            local progressGap = 10
            local progressHeight = 2
            local bottomPadding = 10
            local fixedHeight = bodyY + progressGap + progressHeight + bottomPadding
            local textWidth = math.max(1, width - horizontalPadding * 2 - 6)
            local desiredBodyHeight = 0

            if contentText ~= "" then
                desiredBodyHeight = math.max(18, textService:GetTextSize(
                    contentText,
                    description.TextSize,
                    description.Font,
                    Vector2.new(textWidth, 100000)
                ).Y)
            end

            local bodyHeight = math.min(desiredBodyHeight, math.max(0, availableHeight - fixedHeight))
            local height = math.min(availableHeight, fixedHeight + bodyHeight)

            card.Size = UDim2.fromOffset(width, height)
            header.Position = UDim2.fromOffset(horizontalPadding, 10)
            header.Size = UDim2.new(1, -horizontalPadding * 2, 0, headerHeight)
            body.Position = UDim2.fromOffset(horizontalPadding, bodyY)
            body.Size = UDim2.new(1, -horizontalPadding * 2, 0, bodyHeight)
            body.ScrollBarThickness = desiredBodyHeight > bodyHeight + 1 and 2 or 0
            body.ScrollingEnabled = desiredBodyHeight > bodyHeight + 1
            if not body.ScrollingEnabled then body.CanvasPosition = Vector2.new() end
            progressBackground.Position = UDim2.fromOffset(horizontalPadding, bodyY + bodyHeight + progressGap)
            progressBackground.Size = UDim2.new(1, -horizontalPadding * 2, 0, progressHeight)
        end

        local function disconnectAll()
            if viewportConnection then
                viewportConnection:Disconnect()
                viewportConnection = nil
            end
            for _, connection in ipairs(connections) do
                connection:Disconnect()
            end
            connections = {}
        end

        local function close()
            if closed then return end
            closed = true
            dismiss.Active = false
            dismiss.Selectable = false
            if countdown then countdown:Cancel() end
            if guiService.SelectedObject and guiService.SelectedObject:IsDescendantOf(card) then
                guiService.SelectedObject = previousSelection and previousSelection.Parent and previousSelection or nil
            end
            disconnectAll()

            Utils.tween(card, TweenInfo.new(0.2), { BackgroundTransparency = 1 })
            Utils.tween(stroke, TweenInfo.new(0.2), { Transparency = 1 })
            Utils.tween(titleLabel, TweenInfo.new(0.2), { TextTransparency = 1 })
            Utils.tween(description, TweenInfo.new(0.2), { TextTransparency = 1 })
            Utils.tween(dismiss, TweenInfo.new(0.2), { BackgroundTransparency = 1, TextTransparency = 1 })
            Utils.tween(progressBackground, TweenInfo.new(0.2), { BackgroundTransparency = 1 })
            Utils.tween(progressFill, TweenInfo.new(0.2), { BackgroundTransparency = 1 })
            task.delay(0.2, function()
                if card.Parent then card:Destroy() end
            end)
        end

        local dismissHovered = false
        local dismissFocused = false
        local function updateDismiss()
            local active = dismissHovered or dismissFocused
            Utils.tween(dismiss, TweenInfo.new(0.15), {
                BackgroundTransparency = active and 0.45 or 1,
                TextColor3 = active and Theme.TextPrimary or Theme.TextMuted,
            })
        end

        connect(dismiss.Activated, close)
        connect(dismiss.MouseEnter, function()
            dismissHovered = true
            updateDismiss()
        end)
        connect(dismiss.MouseLeave, function()
            dismissHovered = false
            updateDismiss()
        end)
        connect(dismiss.SelectionGained, function()
            dismissFocused = true
            updateDismiss()
        end)
        connect(dismiss.SelectionLost, function()
            dismissFocused = false
            updateDismiss()
        end)

        local function watchViewport()
            if viewportConnection then viewportConnection:Disconnect() end
            local camera = workspace.CurrentCamera
            viewportConnection = camera and camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateLayout) or nil
            updateLayout()
        end

        connect(workspace:GetPropertyChangedSignal("CurrentCamera"), watchViewport)
        watchViewport()

        Utils.tween(card, TweenInfo.new(0.25), { BackgroundTransparency = Theme.PanelTransparency })
        Utils.tween(stroke, TweenInfo.new(0.25), { Transparency = Theme.PanelStrokeTransparency })
        Utils.tween(titleLabel, TweenInfo.new(0.25), { TextTransparency = 0 })
        Utils.tween(description, TweenInfo.new(0.25), { TextTransparency = 0 })
        Utils.tween(dismiss, TweenInfo.new(0.25), { TextTransparency = 0 })
        Utils.tween(progressBackground, TweenInfo.new(0.25), { BackgroundTransparency = 0.45 })
        Utils.tween(progressFill, TweenInfo.new(0.25), { BackgroundTransparency = 0.1 })

        task.delay(0.25, function()
            if closed then return end
            if duration == 0 then
                close()
                return
            end
            countdown = Utils.tween(progressFill, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
                Size = UDim2.new(0, 0, 1, 0)
            })
            connect(countdown.Completed, close)
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

    local DefaultTheme = _modules["Theme"]
    local Utils = _modules["Utils"]
    local Drag = _modules["Drag"]

    local SAFE_MARGIN = 12
    local MAX_WIDTH = 420
    local HEADER_HEIGHT = 52
    local CONTROL_HEIGHT = 44

    function Auth.show(config)
        config = type(config) == "table" and config or {}
        local Theme = type(config.Theme) == "table" and config.Theme or DefaultTheme
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
        local connections = {}
        local viewportConnection
        local closing = false
        local isLoading = false

        local function connect(signal, callback)
            local connection = signal:Connect(callback)
            table.insert(connections, connection)
            return connection
        end

        local gui = Instance.new("ScreenGui")
        gui.Name = "NMZUI_AUTH"
        gui.ResetOnSpawn = false
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        gui.IgnoreGuiInset = true
        gui.DisplayOrder = 200
        gui.Parent = parent

        local overlay = Instance.new("TextButton")
        overlay.Name = "ModalOverlay"
        overlay.Size = UDim2.fromScale(1, 1)
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
        main.Name = "Modal"
        main.Position = UDim2.fromScale(0.5, 0.5)
        main.AnchorPoint = Vector2.new(0.5, 0.5)
        main.BackgroundColor3 = Theme.SurfaceElevated or Theme.Background
        main.BackgroundTransparency = Theme.PanelTransparency
        main.BorderSizePixel = 0
        main.ClipsDescendants = true
        main.Active = true
        main.Parent = overlay

        local scale = Instance.new("UIScale")
        scale.Scale = 0.94
        scale.Parent = main

        local stroke = Instance.new("UIStroke")
        stroke.Color = Theme.Stroke
        stroke.Thickness = 1
        stroke.Transparency = Theme.PanelStrokeTransparency
        stroke.Parent = main

        local corner = Instance.new("UICorner")
        corner.CornerRadius = Theme.WindowCornerRadius or Theme.CornerRadius
        corner.Parent = main

        local header = Instance.new("Frame")
        header.Name = "Header"
        header.Size = UDim2.new(1, 0, 0, HEADER_HEIGHT)
        header.BackgroundColor3 = Theme.Surface or Theme.PanelBackground
        header.BackgroundTransparency = 0.35
        header.BorderSizePixel = 0
        header.Active = true
        header.Parent = main

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -72, 1, 0)
        title.Position = UDim2.fromOffset(18, 0)
        title.BackgroundTransparency = 1
        title.BorderSizePixel = 0
        title.Text = titleText
        title.TextColor3 = Theme.TextPrimary
        title.Font = Theme.FontBold
        title.TextSize = 16
        title.TextTruncate = Enum.TextTruncate.AtEnd
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = header

        local closeButton = Instance.new("TextButton")
        closeButton.Name = "Close"
        closeButton.Size = UDim2.fromOffset(34, 34)
        closeButton.AnchorPoint = Vector2.new(1, 0.5)
        closeButton.Position = UDim2.new(1, -9, 0.5, 0)
        closeButton.BackgroundColor3 = Theme.SurfaceHover or Theme.SecondaryBackground
        closeButton.BackgroundTransparency = 1
        closeButton.BorderSizePixel = 0
        closeButton.Text = "×"
        closeButton.TextColor3 = Theme.TextSecondary
        closeButton.Font = Theme.FontMedium
        closeButton.TextSize = 19
        closeButton.AutoButtonColor = false
        closeButton.Selectable = true
        closeButton.Parent = header

        local closeCorner = Instance.new("UICorner")
        closeCorner.CornerRadius = UDim.new(1, 0)
        closeCorner.Parent = closeButton

        local body = Instance.new("ScrollingFrame")
        body.Name = "Body"
        body.Position = UDim2.fromOffset(0, HEADER_HEIGHT)
        body.BackgroundTransparency = 1
        body.BorderSizePixel = 0
        body.CanvasSize = UDim2.new()
        body.AutomaticCanvasSize = Enum.AutomaticSize.Y
        body.ScrollingDirection = Enum.ScrollingDirection.Y
        body.ElasticBehavior = Enum.ElasticBehavior.Never
        body.ScrollBarThickness = 0
        body.ScrollBarImageColor3 = Theme.TextMuted
        body.ScrollBarImageTransparency = 0.35
        body.ClipsDescendants = true
        body.Parent = main

        local bodyLayout = Instance.new("UIListLayout")
        bodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
        bodyLayout.Padding = UDim.new(0, Theme.SpacingMD)
        bodyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        bodyLayout.Parent = body

        local bodyPadding = Instance.new("UIPadding")
        bodyPadding.PaddingTop = UDim.new(0, Theme.SpacingLG)
        bodyPadding.PaddingBottom = UDim.new(0, Theme.SpacingLG)
        bodyPadding.PaddingLeft = UDim.new(0, Theme.SpacingLG)
        bodyPadding.PaddingRight = UDim.new(0, Theme.SpacingLG)
        bodyPadding.Parent = body

        local subtitle = Instance.new("TextLabel")
        subtitle.Size = UDim2.new(1, 0, 0, 0)
        subtitle.AutomaticSize = Enum.AutomaticSize.Y
        subtitle.BackgroundTransparency = 1
        subtitle.BorderSizePixel = 0
        subtitle.Text = subtitleText
        subtitle.TextColor3 = Theme.TextSecondary
        subtitle.Font = Theme.FontMedium
        subtitle.TextSize = 13
        subtitle.TextWrapped = true
        subtitle.TextXAlignment = Enum.TextXAlignment.Left
        subtitle.TextYAlignment = Enum.TextYAlignment.Top
        subtitle.LayoutOrder = 1
        subtitle.Parent = body

        local inputContainer = Instance.new("Frame")
        inputContainer.Size = UDim2.new(1, 0, 0, CONTROL_HEIGHT)
        inputContainer.BackgroundColor3 = Theme.Surface or Theme.PanelBackground
        inputContainer.BackgroundTransparency = 0.15
        inputContainer.BorderSizePixel = 0
        inputContainer.LayoutOrder = 2
        inputContainer.Parent = body

        local inputCorner = Instance.new("UICorner")
        inputCorner.CornerRadius = Theme.CornerRadius
        inputCorner.Parent = inputContainer

        local inputStroke = Instance.new("UIStroke")
        inputStroke.Color = Theme.Stroke
        inputStroke.Thickness = 1
        inputStroke.Transparency = Theme.PanelStrokeTransparency
        inputStroke.Parent = inputContainer

        local textBox = Instance.new("TextBox")
        textBox.Size = UDim2.new(1, -Theme.SpacingLG * 2, 1, 0)
        textBox.Position = UDim2.new(0, Theme.SpacingLG, 0, 0)
        textBox.BackgroundTransparency = 1
        textBox.BorderSizePixel = 0
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

        local submitButton = Instance.new("TextButton")
        submitButton.Name = "Submit"
        submitButton.Size = UDim2.new(1, 0, 0, CONTROL_HEIGHT)
        submitButton.BackgroundColor3 = Theme.Accent
        submitButton.BorderSizePixel = 0
        submitButton.Text = submitText
        submitButton.TextColor3 = Theme.Background
        submitButton.Font = Theme.FontBold
        submitButton.TextSize = 14
        submitButton.AutoButtonColor = false
        submitButton.Selectable = true
        submitButton.LayoutOrder = 3
        submitButton.Parent = body

        local submitCorner = Instance.new("UICorner")
        submitCorner.CornerRadius = Theme.CornerRadius
        submitCorner.Parent = submitButton

        local submitStroke = Instance.new("UIStroke")
        submitStroke.Color = Theme.TextPrimary
        submitStroke.Thickness = 1
        submitStroke.Transparency = 1
        submitStroke.Parent = submitButton

        local linkContainer
        local linkLayout
        local linkButtons = {}
        local selectionObjects = { closeButton, textBox, submitButton }

        if #links > 0 then
            linkContainer = Instance.new("Frame")
            linkContainer.Name = "Links"
            linkContainer.Size = UDim2.new(1, 0, 0, 0)
            linkContainer.BackgroundTransparency = 1
            linkContainer.BorderSizePixel = 0
            linkContainer.LayoutOrder = 4
            linkContainer.Parent = body

            linkLayout = Instance.new("UIGridLayout")
            linkLayout.CellPadding = UDim2.fromOffset(Theme.SpacingSM, Theme.SpacingSM)
            linkLayout.SortOrder = Enum.SortOrder.LayoutOrder
            linkLayout.FillDirection = Enum.FillDirection.Horizontal
            linkLayout.Parent = linkContainer

            for _, linkData in ipairs(links) do
                if type(linkData) == "table" then
                    local linkButton = Instance.new("TextButton")
                    linkButton.Size = UDim2.fromScale(1, 1)
                    linkButton.BackgroundColor3 = Theme.Surface or Theme.PanelBackground
                    linkButton.BackgroundTransparency = 0.15
                    linkButton.BorderSizePixel = 0
                    linkButton.Text = ""
                    linkButton.AutoButtonColor = false
                    linkButton.Selectable = true
                    linkButton.LayoutOrder = #linkButtons + 1
                    linkButton.Parent = linkContainer
                    table.insert(linkButtons, linkButton)
                    table.insert(selectionObjects, linkButton)

                    local linkCorner = Instance.new("UICorner")
                    linkCorner.CornerRadius = Theme.CornerRadius
                    linkCorner.Parent = linkButton

                    local linkStroke = Instance.new("UIStroke")
                    linkStroke.Color = Theme.Stroke
                    linkStroke.Thickness = 1
                    linkStroke.Transparency = Theme.PanelStrokeTransparency
                    linkStroke.Parent = linkButton

                    local icon
                    local textOffset = Theme.SpacingMD
                    if linkData.Icon then
                        icon = Instance.new("ImageLabel")
                        icon.Size = UDim2.fromOffset(14, 14)
                        icon.Position = UDim2.new(0, Theme.SpacingMD, 0.5, -7)
                        icon.BackgroundTransparency = 1
                        icon.BorderSizePixel = 0
                        icon.Image = linkData.Icon
                        icon.ImageColor3 = Theme.TextSecondary
                        icon.Parent = linkButton
                        textOffset = 34
                    end

                    local linkLabel = Instance.new("TextLabel")
                    linkLabel.Size = UDim2.new(1, -textOffset - Theme.SpacingMD, 1, -4)
                    linkLabel.Position = UDim2.new(0, textOffset, 0, 2)
                    linkLabel.BackgroundTransparency = 1
                    linkLabel.BorderSizePixel = 0
                    linkLabel.Text = tostring(linkData.Name or "Link")
                    linkLabel.TextColor3 = Theme.TextSecondary
                    linkLabel.Font = Theme.FontMedium
                    linkLabel.TextSize = 11
                    linkLabel.TextWrapped = true
                    linkLabel.TextXAlignment = Enum.TextXAlignment.Left
                    linkLabel.Parent = linkButton

                    local hovered = false
                    local focused = false
                    local function updateLink()
                        local active = hovered or focused
                        Utils.tween(linkButton, TweenInfo.new(0.15), {
                            BackgroundColor3 = active and (Theme.SurfaceHover or Theme.SecondaryBackground) or (Theme.Surface or Theme.PanelBackground),
                            BackgroundTransparency = active and 0 or 0.15,
                        })
                        Utils.tween(linkLabel, TweenInfo.new(0.15), {
                            TextColor3 = active and Theme.TextPrimary or Theme.TextSecondary,
                        })
                        linkStroke.Color = active and Theme.Focus or Theme.Stroke
                        linkStroke.Transparency = active and 0.2 or Theme.PanelStrokeTransparency
                        if icon then
                            Utils.tween(icon, TweenInfo.new(0.15), {
                                ImageColor3 = active and Theme.TextPrimary or Theme.TextSecondary,
                            })
                        end
                    end

                    connect(linkButton.MouseEnter, function()
                        hovered = true
                        updateLink()
                    end)
                    connect(linkButton.MouseLeave, function()
                        hovered = false
                        updateLink()
                    end)
                    connect(linkButton.SelectionGained, function()
                        focused = true
                        updateLink()
                    end)
                    connect(linkButton.SelectionLost, function()
                        focused = false
                        updateLink()
                    end)
                    connect(linkButton.Activated, function()
                        if closing then return end
                        if type(linkData.OnClick) == "function" then
                            local ok, err = pcall(linkData.OnClick, linkLabel)
                            if not ok then warn("Auth link failed: " .. tostring(err)) end
                        end
                    end)
                end
            end
        end

        local function updateSelectionLinks()
            for index, object in ipairs(selectionObjects) do
                local previous = selectionObjects[index - 1] or selectionObjects[#selectionObjects]
                local nextObject = selectionObjects[index + 1] or selectionObjects[1]
                object.NextSelectionUp = previous
                object.NextSelectionLeft = previous
                object.NextSelectionDown = nextObject
                object.NextSelectionRight = nextObject
            end
        end
        updateSelectionLinks()

        local submitState = "idle"
        local submitHovered = false
        local submitFocused = false
        local submitTween

        local function updateSubmitVisual()
            if submitTween then submitTween:Cancel() end
            local background
            local textColor
            if submitState == "loading" then
                background = Theme.SurfaceHover or Theme.SecondaryBackground
                textColor = Theme.TextSecondary
            elseif submitState == "success" then
                background = Theme.Success
                textColor = Theme.Background
            else
                background = (submitHovered or submitFocused) and Theme.AccentHover or Theme.Accent
                textColor = Theme.Background
            end
            submitTween = ts:Create(submitButton, TweenInfo.new(0.15), {
                BackgroundColor3 = background,
                TextColor3 = textColor,
            })
            submitTween:Play()
            submitStroke.Transparency = submitFocused and submitState == "idle" and 0.2 or 1
        end

        local function setSubmitState(state)
            submitState = state
            isLoading = state == "loading"
            local enabled = state == "idle"
            submitButton.Active = enabled
            submitButton.Selectable = enabled
            textBox.TextEditable = enabled
            submitButton.Text = state == "loading" and "Verifying..." or state == "success" and "Success" or submitText
            updateSubmitVisual()
        end

        local inputFocused = false
        local inputSelected = false
        local inputFailed = false
        local function updateInputVisual()
            if inputFailed then
                inputStroke.Color = Theme.Error
                inputStroke.Transparency = 0
            elseif inputFocused or inputSelected then
                inputStroke.Color = Theme.Focus
                inputStroke.Transparency = 0
            else
                inputStroke.Color = Theme.Stroke
                inputStroke.Transparency = Theme.PanelStrokeTransparency
            end
        end

        local function disconnectAll()
            if viewportConnection then
                viewportConnection:Disconnect()
                viewportConnection = nil
            end
            for _, connection in ipairs(connections) do
                connection:Disconnect()
            end
            connections = {}
        end

        local function closeAuth()
            if closing then return end
            closing = true
            isLoading = false
            overlay.Active = false
            closeButton.Active = false
            closeButton.Selectable = false
            submitButton.Active = false
            submitButton.Selectable = false

            local selected = guiService.SelectedObject
            if selected and selected:IsDescendantOf(gui) then
                guiService.SelectedObject = previousSelection and previousSelection.Parent and previousSelection or nil
            end
            disconnectAll()
            if submitTween then submitTween:Cancel() end

            ts:Create(overlay, TweenInfo.new(0.22), { BackgroundTransparency = 1 }):Play()
            ts:Create(main, TweenInfo.new(0.22), { BackgroundTransparency = 1 }):Play()
            ts:Create(scale, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.94 }):Play()
            task.delay(0.22, function()
                if gui.Parent then gui:Destroy() end
            end)
        end

        local closeHovered = false
        local closeFocused = false
        local function updateCloseVisual()
            local active = closeHovered or closeFocused
            Utils.tween(closeButton, TweenInfo.new(0.15), {
                BackgroundTransparency = active and 0 or 1,
                TextColor3 = active and Theme.TextPrimary or Theme.TextSecondary,
            })
        end

        connect(closeButton.Activated, closeAuth)
        connect(closeButton.MouseEnter, function()
            closeHovered = true
            updateCloseVisual()
        end)
        connect(closeButton.MouseLeave, function()
            closeHovered = false
            updateCloseVisual()
        end)
        connect(closeButton.SelectionGained, function()
            closeFocused = true
            updateCloseVisual()
        end)
        connect(closeButton.SelectionLost, function()
            closeFocused = false
            updateCloseVisual()
        end)

        local function resetSubmit(failed)
            if closing then return end
            setSubmitState("idle")
            if failed then
                inputFailed = true
                updateInputVisual()
                task.delay(0.6, function()
                    if closing or not inputStroke.Parent then return end
                    inputFailed = false
                    updateInputVisual()
                end)
            end
        end

        local function doSubmit()
            if isLoading or closing or submitState ~= "idle" then return end
            setSubmitState("loading")

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
                        setSubmitState("success")
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

        connect(submitButton.Activated, doSubmit)
        connect(submitButton.MouseEnter, function()
            submitHovered = true
            updateSubmitVisual()
        end)
        connect(submitButton.MouseLeave, function()
            submitHovered = false
            updateSubmitVisual()
        end)
        connect(submitButton.SelectionGained, function()
            submitFocused = true
            updateSubmitVisual()
        end)
        connect(submitButton.SelectionLost, function()
            submitFocused = false
            updateSubmitVisual()
        end)

        connect(textBox.Focused, function()
            inputFocused = true
            inputFailed = false
            updateInputVisual()
        end)
        connect(textBox.FocusLost, function(enterPressed)
            inputFocused = false
            updateInputVisual()
            if enterPressed then doSubmit() end
        end)
        connect(textBox.SelectionGained, function()
            inputSelected = true
            updateInputVisual()
        end)
        connect(textBox.SelectionLost, function()
            inputSelected = false
            updateInputVisual()
        end)

        connect(uis.InputBegan, function(input)
            if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB then
                closeAuth()
            end
        end)

        local function updateLayout()
            if closing then return end
            local camera = workspace.CurrentCamera
            local viewport = camera and camera.ViewportSize or Vector2.new(800, 600)
            local availableWidth = math.max(1, viewport.X - SAFE_MARGIN * 2)
            local availableHeight = math.max(1, viewport.Y - SAFE_MARGIN * 2)
            local width = math.min(MAX_WIDTH, availableWidth)
            local contentWidth = math.max(1, width - Theme.SpacingLG * 2)

            if linkContainer then
                local columns = contentWidth >= 320 and #linkButtons > 1 and 2 or 1
                local gap = Theme.SpacingSM
                local cellOffset = -gap * (columns - 1) / columns
                local rows = math.ceil(#linkButtons / columns)
                linkLayout.FillDirectionMaxCells = columns
                linkLayout.CellSize = UDim2.new(1 / columns, cellOffset, 0, CONTROL_HEIGHT)
                linkContainer.Size = UDim2.new(1, 0, 0, math.max(0, rows * CONTROL_HEIGHT + (rows - 1) * gap))
            end

            local desiredBodyHeight = bodyLayout.AbsoluteContentSize.Y + Theme.SpacingLG * 2
            local desiredHeight = HEADER_HEIGHT + desiredBodyHeight
            local height = math.min(desiredHeight, availableHeight)
            local bodyHeight = math.max(0, height - HEADER_HEIGHT)
            local position = Vector2.new(
                main.Position.X.Scale * viewport.X + main.Position.X.Offset,
                main.Position.Y.Scale * viewport.Y + main.Position.Y.Offset
            )
            local halfWidth = width * 0.5
            local halfHeight = height * 0.5

            main.Size = UDim2.fromOffset(width, height)
            main.Position = UDim2.fromOffset(
                math.clamp(position.X, SAFE_MARGIN + halfWidth, math.max(SAFE_MARGIN + halfWidth, viewport.X - SAFE_MARGIN - halfWidth)),
                math.clamp(position.Y, SAFE_MARGIN + halfHeight, math.max(SAFE_MARGIN + halfHeight, viewport.Y - SAFE_MARGIN - halfHeight))
            )
            body.Size = UDim2.new(1, 0, 0, bodyHeight)
            body.ScrollBarThickness = desiredBodyHeight > bodyHeight + 1 and 2 or 0
            body.ScrollingEnabled = desiredBodyHeight > bodyHeight + 1
            if not body.ScrollingEnabled then body.CanvasPosition = Vector2.new() end
        end

        local function watchViewport()
            if viewportConnection then viewportConnection:Disconnect() end
            local camera = workspace.CurrentCamera
            viewportConnection = camera and camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateLayout) or nil
            updateLayout()
        end

        connect(bodyLayout:GetPropertyChangedSignal("AbsoluteContentSize"), updateLayout)
        connect(workspace:GetPropertyChangedSignal("CurrentCamera"), watchViewport)
        watchViewport()
        task.defer(updateLayout)

        for _, connection in ipairs(Drag.makeDraggable(header, main, { Margin = SAFE_MARGIN })) do
            table.insert(connections, connection)
        end

        ts:Create(overlay, TweenInfo.new(0.3), { BackgroundTransparency = 0.32 }):Play()
        ts:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 }):Play()

        if uis.GamepadEnabled then
            task.defer(function()
                if gui.Parent and not closing then guiService.SelectedObject = submitButton end
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