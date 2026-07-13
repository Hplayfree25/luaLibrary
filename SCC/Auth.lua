local Auth = {}

local import = function(name)
    local ok, res = pcall(function() return require(script.Parent[name]) end)
    if ok then return res end
    return _G.UniversalUILib_GetModule(name)
end

local DefaultTheme = import("Theme")
local Utils = import("Utils")
local Drag = import("Drag")

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
