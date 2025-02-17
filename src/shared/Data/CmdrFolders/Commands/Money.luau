return {
	Name = "money";
	Aliases = {"m"};
	Description = "Gives you specified money";
	Group = "Admin";
	Args = {
		{
			Type = "number";
			Name = "Money";
			Description = "The amount of money you want to have";
		},
		{
			Type = "player";
			Name = "Player";
			Description = "The player you want to give the money to";
			Optional = true;
		},
		{
			Type = "boolean";
			Name = "Add";
			Description = "If you want to add the money to the player";
			Optional = true;
		};
	};
}