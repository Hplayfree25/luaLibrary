local Auth = {}
local Theme = require(script.Parent.Theme)
local Utils = require(script.Parent.Utils)
local Drag = require(script.Parent.Drag)

function Auth.show(config)
    config = config or {}
    local titleText = config.Title or "AUTH"
    local subtitleText = config.Subtitle or "Please enter your key."
    local placeholder = config.KeyPlaceholder or "Enter Key..."
    local submitText = config.SubmitText or "Verify Key"
    local onSubmit = config.OnSubmit
    local links = config.Links or {}

    local ts = Utils.safeSvc("TweenService")
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "NMZUI_AUTH"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true
    
    local parent = Utils.getSafeGui()
    if not parent then return end
    gui.Parent = parent

    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 1
    overlay.BorderSizePixel = 0
    overlay.Parent = gui

    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 0, 0, 0)
    main.Position = UDim2.new(0.5, 0, 0.5, 0)
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.BackgroundColor3 = Theme.Background
    main.BackgroundTransparency = Theme.BackgroundTransparency
    main.ClipsDescendants = true
    main.Parent = gui

    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.Accent
    stroke.Thickness = 1
    stroke.Transparency = 0.8
    stroke.Parent = main

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = main

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -40, 0, 30)
    title.Position = UDim2.new(0, 20, 0, 20)
    title.BackgroundTransparency = 1
    title.Text = titleText
    title.TextColor3 = Theme.TextPrimary
    title.Font = Theme.FontBold
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = main

    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, -40, 0, 20)
    subtitle.Position = UDim2.new(0, 20, 0, 50)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = subtitleText
    subtitle.TextColor3 = Theme.TextSecondary
    subtitle.Font = Theme.FontMedium
    subtitle.TextSize = 13
    subtitle.TextWrapped = true
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Parent = main

    local inputContainer = Instance.new("Frame")
    inputContainer.Size = UDim2.new(1, -40, 0, 45)
    inputContainer.Position = UDim2.new(0, 20, 0, 85)
    inputContainer.BackgroundColor3 = Theme.PanelBackground
    inputContainer.Parent = main
    
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 6)
    inputCorner.Parent = inputContainer
    
    local inputStroke = Instance.new("UIStroke")
    inputStroke.Color = Theme.Accent
    inputStroke.Thickness = 1
    inputStroke.Transparency = 0.9
    inputStroke.Parent = inputContainer

    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(1, -20, 1, 0)
    textBox.Position = UDim2.new(0, 10, 0, 0)
    textBox.BackgroundTransparency = 1
    textBox.Text = ""
    textBox.PlaceholderText = placeholder
    textBox.PlaceholderColor3 = Theme.TextSecondary
    textBox.TextColor3 = Theme.TextPrimary
    textBox.Font = Theme.FontMedium
    textBox.TextSize = 14
    textBox.TextXAlignment = Enum.TextXAlignment.Left
    textBox.ClearTextOnFocus = false
    textBox.Parent = inputContainer

    textBox.Focused:Connect(function()
        ts:Create(inputStroke, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Transparency = 0}):Play()
    end)
    textBox.FocusLost:Connect(function()
        ts:Create(inputStroke, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Transparency = 0.9}):Play()
    end)

    local submitBtn = Instance.new("TextButton")
    submitBtn.Size = UDim2.new(1, -40, 0, 40)
    submitBtn.Position = UDim2.new(0, 20, 0, 145)
    submitBtn.BackgroundColor3 = Theme.Accent
    submitBtn.Text = submitText
    submitBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    submitBtn.Font = Theme.FontBold
    submitBtn.TextSize = 14
    submitBtn.AutoButtonColor = false
    submitBtn.Parent = main

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = submitBtn

    submitBtn.MouseEnter:Connect(function()
        ts:Create(submitBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.AccentHover}):Play()
    end)
    submitBtn.MouseLeave:Connect(function()
        ts:Create(submitBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Accent}):Play()
    end)

    local linkContainer = Instance.new("Frame")
    linkContainer.Size = UDim2.new(1, -40, 0, 20)
    linkContainer.Position = UDim2.new(0, 20, 0, 200)
    linkContainer.BackgroundTransparency = 1
    linkContainer.Parent = main
    
    local linkLayout = Instance.new("UIListLayout")
    linkLayout.FillDirection = Enum.FillDirection.Horizontal
    linkLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    linkLayout.SortOrder = Enum.SortOrder.LayoutOrder
    linkLayout.Padding = UDim.new(0, 15)
    linkLayout.Parent = linkContainer
    
    for i, linkData in ipairs(links) do
        local linkBtn = Instance.new("TextButton")
        linkBtn.Size = UDim2.new(0, 80, 1, 0)
        linkBtn.BackgroundTransparency = 1
        linkBtn.Text = linkData.Name or "Link"
        linkBtn.TextColor3 = Theme.TextSecondary
        linkBtn.Font = Theme.FontMedium
        linkBtn.TextSize = 12
        linkBtn.Parent = linkContainer
        
        linkBtn.MouseEnter:Connect(function()
            ts:Create(linkBtn, TweenInfo.new(0.2), {TextColor3 = Theme.TextPrimary}):Play()
        end)
        linkBtn.MouseLeave:Connect(function()
            ts:Create(linkBtn, TweenInfo.new(0.2), {TextColor3 = Theme.TextSecondary}):Play()
        end)
        
        linkBtn.MouseButton1Click:Connect(function()
            if linkData.OnClick then
                linkData.OnClick()
            end
        end)
    end

    ts:Create(overlay, TweenInfo.new(0.5), {BackgroundTransparency = 0.3}):Play()
    local targetHeight = #links > 0 and 240 or 210
    ts:Create(main, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 320, 0, targetHeight)}):Play()
    
    Drag.makeDraggable(main)

    local isLoading = false
    
    local function closeAuth()
        ts:Create(overlay, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
        local t = ts:Create(main, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)})
        t:Play()
        t.Completed:Wait()
        gui:Destroy()
    end

    submitBtn.MouseButton1Click:Connect(function()
        if isLoading then return end
        local key = textBox.Text
        
        isLoading = true
        submitBtn.Text = "Verifying..."
        submitBtn.BackgroundColor3 = Theme.PanelBackground
        submitBtn.TextColor3 = Theme.TextSecondary
        textBox.TextEditable = false
        
        if onSubmit then
            onSubmit(key, function(success)
                if success then
                    submitBtn.Text = "Success"
                    submitBtn.TextColor3 = Theme.Accent
                    task.wait(0.5)
                    closeAuth()
                else
                    isLoading = false
                    submitBtn.Text = submitText
                    submitBtn.BackgroundColor3 = Theme.Accent
                    submitBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
                    textBox.TextEditable = true
                end
            end)
        else
            closeAuth()
        end
    end)

    return {
        Close = closeAuth
    }
end

return Auth
