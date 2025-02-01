local FSM = {}
FSM.__index = FSM

--[[

    Simple Finite State Machine
    Encryptal Oct 8 2024

]]

function FSM.new()
    local self = setmetatable({}, FSM)

    self.States = {}
    self.CurrentState = nil
    self.Enabled = true
    self.Debug = shared.Import("Constants").DEBUG

    return self
end

function FSM:AddState(StateName, StartFunction, UpdateFunction, EndFunction)
    self.States[StateName] = {
        Start = StartFunction,
        Update = UpdateFunction,
        End = EndFunction,
    }

    if self.Debug then print("[FSM] Added state", StateName) end
end

function FSM:SetState(StateName, ...)
    if self.CurrentState then
        task.spawn(function()   
            self.CurrentState.End()
        end)

        if self.Debug then print("[FSM] Ending state", StateName) end
    end

    if self.Debug then print("[FSM] Starting state", StateName) end
    self.CurrentState = self.States[StateName] 
    self.States[StateName].Start(...)
end

function FSM:Update(DeltaTime)
    if not self.Enabled then return end
    if not self.CurrentState then return end

    self.CurrentState.Update(DeltaTime)
end

return FSM