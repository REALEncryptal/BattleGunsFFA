return {
	Name = "ammo";
	Aliases = {"am"};
	Description = "Modifies your ammo";
	Group = "Admin";
	Args = {
		{
			Type = "number";
			Name = "Ammo";
			Description = "The amount of ammo you want to have";
		}
	};
    ClientRun = function(context, ammo)
		local Controller = shared.Import("WeaponController")
		if not Controller.Weapon then return "No weapon equipped." end

		Controller.Weapon.Bullets = ammo
		return "Set bullets to "..ammo
	end
}