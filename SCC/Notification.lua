local Notification = {}

local import = function(name)
    local ok, res = pcall(function() return require(script.Parent[name]) end)
    if ok then return res end
    return _G.UniversalUILib_GetModule(name)
end

local Theme = import("Theme")
local Utils = import("Utils")

local containerGui = nil
local listFrame = nil

local function getContainer()
    if containerGui and containerGui.Parent then
        return listFrame
    end
    
    containerGui = Instance.new("ScreenGui")
    containerGui.Name = "UniversalUINotify"
    containerGui.ResetOnSpawn = false
    containerGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    containerGui.Parent = Utils.getSafeGui()
    
    listFrame = Instance.new("Frame")
    listFrame.Size = UDim2.new(0, 280, 1, -40)
    listFrame.Position = UDim2.new(1, -20, 0, 20)
    listFrame.AnchorPoint = Vector2.new(1, 0)
    listFrame.BackgroundTransparency = 1
    listFrame.Parent = containerGui
    
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.Padding = UDim.new(0, 10)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = listFrame
    
    return listFrame
end

function Notification.show(config)
    if type(config) == "string" then
        config = { Title = "Notification", Content = config }
    end
    config = config or {}
    
    local title = config.Title or config.title or "Notification"
    local content = config.Content or config.content or ""
    local duration = config.Duration or config.duration or 4
    
    local parent = getContainer()
    
    -- Main Toast Card
    local card = Instance.new("Frame")
    card.Size = UDim2.new(0, 260, 0, 56)
    card.BackgroundColor3 = Theme.PanelBackground
    card.BackgroundTransparency = Theme.PanelTransparency
    card.Parent = parent
    
    local c = Instance.new("UICorner")
    c.CornerRadius = Theme.CornerRadius
    c.Parent = card
    
    local s = Instance.new("UIStroke")
    s.Color = Theme.Stroke
    s.Transparency = Theme.PanelStrokeTransparency
    s.Parent = card
    
    local lblTitle = Instance.new("TextLabel")
    lblTitle.Size = UDim2.new(1, -24, 0, 20)
    lblTitle.Position = UDim2.new(0, 12, 0, 6)
    lblTitle.BackgroundTransparency = 1
    lblTitle.Text = title
    lblTitle.TextColor3 = Theme.TextPrimary
    lblTitle.Font = Theme.FontBold
    lblTitle.TextSize = 11
    lblTitle.TextXAlignment = Enum.TextXAlignment.Left
    lblTitle.Parent = card
    
    local lblDesc = Instance.new("TextLabel")
    lblDesc.Size = UDim2.new(1, -24, 0, 24)
    lblDesc.Position = UDim2.new(0, 12, 0, 24)
    lblDesc.BackgroundTransparency = 1
    lblDesc.Text = content
    lblDesc.TextColor3 = Theme.TextSecondary
    lblDesc.Font = Theme.FontMedium
    lblDesc.TextSize = 10
    lblDesc.TextXAlignment = Enum.TextXAlignment.Left
    lblDesc.TextYAlignment = Enum.TextYAlignment.Top
    lblDesc.TextWrapped = true
    lblDesc.Parent = card
    
    -- Progress bar showing time left (Universal styling)
    local progressBg = Instance.new("Frame")
    progressBg.Size = UDim2.new(1, -24, 0, 2)
    progressBg.Position = UDim2.new(0, 12, 1, -5)
    progressBg.BackgroundColor3 = Theme.SecondaryBackground
    progressBg.BackgroundTransparency = 0.5
    progressBg.Parent = card
    
    local progressFill = Instance.new("Frame")
    progressFill.Size = UDim2.new(1, 0, 1, 0)
    progressFill.BackgroundColor3 = Theme.Accent
    progressFill.Parent = progressBg
    
    local pCorner = Instance.new("UICorner")
    pCorner.CornerRadius = UDim.new(1, 0)
    pCorner.Parent = progressBg
    local fCorner = Instance.new("UICorner")
    fCorner.CornerRadius = UDim.new(1, 0)
    fCorner.Parent = progressFill

    -- Hide initially for animate-in
    card.Size = UDim2.new(0, 260, 0, 0)
    card.BackgroundTransparency = 1
    s.Transparency = 1
    lblTitle.TextTransparency = 1
    lblDesc.TextTransparency = 1
    progressBg.BackgroundTransparency = 1
    progressFill.BackgroundTransparency = 1
    
    task.spawn(function()
        -- Animate In (Fade + Expand Height)
        Utils.tween(card, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 260, 0, 56),
            BackgroundTransparency = Theme.PanelTransparency
        })
        Utils.tween(s, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = Theme.PanelStrokeTransparency})
        Utils.tween(lblTitle, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0})
        Utils.tween(lblDesc, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0})
        Utils.tween(progressBg, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.5})
        Utils.tween(progressFill, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0})
        
        task.wait(0.3)
        
        -- Smooth progress bar countdown
        local shrinkTween = Utils.tween(progressFill, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
            Size = UDim2.new(0, 0, 1, 0)
        })
        shrinkTween.Completed:Wait()
        
        -- Animate Out (Fade + Collapse Height)
        Utils.tween(card, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 260, 0, 0),
            BackgroundTransparency = 1
        })
        Utils.tween(s, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1})
        Utils.tween(lblTitle, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1})
        Utils.tween(lblDesc, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1})
        Utils.tween(progressBg, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
        Utils.tween(progressFill, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
        
        task.wait(0.3)
        card:Destroy()
    end)
end

return Notification
