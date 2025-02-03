return {
	Name = "constant";
	Aliases = {"c"};
	Description = "Modifies a constant";
	Group = "Admin";
	Args = {
		{
			Type = "action";
			Name = "action";
			Description = "The action you want to perform";
		},
		{
			Type = "string";
			Name = "name";
			Description = "The name of the constant",
            Optional = true
		},
        {
            Type = "string",
            Name = "Value",
            Description = "The value that will be set",
            Optional = true
        }
	};
    ClientRun = shared.Import("ConstantCommandGet")
}