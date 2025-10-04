return function (registry)
	registry:RegisterHook("BeforeRun", function(context)
		if context.Executor.Name ~= "Encryptal" and context.Executor.Name ~= "realaverageant" then
			return "You don't have permission to run this command"
		end
	end)
end
