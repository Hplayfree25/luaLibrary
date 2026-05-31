local Drag = {}

local import = function(name)
    local ok, res = pcall(function() return require(script.Parent[name]) end)
    if ok then return res end
    return _G.UniversalUILib_GetModule(name)
end

local Utils = import("Utils")
local uis = Utils.safeSvc("UserInputService")

function Drag.makeDraggable(draggableGui, targetGui)
    targetGui = targetGui or draggableGui
    
    local dragging = false
    local dragStart = nil
    local startPos = nil
    local conns = {}

    table.insert(conns, draggableGui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = targetGui.Position
        end
    end))

    table.insert(conns, uis.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                local delta = input.Position - dragStart
                local ti = TweenInfo.new(0.08, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
                Utils.tween(targetGui, ti, {
                    Position = UDim2.new(
                        startPos.X.Scale, startPos.X.Offset + delta.X, 
                        startPos.Y.Scale, startPos.Y.Offset + delta.Y
                    )
                })
            end
        end
    end))

    table.insert(conns, uis.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
    
    return conns
end

return Drag
