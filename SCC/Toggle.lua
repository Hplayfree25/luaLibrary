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
	local connections, disabled, hovered, selected = {}, false, false, false
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
	content.Size = UDim2.new(1, -58, 0, 44)
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
	padding.PaddingRight = UDim.new(0, 0)
	padding.Parent = content

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, 0)
	lbl.AutomaticSize = Enum.AutomaticSize.Y
	lbl.BackgroundTransparency = 1
	lbl.BorderSizePixel = 0
	lbl.Text = tostring(text or "Toggle")
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

	local track = Instance.new("Frame")
	track.Size = UDim2.fromOffset(38, 22)
	track.AnchorPoint = Vector2.new(1, 0.5)
	track.Position = UDim2.new(1, -14, 0.5, 0)
	track.BackgroundColor3 = stateVal and Theme.Accent or Theme.SecondaryBackground
	track.BorderSizePixel = 0
	track.Parent = frm
	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = Theme.PillCornerRadius or UDim.new(1, 0)
	trackCorner.Parent = track
	local trackStroke = Instance.new("UIStroke")
	trackStroke.Color = Theme.Stroke
	trackStroke.Transparency = stateVal and (Theme.HoverStrokeTransparency or 0.5) or Theme.PanelStrokeTransparency
	trackStroke.Parent = track
	local knob = Instance.new("Frame")
	knob.Size = UDim2.fromOffset(16, 16)
	knob.Position = stateVal and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
	knob.BackgroundColor3 = stateVal and Theme.Background or Theme.TextSecondary
	knob.BorderSizePixel = 0
	knob.Parent = track
	local knobCorner = Instance.new("UICorner")
	knobCorner.CornerRadius = Theme.PillCornerRadius or UDim.new(1, 0)
	knobCorner.Parent = knob

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromScale(1, 1)
	btn.BackgroundTransparency = 1
	btn.BorderSizePixel = 0
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.Selectable = true
	btn.Parent = frm

	local function updateVisuals(immediate)
		local info = TweenInfo.new(immediate and 0 or 0.16, Enum.EasingStyle.Sine)
		Utils.tween(track, info, { BackgroundColor3 = stateVal and Theme.Accent or Theme.SecondaryBackground })
		Utils.tween(knob, info, {
			Position = stateVal and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
			BackgroundColor3 = stateVal and Theme.Background or Theme.TextSecondary,
		})
		trackStroke.Transparency = stateVal and (Theme.HoverStrokeTransparency or 0.5) or Theme.PanelStrokeTransparency
	end
	local function refresh()
		local on = not disabled and (hovered or selected)
		frm.BackgroundColor3 = on and (Theme.SurfaceHover or Theme.SecondaryBackground) or (Theme.Surface or Theme.PanelBackground)
		lbl.TextColor3 = disabled and Theme.TextMuted or (on and Theme.TextPrimary or Theme.TextSecondary)
		stroke.Transparency = on and (Theme.HoverStrokeTransparency or 0.5) or Theme.PanelStrokeTransparency
	end
	local function set(value, fire)
		stateVal = not not value
		updateVisuals(false)
		if fire and cb then cb(stateVal) end
	end

	connect(btn.MouseEnter, function() hovered = true refresh() end)
	connect(btn.MouseLeave, function() hovered = false refresh() end)
	connect(btn.SelectionGained, function() selected = true refresh() end)
	connect(btn.SelectionLost, function() selected = false refresh() end)
	connect(btn.Activated, function()
		if not disabled then set(not stateVal, true) end
	end)
	updateVisuals(true)

	local self = { frame = frm, button = btn }
	self.set = function(value) set(value, true) end
	self.get = function() return stateVal end
	function self.setDisabled(value)
		disabled = not not value
		btn.Active = not disabled
		btn.Selectable = not disabled
		track.BackgroundTransparency = disabled and 0.45 or 0
		knob.BackgroundTransparency = disabled and 0.25 or 0
		refresh()
	end
	function self.destroy()
		for _, connection in ipairs(connections) do connection:Disconnect() end
		if frm.Parent then frm:Destroy() end
	end
	return self
end

return Toggle
