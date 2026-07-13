local Keybind = {}

local import = function(name)
	local ok, res = pcall(function() return require(script.Parent[name]) end)
	if ok then return res end
	return _G.UniversalUILib_GetModule(name)
end

local DefaultTheme = import("Theme")
local Utils = import("Utils")
local uis = Utils.safeSvc("UserInputService")

local function context(parent)
	if type(parent) == "table" then
		return parent.container, (parent.window and parent.window.theme) or DefaultTheme
	end
	return parent, DefaultTheme
end

local function keyName(key)
	local name = key and key.Name or "None"
	return ({ MouseButton1 = "MB1", MouseButton2 = "MB2", MouseButton3 = "MB3" })[name] or name
end

function Keybind.new(parent, name, defaultKey, cb)
	local container, Theme = context(parent)
	local text = type(name) == "table" and (name.Name or name[1]) or name
	local desc = type(name) == "table" and (name.Desc or name[2]) or nil
	local callback = type(name) == "table" and (name.Callback or cb) or cb
	local currentKey = defaultKey or Enum.KeyCode.E
	local isBinding, disabled, lastCapture = false, false, 0
	local hovered, selected, connections = false, false, {}
	local function connect(signal, fn)
		local connection = signal:Connect(fn)
		table.insert(connections, connection)
		return connection
	end

	local frm = Instance.new("Frame")
	frm.Size = UDim2.new(1, 0, 0, 44)
	frm.AutomaticSize = Enum.AutomaticSize.Y
	frm.BackgroundColor3 = Theme.Surface or Theme.PanelBackground
	frm.BackgroundTransparency = Theme.PanelTransparency
	frm.BorderSizePixel = 0
	frm.Parent = container
	local corner = Instance.new("UICorner")
	corner.CornerRadius = Theme.CardCornerRadius or UDim.new(0, 14)
	corner.Parent = frm
	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Stroke
	stroke.Transparency = Theme.PanelStrokeTransparency
	stroke.Parent = frm

	local content = Instance.new("Frame")
	content.Size = UDim2.new(1, -116, 0, 44)
	content.AutomaticSize = Enum.AutomaticSize.Y
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	content.Parent = frm
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 3)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = content
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, desc and 11 or 14)
	padding.PaddingBottom = UDim.new(0, desc and 11 or 14)
	padding.PaddingLeft = UDim.new(0, 14)
	padding.Parent = content

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, 0)
	lbl.AutomaticSize = Enum.AutomaticSize.Y
	lbl.BackgroundTransparency = 1
	lbl.BorderSizePixel = 0
	lbl.Text = tostring(text or "Keybind")
	lbl.TextColor3 = Theme.TextSecondary
	lbl.Font = Theme.FontMedium
	lbl.TextSize = 13
	lbl.TextWrapped = true
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextYAlignment = Enum.TextYAlignment.Top
	lbl.LayoutOrder = 1
	lbl.Parent = content

	if desc then
		local description = Instance.new("TextLabel")
		description.Size = UDim2.new(1, 0, 0, 0)
		description.AutomaticSize = Enum.AutomaticSize.Y
		description.BackgroundTransparency = 1
		description.BorderSizePixel = 0
		description.Text = tostring(desc)
		description.TextColor3 = Theme.TextMuted
		description.Font = Theme.FontMedium
		description.TextSize = 11
		description.TextWrapped = true
		description.TextXAlignment = Enum.TextXAlignment.Left
		description.TextYAlignment = Enum.TextYAlignment.Top
		description.LayoutOrder = 2
		description.Parent = content
	end

	local bindBtn = Instance.new("TextButton")
	bindBtn.Size = UDim2.fromOffset(88, 34)
	bindBtn.AnchorPoint = Vector2.new(1, 0.5)
	bindBtn.Position = UDim2.new(1, -14, 0.5, 0)
	bindBtn.BackgroundColor3 = Theme.SecondaryBackground
	bindBtn.BorderSizePixel = 0
	bindBtn.Text = keyName(currentKey)
	bindBtn.TextColor3 = Theme.TextPrimary
	bindBtn.Font = Theme.FontMedium
	bindBtn.TextSize = 11
	bindBtn.TextTruncate = Enum.TextTruncate.AtEnd
	bindBtn.AutoButtonColor = false
	bindBtn.Selectable = true
	bindBtn.Parent = frm
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = Theme.FieldCornerRadius or Theme.CornerRadius
	btnCorner.Parent = bindBtn
	local btnStroke = Instance.new("UIStroke")
	btnStroke.Color = Theme.Stroke
	btnStroke.Transparency = Theme.PanelStrokeTransparency
	btnStroke.Parent = bindBtn

	local function render()
		bindBtn.Text = isBinding and "Press a key..." or keyName(currentKey)
		bindBtn.BackgroundColor3 = isBinding and Theme.Accent or Theme.SecondaryBackground
		bindBtn.TextColor3 = disabled and Theme.TextMuted or (isBinding and Theme.Background or Theme.TextPrimary)
		btnStroke.Transparency = isBinding and (Theme.FocusStrokeTransparency or 0.28) or Theme.PanelStrokeTransparency
	end
	local function refresh()
		local on = not disabled and (hovered or selected or isBinding)
		frm.BackgroundColor3 = on and (Theme.SurfaceHover or Theme.SecondaryBackground) or (Theme.Surface or Theme.PanelBackground)
		lbl.TextColor3 = disabled and Theme.TextMuted or (on and Theme.TextPrimary or Theme.TextSecondary)
		stroke.Transparency = on and (Theme.HoverStrokeTransparency or 0.5) or Theme.PanelStrokeTransparency
		if not isBinding then
			btnStroke.Transparency = on and (Theme.HoverStrokeTransparency or 0.5) or Theme.PanelStrokeTransparency
		end
	end
	local function beginBinding()
		if disabled or isBinding then return end
		isBinding = true
		render()
		refresh()
	end
	local function finishBinding(key)
		if key then
			currentKey = key
			lastCapture = os.clock()
		end
		isBinding = false
		render()
		refresh()
	end

	connect(bindBtn.Activated, beginBinding)
	connect(bindBtn.MouseEnter, function() hovered = true refresh() end)
	connect(bindBtn.MouseLeave, function() hovered = false refresh() end)
	connect(bindBtn.SelectionGained, function() selected = true refresh() end)
	connect(bindBtn.SelectionLost, function() selected = false refresh() end)
	connect(uis.InputBegan, function(input, gameProcessed)
		if disabled then return end
		if isBinding then
			if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB then
				finishBinding()
			elseif input.UserInputType == Enum.UserInputType.Keyboard then
				finishBinding(input.KeyCode)
			elseif input.UserInputType == Enum.UserInputType.Gamepad1 then
				finishBinding(input.KeyCode)
			elseif input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.MouseButton2
				or input.UserInputType == Enum.UserInputType.MouseButton3 then
				finishBinding(input.UserInputType)
			end
		elseif not gameProcessed and os.clock() - lastCapture > 0.1
			and (input.KeyCode == currentKey or input.UserInputType == currentKey) then
			if callback then callback() end
		end
	end)

	local self = { frame = frm, button = bindBtn }
	self.set = function(newKey)
		assert(newKey ~= nil and newKey.Name ~= nil, "Keybind value must be an EnumItem")
		finishBinding(newKey)
	end
	self.get = function() return currentKey end
	function self.setDisabled(value)
		disabled = not not value
		bindBtn.Active = not disabled
		bindBtn.Selectable = not disabled
		if disabled then isBinding = false end
		render()
		refresh()
	end
	function self.destroy()
		for _, connection in ipairs(connections) do connection:Disconnect() end
		if frm.Parent then frm:Destroy() end
	end
	return self
end

return Keybind
