local Button = {}
local Theme = require(script.Parent.Theme)
local Utils = require(script.Parent.Utils)

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
