--[[

    CITO LOADER
    Requires, initializes, and connects events for all modules.

    Encryptal 

--]]


local Cito = {}
Cito.__index = Cito
local CollectionService = game:GetService("CollectionService")

local RunService  = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Librarian = require(script.Librarian)
local Signal = require(script.Parent.Packages._Index["sleitnick_signal@2.0.1"].signal)

local IsServer = RunService:IsServer()

function Cito.new()
	local self = setmetatable({}, Cito)

	_G.CitoLoaded = Signal.new()
	self.Controllers = {}

	return self
end

function Cito:Discover(Path)
	self.Paths = Path

	Librarian:Init(self.Paths)

	return self
end

function Cito:PreInit(Paths: {}, Log:boolean)
	for _, Module in ipairs(Paths) do
		if not Module:IsA("ModuleScript") then continue end

		if Log then print("[CITO] Loading module: " .. Module.Name) end

		-- handle externl controllers
		local ModuleIsServer = Module:GetAttribute("IsServer")
		if ModuleIsServer ~= nil then
			if Log then print("[CITO] Module: " .. Module.Name .. " is server: " .. tostring(ModuleIsServer)) end
			if ModuleIsServer ~= IsServer then continue end
			if Log then print("[CITO] Runnning module on: "..(IsServer and "Server" or "Client")) end
		end

		local Name = Module.Name

		-- setup
		Module = require(Module)
		table.insert(self.Controllers, Module)

		Module._NAME = Name
		

		if Module.PreInit then
			-- we want this to finish before we continue
			Module:PreInit()
		end
	end

	return self
end

function Cito:Init(Log:boolean)
	for _, Module in ipairs(self.Controllers) do
		if Module._INITIALIZED then continue end
		if Log then print("[CITO] Initializing module: " .. Module._NAME) end

		if Module.Init then
			-- we dont care if this finishes
			task.spawn(Module.Init)
		end
	end

	local BuiltFunctions = {
		Update = function(Callback)
			if RunService:IsClient() then
				RunService.RenderStepped:Connect(Callback)
			else
				RunService.Heartbeat:Connect(Callback)
			end
		end,
		InputBegan = function(Callback)
			UserInputService.InputBegan:Connect(Callback)
		end,
		InputEnded = function(Callback)
			UserInputService.InputEnded:Connect(Callback)
		end,
		PlayerAdded = function(Callback)
			game.Players.PlayerAdded:Connect(Callback)
		end,
		PlayerRemoving = function(Callback)
			game.Players.PlayerRemoving:Connect(Callback)
		end,
		CharacterAdded = function(Callback)
			if not RunService:IsClient() then return end
			game.Players.LocalPlayer.CharacterAdded:Connect(Callback)
		end,
		CharacterRemoving = function(Callback)
			if not RunService:IsClient() then return end
			game.Players.LocalPlayer.CharacterRemoving:Connect(Callback)
		end
	}

	for _, Module in ipairs(self.Controllers) do
		if Module._INITIALIZED then continue end
		Module._INITIALIZED = true

		if Log then print("[CITO] Initializing functions for module: " .. Module._NAME) end

		for Name, Function in pairs(BuiltFunctions) do
			if not Module[Name] then continue end

			task.spawn(Function, Module[Name])
		end
	end

	_G.CitoLoaded:Fire()

	return self
end

return Cito