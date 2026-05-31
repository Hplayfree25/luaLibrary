local LibraryUrl = "https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Test.lua"
local Success, Library = pcall(function()
    return loadstring(game:HttpGet(LibraryUrl))()
end)

if not Success or not Library then
    return
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local ESP_Settings = {
    Enabled = false,
    LimitDistance = 2000,
    TeamCheck = false,
    TextSize = 13,
    Font = 2,

    Box = { Enabled = false, Color = Color3.fromRGB(255, 255, 255), Outline = true },
    BoxFill = { Enabled = false, Color = Color3.fromRGB(255, 255, 255), Transparency = 0.5 },
    Name = { Enabled = false, Color = Color3.fromRGB(255, 255, 255) },
    Distance = { Enabled = false, Color = Color3.fromRGB(200, 200, 200) },
    HealthBar = { Enabled = false },
    Tracer = { Enabled = false, Origin = "Bottom", Color = Color3.fromRGB(255, 255, 255) },
    Skeleton = { Enabled = false, Color = Color3.fromRGB(255, 255, 255), Thickness = 1 },

    Chams = { 
        Enabled = false, 
        FillColor = Color3.fromRGB(255, 0, 0), 
        OutlineColor = Color3.fromRGB(255, 255, 255),
        FillTransparency = 0.5,
        OutlineTransparency = 0
    }
}

local Aimbot = {
    Enabled         = false,
    ToggleMode      = false,
    TeamCheck       = false,
    VisibleCheck    = false,
    AimPart         = "Head",
    FOV             = 160,
    FOV_Enabled     = false,
    FOV_Color       = Color3.fromRGB(255, 0, 255),
    FOV_LockedColor = Color3.fromRGB(0, 255, 0),
    Smoothness      = 10,
    Prediction      = false,
    PredictionAmount = 0.142
}

local ESP_Cache = {}

local function NewDrawing(Type, Properties)
    local Obj = Drawing.new(Type)
    for k, v in pairs(Properties) do Obj[k] = v end
    return Obj
end

local function CreateESP(Player)
    local Objects = {
        Box = NewDrawing("Square", {Thickness = 1, ZIndex = 2, Visible = false}),
        BoxOutline = NewDrawing("Square", {Thickness = 3, Color = Color3.new(0,0,0), ZIndex = 1, Visible = false}),
        BoxFill = NewDrawing("Square", {Filled = true, ZIndex = 0, Visible = false}),
        Name = NewDrawing("Text", {Text = Player.Name, Center = true, Size = ESP_Settings.TextSize, Font = ESP_Settings.Font, Outline = true, ZIndex = 3, Visible = false}),
        Distance = NewDrawing("Text", {Center = true, Size = ESP_Settings.TextSize - 1, Font = ESP_Settings.Font, Outline = true, ZIndex = 3, Visible = false}),
        HealthBar = NewDrawing("Square", {Filled = true, ZIndex = 2, Visible = false}),
        HealthBarOutline = NewDrawing("Square", {Filled = true, Color = Color3.new(0,0,0), ZIndex = 1, Visible = false}),
        Tracer = NewDrawing("Line", {Thickness = 1, ZIndex = 2, Visible = false}),
        TracerOutline = NewDrawing("Line", {Thickness = 3, Color = Color3.new(0,0,0), ZIndex = 1, Visible = false}),
        SkeletonLines = {},
        Highlight = nil
    }

    for i = 1, 16 do
        table.insert(Objects.SkeletonLines, NewDrawing("Line", {Thickness = 1, ZIndex = 2, Visible = false}))
    end

    ESP_Cache[Player] = Objects
end

local function RemoveESP(Player)
    if ESP_Cache[Player] then
        for k, v in pairs(ESP_Cache[Player]) do
            if k == "Highlight" and v then 
                v:Destroy()
            elseif k == "SkeletonLines" then
                for _, line in pairs(v) do line:Remove() end
            elseif v and v.Remove then 
                v:Remove() 
            end
        end
        ESP_Cache[Player] = nil
    end
end

local SkeletonConnections = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
    {"Head", "Torso"},
    {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
    {"Torso", "Left Leg"}, {"Torso", "Right Leg"}
}

