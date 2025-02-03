return {
	Name = "summon";
	Aliases = {"su"};
	Description = "Summons entities on mouse";
	Group = "Admin";
	Args = {
		{
			Type = "entity";
			Name = "entity";
			Description = "The entity to spawn";
		},
		{
			Type = "number";
			Name = "amount";
			Description = "Amount of entities to spawn"
		}
	};

    Data = function()
		return game.Players.LocalPlayer:GetMouse().Hit.Position
	end
}