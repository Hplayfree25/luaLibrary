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
	local connections = {}
	local function connect(signal, fn)
		local connection = signal:Connect(fn)
		table.insert(connections, connection)
		return connection
	end

	local frm = Instance.new("Frame")
	frm.Size = UDim2.new(1, 0, 0, desc and 64 or 48)
	frm.BackgroundColor3 = Theme.PanelBackground
	frm.BackgroundTransparency = Theme.PanelTransparency
	frm.Parent = container
	local corner = Instance.new("UICorner")
	corner.CornerRadius = Theme.CornerRadius
	corner.Parent = frm
	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Stroke
	stroke.Transparency = Theme.PanelStrokeTransparency
	stroke.Parent = frm

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -124, 0, desc and 22 or 28)
	lbl.Position = UDim2.new(0, 16, 0, desc and 10 or 10)
	lbl.BackgroundTransparency = 1
	lbl.Text = tostring(text or "Keybind")
	lbl.TextColor3 = Theme.TextSecondary
	lbl.Font = Theme.FontMedium
	lbl.TextSize = 13
	lbl.TextWrapped = true
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = frm

	if desc then
		local description = Instance.new("TextLabel")
		description.Size = UDim2.new(1, -124, 0, 22)
		description.Position = UDim2.new(0, 16, 0, 34)
		description.BackgroundTransparency = 1
		description.Text = tostring(desc)
		description.TextColor3 = Theme.TextMuted
		description.Font = Theme.FontMedium
		description.TextSize = 11
		description.TextWrapped = true
		description.TextXAlignment = Enum.TextXAlignment.Left
		description.Parent = frm
	end

	local bindBtn = Instance.new("TextButton")
	bindBtn.Size = UDim2.new(0, 92, 0, 36)
	bindBtn.Position = UDim2.new(1, -108, 0.5, -18)
	bindBtn.BackgroundColor3 = Theme.SecondaryBackground
	bindBtn.Text = keyName(currentKey)
	bindBtn.TextColor3 = Theme.TextPrimary
	bindBtn.Font = Theme.FontMedium
	bindBtn.TextSize = 11
	bindBtn.AutoButtonColor = false
	bindBtn.Selectable = true
	bindBtn.Parent = frm
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 5)
	btnCorner.Parent = bindBtn
	local btnStroke = Instance.new("UIStroke")
	btnStroke.Color = Theme.Stroke
	btnStroke.Transparency = Theme.PanelStrokeTransparency
	btnStroke.Parent = bindBtn

	local function render()
		bindBtn.Text = isBinding and "Press a key..." or keyName(currentKey)
		bindBtn.BackgroundColor3 = isBinding and Theme.Accent or Theme.SecondaryBackground
		bindBtn.TextColor3 = disabled and Theme.TextMuted or Theme.TextPrimary
		btnStroke.Color = isBinding and Theme.Accent or Theme.Stroke
	end
	local function beginBinding()
		if disabled or isBinding then return end
		isBinding = true
		render()
	end
	local function finishBinding(key)
		if key then
			currentKey = key
			lastCapture = os.clock()
		end
		isBinding = false
		render()
	end
	local function focused(on)
		if disabled then return end
		frm.BackgroundColor3 = on and Theme.SecondaryBackground or Theme.PanelBackground
		lbl.TextColor3 = on and Theme.TextPrimary or Theme.TextSecondary
		stroke.Color = on and Theme.Accent or Theme.Stroke
	end

	connect(bindBtn.Activated, beginBinding)
	connect(bindBtn.MouseEnter, function() focused(true) end)
	connect(bindBtn.MouseLeave, function() focused(false) end)
	connect(bindBtn.SelectionGained, function() focused(true) end)
	connect(bindBtn.SelectionLost, function() focused(false) end)
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
		lbl.TextColor3 = disabled and Theme.TextMuted or Theme.TextSecondary
		stroke.Color = Theme.Stroke
		render()
	end
	function self.destroy()
		for _, connection in ipairs(connections) do connection:Disconnect() end
		if frm.Parent then frm:Destroy() end
	end
	return self
end

return Keybind
