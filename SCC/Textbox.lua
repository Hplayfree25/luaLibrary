local Textbox = {}

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

function Textbox.new(parent, name, placeholderText, cb)
	local container, Theme = context(parent)
	local desc = type(name) == "table" and (name.Desc or name[2]) or nil
	local callback = type(name) == "table" and (name.Callback or cb) or cb
	placeholderText = type(name) == "table" and (name.Placeholder or placeholderText) or placeholderText
	name = type(name) == "table" and (name.Name or name[1]) or name
	local connections, disabled = {}, false
	local function connect(signal, fn)
		local connection = signal:Connect(fn)
		table.insert(connections, connection)
		return connection
	end

	local frm = Instance.new("Frame")
	frm.Size = UDim2.new(1, 0, 0, desc and 82 or 64)
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
	lbl.Text = tostring(name or "Text")
	lbl.TextColor3 = Theme.TextSecondary
	lbl.Font = Theme.FontMedium
	lbl.TextSize = 13
	lbl.TextWrapped = true
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = frm

	if desc then
		local description = Instance.new("TextLabel")
		description.Size = UDim2.new(1, -32, 0, 18)
		description.Position = UDim2.new(0, 16, 0, 28)
		description.BackgroundTransparency = 1
		description.Text = tostring(desc)
		description.TextColor3 = Theme.TextMuted
		description.Font = Theme.FontMedium
		description.TextSize = 11
		description.TextWrapped = true
		description.TextXAlignment = Enum.TextXAlignment.Left
		description.Parent = frm
	end

	local boxBg = Instance.new("Frame")
	boxBg.Size = UDim2.new(1, -32, 0, 36)
	boxBg.Position = UDim2.new(0, 16, 1, -44)
	boxBg.BackgroundColor3 = Theme.SecondaryBackground
	boxBg.Parent = frm
	local boxCorner = Instance.new("UICorner")
	boxCorner.CornerRadius = UDim.new(0, 5)
	boxCorner.Parent = boxBg
	local boxStroke = Instance.new("UIStroke")
	boxStroke.Color = Theme.Stroke
	boxStroke.Transparency = Theme.PanelStrokeTransparency
	boxStroke.Parent = boxBg

	local txt = Instance.new("TextBox")
	txt.Size = UDim2.new(1, -20, 1, 0)
	txt.Position = UDim2.new(0, 10, 0, 0)
	txt.BackgroundTransparency = 1
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

	local function focused(on)
		if disabled then return end
		boxStroke.Color = on and Theme.Accent or Theme.Stroke
		boxStroke.Transparency = on and 0.25 or Theme.PanelStrokeTransparency
		frm.BackgroundColor3 = on and Theme.SecondaryBackground or Theme.PanelBackground
		lbl.TextColor3 = on and Theme.TextPrimary or Theme.TextSecondary
	end
	connect(txt.Focused, function() focused(true) end)
	connect(txt.FocusLost, function(enterPressed)
		focused(false)
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
		lbl.TextColor3 = disabled and Theme.TextMuted or Theme.TextSecondary
		boxBg.BackgroundTransparency = disabled and 0.45 or 0
		boxStroke.Color = Theme.Stroke
	end
	function self.destroy()
		for _, connection in ipairs(connections) do connection:Disconnect() end
		if frm.Parent then frm:Destroy() end
	end
	return self
end

return Textbox
