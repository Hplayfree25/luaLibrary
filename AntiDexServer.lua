local rep = game:GetService("ReplicatedStorage")
local evt = Instance.new("RemoteEvent")
evt.Name = "DexEvt"
evt.Parent = rep

evt.OnServerEvent:Connect(function(plr, msg)
    if msg == "Dex" then
        plr:Kick("Dex Explorer Detected")
    end
end)
