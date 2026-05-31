local id = "NMZ_DFLICK2"
local getGenv = getgenv or function() return _G end

if getGenv()[id] then
    pcall(getGenv()[id])
end

local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Hplayfree25/luaLibrary/refs/heads/master/Init.lua?t=" .. tick()))()

local Window = UI.CreateWindow({
    Title = "FLICK NMZ",
    ToggleText = "NMZ",
    Size = UDim2.new(0, 500, 0, 300)
})

local conns = {}
local drws = {}

getGenv()[id] = function()
    for i = 1, #conns do pcall(function() conns[i]:Disconnect() end) end
    for i = 1, #drws do pcall(function() drws[i]:Remove() end) end
    if Window then
        Window.destroy()
    end
    getGenv()[id] = nil
end

local function addConn(c) table.insert(conns, c) end
local function addDrw(d) table.insert(drws, d); return d end

local safeSvc = function(n)
    local s = game:GetService(n)
    if cloneref then return cloneref(s) end
    return s
end

local plrs = safeSvc("Players")
local rs = safeSvc("RunService")
local uis = safeSvc("UserInputService")
local ws = safeSvc("Workspace")

local lplr = plrs.LocalPlayer
local cam = ws.CurrentCamera

local stgs = {
    aimOn = false,
    aimMeth = "Camera",
    aimFov = 160,
    aimSmth = 10,
    aimTgt = "Head",
    aimWall = false,
    aimTeam = false,
    aimPred = false,
    aimPredAmt = 0.142,
    espOn = true,
    espBox = true,
    espTr = true,
    espCol = Color3.fromRGB(100, 150, 255),
    espThk = 1.2
}

local fovCir = addDrw(Drawing.new("Circle"))
fovCir.Visible = false
fovCir.Color = Color3.fromRGB(255, 255, 255)
fovCir.Thickness = 1
fovCir.NumSides = 64
fovCir.Radius = stgs.aimFov
fovCir.Filled = false
fovCir.Transparency = 0.5

local tAim = UI.CreateTab(Window, "AIMBOT", 1)
local tEsp = UI.CreateTab(Window, "ESP", 2)
local tMsc = UI.CreateTab(Window, "MISC", 3)

UI.CreateToggle(tAim, "Aimbot Enabled", stgs.aimOn, function(v) stgs.aimOn = v; fovCir.Visible = v end)
UI.CreateDropdown(tAim, "Aimbot Method", {{name="CAMERA", val="Camera"}, {name="MOUSE", val="Mouse"}}, 1, function(v) stgs.aimMeth = v end)
UI.CreateSlider(tAim, "FOV Size", 10, 600, stgs.aimFov, function(v) return tostring(math.floor(v)) end, function(v) stgs.aimFov = v; fovCir.Radius = v end)
UI.CreateSlider(tAim, "Smoothness", 1, 50, stgs.aimSmth, function(v) return tostring(math.floor(v)) end, function(v) stgs.aimSmth = v end)
UI.CreateDropdown(tAim, "Target Part", {{name="HEAD", val="Head"}, {name="BODY", val="HumanoidRootPart"}}, 1, function(v) stgs.aimTgt = v end)
UI.CreateToggle(tAim, "Team Check", stgs.aimTeam, function(v) stgs.aimTeam = v end)
UI.CreateToggle(tAim, "Wall Check", stgs.aimWall, function(v) stgs.aimWall = v end)
UI.CreateToggle(tAim, "Prediction", stgs.aimPred, function(v) stgs.aimPred = v end)
UI.CreateSlider(tAim, "Pred Amount", 0.05, 0.3, stgs.aimPredAmt, function(v) return string.format("%.3f", v) end, function(v) stgs.aimPredAmt = v end)

UI.CreateToggle(tEsp, "ESP Enabled", stgs.espOn, function(v) stgs.espOn = v end)
UI.CreateToggle(tEsp, "ESP Boxes", stgs.espBox, function(v) stgs.espBox = v end)
UI.CreateToggle(tEsp, "ESP Tracers", stgs.espTr, function(v) stgs.espTr = v end)

UI.CreateButton(tMsc, "Boost FPS", function()
    local ter = safeSvc("Workspace").Terrain
    local lig = safeSvc("Lighting")
    pcall(function()
        ter.WaterWaveSize = 0
        ter.WaterWaveSpeed = 0
        ter.WaterReflectance = 0
        ter.WaterTransparency = 0
        lig.GlobalShadows = false
        lig.FogEnd = 9e9
        lig.Brightness = 0
    end)
    for _, v in pairs(lig:GetDescendants()) do
        if v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") then
            v.Enabled = false
        end
    end
    for _, v in pairs(ws:GetDescendants()) do
        if v:IsA("BasePart") and not v:IsA("MeshPart") then
            v.Material = Enum.Material.Plastic
            v.Reflectance = 0
        elseif v:IsA("Decal") or (v:IsA("Texture") and v.Texture ~= "rbxassetid://1813137837") then
            v.Transparency = 1
        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
            v.Lifetime = NumberRange.new(0)
        elseif v:IsA("Explosion") then
            v.BlastPressure = 1
            v.BlastRadius = 1
        elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") or v:IsA("Sparkles") then
            v.Enabled = false
        elseif v:IsA("MeshPart") then
            v.Material = Enum.Material.Plastic
            v.Reflectance = 0
        end
    end
end)

