local rep = game:GetService("ReplicatedStorage")
local plrs = game:GetService("Players")
local lplr = plrs.LocalPlayer
local pgui = lplr:WaitForChild("PlayerGui")
local cg = game:GetService("CoreGui")
local evt = rep:WaitForChild("DexEvt")

local targets = {
    "Dex", "PropertiesFrame", "ExplorerPanel", "ConsoleHandler", 
    "TextSizeBox", "CtrlScroll", "AutoScroll", "BrickColor"
}

local function isTarget(obj)
    local n = obj.Name
    for _, t in ipairs(targets) do
        if n == t then return true end
    end
    return false
end

local function scan(par)
    for _, c in ipairs(par:GetDescendants()) do
        if isTarget(c) then
            evt:FireServer("Dex")
            return true
        end
    end
    return false
end

local function track(par)
    pcall(function()
        scan(par)
        par.DescendantAdded:Connect(function(c)
            if isTarget(c) then
                evt:FireServer("Dex")
            end
        end)
    end)
end

track(pgui)
track(cg)

task.spawn(function()
    while task.wait(3) do
        pcall(function() scan(cg) end)
        scan(pgui)
    end
end)
