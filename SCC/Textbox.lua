local Textbox = {}

local import = function(name)
    local ok, res = pcall(function() return require(script.Parent[name]) end)
    if ok then return res end
    return _G.UniversalUILib_GetModule(name)
end

local Theme = import("Theme")
local Utils = import("Utils")

function Textbox.new(parent, name, placeholderText, cb)
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
    lbl.Size = UDim2.new(0.4, 0, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = Theme.TextSecondary
    lbl.Font = Theme.FontMedium
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frm
    
    local boxBg = Instance.new("Frame")
    boxBg.Size = UDim2.new(0.5, 0, 0, 24)
    boxBg.Position = UDim2.new(1, -boxBg.Size.X.Offset - (boxBg.Size.X.Scale * frm.AbsoluteSize.X) - 12, 0.5, -12)
    boxBg.BackgroundColor3 = Theme.SecondaryBackground
    boxBg.Parent = frm
    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 6)
    boxCorner.Parent = boxBg
    
    frm:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        boxBg.Position = UDim2.new(1, -boxBg.Size.X.Offset - (boxBg.Size.X.Scale * frm.AbsoluteSize.X) - 12, 0.5, -12)
    end)
    
    local txt = Instance.new("TextBox")
    txt.Size = UDim2.new(1, -10, 1, 0)
    txt.Position = UDim2.new(0, 5, 0, 0)
    txt.BackgroundTransparency = 1
    txt.Text = ""
    txt.PlaceholderText = placeholderText or "Enter text..."
    txt.PlaceholderColor3 = Theme.TextMuted
    txt.TextColor3 = Theme.TextPrimary
    txt.Font = Theme.FontMedium
    txt.TextSize = 12
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.ClearTextOnFocus = false
    txt.Parent = boxBg
    
    txt.FocusLost:Connect(function(enterPressed)
        if cb then cb(txt.Text, enterPressed) end
    end)
    
    local self = {
        frame = frm,
        textbox = txt,
        get = function() return txt.Text end,
        set = function(text) txt.Text = text end
    }
    return self
end

return Textbox