RunService.RenderStepped:Connect(function()
    for Player, Objects in pairs(ESP_Cache) do
        local Character = Player.Character
        local Humanoid = Character and Character:FindFirstChild("Humanoid")
        local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")
        
        local IsValid = ESP_Settings.Enabled and Character and Humanoid and RootPart and Humanoid.Health > 0
        local IsTeammate = ESP_Settings.TeamCheck and Player.Team == LocalPlayer.Team
        
        if IsValid and not IsTeammate then
            local HRP_Pos, OnScreen = Camera:WorldToViewportPoint(RootPart.Position)
            local Dist = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")) and (LocalPlayer.Character.HumanoidRootPart.Position - RootPart.Position).Magnitude or 0

            if ESP_Settings.Chams.Enabled then
                if not Objects.Highlight or Objects.Highlight.Parent ~= Character then
                    if Objects.Highlight then Objects.Highlight:Destroy() end
                    local HL = Instance.new("Highlight")
                    HL.Parent = Character; HL.Adornee = Character; HL.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    Objects.Highlight = HL
                end
                local HL = Objects.Highlight
                HL.FillColor = ESP_Settings.Chams.FillColor; HL.OutlineColor = ESP_Settings.Chams.OutlineColor
                HL.FillTransparency = ESP_Settings.Chams.FillTransparency; HL.OutlineTransparency = ESP_Settings.Chams.OutlineTransparency
                HL.Enabled = true
            else
                if Objects.Highlight then Objects.Highlight:Destroy() Objects.Highlight = nil end
            end

            if OnScreen and Dist <= ESP_Settings.LimitDistance then
                local ScaleFactor = 1 / (HRP_Pos.Z * math.tan(math.rad(Camera.FieldOfView * 0.5)) * 2) * 1000
                local Width, Height = math.floor(4 * ScaleFactor), math.floor(6 * ScaleFactor)
                local BoxPos = Vector2.new(math.floor(HRP_Pos.X - Width * 0.5), math.floor(HRP_Pos.Y - Height * 0.5))

                if ESP_Settings.Box.Enabled then
                    Objects.Box.Size = Vector2.new(Width, Height); Objects.Box.Position = BoxPos; Objects.Box.Color = ESP_Settings.Box.Color; Objects.Box.Visible = true
                    Objects.BoxOutline.Size = Vector2.new(Width, Height); Objects.BoxOutline.Position = BoxPos; Objects.BoxOutline.Visible = ESP_Settings.Box.Outline
                else Objects.Box.Visible = false; Objects.BoxOutline.Visible = false end

                if ESP_Settings.BoxFill.Enabled and ESP_Settings.Box.Enabled then
                    Objects.BoxFill.Size = Vector2.new(Width, Height); Objects.BoxFill.Position = BoxPos; Objects.BoxFill.Color = ESP_Settings.BoxFill.Color; Objects.BoxFill.Transparency = ESP_Settings.BoxFill.Transparency; Objects.BoxFill.Visible = true
                else Objects.BoxFill.Visible = false end

                if ESP_Settings.Name.Enabled then
                    Objects.Name.Position = Vector2.new(BoxPos.X + Width / 2, BoxPos.Y - Objects.Name.TextBounds.Y - 2); Objects.Name.Color = ESP_Settings.Name.Color; Objects.Name.Visible = true
                else Objects.Name.Visible = false end

                if ESP_Settings.Distance.Enabled then
                    Objects.Distance.Text = math.floor(Dist) .. "m"; Objects.Distance.Position = Vector2.new(BoxPos.X + Width / 2, BoxPos.Y + Height + 2); Objects.Distance.Color = ESP_Settings.Distance.Color; Objects.Distance.Visible = true
                else Objects.Distance.Visible = false end

                if ESP_Settings.HealthBar.Enabled then
                    local BarWidth = 2; local HealthY = Height * (Humanoid.Health / Humanoid.MaxHealth)
                    Objects.HealthBarOutline.Size = Vector2.new(BarWidth + 2, Height + 2); Objects.HealthBarOutline.Position = Vector2.new(BoxPos.X - BarWidth - 6, BoxPos.Y - 1); Objects.HealthBarOutline.Visible = true
                    Objects.HealthBar.Size = Vector2.new(BarWidth, HealthY); Objects.HealthBar.Position = Vector2.new(BoxPos.X - BarWidth - 5, BoxPos.Y + (Height - HealthY)); Objects.HealthBar.Color = Color3.fromHSV((Humanoid.Health / Humanoid.MaxHealth) * 0.3, 1, 1); Objects.HealthBar.Visible = true
                else Objects.HealthBar.Visible = false; Objects.HealthBarOutline.Visible = false end

                if ESP_Settings.Tracer.Enabled then
                    local Origin = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    if ESP_Settings.Tracer.Origin == "Center" then Origin = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                    elseif ESP_Settings.Tracer.Origin == "Mouse" then local M = UserInputService:GetMouseLocation() Origin = Vector2.new(M.X, M.Y) end
                    Objects.Tracer.From = Origin; Objects.Tracer.To = Vector2.new(HRP_Pos.X, HRP_Pos.Y); Objects.Tracer.Color = ESP_Settings.Tracer.Color; Objects.Tracer.Visible = true
                    Objects.TracerOutline.From = Origin; Objects.TracerOutline.To = Vector2.new(HRP_Pos.X, HRP_Pos.Y); Objects.TracerOutline.Visible = true
                else Objects.Tracer.Visible = false; Objects.TracerOutline.Visible = false end

                if ESP_Settings.Skeleton.Enabled then
                    local lineIndex = 1
                    for _, pair in ipairs(SkeletonConnections) do
                        local p1 = Character:FindFirstChild(pair[1])
                        local p2 = Character:FindFirstChild(pair[2])
                        
                        if p1 and p2 then
                            local pos1, onScreen1 = Camera:WorldToViewportPoint(p1.Position)
                            local pos2, onScreen2 = Camera:WorldToViewportPoint(p2.Position)

                            if onScreen1 or onScreen2 then
                                local line = Objects.SkeletonLines[lineIndex]
                                if line then
                                    line.From = Vector2.new(pos1.X, pos1.Y)
                                    line.To = Vector2.new(pos2.X, pos2.Y)
                                    line.Color = ESP_Settings.Skeleton.Color
                                    line.Thickness = ESP_Settings.Skeleton.Thickness
                                    line.Visible = true
                                    lineIndex = lineIndex + 1
                                end
                            end
                        end
                    end
                    for i = lineIndex, #Objects.SkeletonLines do
                        Objects.SkeletonLines[i].Visible = false
                    end
                else
                    for _, line in pairs(Objects.SkeletonLines) do line.Visible = false end
                end

            else
                for k, v in pairs(Objects) do 
                    if k == "SkeletonLines" then for _, l in pairs(v) do l.Visible = false end
                    elseif typeof(v) ~= "Instance" then v.Visible = false end 
                end
            end
        else
            for k, v in pairs(Objects) do 
                if k == "SkeletonLines" then for _, l in pairs(v) do l.Visible = false end
                elseif typeof(v) ~= "Instance" then v.Visible = false end 
            end
            if Objects.Highlight then Objects.Highlight:Destroy() Objects.Highlight = nil end
        end
    end
end)

Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(RemoveESP)
for _, Plr in ipairs(Players:GetPlayers()) do if Plr ~= LocalPlayer then CreateESP(Plr) end end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DINAS_FOV"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 9999
ScreenGui.Parent = game:GetService("CoreGui")

