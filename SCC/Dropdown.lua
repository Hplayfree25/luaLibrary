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

local function option(option)
	if type(option) == "table" then
		local label = option.name or option.Name or option.label or option.Label or option[1]
		local value = option.val
		if value == nil then value = option.Value end
		if value == nil then value = option.value end
		if value == nil then value = option[2] end
		if value == nil then value = label end
		return tostring(label or value or "Option"), value
	end
	return tostring(option), option
end

function Dropdown.new(parent, name, opts, defaultIdx, cb)
	local container, Theme = context(parent)
	local desc = type(name) == "table" and (name.Desc or name[2]) or nil
	name = type(name) == "table" and (name.Name or name[1]) or name
	local options = type(opts) == "table" and opts or {}
	local cur = math.clamp(tonumber(defaultIdx) or 1, 1, math.max(#options, 1))
	local connections, optionConnections = {}, {}
	local disabled, expanded = false, false
	local function connect(signal, fn, list)
		local connection = signal:Connect(fn)
		table.insert(list or connections, connection)
		return connection
	end
	local function clearOptionConnections()
		for _, connection in ipairs(optionConnections) do connection:Disconnect() end
		table.clear(optionConnections)
	end

	local collapsedHeight = desc and 68 or 52
	local frm = Instance.new("Frame")
	frm.Size = UDim2.new(1, 0, 0, collapsedHeight)
	frm.BackgroundColor3 = Theme.PanelBackground
	frm.BackgroundTransparency = Theme.PanelTransparency
	frm.ClipsDescendants = true
	frm.Parent = container
	local corner = Instance.new("UICorner")
	corner.CornerRadius = Theme.CornerRadius
	corner.Parent = frm
	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Stroke
	stroke.Transparency = Theme.PanelStrokeTransparency
	stroke.Parent = frm

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -156, 0, 24)
	lbl.Position = UDim2.new(0, 16, 0, desc and 10 or 14)
	lbl.BackgroundTransparency = 1
	lbl.Text = tostring(name or "Dropdown")
	lbl.TextColor3 = Theme.TextSecondary
	lbl.Font = Theme.FontMedium
	lbl.TextSize = 13
	lbl.TextWrapped = true
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = frm

	if desc then
		local description = Instance.new("TextLabel")
		description.Size = UDim2.new(1, -156, 0, 22)
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

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 124, 0, 36)
	btn.Position = UDim2.new(1, -140, 0, desc and 16 or 8)
	btn.BackgroundColor3 = Theme.SecondaryBackground
	btn.TextColor3 = Theme.TextSecondary
	btn.Font = Theme.FontMedium
	btn.TextSize = 11
	btn.TextTruncate = Enum.TextTruncate.AtEnd
	btn.AutoButtonColor = false
	btn.Selectable = true
	btn.Parent = frm
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 5)
	btnCorner.Parent = btn

	local list = Instance.new("ScrollingFrame")
	list.Size = UDim2.new(1, -24, 0, 0)
	list.Position = UDim2.new(0, 12, 0, collapsedHeight)
	list.BackgroundColor3 = Theme.SecondaryBackground
	list.BorderSizePixel = 0
	list.CanvasSize = UDim2.new()
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.ScrollBarThickness = 3
	list.ScrollBarImageColor3 = Theme.Accent
	list.Visible = false
	list.Parent = frm
	local listCorner = Instance.new("UICorner")
	listCorner.CornerRadius = UDim.new(0, 5)
	listCorner.Parent = list
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
		btn.Text = #options > 0 and (option(options[cur])) .. (expanded and "  ▲" or "  ▼") or "No options"
	end
	local function select(index, fire)
		if #options == 0 then return end
		cur = math.clamp(index, 1, #options)
		updateButton()
		if fire and cb then
			local _, value = option(options[cur])
			cb(value)
		end
	end
	setExpanded = function(value)
		expanded = not disabled and #options > 0 and not not value
		local listHeight = expanded and math.min(#options * 40 + 12, 172) or 0
		list.Visible = expanded
		list.Size = UDim2.new(1, -24, 0, listHeight)
		frm.Size = UDim2.new(1, 0, 0, collapsedHeight + listHeight + (expanded and 8 or 0))
		stroke.Color = expanded and Theme.Accent or Theme.Stroke
		updateButton()
	end
	rebuild = function()
		clearOptionConnections()
		for _, child in ipairs(list:GetChildren()) do
			if child:IsA("GuiButton") then child:Destroy() end
		end
		for index, raw in ipairs(options) do
			local label = option(raw)
			local item = Instance.new("TextButton")
			item.Size = UDim2.new(1, -12, 0, 36)
			item.BackgroundColor3 = index == cur and Theme.Accent or Theme.PanelBackground
			item.BackgroundTransparency = index == cur and 0.1 or Theme.PanelTransparency
			item.Text = label
			item.TextColor3 = index == cur and Theme.TextPrimary or Theme.TextSecondary
			item.Font = Theme.FontMedium
			item.TextSize = 12
			item.TextWrapped = true
			item.AutoButtonColor = false
			item.Selectable = true
			item.LayoutOrder = index
			item.Parent = list
			local itemCorner = Instance.new("UICorner")
			itemCorner.CornerRadius = UDim.new(0, 4)
			itemCorner.Parent = item
			connect(item.Activated, function()
				if disabled then return end
				select(index, true)
				setExpanded(false)
				Utils.safeSvc("GuiService").SelectedObject = btn
			end, optionConnections)
			connect(item.SelectionGained, function()
				if not disabled then item.BackgroundColor3 = Theme.AccentHover or Theme.Accent end
			end, optionConnections)
			connect(item.SelectionLost, function()
				item.BackgroundColor3 = index == cur and Theme.Accent or Theme.PanelBackground
			end, optionConnections)
		end
		setExpanded(expanded)
	end

	connect(btn.Activated, function()
		if not disabled then setExpanded(not expanded) end
	end)
	connect(btn.SelectionGained, function()
		if not disabled then
			btn.TextColor3 = Theme.TextPrimary
			stroke.Color = Theme.Accent
		end
	end)
	connect(btn.SelectionLost, function()
		btn.TextColor3 = disabled and Theme.TextMuted or Theme.TextSecondary
		if not expanded then stroke.Color = Theme.Stroke end
	end)
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
		btn.TextColor3 = disabled and Theme.TextMuted or Theme.TextSecondary
		if disabled then setExpanded(false) end
	end
	function self.destroy()
		clearOptionConnections()
		for _, connection in ipairs(connections) do connection:Disconnect() end
		if frm.Parent then frm:Destroy() end
	end
	return self
end

return Dropdown
