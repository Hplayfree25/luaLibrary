local Toggle = {}

local import = function(name)
    local ok, res = pcall(function() return require(script.Parent[name]) end)
    if ok then return res end
    return _G.UniversalUILib_GetModule(name)
end

local Theme = import("Theme")
local Utils = import("Utils")

function Toggle.new(parent, name, defaultState, cb)
    local text = type(name) == "table" and (name.Name or name[1]) or name
    local desc = type(name) == "table" and (name.Desc or name[2]) or nil

    local stateVal = defaultState or false
    
    local frm = Instance.new("Frame")
    frm.Size = UDim2.new(1, 0, 0, desc and 48 or 36)
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
    lbl.Size = desc and UDim2.new(0.7, 0, 0, 16) or UDim2.new(0.7, 0, 1, 0)
    lbl.Position = desc and UDim2.new(0, 12, 0, 8) or UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Theme.TextSecondary
    lbl.Font = Theme.FontMedium
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frm
    
    if desc then
        local lblDesc = Instance.new("TextLabel")
        lblDesc.Size = UDim2.new(0.7, 0, 0, 14)
        lblDesc.Position = UDim2.new(0, 12, 0, 26)
        lblDesc.BackgroundTransparency = 1
        lblDesc.Text = desc
        lblDesc.TextColor3 = Theme.TextSecondary
        lblDesc.TextTransparency = 0.4
        lblDesc.Font = Theme.FontMedium
        lblDesc.TextSize = 11
        lblDesc.TextXAlignment = Enum.TextXAlignment.Left
        lblDesc.Parent = frm
    end
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 34, 0, 18)
    btn.Position = UDim2.new(1, -46, 0.5, -9)
    btn.BackgroundColor3 = stateVal and Theme.Accent or Theme.SecondaryBackground
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = frm
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(1, 0)
    bc.Parent = btn
    
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = stateVal and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Parent = btn
    local kc = Instance.new("UICorner")
    kc.CornerRadius = UDim.new(1, 0)
    kc.Parent = knob
    
    local function updateVisuals()
        local ti = TweenInfo.new(0.2, Enum.EasingStyle.Sine)
        Utils.tween(btn, ti, {BackgroundColor3 = stateVal and Theme.Accent or Theme.SecondaryBackground})
        Utils.tween(knob, ti, {Position = stateVal and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)})
    end
    
    -- Smooth hover transition
    frm.MouseEnter:Connect(function()
        Utils.tween(frm, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {BackgroundColor3 = Theme.SecondaryBackground})
        Utils.tween(lbl, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {TextColor3 = Theme.TextPrimary})
    end)
    frm.MouseLeave:Connect(function()
        Utils.tween(frm, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {BackgroundColor3 = Theme.PanelBackground})
        Utils.tween(lbl, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {TextColor3 = Theme.TextSecondary})
    end)
    
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
