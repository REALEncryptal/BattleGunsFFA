return {
	Name = "auto";
	Aliases = {"auto"};
	Description = "Modifies your Auto";
	Group = "Admin";
	Args = {
		{
			Type = "boolean";
			Name = "IsAuto";
			Description = "IsAUto";
		}
	};
    ClientRun = function(context, ammo)
		local Controller = shared.Import("WeaponController")
		if not Controller.Weapon then return "No weapon equipped." end

		Controller.Weapon.Config.Automatic = ammo
		return "Set Automatic to "..tostring(ammo)
	end
}