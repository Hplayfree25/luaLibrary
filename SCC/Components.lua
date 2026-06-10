local Components = {}

local import = function(name)
    local ok, res = pcall(function() return require(script.Parent[name]) end)
    if ok then return res end
    return _G.UniversalUILib_GetModule(name)
end

Components.Button = import("Button")
Components.Toggle = import("Toggle")
Components.Slider = import("Slider")
Components.Dropdown = import("Dropdown")
Components.Textbox = import("Textbox")
Components.Label = import("Label")
Components.Keybind = import("Keybind")
Components.Tab = import("Tab")

return Components
