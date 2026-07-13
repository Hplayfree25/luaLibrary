local Auth = {}

local import = function(name)
    local ok, res = pcall(function() return require(script.Parent[name]) end)
    if ok then return res end
    return _G.UniversalUILib_GetModule(name)
end

local Theme = import("Theme")
local Utils = import("Utils")
local Drag = import("Drag")

function Auth.show(config)
    config = type(config) == "table" and config or {}
    local titleText = tostring(config.Title or "AUTH")
    local subtitleText = tostring(config.Subtitle or "Please enter your key.")
    local placeholder = tostring(config.KeyPlaceholder or "Enter Key...")
    local submitText = tostring(config.SubmitText or "Verify Key")
    local onSubmit = config.OnSubmit
    local links = type(config.Links) == "table" and config.Links or {}

    local ts = Utils.safeSvc("TweenService")
    local uis = Utils.safeSvc("UserInputService")
    local guiService = Utils.safeSvc("GuiService")
    local parent = Utils.getSafeGui()
    if not parent then return end

    local previousSelection = guiService.SelectedObject
    local gui = Instance.new("ScreenGui")
    gui.Name = "NMZUI_AUTH"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 200
    gui.Parent = parent

    local overlay = Instance.new("TextButton")
    overlay.Name = "ModalOverlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 1
    overlay.BorderSizePixel = 0
    overlay.Text = ""
    overlay.AutoButtonColor = false
    overlay.Active = true
    overlay.Modal = true
    overlay.Selectable = false
    overlay.Parent = gui

    local main = Instance.new("Frame")
    main.Size = UDim2.new(1, -32, 0, 0)
    main.Position = UDim2.new(0.5, 0, 0.5, 0)
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.AutomaticSize = Enum.AutomaticSize.Y
    main.BackgroundColor3 = Theme.Background
    main.BackgroundTransparency = Theme.BackgroundTransparency
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.Parent = overlay

    local sizeConstraint = Instance.new("UISizeConstraint")
    sizeConstraint.MaxSize = Vector2.new(400, 10000)
    sizeConstraint.Parent = main

    local scale = Instance.new("UIScale")
    scale.Scale = 0.92
    scale.Parent = main

    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.Stroke
    stroke.Thickness = 1
    stroke.Transparency = Theme.PanelStrokeTransparency
    stroke.Parent = main

    local corner = Instance.new("UICorner")
    corner.CornerRadius = Theme.WindowCornerRadius
    corner.Parent = main

    local mainLayout = Instance.new("UIListLayout")
    mainLayout.SortOrder = Enum.SortOrder.LayoutOrder
    mainLayout.Padding = UDim.new(0, Theme.SpacingMD)
    mainLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    mainLayout.Parent = main

    local mainPad = Instance.new("UIPadding")
    mainPad.PaddingTop = UDim.new(0, Theme.SpacingXL)
    mainPad.PaddingBottom = UDim.new(0, Theme.SpacingXL)
    mainPad.PaddingLeft = UDim.new(0, Theme.SpacingLG)
    mainPad.PaddingRight = UDim.new(0, Theme.SpacingLG)
    mainPad.Parent = main

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 0)
    title.AutomaticSize = Enum.AutomaticSize.Y
    title.BackgroundTransparency = 1
    title.Text = titleText
    title.TextColor3 = Theme.TextPrimary
    title.Font = Theme.FontBold
    title.TextSize = 18
    title.TextWrapped = true
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.LayoutOrder = 1
    title.Parent = main

    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, 0, 0, 0)
    subtitle.AutomaticSize = Enum.AutomaticSize.Y
    subtitle.BackgroundTransparency = 1
    subtitle.Text = subtitleText
    subtitle.TextColor3 = Theme.TextSecondary
    subtitle.Font = Theme.FontMedium
    subtitle.TextSize = 13
    subtitle.TextWrapped = true
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.TextYAlignment = Enum.TextYAlignment.Top
    subtitle.LayoutOrder = 2
    subtitle.Parent = main

    local inputContainer = Instance.new("Frame")
    inputContainer.Size = UDim2.new(1, 0, 0, 42)
    inputContainer.BackgroundColor3 = Theme.Surface
    inputContainer.BorderSizePixel = 0
    inputContainer.LayoutOrder = 3
    inputContainer.Parent = main

    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = Theme.CornerRadius
    inputCorner.Parent = inputContainer

    local inputStroke = Instance.new("UIStroke")
    inputStroke.Color = Theme.Focus
    inputStroke.Thickness = 1
    inputStroke.Transparency = 0.75
    inputStroke.Parent = inputContainer

    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(1, -Theme.SpacingLG * 2, 1, 0)
    textBox.Position = UDim2.new(0, Theme.SpacingLG, 0, 0)
    textBox.BackgroundTransparency = 1
    textBox.Text = ""
    textBox.PlaceholderText = placeholder
    textBox.PlaceholderColor3 = Theme.TextMuted
    textBox.TextColor3 = Theme.TextPrimary
    textBox.Font = Theme.FontMedium
    textBox.TextSize = 14
    textBox.TextXAlignment = Enum.TextXAlignment.Left
    textBox.ClearTextOnFocus = false
    textBox.Selectable = true
    textBox.Parent = inputContainer

    local submitBtn = Instance.new("TextButton")
    submitBtn.Size = UDim2.new(1, 0, 0, 42)
    submitBtn.BackgroundColor3 = Theme.Accent
    submitBtn.BorderSizePixel = 0
    submitBtn.Text = submitText
    submitBtn.TextColor3 = Theme.Background
    submitBtn.Font = Theme.FontBold
    submitBtn.TextSize = 14
    submitBtn.AutoButtonColor = false
    submitBtn.Selectable = true
    submitBtn.LayoutOrder = 4
    submitBtn.Parent = main

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = Theme.CornerRadius
    buttonCorner.Parent = submitBtn

    submitBtn.MouseEnter:Connect(function()
        ts:Create(submitBtn, TweenInfo.new(0.2), { BackgroundColor3 = Theme.AccentHover }):Play()
    end)
    submitBtn.MouseLeave:Connect(function()
        ts:Create(submitBtn, TweenInfo.new(0.2), { BackgroundColor3 = Theme.Accent }):Play()
    end)

    local selectionObjects = { textBox, submitBtn }

    if #links > 0 then
        local linkContainer = Instance.new("Frame")
        linkContainer.Size = UDim2.new(1, 0, 0, 0)
        linkContainer.AutomaticSize = Enum.AutomaticSize.Y
        linkContainer.BackgroundTransparency = 1
        linkContainer.LayoutOrder = 5
        linkContainer.Parent = main

        local linkLayout = Instance.new("UIGridLayout")
        linkLayout.CellSize = #links == 1 and UDim2.new(1, 0, 0, 34) or UDim2.new(0.5, -Theme.SpacingXS, 0, 34)
        linkLayout.CellPadding = UDim2.new(0, Theme.SpacingSM, 0, Theme.SpacingSM)
        linkLayout.SortOrder = Enum.SortOrder.LayoutOrder
        linkLayout.Parent = linkContainer

        for i, linkData in ipairs(links) do
            if type(linkData) == "table" then
                local linkBtn = Instance.new("TextButton")
                linkBtn.Size = UDim2.new(1, 0, 1, 0)
                linkBtn.BackgroundColor3 = Theme.Surface
                linkBtn.BorderSizePixel = 0
                linkBtn.Text = ""
                linkBtn.AutoButtonColor = false
                linkBtn.Selectable = true
                linkBtn.LayoutOrder = i
                linkBtn.Parent = linkContainer
                table.insert(selectionObjects, linkBtn)

                local linkCorner = Instance.new("UICorner")
                linkCorner.CornerRadius = Theme.CornerRadius
                linkCorner.Parent = linkBtn

                local linkStroke = Instance.new("UIStroke")
                linkStroke.Color = Theme.Stroke
                linkStroke.Transparency = Theme.PanelStrokeTransparency
                linkStroke.Parent = linkBtn

                local icon
                local textXOffset = Theme.SpacingSM
                if linkData.Icon then
                    icon = Instance.new("ImageLabel")
                    icon.Size = UDim2.new(0, 14, 0, 14)
                    icon.Position = UDim2.new(0, Theme.SpacingMD, 0.5, -7)
                    icon.BackgroundTransparency = 1
                    icon.Image = linkData.Icon
                    icon.ImageColor3 = Theme.TextSecondary
                    icon.Parent = linkBtn
                    textXOffset = 32
                end

                local linkLabel = Instance.new("TextLabel")
                linkLabel.Size = UDim2.new(1, -textXOffset - Theme.SpacingSM, 1, 0)
                linkLabel.Position = UDim2.new(0, textXOffset, 0, 0)
                linkLabel.BackgroundTransparency = 1
                linkLabel.Text = tostring(linkData.Name or "Link")
                linkLabel.TextColor3 = Theme.TextSecondary
                linkLabel.Font = Theme.FontMedium
                linkLabel.TextSize = 11
                linkLabel.TextTruncate = Enum.TextTruncate.AtEnd
                linkLabel.Parent = linkBtn

                linkBtn.MouseEnter:Connect(function()
                    ts:Create(linkBtn, TweenInfo.new(0.2), { BackgroundColor3 = Theme.SurfaceHover }):Play()
                    ts:Create(linkLabel, TweenInfo.new(0.2), { TextColor3 = Theme.TextPrimary }):Play()
                    if icon then ts:Create(icon, TweenInfo.new(0.2), { ImageColor3 = Theme.TextPrimary }):Play() end
                end)
                linkBtn.MouseLeave:Connect(function()
                    ts:Create(linkBtn, TweenInfo.new(0.2), { BackgroundColor3 = Theme.Surface }):Play()
                    ts:Create(linkLabel, TweenInfo.new(0.2), { TextColor3 = Theme.TextSecondary }):Play()
                    if icon then ts:Create(icon, TweenInfo.new(0.2), { ImageColor3 = Theme.TextSecondary }):Play() end
                end)
                linkBtn.Activated:Connect(function()
                    if type(linkData.OnClick) == "function" then
                        local ok, err = pcall(linkData.OnClick, linkLabel)
                        if not ok then warn("Auth link failed: " .. tostring(err)) end
                    end
                end)
            end
        end
    end

    for i, object in ipairs(selectionObjects) do
        local previous = selectionObjects[i - 1] or selectionObjects[#selectionObjects]
        local nextObject = selectionObjects[i + 1] or selectionObjects[1]
        object.NextSelectionUp = previous
        object.NextSelectionLeft = previous
        object.NextSelectionDown = nextObject
        object.NextSelectionRight = nextObject
    end

    local isLoading = false
    local closing = false

    local function closeAuth()
        if closing then return end
        closing = true
        local selected = guiService.SelectedObject
        if selected and selected:IsDescendantOf(gui) then
            guiService.SelectedObject = previousSelection and previousSelection.Parent and previousSelection or nil
        end
        ts:Create(overlay, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
        local tween = ts:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.92 })
        tween:Play()
        tween.Completed:Connect(function()
            if gui.Parent then gui:Destroy() end
        end)
    end

    local function resetSubmit(failed)
        if closing then return end
        isLoading = false
        submitBtn.Text = submitText
        submitBtn.BackgroundColor3 = Theme.Accent
        submitBtn.TextColor3 = Theme.Background
        textBox.TextEditable = true
        if failed then
            inputStroke.Color = Theme.Error
            inputStroke.Transparency = 0
            task.delay(0.6, function()
                if inputStroke.Parent and not textBox:IsFocused() then
                    Utils.tween(inputStroke, TweenInfo.new(0.2), { Color = Theme.Focus, Transparency = 0.75 })
                end
            end)
        end
    end

    local function doSubmit()
        if isLoading or closing then return end
        isLoading = true
        submitBtn.Text = "Verifying..."
        submitBtn.BackgroundColor3 = Theme.Surface
        submitBtn.TextColor3 = Theme.TextSecondary
        textBox.TextEditable = false

        if type(onSubmit) ~= "function" then
            closeAuth()
            return
        end

        local settled = false
        local function finish(success)
            if settled or closing then return end
            settled = true
            task.defer(function()
                if closing then return end
                if success then
                    submitBtn.Text = "Success"
                    submitBtn.BackgroundColor3 = Theme.Success
                    submitBtn.TextColor3 = Theme.Background
                    task.delay(0.5, closeAuth)
                else
                    resetSubmit(true)
                end
            end)
        end

        task.spawn(function()
            local ok, result = pcall(onSubmit, textBox.Text, finish)
            if not ok then
                warn("Auth submit failed: " .. tostring(result))
                finish(false)
            elseif type(result) == "boolean" then
                finish(result)
            end
        end)
    end

    submitBtn.Activated:Connect(doSubmit)

    textBox.Focused:Connect(function()
        ts:Create(inputStroke, TweenInfo.new(0.2), { Color = Theme.Focus, Transparency = 0 }):Play()
    end)
    textBox.FocusLost:Connect(function(enterPressed)
        ts:Create(inputStroke, TweenInfo.new(0.2), { Color = Theme.Focus, Transparency = 0.75 }):Play()
        if enterPressed then doSubmit() end
    end)

    ts:Create(overlay, TweenInfo.new(0.35), { BackgroundTransparency = 0.28 }):Play()
    ts:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 }):Play()

    Drag.makeDraggable(main)
    if uis.GamepadEnabled then
        task.defer(function()
            if gui.Parent then guiService.SelectedObject = submitBtn end
        end)
    end

    return { Close = closeAuth }
end

return Auth
