-- Universal UI Library (Bundled)
local _modules = {}

-- Module: Theme
_modules["Theme"] = (function()
    local Theme = {
        -- Fonts
        FontBold = Enum.Font.GothamBold,
        FontMedium = Enum.Font.GothamMedium,
        
        -- Colors
        Background = Color3.fromRGB(12, 12, 16),
        PanelBackground = Color3.fromRGB(25, 25, 30),
        Accent = Color3.fromRGB(100, 150, 255),
        AccentHover = Color3.fromRGB(120, 170, 255),
        SecondaryBackground = Color3.fromRGB(40, 40, 45),
        TabInactive = Color3.fromRGB(20, 20, 25),
        TabActive = Color3.fromRGB(40, 40, 50),
        TextPrimary = Color3.fromRGB(255, 255, 255),
        TextSecondary = Color3.fromRGB(240, 240, 240),
        TextMuted = Color3.fromRGB(150, 150, 150),
        Stroke = Color3.fromRGB(255, 255, 255),
        
        -- Transparencies
        BackgroundTransparency = 0.1,
        PanelTransparency = 0.6,
        StrokeTransparency = 0.85,
        PanelStrokeTransparency = 0.92,
        
        -- Misc
        CornerRadius = UDim.new(0, 8),
        WindowCornerRadius = UDim.new(0, 12)
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
            theme = Theme,
            destroy = function()
                if rsConn then rsConn:Disconnect() end
                gui:Destroy()
            end
        }
        
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
        btn.Size = UDim2.new(1, -20, 0, 35)
        btn.BackgroundColor3 = Theme.TabInactive
        btn.Text = name
        btn.TextColor3 = Theme.TextMuted
        btn.Font = Theme.FontBold
        btn.TextSize = 13
        btn.LayoutOrder = order or 1
        local c = Instance.new("UICorner")
        c.CornerRadius = Theme.CornerRadius
        c.Parent = btn
        btn.Parent = window.tabContainer
    
        local frm = Instance.new("ScrollingFrame")
        frm.Size = UDim2.new(1, -15, 1, -20)
        frm.Position = UDim2.new(0, 15, 0, 10)
        frm.BackgroundTransparency = 1
        frm.ScrollBarThickness = 3
        frm.ScrollBarImageColor3 = Theme.Accent
        frm.Visible = false
        frm.Parent = window.rightPanel
        
        local lay = Instance.new("UIListLayout")
        lay.SortOrder = Enum.SortOrder.LayoutOrder
        lay.Padding = UDim.new(0, 8)
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
        local ti = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        if window.tabs then
            for _, tab in ipairs(window.tabs) do
                local isSelected = (tab.name == tabName)
                tab.container.Visible = isSelected
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
        local frm = Instance.new("Frame")
        frm.Size = UDim2.new(1, 0, 0, 40)
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
        btn.Text = name
        btn.TextColor3 = Theme.TextSecondary
        btn.Font = Theme.FontMedium
        btn.TextSize = 14
        btn.Parent = frm
        
        btn.MouseButton1Click:Connect(function()
            local ti = TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
            Utils.tween(frm, ti, {BackgroundColor3 = Theme.Accent})
            task.delay(0.1, function()
                pcall(function() Utils.tween(frm, ti, {BackgroundColor3 = Theme.PanelBackground}) end)
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
        local stateVal = defaultState or false
        
        local frm = Instance.new("Frame")
        frm.Size = UDim2.new(1, 0, 0, 40)
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
        lbl.Size = UDim2.new(0.7, 0, 1, 0)
        lbl.Position = UDim2.new(0, 12, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = name
        lbl.TextColor3 = Theme.TextSecondary
        lbl.Font = Theme.FontMedium
        lbl.TextSize = 13
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = frm
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 40, 0, 20)
        btn.Position = UDim2.new(1, -52, 0.5, -10)
        btn.BackgroundColor3 = stateVal and Theme.Accent or Theme.SecondaryBackground
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
        
        local function updateVisuals()
            local ti = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
            Utils.tween(btn, ti, {BackgroundColor3 = stateVal and Theme.Accent or Theme.SecondaryBackground})
            Utils.tween(knob, ti, {Position = stateVal and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)})
        end
        
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
        frm.Size = UDim2.new(1, 0, 0, 50)
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
        lbl.TextSize = 13
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = frm
        local bg = Instance.new("Frame")
        bg.Size = UDim2.new(1, -24, 0, 6)
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
        frm.Size = UDim2.new(1, 0, 0, 40)
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
        lbl.TextSize = 13
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = frm
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 100, 0, 22)
        btn.Position = UDim2.new(1, -112, 0.5, -11)
        btn.BackgroundColor3 = Theme.SecondaryBackground
        btn.Text = opts[defaultIdx].name
        btn.TextColor3 = Theme.TextPrimary
        btn.Font = Theme.FontBold
        btn.TextSize = 11
        btn.Parent = frm
        local bc = Instance.new("UICorner")
        bc.CornerRadius = UDim.new(0, 6)
        bc.Parent = btn
        
        local cur = defaultIdx
        
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
        frm.Size = UDim2.new(1, 0, 0, 40)
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
        lbl.TextSize = 13
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = frm
        
        local boxBg = Instance.new("Frame")
        boxBg.Size = UDim2.new(0.5, 0, 0, 24)
        boxBg.Position = UDim2.new(1, -boxBg.Size.X.Offset - (boxBg.Size.X.Scale * frm.AbsoluteSize.X) - 12, 0.5, -12)
        boxBg.BackgroundColor3 = Theme.SecondaryBackground
        boxBg.Parent = frm
        local boxCorner = Instance.new("UICorner")
        boxCorner.CornerRadius = UDim.new(0, 6)
        boxCorner.Parent = boxBg
        
        frm:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            boxBg.Position = UDim2.new(1, -boxBg.Size.X.Offset - (boxBg.Size.X.Scale * frm.AbsoluteSize.X) - 12, 0.5, -12)
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
        txt.TextSize = 12
        txt.TextXAlignment = Enum.TextXAlignment.Left
        txt.ClearTextOnFocus = false
        txt.Parent = boxBg
        
        txt.FocusLost:Connect(function(enterPressed)
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

-- Entry Point: Init
local Lib = {}

Lib.Theme = _modules["Theme"]
Lib.Utils = _modules["Utils"]
Lib.Drag = _modules["Drag"]
Lib.Window = _modules["Window"]
Lib.Components = _modules["Components"]

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

return Lib