local scriptId = "UniversalUI_TestScript"
local getGenv = getgenv or function() return _G end

if getGenv()[scriptId] then
    pcall(getGenv()[scriptId])
end

local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Hplayfree25/luaLibrary/refs/heads/master/Init.lua?t=" .. tick()))()

local Window = UI.CreateWindow({
    Title = "Universal UI Test",
    ToggleText = "TST",
    Keybind = Enum.KeyCode.RightControl, -- Contoh kustomisasi keybind
    Size = UDim2.new(0, 500, 0, 300),
    HideOnStartup = true,
    OnIntroCompleted = function(win)
        UI.CreateAuth({
            Title = "Faldloudnd's App",
            Subtitle = "Please enter your KeyAuth license.",
            KeyPlaceholder = "Enter License Key...",
            SubmitText = "Verify Key",
            Links = {
                {
                    Name = "Get Key",
                    Icon = "rbxassetid://10709769508",
                    OnClick = function(lbl)
                        print("Opening Get Key link...")
                        -- setclipboard("https://link-to-key.com")
                        local oldText = lbl.Text
                        lbl.Text = "Copied!"
                        UI.Notify("Success", "Link Copied to Clipboard!", 3)
                        task.wait(1.5)
                        lbl.Text = oldText
                    end
                },
                {
                    Name = "Discord",
                    Icon = "rbxassetid://14800392398",
                    OnClick = function()
                        print("Opening Discord...")
                        -- setclipboard("https://discord.gg/nmzui")
                    end
                }
            },
            OnSubmit = function(key, callback)
                task.spawn(function()
                    UI.Notify("KeyAuth", "Connecting to server...", 2)
                    task.wait(1.5)
                    
                    -- Here you would put your actual KeyAuth HttpGet request
                    if key == "KEYAUTH-TEST-123" or key == "NMZUI_PREMIUM" then
                        callback(true)
                        win.show()
                        UI.Notify("KeyAuth", "License validated successfully!", 3)
                    else
                        callback(false)
                        UI.Notify("KeyAuth Error", "Invalid license key.", 3)
                    end
                end)
            end
        })
    end
})

getGenv()[scriptId] = function()
    if Window then
        Window.destroy()
    end
    getGenv()[scriptId] = nil
end

local Tab1 = UI.CreateTab(Window, "MAIN", 1)
local Tab2 = UI.CreateTab(Window, "SETTINGS", 2)

UI.CreateToggle(Tab1, {Name = "Test Toggle", Desc = "Ini adalah contoh deskripsi toggle"}, true, function(state)
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

UI.CreateButton(Tab2, {Name = "Send Test Notification", Desc = "Munculkan notif percobaan"}, function()
    UI.Notify("Universal UI", "This is a clean, modern notification toast!", 4)
end)

UI.CreateButton(Tab2, "Unload Script", function()
    if getGenv()[scriptId] then
        getGenv()[scriptId]()
    end
end)
