local Toggle = {}

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

function Toggle.new(parent, name, defaultState, cb)
	local container, Theme = context(parent)
	local text = type(name) == "table" and (name.Name or name[1]) or name
	local desc = type(name) == "table" and (name.Desc or name[2]) or nil
	local stateVal = not not defaultState
	local connections, disabled = {}, false
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

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromScale(1, 1)
	btn.BackgroundTransparency = 1
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.Selectable = true
	btn.Parent = frm

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -76, 0, desc and 22 or 28)
	lbl.Position = UDim2.new(0, 16, 0, desc and 10 or 10)
	lbl.BackgroundTransparency = 1
	lbl.Text = tostring(text or "Toggle")
	lbl.TextColor3 = Theme.TextSecondary
	lbl.Font = Theme.FontMedium
	lbl.TextSize = 13
	lbl.TextWrapped = true
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = frm

	if desc then
		local description = Instance.new("TextLabel")
		description.Size = UDim2.new(1, -76, 0, 22)
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

	local track = Instance.new("Frame")
	track.Size = UDim2.new(0, 44, 0, 24)
	track.Position = UDim2.new(1, -60, 0.5, -12)
	track.BackgroundColor3 = Theme.SecondaryBackground
	track.Parent = frm
	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(1, 0)
	trackCorner.Parent = track
	local knob = Instance.new("Frame")
	knob.Size = UDim2.fromOffset(18, 18)
	knob.BackgroundColor3 = Theme.TextPrimary
	knob.Parent = track
	local knobCorner = Instance.new("UICorner")
	knobCorner.CornerRadius = UDim.new(1, 0)
	knobCorner.Parent = knob

	local function updateVisuals()
		Utils.tween(track, TweenInfo.new(0.16, Enum.EasingStyle.Sine), {
			BackgroundColor3 = stateVal and Theme.Accent or Theme.SecondaryBackground,
		})
		Utils.tween(knob, TweenInfo.new(0.16, Enum.EasingStyle.Sine), {
			Position = stateVal and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9),
		})
	end
	local function focused(on)
		if disabled then return end
		frm.BackgroundColor3 = on and Theme.SecondaryBackground or Theme.PanelBackground
		lbl.TextColor3 = on and Theme.TextPrimary or Theme.TextSecondary
		stroke.Color = on and Theme.Accent or Theme.Stroke
	end
	local function set(value, fire)
		stateVal = not not value
		updateVisuals()
		if fire and cb then cb(stateVal) end
	end

	connect(btn.MouseEnter, function() focused(true) end)
	connect(btn.MouseLeave, function() focused(false) end)
	connect(btn.SelectionGained, function() focused(true) end)
	connect(btn.SelectionLost, function() focused(false) end)
	connect(btn.Activated, function()
		if not disabled then set(not stateVal, true) end
	end)
	updateVisuals()

	local self = { frame = frm, button = btn }
	self.set = function(value) set(value, true) end
	self.get = function() return stateVal end
	function self.setDisabled(value)
		disabled = not not value
		btn.Active = not disabled
		btn.Selectable = not disabled
		lbl.TextColor3 = disabled and Theme.TextMuted or Theme.TextSecondary
		track.BackgroundTransparency = disabled and 0.45 or 0
		stroke.Color = Theme.Stroke
	end
	function self.destroy()
		for _, connection in ipairs(connections) do connection:Disconnect() end
		if frm.Parent then frm:Destroy() end
	end
	return self
end

return Toggle
