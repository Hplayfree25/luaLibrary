local Dropdown = {}
local Theme = require(script.Parent.Theme)
local Utils = require(script.Parent.Utils)

function Dropdown.new(parent, name, opts, defaultIdx, cb)
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
    lbl.Size = UDim2.new(0.5, 0, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = Theme.TextSecondary
    lbl.Font = Theme.FontMedium
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frm
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 100, 0, 22)
    btn.Position = UDim2.new(1, -112, 0.5, -11)
    btn.BackgroundColor3 = Theme.SecondaryBackground
    btn.Text = opts[defaultIdx].name
    btn.TextColor3 = Theme.TextPrimary
    btn.Font = Theme.FontBold
    btn.TextSize = 11
    btn.Parent = frm
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 6)
    bc.Parent = btn
    
    local cur = defaultIdx
    
    btn.MouseButton1Click:Connect(function()
        cur = cur + 1
        if cur > #opts then cur = 1 end
        btn.Text = opts[cur].name
        if cb then cb(opts[cur].val) end
    end)
    
    local self = {
        frame = frm,
        button = btn,
        setOptions = function(newOpts, newDefaultIdx)
            opts = newOpts
            cur = newDefaultIdx or 1
            btn.Text = opts[cur].name
            if cb then cb(opts[cur].val) end
        end,
        get = function() return opts[cur].val end
    }
    return self
end

return Dropdown
