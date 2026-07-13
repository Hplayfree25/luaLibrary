local Tab = {}

local import = function(name)
    local ok, res = pcall(function() return require(script.Parent[name]) end)
    if ok then return res end
    return _G.UniversalUILib_GetModule(name)
end

local DefaultTheme = import("Theme")
local Utils = import("Utils")

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
