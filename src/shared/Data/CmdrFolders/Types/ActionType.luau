return function (registry)
	registry:RegisterType("action", registry.Cmdr.Util.MakeEnumType("Action", {"Set", "Get"}))
end