local Textbox = {}

local import = function(name)
	local ok, res = pcall(function() return require(script.Parent[name]) end)
	if ok then return res end
	return _G.UniversalUILib_GetModule(name)
end

local DefaultTheme = import("Theme")

local function context(parent)
	if type(parent) == "table" then
		return parent.container, (parent.window and parent.window.theme) or DefaultTheme
	end
	return parent, DefaultTheme
end

function Textbox.new(parent, name, placeholderText, cb)
	local container, Theme = context(parent)
	local desc = type(name) == "table" and (name.Desc or name[2]) or nil
	local callback = type(name) == "table" and (name.Callback or cb) or cb
	placeholderText = type(name) == "table" and (name.Placeholder or placeholderText) or placeholderText
	name = type(name) == "table" and (name.Name or name[1]) or name
	local connections, disabled, hovered, focused = {}, false, false, false
	local function connect(signal, fn)
		local connection = signal:Connect(fn)
		table.insert(connections, connection)
		return connection
	end

	local frm = Instance.new("Frame")
	frm.Size = UDim2.new(1, 0, 0, 0)
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
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = frm
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 14)
	padding.PaddingRight = UDim.new(0, 14)
	padding.Parent = frm

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, 0)
	lbl.AutomaticSize = Enum.AutomaticSize.Y
	lbl.BackgroundTransparency = 1
	lbl.BorderSizePixel = 0
	lbl.Text = tostring(name or "Text")
	lbl.TextColor3 = Theme.TextSecondary
	lbl.Font = Theme.FontMedium
	lbl.TextSize = 13
	lbl.TextWrapped = true
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextYAlignment = Enum.TextYAlignment.Top
	lbl.LayoutOrder = 1
	lbl.Parent = frm

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
		description.Parent = frm
	end

	local boxBg = Instance.new("Frame")
	boxBg.Size = UDim2.new(1, 0, 0, 34)
	boxBg.BackgroundColor3 = Theme.SecondaryBackground
	boxBg.BorderSizePixel = 0
	boxBg.LayoutOrder = 3
	boxBg.Parent = frm
	local boxCorner = Instance.new("UICorner")
	boxCorner.CornerRadius = Theme.FieldCornerRadius or Theme.CornerRadius
	boxCorner.Parent = boxBg
	local boxStroke = Instance.new("UIStroke")
	boxStroke.Color = Theme.Stroke
	boxStroke.Transparency = Theme.PanelStrokeTransparency
	boxStroke.Parent = boxBg

	local txt = Instance.new("TextBox")
	txt.Size = UDim2.new(1, -20, 1, 0)
	txt.Position = UDim2.new(0, 10, 0, 0)
	txt.BackgroundTransparency = 1
	txt.BorderSizePixel = 0
	txt.Text = ""
	txt.PlaceholderText = placeholderText or "Enter text..."
	txt.PlaceholderColor3 = Theme.TextMuted
	txt.TextColor3 = Theme.TextPrimary
	txt.Font = Theme.FontMedium
	txt.TextSize = 12
	txt.TextXAlignment = Enum.TextXAlignment.Left
	txt.ClearTextOnFocus = false
	txt.Selectable = true
	txt.Parent = boxBg

	local function refresh()
		local on = not disabled and (hovered or focused)
		frm.BackgroundColor3 = on and (Theme.SurfaceHover or Theme.SecondaryBackground) or (Theme.Surface or Theme.PanelBackground)
		lbl.TextColor3 = disabled and Theme.TextMuted or (on and Theme.TextPrimary or Theme.TextSecondary)
		stroke.Transparency = on and (Theme.HoverStrokeTransparency or 0.5) or Theme.PanelStrokeTransparency
		boxStroke.Transparency = focused and (Theme.FocusStrokeTransparency or 0.28)
			or (on and (Theme.HoverStrokeTransparency or 0.5) or Theme.PanelStrokeTransparency)
	end
	connect(boxBg.MouseEnter, function() hovered = true refresh() end)
	connect(boxBg.MouseLeave, function() hovered = false refresh() end)
	connect(txt.Focused, function() focused = true refresh() end)
	connect(txt.FocusLost, function(enterPressed)
		focused = false
		refresh()
		if not disabled and callback then callback(txt.Text, enterPressed) end
	end)
	connect(txt.SelectionGained, function()
		if not disabled and not txt:IsFocused() then txt:CaptureFocus() end
	end)

	local self = { frame = frm, textbox = txt }
	self.get = function() return txt.Text end
	self.set = function(text) txt.Text = tostring(text or "") end
	function self.setDisabled(value)
		disabled = not not value
		txt.TextEditable = not disabled
		txt.Selectable = not disabled
		if disabled and txt:IsFocused() then txt:ReleaseFocus() end
		boxBg.BackgroundTransparency = disabled and 0.45 or 0
		refresh()
	end
	function self.destroy()
		for _, connection in ipairs(connections) do connection:Disconnect() end
		if frm.Parent then frm:Destroy() end
	end
	return self
end

return Textbox