UI.CreateButton(tMsc, "Unload Script", function()
    if getGenv()[id] then getGenv()[id]() end
end)

local function GetTarget()
    local closest = nil
    local bestDist = stgs.aimFov

    for _, plr in ipairs(plrs:GetPlayers()) do
        if plr == lplr or not plr.Character or not plr.Character:FindFirstChild("Humanoid") or plr.Character.Humanoid.Health <= 0 then continue end
        if stgs.aimTeam and plr.Team == lplr.Team then continue end

        local part = plr.Character:FindFirstChild(stgs.aimTgt) or plr.Character:FindFirstChild("HumanoidRootPart")
        if not part then continue end

        local pos = part.Position
        if stgs.aimPred then
            pos = pos + (part.Velocity * stgs.aimPredAmt)
        end

        local screenPos, onScreen = cam:WorldToViewportPoint(pos)
        if not onScreen then continue end

        local center = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
        if stgs.aimMeth == "Mouse" then center = uis:GetMouseLocation() end
        
        local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
        if dist >= bestDist then continue end

        if stgs.aimWall then
            local rayParams = RaycastParams.new()
            local ignores = {cam}
            if lplr.Character then table.insert(ignores, lplr.Character) end
            rayParams.FilterDescendantsInstances = ignores
            rayParams.FilterType = Enum.RaycastFilterType.Blacklist
            local result = ws:Raycast(cam.CFrame.Position, pos - cam.CFrame.Position, rayParams)
            if result and not result.Instance:IsDescendantOf(plr.Character) then continue end
        end

        bestDist = dist
        closest = pos
    end
    return closest
end

local function drawEsp(plr)
    local box = addDrw(Drawing.new("Square"))
    local trc = addDrw(Drawing.new("Line"))
    local conn
    conn = rs.RenderStepped:Connect(function()
        if not plr or not plr.Parent then
            box.Visible = false
            trc.Visible = false
            if conn then conn:Disconnect() end
            return
        end
        local ok, err = pcall(function()
            if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 and plr ~= lplr then
                local hPos, onScr = cam:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position)
                if onScr and stgs.espOn then
                    if stgs.espBox then
                        local sx = 1000 / hPos.Z
                        local sy = 2000 / hPos.Z
                        box.Visible = true
                        box.Size = Vector2.new(sx, sy)
                        box.Position = Vector2.new(hPos.X - sx / 2, hPos.Y - sy / 2)
                        box.Color = stgs.espCol
                        box.Thickness = stgs.espThk
                    else
                        box.Visible = false
                    end
                    if stgs.espTr then
                        trc.Visible = true
                        trc.From = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
                        trc.To = Vector2.new(hPos.X, hPos.Y)
                        trc.Color = stgs.espCol
                        trc.Thickness = stgs.espThk
                    else
                        trc.Visible = false
                    end
                else
                    box.Visible = false
                    trc.Visible = false
                end
            else
                box.Visible = false
                trc.Visible = false
            end
        end)
        if not ok then
            box.Visible = false
            trc.Visible = false
        end
    end)
    addConn(conn)
end

local curPlrs = plrs:GetPlayers()
for i = 1, #curPlrs do
    drawEsp(curPlrs[i])
end
addConn(plrs.PlayerAdded:Connect(drawEsp))

local function aimStep()
    fovCir.Radius = stgs.aimFov
    local mPos = uis:GetMouseLocation()
    local centerPos = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
    if stgs.aimMeth == "Mouse" then
        fovCir.Position = mPos
    else
        fovCir.Position = centerPos
    end

    if not stgs.aimOn then
        fovCir.Color = Color3.fromRGB(255, 255, 255)
        return
    end

    local targetPos = GetTarget()
    if targetPos then
        fovCir.Color = Color3.fromRGB(0, 255, 0)
        if stgs.aimMeth == "Camera" then
            local look = CFrame.lookAt(cam.CFrame.Position, targetPos)
            cam.CFrame = cam.CFrame:Lerp(look, 1 / stgs.aimSmth)
        else
            if mousemoverel then
                local sPos = cam:WorldToScreenPoint(targetPos)
                local dx = sPos.X - mPos.X
                local dy = sPos.Y - mPos.Y
                mousemoverel(dx * (1 / stgs.aimSmth), dy * (1 / stgs.aimSmth))
            end
        end
    else
        fovCir.Color = Color3.fromRGB(255, 255, 255)
    end
end

addConn(rs.Heartbeat:Connect(aimStep))