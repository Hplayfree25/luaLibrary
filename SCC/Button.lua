local Button = {}

local import = function(name)
    local ok, res = pcall(function() return require(script.Parent[name]) end)
    if ok then return res end
    return _G.UniversalUILib_GetModule(name)
end

local Theme = import("Theme")
local Utils = import("Utils")

function Button.new(parent, name, cb)
    local text = type(name) == "table" and (name.Name or name[1]) or name
    local desc = type(name) == "table" and (name.Desc or name[2]) or nil

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
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = frm
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = desc and UDim2.new(1, 0, 0, 16) or UDim2.new(1, 0, 1, 0)
    lbl.Position = desc and UDim2.new(0, 0, 0, 8) or UDim2.new(0, 0, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Theme.TextSecondary
    lbl.Font = Theme.FontMedium
    lbl.TextSize = 12
    lbl.Parent = frm
    
    if desc then
        local lblDesc = Instance.new("TextLabel")
        lblDesc.Size = UDim2.new(1, 0, 0, 14)
        lblDesc.Position = UDim2.new(0, 0, 0, 26)
        lblDesc.BackgroundTransparency = 1
        lblDesc.Text = desc
        lblDesc.TextColor3 = Theme.TextSecondary
        lblDesc.TextTransparency = 0.4
        lblDesc.Font = Theme.FontMedium
        lblDesc.TextSize = 11
        lblDesc.Parent = frm
    end
    
    -- Smooth hover transition
    btn.MouseEnter:Connect(function()
        Utils.tween(frm, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
            BackgroundColor3 = Theme.SecondaryBackground
        })
        Utils.tween(lbl, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
            TextColor3 = Theme.TextPrimary
        })
    end)
    btn.MouseLeave:Connect(function()
        Utils.tween(frm, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
            BackgroundColor3 = Theme.PanelBackground
        })
        Utils.tween(lbl, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
            TextColor3 = Theme.TextSecondary
        })
    end)
    
    btn.MouseButton1Click:Connect(function()
        local ti = TweenInfo.new(0.1, Enum.EasingStyle.Sine)
        Utils.tween(frm, ti, {BackgroundColor3 = Theme.Accent})
        task.delay(0.1, function()
            pcall(function() 
                Utils.tween(frm, ti, {
                    BackgroundColor3 = (btn.Active and Theme.SecondaryBackground) or Theme.PanelBackground
                }) 
            end)
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
