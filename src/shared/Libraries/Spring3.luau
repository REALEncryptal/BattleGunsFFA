--[[
    [Spring3]
Created by Encryptal
2023-11-14

Sources

https://forum.unity.com/threads/spring-simulation.245592/
https://www.khanacademy.org/science/physics/work-and-energy/hookes-law/a/what-is-hookes-law

youtube video that i cant find    

]]

local Spring = {}
Spring.__index = Spring

local Quality = 8
local V_ZERO = Vector3.zero

local function MaxClamp(list, n)
    local new = table.clone(list)
    
    for i,v in pairs(new) do
        if v>n or v < -n then
            new[i] = 0
        end
    end
    
    return new
end

function Spring.new(mass:number, force:number, damping:number, speed:number)
    local self = setmetatable({},Spring)
    
    -- Consts
    self.Mass = mass or 5
    self.Force = force or 50
    self.Damping = damping or 4
    self.Speed = speed or 4


    
    -- Dynamics
    self.Target     = V_ZERO
    self.Position = V_ZERO
    self.Velocity = V_ZERO

    return self
end

function Spring:Shove(force:Vector3)
    self.Velocity += force
end

function Spring:Update(DeltaTime:number): Vector3
    local sdt = 0
    
    if DeltaTime > 1 then
        sdt = 1 * self.Speed
    elseif DeltaTime < 1 then
        sdt = DeltaTime * self.Speed
    end
    
    for i = 1, Quality do
        self.Velocity = self.Velocity + ((((self.Target - self.Position) * self.Force) / self.Mass) - self.Velocity * self.Damping) * (sdt/Quality)
        self.Position = self.Position + self.Velocity * (sdt/Quality)
    end
    
    return self.Position
end

return Spring