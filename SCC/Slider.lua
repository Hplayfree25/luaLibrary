local Slider = {}

local import = function(name)
    local ok, res = pcall(function() return require(script.Parent[name]) end)
    if ok then return res end
    return _G.UniversalUILib_GetModule(name)
end

local Theme = import("Theme")
local Utils = import("Utils")

function Slider.new(parent, name, minVal, maxVal, defaultVal, formatFunc, cb)
    local uis = Utils.safeSvc("UserInputService")
    local formatVal = formatFunc or function(v) return tostring(v) end
    
    local frm = Instance.new("Frame")
    frm.Size = UDim2.new(1, 0, 0, 48)
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
    lbl.Size = UDim2.new(1, -24, 0, 20)
    lbl.Position = UDim2.new(0, 12, 0, 6)
    lbl.BackgroundTransparency = 1
    lbl.Text = name .. ": " .. formatVal(defaultVal)
    lbl.TextColor3 = Theme.TextSecondary
    lbl.Font = Theme.FontMedium
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frm
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, -24, 0, 5)
    bg.Position = UDim2.new(0, 12, 0, 32)
    bg.BackgroundColor3 = Theme.SecondaryBackground
    bg.Parent = frm
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(1, 0)
    bc.Parent = bg
    local fil = Instance.new("Frame")
    local pct = (defaultVal - minVal) / (maxVal - minVal)
    fil.Size = UDim2.new(pct, 0, 1, 0)
    fil.BackgroundColor3 = Theme.Accent
    fil.Parent = bg
    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(1, 0)
    fc.Parent = fil
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = bg
    
    local sliding = false
    local currentVal = defaultVal
    
    local function updateSlider(inputPos)
        local p = math.clamp(inputPos.X - bg.AbsolutePosition.X, 0, bg.AbsoluteSize.X) / bg.AbsoluteSize.X
        currentVal = minVal + (maxVal - minVal) * p
        fil.Size = UDim2.new(p, 0, 1, 0)
        lbl.Text = name .. ": " .. formatVal(currentVal)
        if cb then cb(currentVal) end
    end
    
    -- Smooth hover transitions
    frm.MouseEnter:Connect(function()
        Utils.tween(frm, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {BackgroundColor3 = Theme.SecondaryBackground})
        Utils.tween(lbl, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {TextColor3 = Theme.TextPrimary})
        Utils.tween(fil, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {BackgroundColor3 = Theme.AccentHover})
    end)
    frm.MouseLeave:Connect(function()
        Utils.tween(frm, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {BackgroundColor3 = Theme.PanelBackground})
        Utils.tween(lbl, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {TextColor3 = Theme.TextSecondary})
        Utils.tween(fil, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {BackgroundColor3 = Theme.Accent})
    end)
    
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            updateSlider(input.Position)
        end
    end)
    uis.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = false
        end
    end)
    uis.InputChanged:Connect(function(input)
        if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input.Position)
        end
    end)
    
    local self = {
        frame = frm,
        set = function(val)
            currentVal = math.clamp(val, minVal, maxVal)
            local p = (currentVal - minVal) / (maxVal - minVal)
            fil.Size = UDim2.new(p, 0, 1, 0)
            lbl.Text = name .. ": " .. formatVal(currentVal)
            if cb then cb(currentVal) end
        end,
        get = function() return currentVal end
    }
    return self
end

return Slider
