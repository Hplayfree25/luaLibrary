local Label = {}

local import = function(name)
    local ok, res = pcall(function() return require(script.Parent[name]) end)
    if ok then return res end
    return _G.UniversalUILib_GetModule(name)
end

local Theme = import("Theme")
local Utils = import("Utils")

function Label.new(parent, text)
    local title = type(text) == "table" and (text.Name or text[1]) or text
    local desc = type(text) == "table" and (text.Desc or text[2]) or nil

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
    lbl.Size = desc and UDim2.new(1, -24, 0, 16) or UDim2.new(1, -24, 1, 0)
    lbl.Position = desc and UDim2.new(0, 12, 0, 8) or UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = title
    lbl.TextColor3 = Theme.TextPrimary
    lbl.Font = Theme.FontMedium
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frm
    
    local lblDesc
    if desc then
        lblDesc = Instance.new("TextLabel")
        lblDesc.Size = UDim2.new(1, -24, 0, 14)
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

    local self = {
        frame = frm,
        label = lbl,
        descLabel = lblDesc,
        set = function(newText)
            if type(newText) == "table" then
                if newText.Name then lbl.Text = newText.Name end
                if newText.Desc and lblDesc then lblDesc.Text = newText.Desc end
            else
                lbl.Text = newText
            end
        end,
        get = function() return lbl.Text end
    }
    return self
end

return Label
