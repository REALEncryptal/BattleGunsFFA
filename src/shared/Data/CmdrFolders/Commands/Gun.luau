return {
	Name = "Gun";
	Aliases = {"g"};
	Description = "Gives you specified gun";
	Group = "Admin";
	Args = {
		{
			Type = "weapon";
			Name = "Name";
			Description = "The name of the gun you want to have";
		},
		{
			Type = "player";
			Name = "Player";
			Description = "The player you want to give the gun to";
			Optional = true;
		},
	};
}