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
	content.Size = UDim2.new(1, 0, 0, 44)
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
	padding.PaddingRight = UDim.new(0, 14)
	padding.Parent = content

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, 0)
	lbl.AutomaticSize = Enum.AutomaticSize.Y
	lbl.BackgroundTransparency = 1
	lbl.BorderSizePixel = 0
	lbl.Text = tostring(text or "Button")
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

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromScale(1, 1)
	btn.BackgroundTransparency = 1
	btn.BorderSizePixel = 0
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.Selectable = true
	btn.Parent = frm

	local function refresh()
		local on = not disabled and (hovered or selected)
		Utils.tween(frm, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {
			BackgroundColor3 = on and (Theme.SurfaceHover or Theme.SecondaryBackground) or (Theme.Surface or Theme.PanelBackground),
		})
		Utils.tween(lbl, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {
			TextColor3 = disabled and Theme.TextMuted or (on and Theme.TextPrimary or Theme.TextSecondary),
		})
		Utils.tween(stroke, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {
			Transparency = on and (Theme.HoverStrokeTransparency or 0.5) or Theme.PanelStrokeTransparency,
		})
	end

	connect(btn.MouseEnter, function() hovered = true refresh() end)
	connect(btn.MouseLeave, function() hovered = false refresh() end)
	connect(btn.SelectionGained, function() selected = true refresh() end)
	connect(btn.SelectionLost, function() selected = false refresh() end)
	connect(btn.Activated, function()
		if disabled then return end
		Utils.tween(frm, TweenInfo.new(0.08, Enum.EasingStyle.Sine), {
			BackgroundColor3 = Theme.SurfaceActive or Theme.SecondaryBackground,
		})
		task.delay(0.09, function()
			if frm.Parent and not disabled then refresh() end
		end)
		if callback then callback() end
	end)

	local self = { frame = frm, button = btn }
	function self.setDisabled(value)
		disabled = not not value
		btn.Active = not disabled
		btn.Selectable = not disabled
		refresh()
	end
	function self.destroy()
		for _, connection in ipairs(connections) do connection:Disconnect() end
		if frm.Parent then frm:Destroy() end
	end
	return self
end

return Button
