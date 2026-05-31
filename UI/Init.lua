local Lib = {}

Lib.Theme = require(script.Theme)
Lib.Utils = require(script.Utils)
Lib.Drag = require(script.Drag)
Lib.Window = require(script.Window)
Lib.Components = require(script.Components)

function Lib.CreateWindow(titleText)
    return Lib.Window.new(titleText)
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

return Lib
