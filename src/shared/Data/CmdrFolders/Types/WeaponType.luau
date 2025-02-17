local ReplicatedStorage = game:GetService("ReplicatedStorage")
return function (registry)
	local Weapons= ReplicatedStorage.Assets.AdminWeapons:GetChildren()
	for i, Weapon in ipairs(Weapons) do
		Weapons[i] = Weapon.Name
	end

	registry:RegisterType("weapon", registry.Cmdr.Util.MakeEnumType("Weapon", Weapons))
end