local FOV_Frame = Instance.new("Frame")
FOV_Frame.BackgroundTransparency = 1
FOV_Frame.AnchorPoint = Vector2.new(0.5, 0.5)
FOV_Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
FOV_Frame.Size = UDim2.new(0, Aimbot.FOV * 2, 0, Aimbot.FOV * 2)

local Stroke = Instance.new("UIStroke")
Stroke.Thickness = 2.5
Stroke.Color = Aimbot.FOV_Color
Stroke.Transparency = 0.25
Stroke.Parent = FOV_Frame

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(1, 0)
Corner.Parent = FOV_Frame

FOV_Frame.Parent = ScreenGui

local function UpdateFOV()
    FOV_Frame.Size = UDim2.new(0, Aimbot.FOV * 2, 0, Aimbot.FOV * 2)
    FOV_Frame.Visible = Aimbot.FOV_Enabled and Aimbot.Enabled
    Stroke.Color = Aimbot.FOV_Color
end

local function GetTarget()
    local closest = nil
    local bestDist = Aimbot.FOV

    for _, plr in Players:GetPlayers() do
        if plr == LocalPlayer or not plr.Character or plr.Character:FindFirstChild("Humanoid").Health <= 0 then continue end
        if Aimbot.TeamCheck and plr.Team == LocalPlayer.Team then continue end

        local part = plr.Character:FindFirstChild(Aimbot.AimPart) or plr.Character:FindFirstChild("HumanoidRootPart")
        if not part then continue end

        local pos = part.Position
        if Aimbot.Prediction then
            pos = pos + (part.Velocity * Aimbot.PredictionAmount)
        end

        local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
        if not onScreen then continue end

        local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
        if dist >= bestDist then continue end

        if Aimbot.VisibleCheck then
            local rayParams = RaycastParams.new()
            rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
            rayParams.FilterType = Enum.RaycastFilterType.Blacklist
            local result = Workspace:Raycast(Camera.CFrame.Position, pos - Camera.CFrame.Position, rayParams)
            if result and not result.Instance:IsDescendantOf(plr.Character) then continue end
        end

        bestDist = dist
        closest = pos
    end
    return closest
