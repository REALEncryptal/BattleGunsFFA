function tabletostring(v, spaces, usesemicolon, depth)
	if type(v) ~= 'table' then
		return tostring(v)
	elseif not next(v) then
		return '{}'
	end

	spaces = spaces or 4
	depth = depth or 1

	local space = (" "):rep(depth * spaces)
	local sep = usesemicolon and ";" or ","
	local concatenationBuilder = {"{"}
	
	for k, x in next, v do
		table.insert(concatenationBuilder, ("\n%s[%s] = %s%s"):format(space,type(k)=='number'and tostring(k)or('"%s"'):format(tostring(k)), tabletostring(x, spaces, usesemicolon, depth+1), sep))
	end

	local s = table.concat(concatenationBuilder)
	return ("%s\n%s}"):format(s:sub(1,-2), space:sub(1, -spaces-1))
end

local IsServer = game:GetService("RunService"):IsServer()

return function (context, action, name, value:string)
	local Constants = shared.Import "Constants"

	if not name then
        if not IsServer then return end
		return tabletostring(Constants)
	end

	local RequestedValue = Constants[name]
	if RequestedValue == nil then 
        if not IsServer then return end
        return name .. " is not a valid constant. type <constant get> to see all constants." 
    end

	local RequestedValueType = typeof(RequestedValue)

	if action == "Get" then
		if RequestedValueType == "table" then
			RequestedValue = tabletostring(RequestedValue)
		end

        if not IsServer then return end
		return name.." ["..tostring(RequestedValueType).."]: "..tostring(RequestedValue)
	end

	if not table.find({"string", "boolean", "number"}, RequestedValueType) then 
        if not IsServer then return end
        return "Type "..RequestedValueType.." is not supported." 
    end

	if RequestedValueType == "string" then
		value = tostring(value)
	elseif  RequestedValueType == "number" then
		value = tonumber(value)
	elseif  RequestedValueType == "boolean" then
		value = value:lower() == "true"
	end

	Constants[name] = value

    if not IsServer then return end
	return "Set ".. name.." to "..tostring(value).." with type "..tostring(RequestedValueType)
end