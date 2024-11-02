local Controller = {}

local Event
function Controller:Init()
    print("ResetController Init")
    Event = shared.Import "Event"
    local ResetEvent = Instance.new("BindableEvent")

    local coreCall do
        local MAX_RETRIES = 8
    
        local StarterGui = game:GetService('StarterGui')
        local RunService = game:GetService('RunService')
    
        function coreCall(method, ...)
            local result = {}
            for retries = 1, MAX_RETRIES do
                result = {pcall(StarterGui[method], StarterGui, ...)}
                if result[1] then
                    break
                end
                RunService.Stepped:Wait()
            end
            return unpack(result)
        end
    end
    
    coreCall('SetCore', 'ResetButtonCallback', ResetEvent)

    ResetEvent.Event:Connect(function()
        Event:FireServer("Reset")
    end)
end

return Controller