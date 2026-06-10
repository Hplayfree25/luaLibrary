local Keybind = {}

local import = function(name)
    local ok, res = pcall(function() return require(script.Parent[name]) end)
    if ok then return res end
    return _G.UniversalUILib_GetModule(name)
end

local Theme = import("Theme")
local Utils = import("Utils")
local uis = Utils.safeSvc("UserInputService")

function Keybind.new(parent, name, defaultKey, cb)
    local text = type(name) == "table" and (name.Name or name[1]) or name
    local desc = type(name) == "table" and (name.Desc or name[2]) or nil

    local currentKey = defaultKey or Enum.KeyCode.E
    local isBinding = false
    
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
    lbl.Size = desc and UDim2.new(0.6, 0, 0, 16) or UDim2.new(0.6, 0, 1, 0)
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
        lblDesc.Size = UDim2.new(0.6, 0, 0, 14)
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
    
    local bindBtn = Instance.new("TextButton")
    bindBtn.Size = UDim2.new(0, 80, 0, 20)
    bindBtn.Position = UDim2.new(1, -92, 0.5, -10)
    bindBtn.BackgroundColor3 = Theme.SecondaryBackground
    bindBtn.Text = currentKey.Name
    bindBtn.TextColor3 = Theme.TextPrimary
    bindBtn.Font = Theme.FontMedium
    bindBtn.TextSize = 11
    bindBtn.AutoButtonColor = false
    bindBtn.Parent = frm
    
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 4)
    bc.Parent = bindBtn
    
    local bs = Instance.new("UIStroke")
    bs.Color = Theme.Stroke
    bs.Transparency = 0.5
    bs.Parent = bindBtn
    
    -- Hover effect
    frm.MouseEnter:Connect(function()
        Utils.tween(frm, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {BackgroundColor3 = Theme.SecondaryBackground})
        Utils.tween(lbl, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {TextColor3 = Theme.TextPrimary})
    end)
    frm.MouseLeave:Connect(function()
        Utils.tween(frm, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {BackgroundColor3 = Theme.PanelBackground})
        Utils.tween(lbl, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {TextColor3 = Theme.TextSecondary})
    end)

    bindBtn.MouseEnter:Connect(function()
        if not isBinding then
            Utils.tween(bindBtn, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {BackgroundColor3 = Theme.Accent, TextColor3 = Color3.fromRGB(0, 0, 0)})
        end
    end)
    bindBtn.MouseLeave:Connect(function()
        if not isBinding then
            Utils.tween(bindBtn, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {BackgroundColor3 = Theme.SecondaryBackground, TextColor3 = Theme.TextPrimary})
        end
    end)
    
    bindBtn.MouseButton1Click:Connect(function()
        if isBinding then return end
        isBinding = true
        bindBtn.Text = "..."
        Utils.tween(bindBtn, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {BackgroundColor3 = Theme.Accent, TextColor3 = Color3.fromRGB(0, 0, 0)})
    end)
    
    uis.InputBegan:Connect(function(input, gp)
        if isBinding then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                local key = input.KeyCode
                if key == Enum.KeyCode.Escape then
                    isBinding = false
                    bindBtn.Text = currentKey.Name
                    Utils.tween(bindBtn, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {BackgroundColor3 = Theme.SecondaryBackground, TextColor3 = Theme.TextPrimary})
                    return
                end
                
                currentKey = key
                isBinding = false
                bindBtn.Text = currentKey.Name
                Utils.tween(bindBtn, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {BackgroundColor3 = Theme.SecondaryBackground, TextColor3 = Theme.TextPrimary})
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
                currentKey = input.UserInputType
                isBinding = false
                
                local name = currentKey.Name
                if name == "MouseButton1" then name = "MB1"
                elseif name == "MouseButton2" then name = "MB2"
                elseif name == "MouseButton3" then name = "MB3" end
                
                bindBtn.Text = name
                Utils.tween(bindBtn, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {BackgroundColor3 = Theme.SecondaryBackground, TextColor3 = Theme.TextPrimary})
            end
        else
            if not gp then
                if input.KeyCode == currentKey or input.UserInputType == currentKey then
                    if cb then cb() end
                end
            end
        end
    end)
    
    local self = {
        frame = frm,
        set = function(newKey)
            currentKey = newKey
            bindBtn.Text = currentKey.Name
        end,
        get = function() return currentKey end
    }
    return self
end

return Keybind
