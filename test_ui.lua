local scriptId = "UniversalUI_TestScript"
local getGenv = getgenv or function() return _G end

if getGenv()[scriptId] then
    pcall(getGenv()[scriptId])
end

local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Hplayfree25/luaLibrary/refs/heads/master/Init.lua?t=" .. tick()))()

local Window = UI.CreateWindow({
    Title = "Universal UI Test",
    ToggleText = "TST",
    Size = UDim2.new(0, 500, 0, 300)
})

UI.Notify("Universal UI", "NMZUI successfully loaded!", 4)

getGenv()[scriptId] = function()
    if Window then
        Window.destroy()
    end
    getGenv()[scriptId] = nil
end

local Tab1 = UI.CreateTab(Window, "MAIN", 1)
local Tab2 = UI.CreateTab(Window, "SETTINGS", 2)

UI.CreateToggle(Tab1, "Test Toggle", true, function(state)
    print("Toggle state changed to:", state)
end)

UI.CreateSlider(Tab1, "Test Slider", 0, 100, 50, function(v) return tostring(math.floor(v)) end, function(v)
    print("Slider value changed to:", v)
end)

UI.CreateDropdown(Tab1, "Test Dropdown", {
    {name = "Option A", val = "A"},
    {name = "Option B", val = "B"},
    {name = "Option C", val = "C"}
}, 1, function(val)
    print("Dropdown selection changed to:", val)
end)

UI.CreateTextbox(Tab2, "Test Textbox", "Type something...", function(text, enterPressed)
    print("Textbox text changed to:", text, "| Enter pressed:", enterPressed)
end)

UI.CreateButton(Tab2, "Send Test Notification", function()
    UI.Notify("Universal UI", "This is a clean, modern notification toast!", 4)
end)

UI.CreateButton(Tab2, "Unload Script", function()
    if getGenv()[scriptId] then
        getGenv()[scriptId]()
    end
end)
