local scriptId = "UniversalUI_TestScript"
local env = (getgenv or function() return _G end)()

if env[scriptId] then pcall(env[scriptId]) end

local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Hplayfree25/luaLibrary/refs/heads/master/Init.lua?t=" .. tick()))()
local Window = UI.CreateWindow({
    Title = "Universal UI Test",
    ToggleText = "TST",
    Keybind = Enum.KeyCode.RightControl,
    GamepadKeybind = Enum.KeyCode.ButtonStart,
    Size = UDim2.fromOffset(560, 380),
    HideOnStartup = true,
    OnIntroCompleted = function(win)
        assert(win.isReady(), "window must be ready after intro")
        UI.Notify({Title = "SCC Ready", Content = "Press RightControl, Start, or the mobile button.", Duration = 4})
    end
})

assert(not Window.isReady(), "window must remain locked during intro")

env[scriptId] = function()
    if Window then Window.destroy() end
    env[scriptId] = nil
end

local Main = UI.CreateTab(Window, "MAIN", 1)
local Settings = UI.CreateTab(Window, "SETTINGS", 2)

UI.CreateSection(Main, "AIM ASSIST")
UI.CreateLabel(Main, {
    Name = "Responsive controls",
    Desc = "Resize or rotate the screen to test the compact navigation layout."
})

local toggle = UI.CreateToggle(Main, {
    Name = "Test Toggle",
    Desc = "Supports mouse, touch, keyboard, and gamepad."
}, true, function(state)
    print("Toggle state:", state)
end)
assert(toggle.get() == true, "toggle default mismatch")

UI.CreateKeybind(Main, {
    Name = "Action Hotkey",
    Desc = "Select this control to capture a new key."
}, Enum.KeyCode.E, function()
    UI.Notify({Title = "Keybind", Content = "Action hotkey triggered.", Duration = 3})
end)

local slider = UI.CreateSlider(Main, {
    Name = "Test Slider",
    Desc = "Arrow keys and D-pad adjust the selected slider.",
    Min = 0,
    Max = 100,
    Default = 50,
    Step = 5,
    Format = function(value) return tostring(math.floor(value)) end,
}, function(value)
    print("Slider value:", value)
end)
assert(slider.get() == 50, "slider default mismatch")

local dropdown = UI.CreateDropdown(Main, "Test Dropdown", {
    {name = "Option A", val = "A"},
    {name = "Option B", val = "B"},
    {name = "Option C", val = "C"}
}, 1, function(value)
    print("Dropdown selection:", value)
end)
assert(dropdown.get() == "A", "dropdown default mismatch")

UI.CreateSeparator(Main)

UI.CreateSection(Settings, "INPUT & ACTIONS")
local textbox = UI.CreateTextbox(Settings, "Test Textbox", "Type something...", function(text, enterPressed)
    print("Textbox:", text, "| Enter:", enterPressed)
end)
textbox.set("SCC responsive test")
assert(textbox.get() == "SCC responsive test", "textbox setter mismatch")

UI.CreateButton(Settings, {
    Name = "Send Notification",
    Desc = "Shows a responsive notification with automatic text height."
}, function()
    UI.Notify({
        Title = "Universal UI",
        Content = "This notification adapts to narrow screens and longer wrapped content.",
        Duration = 4
    })
end)

local disabled = UI.CreateButton(Settings, "Disabled Button", function()
    error("disabled button should not run")
end)
disabled.setDisabled(true)

UI.CreateButton(Settings, "Unload Script", function()
    if env[scriptId] then env[scriptId]() end
end)
