local Button = {}

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

function Button.new(parent, name, cb)
	local container, Theme = context(parent)
	local text = type(name) == "table" and (name.Name or name[1]) or name
	local desc = type(name) == "table" and (name.Desc or name[2]) or nil
	local callback = type(name) == "table" and (name.Callback or cb) or cb
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
	lbl.Size = UDim2.new(1, -32, 0, desc and 22 or 28)
	lbl.Position = UDim2.new(0, 16, 0, desc and 10 or 10)
	lbl.BackgroundTransparency = 1
	lbl.Text = tostring(text or "Button")
	lbl.TextColor3 = Theme.TextSecondary
	lbl.Font = Theme.FontMedium
	lbl.TextSize = 13
	lbl.TextWrapped = true
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = frm

	if desc then
		local description = Instance.new("TextLabel")
		description.Size = UDim2.new(1, -32, 0, 22)
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

	local function focused(on)
		if disabled then return end
		Utils.tween(frm, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {
			BackgroundColor3 = on and Theme.SecondaryBackground or Theme.PanelBackground,
		})
		Utils.tween(lbl, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {
			TextColor3 = on and Theme.TextPrimary or Theme.TextSecondary,
		})
		stroke.Color = on and Theme.Accent or Theme.Stroke
	end

	connect(btn.MouseEnter, function() focused(true) end)
	connect(btn.MouseLeave, function() focused(false) end)
	connect(btn.SelectionGained, function() focused(true) end)
	connect(btn.SelectionLost, function() focused(false) end)
	connect(btn.Activated, function()
		if disabled then return end
		Utils.tween(frm, TweenInfo.new(0.08, Enum.EasingStyle.Sine), { BackgroundColor3 = Theme.Accent })
		task.delay(0.09, function()
			if frm.Parent and not disabled then focused(false) end
		end)
		if callback then callback() end
	end)

	local self = { frame = frm, button = btn }
	function self.setDisabled(value)
		disabled = not not value
		btn.Active = not disabled
		btn.Selectable = not disabled
		lbl.TextColor3 = disabled and Theme.TextMuted or Theme.TextSecondary
		frm.BackgroundColor3 = Theme.PanelBackground
		stroke.Color = Theme.Stroke
	end
	function self.destroy()
		for _, connection in ipairs(connections) do connection:Disconnect() end
		if frm.Parent then frm:Destroy() end
	end
	return self
end

return Button
