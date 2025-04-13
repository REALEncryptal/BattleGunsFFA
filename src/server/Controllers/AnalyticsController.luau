local Controller = {}

local AnalyticsService = game:GetService("AnalyticsService")

local Event

function Controller:Init()
    Event = shared.Import "Event"

    -- Events
    Event:Listen("FunnelStep", Controller.FunnelStep)
end


return Controller