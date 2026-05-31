local Tab = {}
local Theme = require(script.Parent.Theme)
local Utils = require(script.Parent.Utils)

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
