local Dropdown = {}

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

local function option(raw)
	if type(raw) == "table" then
		local label = raw.name or raw.Name or raw.label or raw.Label or raw[1]
		local value = raw.val
		if value == nil then value = raw.Value end
		if value == nil then value = raw.value end
		if value == nil then value = raw[2] end
		if value == nil then value = label end
		return tostring(label or value or "Option"), value
	end
	return tostring(raw), raw
end

function Dropdown.new(parent, name, opts, defaultIdx, cb)
	local container, Theme = context(parent)
	local desc = type(name) == "table" and (name.Desc or name[2]) or nil
	name = type(name) == "table" and (name.Name or name[1]) or name
	local options = type(opts) == "table" and opts or {}
	local cur = math.clamp(tonumber(defaultIdx) or 1, 1, math.max(#options, 1))
	local connections, optionConnections, items = {}, {}, {}
	local disabled, expanded, triggerHover, triggerFocus = false, false, false, false
	local function connect(signal, fn, list)
		local connection = signal:Connect(fn)
		table.insert(list or connections, connection)
		return connection
	end
	local function clearOptionConnections()
		for _, connection in ipairs(optionConnections) do connection:Disconnect() end
		table.clear(optionConnections)
		table.clear(items)
	end

	local frm = Instance.new("Frame")
	frm.Size = UDim2.new(1, 0, 0, 0)
	frm.AutomaticSize = Enum.AutomaticSize.Y
	frm.BackgroundTransparency = 1
	frm.BorderSizePixel = 0
	frm.Parent = container
	local rootLayout = Instance.new("UIListLayout")
	rootLayout.Padding = UDim.new(0, 6)
	rootLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rootLayout.Parent = frm

	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 48)
	header.AutomaticSize = Enum.AutomaticSize.Y
	header.BackgroundColor3 = Theme.Surface or Theme.PanelBackground
	header.BackgroundTransparency = Theme.PanelTransparency
	header.BorderSizePixel = 0
	header.LayoutOrder = 1
	header.Parent = frm
	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = Theme.CardCornerRadius or UDim.new(0, 14)
	headerCorner.Parent = header
	local headerStroke = Instance.new("UIStroke")
	headerStroke.Color = Theme.Stroke
	headerStroke.Transparency = Theme.PanelStrokeTransparency
	headerStroke.Parent = header

	local content = Instance.new("Frame")
	content.Size = UDim2.new(1, -150, 0, 48)
	content.AutomaticSize = Enum.AutomaticSize.Y
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	content.Parent = header
	local contentLayout = Instance.new("UIListLayout")
	contentLayout.Padding = UDim.new(0, 3)
	contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
	contentLayout.Parent = content
	local contentPadding = Instance.new("UIPadding")
	contentPadding.PaddingTop = UDim.new(0, desc and 10 or 15)
	contentPadding.PaddingBottom = UDim.new(0, desc and 10 or 15)
	contentPadding.PaddingLeft = UDim.new(0, 14)
	contentPadding.Parent = content

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, 0)
	lbl.AutomaticSize = Enum.AutomaticSize.Y
	lbl.BackgroundTransparency = 1
	lbl.BorderSizePixel = 0
	lbl.Text = tostring(name or "Dropdown")
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
	btn.Size = UDim2.fromOffset(124, 34)
	btn.AnchorPoint = Vector2.new(1, 0.5)
	btn.Position = UDim2.new(1, -14, 0.5, 0)
	btn.BackgroundColor3 = Theme.SecondaryBackground
	btn.BorderSizePixel = 0
	btn.TextColor3 = Theme.TextSecondary
	btn.Font = Theme.FontMedium
	btn.TextSize = 11
	btn.TextTruncate = Enum.TextTruncate.AtEnd
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.AutoButtonColor = false
	btn.Selectable = true
	btn.Parent = header
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = Theme.FieldCornerRadius or Theme.CornerRadius
	btnCorner.Parent = btn
	local btnStroke = Instance.new("UIStroke")
	btnStroke.Color = Theme.Stroke
	btnStroke.Transparency = Theme.PanelStrokeTransparency
	btnStroke.Parent = btn
	local btnPadding = Instance.new("UIPadding")
	btnPadding.PaddingLeft = UDim.new(0, 11)
	btnPadding.PaddingRight = UDim.new(0, 30)
	btnPadding.Parent = btn

	local chevron = Instance.new("TextLabel")
	chevron.Size = UDim2.fromOffset(22, 22)
	chevron.AnchorPoint = Vector2.new(1, 0.5)
	chevron.Position = UDim2.new(1, -6, 0.5, 0)
	chevron.BackgroundTransparency = 1
	chevron.BorderSizePixel = 0
	chevron.Text = "⌄"
	chevron.TextColor3 = Theme.TextMuted
	chevron.Font = Theme.FontBold
	chevron.TextSize = 14
	chevron.Parent = btn

	local list = Instance.new("ScrollingFrame")
	list.Size = UDim2.new(1, 0, 0, 0)
	list.BackgroundColor3 = Theme.SurfaceElevated or Theme.SecondaryBackground
	list.BackgroundTransparency = Theme.PanelTransparency
	list.BorderSizePixel = 0
	list.CanvasSize = UDim2.new()
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.ScrollBarThickness = 2
	list.ScrollBarImageColor3 = Theme.TextMuted
	list.Visible = false
	list.LayoutOrder = 2
	list.Parent = frm
	local listCorner = Instance.new("UICorner")
	listCorner.CornerRadius = Theme.CardCornerRadius or UDim.new(0, 14)
	listCorner.Parent = list
	local listStroke = Instance.new("UIStroke")
	listStroke.Color = Theme.Stroke
	listStroke.Transparency = Theme.PanelStrokeTransparency
	listStroke.Parent = list
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 6)
	padding.PaddingBottom = UDim.new(0, 6)
	padding.PaddingLeft = UDim.new(0, 6)
	padding.PaddingRight = UDim.new(0, 6)
	padding.Parent = list

	local setExpanded, rebuild
	local function updateButton()
		btn.Text = #options > 0 and (option(options[cur])) or "No options"
		chevron.Text = expanded and "⌃" or "⌄"
	end
	local function paint(index, hot)
		local item = items[index]
		if not item then return end
		local chosen = index == cur
		item.BackgroundColor3 = chosen and Theme.Accent
			or (hot and (Theme.SurfaceHover or Theme.SecondaryBackground) or (Theme.Surface or Theme.PanelBackground))
		item.BackgroundTransparency = chosen and 0 or (hot and 0 or Theme.PanelTransparency)
		item.TextColor3 = chosen and Theme.Background or (hot and Theme.TextPrimary or Theme.TextSecondary)
	end
	local function select(index, fire)
		if #options == 0 then return end
		local old = cur
		cur = math.clamp(index, 1, #options)
		paint(old, false)
		paint(cur, false)
		updateButton()
		if fire and cb then
			local _, value = option(options[cur])
			cb(value)
		end
	end
	local function refreshTrigger()
		local on = not disabled and (triggerHover or triggerFocus or expanded)
		header.BackgroundColor3 = on and (Theme.SurfaceHover or Theme.SecondaryBackground) or (Theme.Surface or Theme.PanelBackground)
		lbl.TextColor3 = disabled and Theme.TextMuted or (on and Theme.TextPrimary or Theme.TextSecondary)
		btn.TextColor3 = disabled and Theme.TextMuted or (on and Theme.TextPrimary or Theme.TextSecondary)
		chevron.TextColor3 = disabled and Theme.TextMuted or (on and Theme.TextPrimary or Theme.TextMuted)
		headerStroke.Transparency = on and (Theme.HoverStrokeTransparency or 0.5) or Theme.PanelStrokeTransparency
		btnStroke.Transparency = on and (Theme.FocusStrokeTransparency or 0.28) or Theme.PanelStrokeTransparency
	end
	setExpanded = function(value)
		expanded = not disabled and #options > 0 and not not value
		local count = #options
		local listHeight = expanded and math.min(count * 36 + 8, 160) or 0
		list.Visible = expanded
		list.Size = UDim2.new(1, 0, 0, listHeight)
		updateButton()
		refreshTrigger()
	end
	rebuild = function()
		clearOptionConnections()
		for _, child in ipairs(list:GetChildren()) do
			if child:IsA("GuiButton") then child:Destroy() end
		end
		for index, raw in ipairs(options) do
			local label = option(raw)
			local item = Instance.new("TextButton")
			item.Size = UDim2.new(1, 0, 0, 32)
			item.BorderSizePixel = 0
			item.Text = label
			item.Font = Theme.FontMedium
			item.TextSize = 12
			item.TextWrapped = true
			item.AutoButtonColor = false
			item.Selectable = not disabled
			item.Active = not disabled
			item.LayoutOrder = index
			item.Parent = list
			items[index] = item
			local itemCorner = Instance.new("UICorner")
			itemCorner.CornerRadius = Theme.FieldCornerRadius or Theme.CornerRadius
			itemCorner.Parent = item
			paint(index, false)
			local pointer, focus = false, false
			local function refreshItem() paint(index, not disabled and (pointer or focus)) end
			connect(item.MouseEnter, function() pointer = true refreshItem() end, optionConnections)
			connect(item.MouseLeave, function() pointer = false refreshItem() end, optionConnections)
			connect(item.SelectionGained, function() focus = true refreshItem() end, optionConnections)
			connect(item.SelectionLost, function() focus = false refreshItem() end, optionConnections)
			connect(item.Activated, function()
				if disabled then return end
				select(index, true)
				setExpanded(false)
				Utils.safeSvc("GuiService").SelectedObject = btn
			end, optionConnections)
		end
		setExpanded(expanded)
	end

	connect(btn.Activated, function()
		if not disabled then setExpanded(not expanded) end
	end)
	connect(btn.MouseEnter, function() triggerHover = true refreshTrigger() end)
	connect(btn.MouseLeave, function() triggerHover = false refreshTrigger() end)
	connect(btn.SelectionGained, function() triggerFocus = true refreshTrigger() end)
	connect(btn.SelectionLost, function() triggerFocus = false refreshTrigger() end)
	connect(btn.InputBegan, function(input)
		if disabled or #options == 0 then return end
		if input.KeyCode == Enum.KeyCode.Down or input.KeyCode == Enum.KeyCode.DPadDown then
			select(cur % #options + 1, true)
		elseif input.KeyCode == Enum.KeyCode.Up or input.KeyCode == Enum.KeyCode.DPadUp then
			select((cur - 2) % #options + 1, true)
		elseif input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB then
			setExpanded(false)
		end
	end)
	rebuild()

	local self = { frame = frm, button = btn }
	function self.setOptions(newOpts, newDefaultIdx)
		assert(type(newOpts) == "table", "Dropdown options must be a table")
		options = newOpts
		cur = math.clamp(tonumber(newDefaultIdx) or 1, 1, math.max(#options, 1))
		rebuild()
		if #options > 0 and cb then
			local _, value = option(options[cur])
			cb(value)
		end
	end
	function self.get()
		if #options == 0 then return nil end
		local _, value = option(options[cur])
		return value
	end
	function self.setDisabled(value)
		disabled = not not value
		btn.Active = not disabled
		btn.Selectable = not disabled
		if disabled then setExpanded(false) end
		for _, item in ipairs(items) do
			item.Active = not disabled
			item.Selectable = not disabled
		end
		refreshTrigger()
	end
	function self.destroy()
		clearOptionConnections()
		for _, connection in ipairs(connections) do connection:Disconnect() end
		if frm.Parent then frm:Destroy() end
	end
	return self
end

return Dropdown
