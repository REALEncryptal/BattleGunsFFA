local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

--[[

	Encryptal
	2025-02-18
	
	Literally just context action service but good

--]]

local Util = {
	_Keys = {}, -- store calbacks
	_Map = {}, -- store the position of those callbacks
	_Buttons = {},
	_TouchObjects = {},
	_Root = nil,
	
	_IsMobile = UserInputService:GetLastInputType() == Enum.UserInputType.Touch
}

-- methods
function Util:BindAction(Action, Callback, CreateMobileButton, ...)
	assert(typeof(Action)=="string", "[InputUtil] BindAction > Action must be a string not "..typeof(Action))
	assert(Util._Map[Action] == nil, "[InputUtil] BindAction > "..Action	.." has already been bound.")
	assert(typeof(Callback)=="function", "[InputUtil] BindAction > Callback must be a function not "..typeof(Callback))
	assert(typeof(CreateMobileButton)=="boolean", "[InputUtil] BindAction > CreateMobileButton must be a boolean not "..typeof(CreateMobileButton))
	
	-- go through each key
	for _, Input in ipairs({...}) do
		assert(typeof(Input)=="EnumItem" , "[InputUtil] BindAction > CreateMobileButton must be a KeyCode or UserInputType not "..typeof(Input))
		assert(tostring(Input.EnumType)=="KeyCode" or tostring(Input.EnumType)=="UserInputType" , "[InputUtil] BindAction > CreateMobileButton must be a KeyCode or UserInputType not "..tostring(Input.EnumType))
		
		-- create a table for the key if it doesnt exist
		Util._Keys[Input] = Util._Keys[Input] or {}
		Util._Map[Action] = Util._Map[Action] or {}

		Util._Keys[Input][Action] = Callback
		table.insert(Util._Map[Action], Input)
	end
	
	-- create ui if not made
	if not Util._Root then
		Util._Root = Instance.new("ScreenGui")
		Util._Root.Name = "InputUtil"
		Util._Root.ResetOnSpawn = false
		Util._Root.Parent = LocalPlayer.PlayerGui
	end
	
	-- check if mobile button needed
	if not CreateMobileButton then return end
	
	-- destroy existing button
	if Util._Buttons[Action] then
		Util._Buttons[Action]:Destroy()
	end
	
	-- create button
	Util._Buttons[Action] = Util:_CreateMobileButton()
	Util._Buttons[Action].Name = Action
	
	--
	Util:_ToggleMobileControls(Util._IsMobile)
	
	-- create signals
	Util._Buttons[Action].InputBegan:Connect(function(InputObject)
		if Util._TouchObjects[Action] or InputObject.UserInputType ~= Enum.UserInputType.Touch
			or InputObject.UserInputState ~= Enum.UserInputState.Begin then
			return
		end
		
		Util._TouchObjects[Action] = InputObject
		
		Util:_ChangeButtonRectOffset(Action, Vector2.new(1,1))
		Util._MobileInputEvent(Action, Enum.UserInputState.Begin)
	end)
	
	Util._Buttons[Action].InputEnded:Connect(function(InputObject)
		if InputObject ~= Util._TouchObjects[Action] then return end
		
		Util._TouchObjects[Action] = nil
		
		Util:_ChangeButtonRectOffset(Action, Vector2.new(0,1))
		Util._MobileInputEvent(Action, Enum.UserInputState.End)
	end)
end

function Util:UnbindAction(Action:string)
	assert(typeof(Action)=="string", "[InputUtil] UnbindAction > Action must be a string.")
	assert(Util._Map[Action], "[InputUtil] UnbindAction > "..Action.." has not been binded.")
	
	-- remove callbacks
	for _, Input in ipairs(Util._Map[Action]) do
		Util._Keys[Input][Action] = nil	
	end
	
	-- remove map
	Util._Map[Action] = nil
	
	-- remove button
	Util._Buttons[Action]:Destroy()
	Util._Buttons[Action] = nil
end

--
function Util:GetButton(Action:string):ImageButton
	assert(typeof(Action)=="string", "[InputUtil] GetButton > Action must be a string not "..typeof(Action))
	assert(Util._Buttons[Action], "[InputUtil] GetButton > "..Action.." has not been bound.")
	
	return Util._Buttons[Action]
end

function Util:SetImage(Action:string, Image:string)
	assert(typeof(Action)=="string", "[InputUtil] SetImage > Action must be a string not "..typeof(Action))
	assert(typeof(Image)=="string", "[InputUtil] SetImage > Image must be a string not "..typeof(Image))
	assert(Util._Buttons[Action], "[InputUtil] SetImage > "..Action.." has not been bound.")
	
	Util:GetButton(Action).Image = Image
