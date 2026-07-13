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