end

RunService.Heartbeat:Connect(function()
    UpdateFOV()

    local shouldAim = Aimbot.Enabled and (Aimbot.ToggleMode or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2))

    if not shouldAim then
        Stroke.Color = Aimbot.FOV_Color
        return
    end

    local target = GetTarget()
    if target then
        Stroke.Color = Aimbot.FOV_LockedColor
        local look = CFrame.lookAt(Camera.CFrame.Position, target)
        Camera.CFrame = Camera.CFrame:Lerp(look, 1 / Aimbot.Smoothness)
    else
        Stroke.Color = Aimbot.FOV_Color
    end
end)

Library:Watermark("DINAS PROJECT | V 1.0")
local Window = Library:Window("DINAS PROJECT")

Window:Section("Main")

local VisualsTab = Window:Tab("Visuals")
local EspPage = VisualsTab:SubTab("ESP")
local ChamsPage = VisualsTab:SubTab("Chams")

local MasterGroup = EspPage:Groupbox("Activation", "Left")
MasterGroup:AddToggle({
    Title = "Enable ESP",
    Default = false,
    Callback = function(V) 
        ESP_Settings.Enabled = V 
    end
})

local ElementsGroup = EspPage:Groupbox("Elements", "Left")
ElementsGroup:AddToggle({ Title = "Boxes", Default = false, Callback = function(V) ESP_Settings.Box.Enabled = V end })
ElementsGroup:AddToggle({ Title = "Skeleton", Default = false, Callback = function(V) ESP_Settings.Skeleton.Enabled = V end })
ElementsGroup:AddToggle({ Title = "Names", Default = false, Callback = function(V) ESP_Settings.Name.Enabled = V end })
ElementsGroup:AddToggle({ Title = "Health Bar", Default = false, Callback = function(V) ESP_Settings.HealthBar.Enabled = V end })
ElementsGroup:AddToggle({ Title = "Distance", Default = false, Callback = function(V) ESP_Settings.Distance.Enabled = V end })
ElementsGroup:AddToggle({ Title = "Tracers", Default = false, Callback = function(V) ESP_Settings.Tracer.Enabled = V end })

local EspSettingsGroup = EspPage:Groupbox("Settings", "Right")
EspSettingsGroup:AddColorPicker({ Title = "Box Color", Default = ESP_Settings.Box.Color, Callback = function(V) ESP_Settings.Box.Color = V end })
EspSettingsGroup:AddColorPicker({ Title = "Skeleton Color", Default = ESP_Settings.Skeleton.Color, Callback = function(V) ESP_Settings.Skeleton.Color = V end })
EspSettingsGroup:AddColorPicker({ Title = "Name Color", Default = ESP_Settings.Name.Color, Callback = function(V) ESP_Settings.Name.Color = V end })
EspSettingsGroup:AddToggle({ Title = "Box Fill", Default = false, Callback = function(V) ESP_Settings.BoxFill.Enabled = V end })
EspSettingsGroup:AddColorPicker({ Title = "Fill Color", Default = ESP_Settings.BoxFill.Color, Callback = function(V) ESP_Settings.BoxFill.Color = V end })
EspSettingsGroup:AddSlider({ Title = "Max Distance", Min = 100, Max = 5000, Default = 2000, Suffix = " studs", Callback = function(V) ESP_Settings.LimitDistance = V end })

local ChamsGroup = ChamsPage:Groupbox("Chams", "Left")
ChamsGroup:AddToggle({ Title = "Enable Chams", Default = false, Callback = function(V) ESP_Settings.Chams.Enabled = V end })
ChamsGroup:AddColorPicker({ Title = "Fill Color", Default = ESP_Settings.Chams.FillColor, Callback = function(V) ESP_Settings.Chams.FillColor = V end })
ChamsGroup:AddColorPicker({ Title = "Outline Color", Default = ESP_Settings.Chams.OutlineColor, Callback = function(V) ESP_Settings.Chams.OutlineColor = V end })

