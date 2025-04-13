return {
	Name = "rpm";
	Aliases = {"rpm"};
	Description = "Modifies your RPM";
	Group = "Admin";
	Args = {
		{
			Type = "number";
			Name = "RPM";
			Description = "The amount of RPM you want to have";
		}
	};
    ClientRun = function(context, ammo)
		local Controller = shared.Import("WeaponController")
		if not Controller.Weapon then return "No weapon equipped." end

		Controller.Weapon.Config.RPM = ammo
		return "Set RPM to "..ammo
	end
}