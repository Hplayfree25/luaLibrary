local Toggle = {}
local Theme = require(script.Parent.Theme)
local Utils = require(script.Parent.Utils)

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
