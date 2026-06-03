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
    frm.Size = UDim2.new(1, 0, 0, 0)
    frm.AutomaticSize = Enum.AutomaticSize.Y
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
    
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 4)
    layout.Parent = frm
    
    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 10)
    pad.PaddingBottom = UDim.new(0, 10)
    pad.PaddingLeft = UDim.new(0, 12)
    pad.PaddingRight = UDim.new(0, 12)
    pad.Parent = frm
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 0)
    lbl.AutomaticSize = Enum.AutomaticSize.Y
    lbl.BackgroundTransparency = 1
    lbl.Text = title
    lbl.TextColor3 = Theme.TextPrimary
    lbl.Font = Theme.FontMedium
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextYAlignment = Enum.TextYAlignment.Top
    lbl.TextWrapped = true
    lbl.LayoutOrder = 1
    lbl.Parent = frm
    
    local lblDesc
    if desc then
        lblDesc = Instance.new("TextLabel")
        lblDesc.Size = UDim2.new(1, 0, 0, 0)
        lblDesc.AutomaticSize = Enum.AutomaticSize.Y
        lblDesc.BackgroundTransparency = 1
        lblDesc.Text = desc
        lblDesc.TextColor3 = Theme.TextSecondary
        lblDesc.TextTransparency = 0.4
        lblDesc.Font = Theme.FontMedium
        lblDesc.TextSize = 11
        lblDesc.TextXAlignment = Enum.TextXAlignment.Left
        lblDesc.TextYAlignment = Enum.TextYAlignment.Top
        lblDesc.TextWrapped = true
        lblDesc.LayoutOrder = 2
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
