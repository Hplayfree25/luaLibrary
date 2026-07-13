local Notification = {}

local import = function(name)
    local ok, res = pcall(function() return require(script.Parent[name]) end)
    if ok then return res end
    return _G.UniversalUILib_GetModule(name)
end

local DefaultTheme = import("Theme")
local Utils = import("Utils")

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
