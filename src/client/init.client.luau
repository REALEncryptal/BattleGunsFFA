--[[

    CITO CLIENT
    Initializes Cito loader with client modules.

    Encryptal 

--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cito = require(ReplicatedStorage.Shared:WaitForChild("Cito")).new()

Cito:Discover({ReplicatedStorage.Shared, script}) -- All descendent modules of these directories can be imported.
    :PreInit(ReplicatedStorage.Shared.SharedControllers)
    :PreInit(script.Controllers)
    :Init()

