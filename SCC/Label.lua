local Label = {}

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

function Label.new(parent, text)
	local container, Theme = context(parent)
	local title = type(text) == "table" and (text.Name or text[1]) or text
	local desc = type(text) == "table" and (text.Desc or text[2]) or nil
	local frm = Instance.new("Frame")
	frm.Size = UDim2.new(1, 0, 0, 0)
	frm.AutomaticSize = Enum.AutomaticSize.Y
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
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 5)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = frm
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 12)
	padding.PaddingBottom = UDim.new(0, 12)
	padding.PaddingLeft = UDim.new(0, 16)
	padding.PaddingRight = UDim.new(0, 16)
	padding.Parent = frm

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, 0)
	lbl.AutomaticSize = Enum.AutomaticSize.Y
	lbl.BackgroundTransparency = 1
	lbl.Text = tostring(title or "")
	lbl.TextColor3 = Theme.TextPrimary
	lbl.Font = Theme.FontMedium
	lbl.TextSize = 13
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextYAlignment = Enum.TextYAlignment.Top
	lbl.TextWrapped = true
	lbl.LayoutOrder = 1
	lbl.Parent = frm

	local lblDesc
	if desc then
		lblDesc = Instance.new("TextLabel")
		lblDesc.Size = UDim2.new(1, 0, 0, 0)
		lblDesc.AutomaticSize = Enum.AutomaticSize.Y
		lblDesc.BackgroundTransparency = 1
		lblDesc.Text = tostring(desc)
		lblDesc.TextColor3 = Theme.TextMuted
		lblDesc.Font = Theme.FontMedium
		lblDesc.TextSize = 11
		lblDesc.TextXAlignment = Enum.TextXAlignment.Left
		lblDesc.TextYAlignment = Enum.TextYAlignment.Top
		lblDesc.TextWrapped = true
		lblDesc.LayoutOrder = 2
		lblDesc.Parent = frm
	end

	local self = { frame = frm, label = lbl, descLabel = lblDesc }
	function self.set(newText)
		if type(newText) == "table" then
			if newText.Name or newText[1] then lbl.Text = tostring(newText.Name or newText[1]) end
			if lblDesc and (newText.Desc or newText[2]) then lblDesc.Text = tostring(newText.Desc or newText[2]) end
		else
			lbl.Text = tostring(newText or "")
		end
	end
	self.get = function() return lbl.Text end
	function self.destroy()
		if frm.Parent then frm:Destroy() end
	end
	return self
end

function Label.section(parent, text)
	local container, Theme = context(parent)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, 28)
	lbl.BackgroundTransparency = 1
	lbl.Text = tostring(type(text) == "table" and (text.Name or text[1]) or text or "")
	lbl.TextColor3 = Theme.TextPrimary
	lbl.Font = Theme.FontBold
	lbl.TextSize = 12
	lbl.TextWrapped = true
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = container
	return {
		frame = lbl,
		label = lbl,
		set = function(value) lbl.Text = tostring(value or "") end,
		get = function() return lbl.Text end,
		destroy = function() if lbl.Parent then lbl:Destroy() end end,
	}
end

function Label.separator(parent)
	local container, Theme = context(parent)
	local frm = Instance.new("Frame")
	frm.Size = UDim2.new(1, 0, 0, 13)
	frm.BackgroundTransparency = 1
	frm.Parent = container
	local line = Instance.new("Frame")
	line.Size = UDim2.new(1, 0, 0, 1)
	line.Position = UDim2.new(0, 0, 0.5, 0)
	line.BackgroundColor3 = Theme.Stroke
	line.BackgroundTransparency = Theme.StrokeTransparency
	line.BorderSizePixel = 0
	line.Parent = frm
	return { frame = frm, destroy = function() if frm.Parent then frm:Destroy() end end }
end

Label.newSection = Label.section
Label.newSeparator = Label.separator
Label.Section = Label.section
Label.Separator = Label.separator

return Label
