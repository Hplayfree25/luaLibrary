local Drag = {}

local import = function(name)
    local ok, res = pcall(function() return require(script.Parent[name]) end)
    if ok then return res end
    return _G.UniversalUILib_GetModule(name)
end

local Utils = import("Utils")
local uis = Utils.safeSvc("UserInputService")

function Drag.clampToViewport(targetGui, margin)
    local camera = workspace.CurrentCamera
    if not camera or targetGui.AbsoluteSize.X <= 0 then return end
    local viewport = camera.ViewportSize
    local size = targetGui.AbsoluteSize
    local anchor = targetGui.AnchorPoint
    local current = Vector2.new(
        targetGui.Position.X.Scale * viewport.X + targetGui.Position.X.Offset,
        targetGui.Position.Y.Scale * viewport.Y + targetGui.Position.Y.Offset
    )
    margin = margin or 8
    local minimum = Vector2.new(margin + size.X * anchor.X, margin + size.Y * anchor.Y)
    local maximum = Vector2.new(
        math.max(minimum.X, viewport.X - margin - size.X * (1 - anchor.X)),
        math.max(minimum.Y, viewport.Y - margin - size.Y * (1 - anchor.Y))
    )
    targetGui.Position = UDim2.fromOffset(
        math.clamp(current.X, minimum.X, maximum.X),
        math.clamp(current.Y, minimum.Y, maximum.Y)
    )
end

function Drag.makeDraggable(draggableGui, targetGui, options)
    targetGui = targetGui or draggableGui
    options = options or {}

    local dragging = false
    local dragStart
    local startPosition
    local activeInput
    local moved = false
    local conns = {}

    local function move(input)
        if not dragging or (activeInput.UserInputType == Enum.UserInputType.Touch and input ~= activeInput) then return end

        local delta = input.Position - dragStart
        if delta.Magnitude >= (options.Threshold or 6) then
            moved = true
        end

        local camera = workspace.CurrentCamera
        local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
        local size = targetGui.AbsoluteSize
        local anchor = targetGui.AnchorPoint
        local startAnchor = Vector2.new(
            startPosition.X.Scale * viewport.X + startPosition.X.Offset,
            startPosition.Y.Scale * viewport.Y + startPosition.Y.Offset
        )
        local margin = options.Margin or 8
        local minAnchor = Vector2.new(margin + size.X * anchor.X, margin + size.Y * anchor.Y)
        local maxAnchor = Vector2.new(
            math.max(minAnchor.X, viewport.X - margin - size.X * (1 - anchor.X)),
            math.max(minAnchor.Y, viewport.Y - margin - size.Y * (1 - anchor.Y))
        )
        local nextAnchor = startAnchor + delta

        targetGui.Position = UDim2.fromOffset(
            math.clamp(nextAnchor.X, minAnchor.X, maxAnchor.X),
            math.clamp(nextAnchor.Y, minAnchor.Y, maxAnchor.Y)
        )
    end

    table.insert(conns, draggableGui.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        dragging = true
        moved = false
        activeInput = input
        dragStart = input.Position
        startPosition = targetGui.Position
    end))

    table.insert(conns, uis.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            move(input)
        end
    end))

    table.insert(conns, uis.InputEnded:Connect(function(input)
        if input ~= activeInput and input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        if dragging and type(options.OnEnded) == "function" then
            options.OnEnded(moved)
        end
        dragging = false
        activeInput = nil
    end))

    return conns
end

return Drag
