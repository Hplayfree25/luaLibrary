local Notification = {}

local import = function(name)
    local ok, res = pcall(function() return require(script.Parent[name]) end)
    if ok then return res end
    return _G.UniversalUILib_GetModule(name)
end

local Theme = import("Theme")
local Utils = import("Utils")

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
