--[[

    CITO CLIENT
    Initializes Cito loader with client modules.

    Encryptal 

--]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cito = require(ReplicatedStorage.Shared:WaitForChild("Cito")).new()

Cito:Discover({ReplicatedStorage.Shared, script}) -- All descendent modules of these directories can be imported.
    :PreInit(ReplicatedStorage.Shared.SharedControllers:GetDescendants())
    :PreInit(script.Controllers:GetDescendants())
    :Init()
    :PreInit(CollectionService:GetTagged("CitoController"))
    :Init()