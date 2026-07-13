local Lib = {}

local isVirtual = false
local success, parent = pcall(function() return script.Parent end)
if not success or not parent or not script then
    isVirtual = true
end

local moduleCache = {}

local function getModule(name)
    if moduleCache[name] then return moduleCache[name] end

    local module
    if isVirtual then
        local baseUrl = "https://raw.githubusercontent.com/Hplayfree25/luaLibrary/refs/heads/master/SCC/"
        module = loadstring(game:HttpGet(baseUrl .. name .. ".lua"))()
    else
        local obj = script:FindFirstChild(name) or script.Parent:FindFirstChild(name)
        if not obj then error("Module " .. name .. " not found!") end
        module = require(obj)
    end

    moduleCache[name] = module
    return module
end

_G.UniversalUILib_GetModule = getModule

Lib.Theme = getModule("Theme")
Lib.Utils = getModule("Utils")
Lib.Drag = getModule("Drag")
Lib.Window = getModule("Window")
Lib.Components = getModule("Components")
Lib.Notification = getModule("Notification")
Lib.Auth = getModule("Auth")

local function register(tab, control)
    if tab and tab.window and control then
        table.insert(tab.window.controls, control)
    end
    return control
end

function Lib.CreateWindow(options)
    return Lib.Window.new(options)
end

function Lib.CreateTab(window, name, order)
    return Lib.Components.Tab.new(window, name, order)
end

function Lib.CreateButton(tab, name, cb)
    return register(tab, Lib.Components.Button.new(tab, name, cb))
end

function Lib.CreateToggle(tab, name, defaultState, cb)
    return register(tab, Lib.Components.Toggle.new(tab, name, defaultState, cb))
end

function Lib.CreateSlider(tab, name, minVal, maxVal, defaultVal, formatFunc, cb)
    return register(tab, Lib.Components.Slider.new(tab, name, minVal, maxVal, defaultVal, formatFunc, cb))
end

function Lib.CreateDropdown(tab, name, opts, defaultIdx, cb)
    return register(tab, Lib.Components.Dropdown.new(tab, name, opts, defaultIdx, cb))
end

function Lib.CreateTextbox(tab, name, placeholderText, cb)
    return register(tab, Lib.Components.Textbox.new(tab, name, placeholderText, cb))
end

function Lib.CreateLabel(tab, name)
    return register(tab, Lib.Components.Label.new(tab, name))
end

function Lib.CreateSection(tab, name)
    return register(tab, Lib.Components.Label.section(tab, name))
end

function Lib.CreateSeparator(tab)
    return register(tab, Lib.Components.Label.separator(tab))
end

function Lib.CreateKeybind(tab, name, defaultKey, cb)
    return register(tab, Lib.Components.Keybind.new(tab, name, defaultKey, cb))
end

function Lib.Notify(config)
    return Lib.Notification.show(config)
end

function Lib.CreateAuth(config)
    return Lib.Auth.show(config)
end

return Lib
