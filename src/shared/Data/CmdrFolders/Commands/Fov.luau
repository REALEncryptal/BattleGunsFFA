return {
	Name = "fov";
	Aliases = {"fov"};
	Description = "Modifies your FOV";
	Group = "Admin";
	Args = {
		{
			Type = "number";
			Name = "fov";
			Description = "The Fov you want";
			Optional = true
		}
	};
    ClientRun = function(context, fov)
		if fov then 
			workspace.CurrentCamera.FieldOfView = fov
		else
			workspace.CurrentCamera.FieldOfView = shared.Import("Constants").DEFAULT_FOV
		end

		return "Set FOV to "..workspace.CurrentCamera.FieldOfView
	end
}