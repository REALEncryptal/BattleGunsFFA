return function (registry)
	registry:RegisterType("entity", registry.Cmdr.Util.MakeEnumType("Entity", {"Default", "Immune", "Runner"}))
end