end

function Util:SetPosition(Action:string, Position:UDim2)
	assert(typeof(Action)=="string", "[InputUtil] SetPosition > Action must be a string not "..typeof(Action))
	assert(typeof(Position)=="UDim2", "[InputUtil] SetPosition > Position must be a UDim2 not "..typeof(Position))
	assert(Util._Buttons[Action], "[InputUtil] SetPosition > "..Action.." has not been bound.")
	
	Util:GetButton(Action).Position = Position
end
	
function Util:SetSize(Action:string, Size:UDim2)
	assert(typeof(Action)=="string", "[InputUtil] SetSize > Action must be a string not "..typeof(Action))
	assert(typeof(Size)=="UDim2", "[InputUtil] SetSize > Size must be a UDim2 not "..typeof(Size))
	assert(Util._Buttons[Action], "[InputUtil] SetSize > "..Action.." has not been bound.")

	Util:GetButton(Action).Size = Size
end
	
function Util:GetRoot():ScreenGui
	return Util._Root
end

-- function
function Util:_CreateMobileButton():ImageButton
	local Button = Instance.new("ImageButton")
	
	--Button.AnchorPoint = Vector2.new(0.5, 0.5)
	Button.BackgroundTransparency = 1
	Button.Image = "rbxassetid://129197678592746"
	Button.ImageRectSize = Vector2.new(145,145)
	Button.ImageRectOffset = Vector2.new(0, 145)
	
	Util:_ResizeButton(Button)
	
	Button.Parent = Util._Root
	
	return Button
end

function Util:_ResizeButton(Image:ImageButton)
	local minAxis = math.min(Util._Root.AbsoluteSize.x, Util._Root.AbsoluteSize.y)
	local isSmallScreen = minAxis <= 500
	local buttonSize = isSmallScreen and 70 or 120

	Image.Size = UDim2.new(0, buttonSize, 0, buttonSize)
	Image.Position = isSmallScreen and UDim2.new(1, -(buttonSize*1.5-10), 1, -buttonSize - 20) or
		UDim2.new(1, -(buttonSize*1.5-10), 1, -buttonSize * 1.75)
end

function Util:_ChangeButtonRectOffset(Action:string, Vector:Vector2, Increment:number)
	Increment = Increment or 145
	
	Util:GetButton(Action).ImageRectOffset = Vector * Increment
end

function Util:_ToggleMobileControls(Show:boolean)
	if not Util._Root then return end
	
	Util._Root.Enabled = Show
end

-- handler
function Util._InputEvent(InputState:EnumItem, InputObject:InputObject, Processed:boolean)
	if Processed then return end
	-- get the input actions based on the input type
	local Input = InputObject.UserInputType == Enum.UserInputType.Keyboard and InputObject.KeyCode or InputObject.UserInputType
	local Actions = Util._Keys[Input]

	-- if theres no binded actions then return
	if not Actions then return end

	-- run callbacks
	for Action, Callback in pairs(Actions) do
		Callback(Action, InputState, InputObject)
	end
end

function Util._MobileInputEvent(Action:string, InputState:EnumItem)
	local Callback = Util._Keys[Util._Map[Action][1]][Action]
	
	Callback(Action, InputState, {UserInputType = Enum.UserInputType.Touch, UserInputState = InputState})
end

function Util._UpdateInputType(InputType)
	-- save initial state for later comparison
	local WasMobile = Util._IsMobile
	
	-- update state
	if InputType == Enum.UserInputType.Touch then
		Util._IsMobile = true
	else
		Util._IsMobile = false
	end
	
	-- update mobile buttons visibility if there was a change
	if WasMobile ~= Util._IsMobile then
		Util:_ToggleMobileControls(Util._IsMobile)
	end
end

-- connections
UserInputService.InputBegan:Connect(function(...)
	Util._InputEvent(Enum.UserInputState.Begin, ...)
end)

UserInputService.InputEnded:Connect(function(...)
	Util._InputEvent(Enum.UserInputState.End, ...)
end)

UserInputService.LastInputTypeChanged:Connect(Util._UpdateInputType)

-- util functions
function CountTable(Table:{any:any}):number
	local Count = 0
	
	for _,Value in pairs(Table) do
		if not Value then continue end
		Count += 1
	end
	
	return Count
end

return Util