local AimbotTab = Window:Tab("Aimbot")
local Page = AimbotTab:SubTab("Main")

Page:Groupbox("Aimbot Control", "Left"):AddToggle({
    Title = "Enable Aimbot",
    Default = false,
    Callback = function(v) Aimbot.Enabled = v end
})

Page:Groupbox("Aimbot Control", "Left"):AddToggle({
    Title = "Toggle Mode (Mobile Friendly)",
    Default = false,
    Description = "ON / OFF",
    Callback = function(v) Aimbot.ToggleMode = v end
})

Page:Groupbox("Aimbot Control", "Left"):AddDropdown({
    Title = "Aim Part",
    Values = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"},
    Default = "Head",
    Callback = function(v) Aimbot.AimPart = v end
})

Page:Groupbox("Checks", "Left"):AddToggle({
    Title = "Visible Check (Wall Check)",
    Default = false,
    Callback = function(v) Aimbot.VisibleCheck = v end
})

-- FOV Ð Ð…Ð Â°Ð¡ÐƒÐ¡â€šÐ¡Ð‚Ð Ñ•Ð â„–Ð Ñ”Ð Ñ‘
Page:Groupbox("FOV Settings", "Right"):AddToggle({
    Title = "Show FOV Circle",
    Default = false,
    Callback = function(v)
        Aimbot.FOV_Enabled = v
        UpdateFOV()
    end
})

Page:Groupbox("FOV Settings", "Right"):AddSlider({
    Title = "FOV Size",
    Min = 10, Max = 600, Default = 160,
    Callback = function(v)
        Aimbot.FOV = v
        UpdateFOV()
    end
})

Page:Groupbox("FOV Settings", "Right"):AddColorPicker({
    Title = "FOV Color",
    Default = Aimbot.FOV_Color,
    Callback = function(v)
        Aimbot.FOV_Color = v
        UpdateFOV()
    end
})

Page:Groupbox("FOV Settings", "Right"):AddColorPicker({
    Title = "Locked Color",
    Default = Aimbot.FOV_LockedColor,
    Callback = function(v) Aimbot.FOV_LockedColor = v end
})

Page:Groupbox("Smoothness", "Left"):AddSlider({
    Title = "Smoothness",
    Min = 1, Max = 50, Default = 10,
    Suffix = " (lower = sharper)",
    Callback = function(v) Aimbot.Smoothness = v end
})


-- // 3. SETTINGS TAB //
Window:Section("System")
local SettingsTab = Window:Tab("Settings")

-- >> CONFIG MANAGER <<
local SettingsPage = SettingsTab:SubTab("Menu Settings")

-- >> Ð›Ð•Ð’ÐÐ¯  CONFIG MANAGER <<
local ConfigGroup = SettingsPage:Groupbox("Configuration", "Left")
local Configs = Library:GetConfigs()

ConfigGroup:AddDropdown({
    Title = "Select Config",
    Values = Configs,
    Default = "default",
    Multi = false,
    Flag = "SelectedConfig",
    Callback = function(Value) end
})

ConfigGroup:AddTextbox({
    Title = "New Config Name",
    Placeholder = "Type name...",
    Flag = "NewConfigName",
    Callback = function(Value) end
})

ConfigGroup:AddButton({
    Title = "Load Selected",
    Callback = function()
        local name = Library.Flags["SelectedConfig"]
        if name then
            Library:LoadConfig(name)
        else
            Library:Notify("Error", "No config selected!", 3)
        end
    end
})

ConfigGroup:AddButton({
    Title = "Save Config",
    Callback = function()
        local name = Library.Flags["NewConfigName"]
        if name == "" or name == nil then name = Library.Flags["SelectedConfig"] end
        if name and name ~= "" then
            Library:SaveConfig(name)
            local NewList = Library:GetConfigs()
            if Library.Items["SelectedConfig"] then Library.Items["SelectedConfig"].Refresh(NewList) end
        else
            Library:Notify("Error", "Enter a name or select a config!", 3)
        end
    end
})

