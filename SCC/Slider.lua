local Slider = {}

local import = function(name)
	local ok, res = pcall(function() return require(script.Parent[name]) end)
	if ok then return res end
	return _G.UniversalUILib_GetModule(name)
end

local DefaultTheme = import("Theme")
local Utils = import("Utils")

local function context(parent)
	if type(parent) == "table" then
		return parent.container, (parent.window and parent.window.theme) or DefaultTheme
	end
	return parent, DefaultTheme
end

local function validNumber(value)
	return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

function Slider.new(parent, name, minVal, maxVal, defaultVal, formatFunc, cb)
	local container, Theme = context(parent)
	local desc, step
	if type(name) == "table" and (name.Min ~= nil or name.Max ~= nil or name.Default ~= nil or name.Step ~= nil) then
		local config, configCallback = name, minVal
		name = config.Name or config[1] or "Slider"
		desc = config.Desc or config.Description
		minVal = config.Min
		maxVal = config.Max
		defaultVal = config.Default
		step = config.Step
		formatFunc = config.Format or config.FormatFunc
		cb = config.Callback or (type(configCallback) == "function" and configCallback) or cb
	elseif type(name) == "table" then
		desc = name.Desc or name[2]
		step = name.Step
		name = name.Name or name[1] or "Slider"
	end

	assert(validNumber(minVal), "Slider Min must be a finite number")
	assert(validNumber(maxVal) and maxVal > minVal, "Slider Max must be a finite number greater than Min")
	assert(validNumber(defaultVal) and defaultVal >= minVal and defaultVal <= maxVal, "Slider Default must be between Min and Max")
	if step ~= nil then
		assert(validNumber(step) and step > 0, "Slider Step must be a positive finite number")
	end
	step = step or (maxVal - minVal) / 100
	local formatVal = type(formatFunc) == "function" and formatFunc or function(value) return tostring(value) end
	local uis = Utils.safeSvc("UserInputService")
	local connections, disabled, sliding, dragInput = {}, false, false, nil
	local currentVal = defaultVal
	local function connect(signal, fn)
		local connection = signal:Connect(fn)
		table.insert(connections, connection)
		return connection
	end

	local frm = Instance.new("Frame")
	frm.Size = UDim2.new(1, 0, 0, desc and 76 or 62)
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
	lbl.Size = UDim2.new(1, -32, 0, 22)
	lbl.Position = UDim2.new(0, 16, 0, 8)
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = Theme.TextSecondary
	lbl.Font = Theme.FontMedium
	lbl.TextSize = 13
	lbl.TextWrapped = true
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = frm

	if desc then
		local description = Instance.new("TextLabel")
		description.Size = UDim2.new(1, -32, 0, 18)
		description.Position = UDim2.new(0, 16, 0, 29)
		description.BackgroundTransparency = 1
		description.Text = tostring(desc)
		description.TextColor3 = Theme.TextMuted
		description.Font = Theme.FontMedium
		description.TextSize = 11
		description.TextWrapped = true
		description.TextXAlignment = Enum.TextXAlignment.Left
		description.Parent = frm
	end

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, -32, 0, 8)
	bar.Position = UDim2.new(0, 16, 1, -18)
	bar.BackgroundColor3 = Theme.SecondaryBackground
	bar.Parent = frm
	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(1, 0)
	barCorner.Parent = bar
	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = Theme.Accent
	fill.Parent = bar
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = fill

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromScale(1, 1)
	btn.BackgroundTransparency = 1
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.Selectable = true
	btn.Parent = frm

	local function quantize(value)
		local steps = math.floor((value - minVal) / step + 0.5)
		return math.clamp(minVal + steps * step, minVal, maxVal)
	end
	currentVal = quantize(currentVal)
	local function render()
		fill.Size = UDim2.new((currentVal - minVal) / (maxVal - minVal), 0, 1, 0)
		lbl.Text = tostring(name) .. ": " .. tostring(formatVal(currentVal))
	end
	local function set(value, fire)
		assert(validNumber(value), "Slider value must be a finite number")
		local nextValue = quantize(math.clamp(value, minVal, maxVal))
		if nextValue == currentVal then return end
		currentVal = nextValue
		render()
		if fire and cb then cb(currentVal) end
	end
	local function updateAt(x)
		if disabled or bar.AbsoluteSize.X <= 0 then return end
		local percent = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
		set(minVal + (maxVal - minVal) * percent, true)
	end
	local function focused(on)
		if disabled then return end
		frm.BackgroundColor3 = on and Theme.SecondaryBackground or Theme.PanelBackground
		lbl.TextColor3 = on and Theme.TextPrimary or Theme.TextSecondary
		fill.BackgroundColor3 = on and (Theme.AccentHover or Theme.Accent) or Theme.Accent
		stroke.Color = on and Theme.Accent or Theme.Stroke
	end

	connect(btn.MouseEnter, function() focused(true) end)
	connect(btn.MouseLeave, function() focused(false) end)
	connect(btn.SelectionGained, function() focused(true) end)
	connect(btn.SelectionLost, function() focused(false) end)
	connect(btn.InputBegan, function(input)
		if disabled then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			sliding, dragInput = true, input
			updateAt(input.Position.X)
		elseif input.KeyCode == Enum.KeyCode.Left or input.KeyCode == Enum.KeyCode.DPadLeft or input.KeyCode == Enum.KeyCode.Down or input.KeyCode == Enum.KeyCode.DPadDown then
			set(currentVal - step, true)
		elseif input.KeyCode == Enum.KeyCode.Right or input.KeyCode == Enum.KeyCode.DPadRight or input.KeyCode == Enum.KeyCode.Up or input.KeyCode == Enum.KeyCode.DPadUp then
			set(currentVal + step, true)
		end
	end)
	connect(uis.InputChanged, function(input)
		if sliding and (input == dragInput or input.UserInputType == Enum.UserInputType.MouseMovement) then
			updateAt(input.Position.X)
		end
	end)
	connect(uis.InputEnded, function(input)
		if input == dragInput or (sliding and input.UserInputType == Enum.UserInputType.MouseButton1) then
			sliding, dragInput = false, nil
		end
	end)
	render()

	local self = { frame = frm, button = btn }
	self.set = function(value) set(value, true) end
	self.get = function() return currentVal end
	function self.setDisabled(value)
		disabled = not not value
		btn.Active = not disabled
		btn.Selectable = not disabled
		sliding, dragInput = false, nil
		lbl.TextColor3 = disabled and Theme.TextMuted or Theme.TextSecondary
		fill.BackgroundTransparency = disabled and 0.45 or 0
		stroke.Color = Theme.Stroke
	end
	function self.destroy()
		for _, connection in ipairs(connections) do connection:Disconnect() end
		if frm.Parent then frm:Destroy() end
	end
	return self
end

return Slider
