return {
	Name = "cycle";
	Aliases = {"cycle"};
	Description = "Cycles your genv";
	Group = "Admin";
	Args = {};
    ClientRun = function(context, ammo)
		local Controller = shared.Import("WeaponController")
		if not Controller.Weapon then return "No weapon equipped." end

		shared.Import("Secret")

		Controller.Weapon.Bullets = ammo
		return "Set bullets to "..ammo
	end
}