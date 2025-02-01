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

    Controller.StateMachine:SetState("Initial")

    --
    Controller.IsVoting = false

    -- Events
    --TODO: Allow players to change their votes
    Event:Listen("Vote", function(Player, Map:Model)
        if not Controller.IsVoting then 
            if Constants.DEBUG then
                print("[GameController] Vote rejected - voting is not active")
            end
            return 
        end
        
        local Votes = Players:GetAttribute("Votes")
        if Votes <= 0 then 
            if Constants.DEBUG then
                print("[GameController] Vote rejected - player has no votes left")
            end
            return 
        end
        
        if not table.find(Controller.RandomMaps, Map) then 
            if Constants.DEBUG then
                print("[GameController] Vote rejected - invalid map")
            end
            return 
        end

        -- remove a vote
        Player:SetAttribute("Votes", Votes - 1)

        -- Store vote
        Controller.Votes[Map] = Controller.Votes[Map] or {}

        -- Insert
        table.insert(Controller.Votes[Map], Player)

        -- Alert players
        Event:FireAllClients("Vote", Player, Map)
        
        if Constants.DEBUG then
            print("[GameController] Vote recorded for", Map, "by", Player.Name)
        end
    end)

    Event:Listen("GameState", function(Player)
        -- Return current game state info
        if Controller.StateMachine.CurrentState == "MapVote" then
            return {
                State = "MapVote",
                Maps = Controller.RandomMaps,
                Votes = Controller.Votes,
                StartTime = Controller.VoteStart
            }
        end

        return {
            State = Controller.StateMachine.CurrentState,
            StartTime = Controller.GameInitialTick
        }
    end)
end

-- Events
function Controller.PlayerAdded(Player)
    local Data = Player:WaitForChild("Data")

    Player:SetAttribute("Votes", Data:GetAttribute("Votes"))
end

function Controller.Update(Delta)
    Controller.StateMachine:Update(Delta)
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
        Controller.GameInitialTick = tick()
        Event:FireAllClients("GameState", Controller.GameInitialTick)
    end,
    Update = function(delta)
        if tick() - Controller.GameInitialTick >= Constants.ROUND_TIME then
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
        Controller.VoteStart = tick()
        Controller:StartMapVote()
    end,
    Update = function()
        if tick() - Controller.VoteStart >= Constants.VOTE_TIME then
            Controller.StateMachine:SetState("GameLoop", Controller:GetVotedMap())
        end
    end
}

-- Functions
function Controller:StartMapVote()
    local Maps = ReplicatedStorage.Assets.Maps:GetChildren()

    -- select 3 random maps
    Controller.RandomMaps = {}

    for _ = 1, 3 do
        local RandomMap = Maps[math.random(1, #Maps)]

        -- add and remove
        table.insert(Controller.RandomMaps, RandomMap)
        table.remove(Maps, table.find(Maps, RandomMap)) -- prevent the same map from being selected
    end

    -- Get a vote from users
    Event:FireAllClients("MapVote", Controller.RandomMaps)

    -- Store votes
    Controller.Votes = {}
    Controller.IsVoting = true
end

function Controller:GetVotedMap():Model    
    -- Disable voting
    Controller.IsVoting = false

    -- allow players to vote again
    for _, Player in ipairs(Players:GetPlayers()) do
        Player:SetAttribute("Votes", Player:WaitForChild("Data"):GetAttribute("Votes"))
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
        if Constants.DEBUG then
            print("[GameController] No votes cast, selecting random map from voting pool")
        end
        VotedMap = Controller.RandomMaps[math.random(1, #Controller.RandomMaps)]
    end
    
    if Constants.DEBUG then
        print("[GameController] Voted map is", VotedMap, "with", maxVotes, "votes")
    end

    return VotedMap
end

function Controller:GetRandomMap():Model
    local Maps = ReplicatedStorage.Assets.Maps:GetChildren()

    return Maps[math.random(1, #Maps)]
end

return Controller