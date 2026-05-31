local Tab = {}

local import = function(name)
    local ok, res = pcall(function() return require(script.Parent[name]) end)
    if ok then return res end
    return _G.UniversalUILib_GetModule(name)
end

local Theme = import("Theme")
local Utils = import("Utils")

function Tab.new(window, name, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 32)
    btn.BackgroundColor3 = Theme.TabInactive
    btn.Text = name
    btn.TextColor3 = Theme.TextMuted
    btn.Font = Theme.FontBold
    btn.TextSize = 11
    btn.LayoutOrder = order or 1
    local c = Instance.new("UICorner")
    c.CornerRadius = Theme.CornerRadius
    c.Parent = btn
    btn.Parent = window.tabContainer

    local frm = Instance.new("ScrollingFrame")
    frm.Size = UDim2.new(1, -20, 1, -20)
    frm.Position = UDim2.new(0, 15, 0, 10)
    frm.BackgroundTransparency = 1
    frm.ScrollBarThickness = 2
    frm.ScrollBarImageColor3 = Theme.Accent
    frm.ScrollBarImageTransparency = 0.5
    frm.Visible = false
    frm.Parent = window.rightPanel
    
    local lay = Instance.new("UIListLayout")
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.Padding = UDim.new(0, 6)
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
    
    -- Smooth hover transition for Tab button
    btn.MouseEnter:Connect(function()
        if not (btn.BackgroundColor3 == Theme.TabActive) then
            Utils.tween(btn, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
                BackgroundColor3 = Theme.SecondaryBackground,
                TextColor3 = Theme.TextSecondary
            })
        end
    end)
    btn.MouseLeave:Connect(function()
        if not (btn.BackgroundColor3 == Theme.TabActive) then
            Utils.tween(btn, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
                BackgroundColor3 = Theme.TabInactive,
                TextColor3 = Theme.TextMuted
            })
        end
    end)
    
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
    local ti = TweenInfo.new(0.2, Enum.EasingStyle.Sine)
    if window.tabs then
        for _, tab in ipairs(window.tabs) do
            local isSelected = (tab.name == tabName)
            if isSelected and not tab.container.Visible then
                tab.container.Visible = true
                -- Subtle fade-in slide animation
                tab.container.Position = UDim2.new(0, 15, 0, 16)
                Utils.tween(tab.container, TweenInfo.new(0.25, Enum.EasingStyle.OutQuad), {
                    Position = UDim2.new(0, 15, 0, 10)
                })
            elseif not isSelected then
                tab.container.Visible = false
            end
            
            Utils.tween(tab.button, ti, {
                BackgroundColor3 = isSelected and Theme.TabActive or Theme.TabInactive,
                TextColor3 = isSelected and Theme.TextPrimary or Theme.TextMuted
            })
        end
    end
end

return Tab