ConfigGroup:AddButton({
    Title = "Delete Config",
    Callback = function()
        local name = Library.Flags["SelectedConfig"]
        if name and name ~= "" then
            Library:DeleteConfig(name)
            
            local NewList = Library:GetConfigs()
            if Library.Items["SelectedConfig"] then 
                Library.Items["SelectedConfig"].Refresh(NewList) 
            end
       
            Library.Flags["SelectedConfig"] = nil
        else
            Library:Notify("Error", "Select a config first!", 3)
        end
    end
})

ConfigGroup:AddButton({
    Title = "Refresh List",
    Callback = function()
        local NewList = Library:GetConfigs()
        if Library.Items["SelectedConfig"] then Library.Items["SelectedConfig"].Refresh(NewList) end
        Library:Notify("Configs", "List refreshed", 2)
    end
})

-- >> ÐŸÐ ÐÐ’ÐÐ¯ Ð¡Ð¢ÐžÐ ÐžÐÐ: THEME MANAGER <<
local ThemeGroup = SettingsPage:Groupbox("Theme Manager", "Right")

local ThemeList = {}
if Library.ThemePresets then
    for ThemeName, _ in pairs(Library.ThemePresets) do
        table.insert(ThemeList, ThemeName)
    end
    table.sort(ThemeList)
    
    ThemeGroup:AddDropdown({
        Title = "Preset Theme",
        Values = ThemeList,
        Default = "Default",
        Multi = false,
        Callback = function(Value)
            if Library.SetTheme then
                Library:SetTheme(Value)
            else
                warn("Library is outdated, SetTheme missing!")
            end
        end
    })
    ThemeGroup:AddSeparator()
end

ThemeGroup:AddLabel("Custom Colors")

ThemeGroup:AddColorPicker({
    Title = "Accent Color", Default = Library.Theme.Accent, Flag = "ThemeAccent",
    Callback = function(Value) Library:UpdateTheme("Accent", Value) end
})

ThemeGroup:AddColorPicker({
    Title = "Background", Default = Library.Theme.Background, Flag = "ThemeBackground",
    Callback = function(Value) Library:UpdateTheme("Background", Value) end
})

ThemeGroup:AddColorPicker({
    Title = "Sidebar", Default = Library.Theme.Sidebar, Flag = "ThemeSidebar",
    Callback = function(Value) Library:UpdateTheme("Sidebar", Value) end
})

ThemeGroup:AddColorPicker({
    Title = "Groupbox", Default = Library.Theme.Groupbox, Flag = "ThemeGroupbox",
    Callback = function(Value) Library:UpdateTheme("Groupbox", Value) end
})

ThemeGroup:AddLabel("Text & Outlines")

ThemeGroup:AddColorPicker({
    Title = "Main Text", Default = Library.Theme.Text, Flag = "ThemeText",
    Callback = function(Value) Library:UpdateTheme("Text", Value) end
})

ThemeGroup:AddColorPicker({
    Title = "Secondary Text", Default = Library.Theme.TextDark, Flag = "ThemeTextDark",
    Callback = function(Value) Library:UpdateTheme("TextDark", Value) end
})

ThemeGroup:AddColorPicker({
    Title = "Outline/Stroke", Default = Library.Theme.Outline, Flag = "ThemeOutline",
    Callback = function(Value) Library:UpdateTheme("Outline", Value) end
})

ThemeGroup:AddButton({
    Title = "Reset Theme to Default",
    Callback = function()
        Library:SetTheme("Default")
        Library:Notify("Theme", "Colors reset to default", 2)
    end
})
    
-- >> ( Theme Manager) : UI SETTINGS <<
local UISettings = SettingsPage:Groupbox("UI Settings", "Right")

UISettings:AddToggle({
    Title = "Show Watermark",
    Default = true,
    Flag = "WatermarkToggle",
    Callback = function(Value)
        Library.WatermarkSettings.Enabled = Value
    end
})

UISettings:AddTextbox({
    Title = "Watermark Text",
    Default = "RedOnyx",
    Placeholder = "Enter text...",
    ClearOnFocus = false,
    Callback = function(Value)
        Library.WatermarkSettings.Text = Value
    end
})

UISettings:AddButton({
    Title = "Unload / Destroy UI",
    Callback = function()
        local gui = game:GetService("CoreGui"):FindFirstChild("RedOnyxV17")
        local water = game:GetService("CoreGui"):FindFirstChild("Watermark")
        if gui then gui:Destroy() end
        if water then water:Destroy() end
    end
})