local Utils = {}

function Utils.safeSvc(n)
    local s = game:GetService(n)
    if cloneref then return cloneref(s) end
    return s
end

function Utils.getSafeGui()
    if gethui then return gethui() end
    local lplr = Utils.safeSvc("Players").LocalPlayer
    local cgOk, cg = pcall(function() return Utils.safeSvc("CoreGui") end)
    if cgOk and cg then return cg end
    return lplr:WaitForChild("PlayerGui")
end

function Utils.tween(obj, info, props)
    local ts = Utils.safeSvc("TweenService")
    local tw = ts:Create(obj, info, props)
    tw:Play()
    return tw
end

return Utils
