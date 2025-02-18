local ReplicatedStorage = game:GetService("ReplicatedStorage")
return function (registry)
	local Names = {}

	for _, Bot in ipairs(ReplicatedStorage.Assets.Bots:GetChildren()) do
		table.insert(Names, Bot.Name)
	end

	registry:RegisterType("entity", registry.Cmdr.Util.MakeEnumType("Entity", Names))
end