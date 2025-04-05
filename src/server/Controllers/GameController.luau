local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Controller = {}

Controller.States = {}

local Constants, Event, StateMachine

function Controller:Init()
    Constants = shared.Import "Constants"
    Event = shared.Import "Event"
    StateMachine = shared.Import "StateMachine"

    --
    Controller.StateMachine = StateMachine.new()
    local Empty = function()end

    for StateName, StateData in pairs(Controller.States) do
        Controller.StateMachine:AddState(
            StateName,
            StateData.Start or Empty, 
            StateData.Update or Empty, 
            StateData.End or Empty
        )
    end

    if Constants.LOOP then 
        Controller.StateMachine:SetState("Initial")
    end

    --
    Controller.IsVoting = false

    -- Events
    --TODO: Allow players to change their votes
    Event:Listen("Vote", function(Player, MapName)
        if not Controller.IsVoting then 
            Constants:Debug("[GameController] Vote rejected - voting is not active")
            return 
        end
        
        local Votes = Player:GetAttribute("Votes")
        if Votes <= 0 then 
            Constants:Debug("[GameController] Changing votes")

            -- remove the player from the previous vote
            for Map, Players in pairs(Controller.Votes) do
                local Index = table.find(Players, Player)
                if not Index then continue end

                table.remove(Controller.Votes[Map], Index)
                print("Removed", Player.Name, "from", Map)
            end

            -- add a vote
            Player:SetAttribute("Votes", 1)
        end
        
        if not table.find(Controller.RandomMaps, MapName) then 
            Constants:Debug("[GameController] Vote rejected - invalid map")
            return 
        end

        -- remove a vote
        Player:SetAttribute("Votes", Votes - 1)

        -- Store vote
        Controller.Votes[MapName] = Controller.Votes[MapName] or {}

        -- Insert
        table.insert(Controller.Votes[MapName], Player)

        -- Alert players
        Event:FireAllClients("Vote", Player, MapName)

        Constants:Debug("[GameController] Vote recorded for", MapName, "by", Player.Name)
    end)

    Event:Listen("GameState", function(Player)
        if not Constants.LOOP then
            return {
                State = "Test",
                StartTime = workspace:GetServerTimeNow()
            }
        end

        -- Return current game state info
        if Controller.StateMachine.CurrentStateName == "MapVote" then
            return {
                State = "MapVote",
                Maps = Controller.RandomMaps,
                Votes = Controller.Votes,
                StartTime = Controller.VoteStart
            }
        end

        return {
            State = Controller.StateMachine.CurrentStateName,
            StartTime = Controller.GameInitialTick
        }
    end)
end

-- Events
function Controller.PlayerAdded(Player)
    local Data = Player:FindFirstChild("Data")

    Player:SetAttribute("Votes", if Data then Data:GetAttribute("Votes") else 1)
end

function Controller.Update(Delta)
    if Constants.LOOP then
        if not Controller.StateMachine.CurrentState then
            Controller.StateMachine:SetState("Initial")
        end
        Controller.StateMachine:Update(Delta)
    end
end

-- States
-- When the game starts
Controller.States.Initial = {
    Start = function()
        Controller.StateMachine:SetState("GameLoop", Controller:GetRandomMap())
    end
}

-- After map has been selected
Controller.States.GameLoop = {
    Start = function(Map)
        Controller.Map = Map:Clone()

        Controller.Map.Parent = workspace.Map
        Controller.GameInitialTick = workspace:GetServerTimeNow()
        Event:FireAllClients("GameState", {
            State = Controller.StateMachine.CurrentStateName,
            StartTime = Controller.GameInitialTick
        })

        for _, Player:Player in ipairs(Players:GetPlayers()) do
            Player:SetAttribute("Kills", 0)
            Player:SetAttribute("KillStreak", 0)
            Player:LoadCharacter()
        end
    end,
    Update = function(delta)
        if workspace:GetServerTimeNow() - Controller.GameInitialTick >= Constants.ROUND_TIME then
            Controller.StateMachine:SetState("MapVote")
        end
    end,
    End = function()
        Controller.Map:Destroy()
        Controller.Map = nil
    end
}

-- Map Vote
Controller.States.MapVote = {
    Start = function()
        Controller.VoteStart = workspace:GetServerTimeNow()

        Event:FireAllClients("GameState", {
            State = Controller.StateMachine.CurrentStateName,
            StartTime = Controller.VoteStart
        })
        Controller:StartMapVote()
    end,
    Update = function()
        if workspace:GetServerTimeNow() - Controller.VoteStart >= Constants.VOTE_TIME then
            local Map = ReplicatedStorage.Assets.Maps:FindFirstChild(Controller:GetVotedMap())
            Controller.StateMachine:SetState("GameLoop", Map)
        end
    end,
    End = function()
        Event:FireAllClients("MapVoteEnd")
    end
}

-- Functions
function Controller:StartMapVote()
    local Maps = ReplicatedStorage.Assets.Maps:GetChildren()

    -- select 3 random maps
    Controller.RandomMaps = {}

    for _ = 1, 3 do
        -- check if there are enough maps
        if #Maps <= 0 then
            break
        end

        -- select a random map
        local RandomMap = Maps[math.random(1, #Maps)]

        -- add and remove
        table.insert(Controller.RandomMaps, RandomMap.Name)
        table.remove(Maps, table.find(Maps, RandomMap)) -- prevent the same map from being selected
    end

    if #Controller.RandomMaps <= 1 then
        Constants:Debug("[GameController] Skipping map vote -  not enough maps")
        Controller.StateMachine:SetState("GameLoop", Controller:GetRandomMap())
    else
        -- Get a vote from users
        Event:FireAllClients("MapVote", Controller.RandomMaps)
    end

    -- Store votes
    Controller.Votes = {}
    Controller.IsVoting = true
end

function Controller:GetVotedMap()    
    -- Disable voting
    Controller.IsVoting = false

    -- allow players to vote again
    for _, Player in ipairs(Players:GetPlayers()) do
        Player:SetAttribute("Votes", Player:FindFirstChild("Data"):GetAttribute("Votes") or 1)
    end

    -- find the map with the most votes
    local VotedMap = nil
    local maxVotes = 0

    for Map, Votes in pairs(Controller.Votes) do
        if #Votes > maxVotes then
            VotedMap = Map
            maxVotes = #Votes
        end
    end
    
    -- If no votes were cast, return a random map from the voting pool
    if not VotedMap then
        Constants:Debug("[GameController] No votes cast, selecting random map from voting pool")
        VotedMap = Controller.RandomMaps[math.random(1, #Controller.RandomMaps)]
    end
    
    Constants:Debug("[GameController] Voted map is", VotedMap, "with", maxVotes, "votes")

    return VotedMap
end

function Controller:GetRandomMap():Model
    local Maps = ReplicatedStorage.Assets.Maps:GetChildren()

    return Maps[math.random(1, #Maps)]
end

return Controller