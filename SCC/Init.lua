local Lib = {}

local isVirtual = false
local success, parent = pcall(function() return script.Parent end)
if not success or not parent or not script then
    isVirtual = true
end

local moduleCache = {}

local function getModule(name)
    if moduleCache[name] then
        return moduleCache[name]
    end
    
    local module
    if isVirtual then
        local baseUrl = "https://raw.githubusercontent.com/Hplayfree25/luaLibrary/refs/heads/master/SCC/"
        local code = game:HttpGet(baseUrl .. name .. ".lua")
        module = loadstring(code)()
    else
        local obj = script:FindFirstChild(name) or script.Parent:FindFirstChild(name)
        if obj then
            module = require(obj)
        else
            error("Module " .. name .. " not found!")
        end
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

function Lib.CreateWindow(options)
    return Lib.Window.new(options)
end

function Lib.CreateTab(window, name, order)
    return Lib.Components.Tab.new(window, name, order)
end

function Lib.CreateButton(tab, name, cb)
    return Lib.Components.Button.new(tab.container, name, cb)
end

function Lib.CreateToggle(tab, name, defaultState, cb)
    return Lib.Components.Toggle.new(tab.container, name, defaultState, cb)
end

function Lib.CreateSlider(tab, name, minVal, maxVal, defaultVal, formatFunc, cb)
    return Lib.Components.Slider.new(tab.container, name, minVal, maxVal, defaultVal, formatFunc, cb)
end

function Lib.CreateDropdown(tab, name, opts, defaultIdx, cb)
    return Lib.Components.Dropdown.new(tab.container, name, opts, defaultIdx, cb)
end

function Lib.CreateTextbox(tab, name, placeholderText, cb)
    return Lib.Components.Textbox.new(tab.container, name, placeholderText, cb)
end

function Lib.Notify(config)
    return Lib.Notification.show(config)
end

return Lib
