local trans = {}
trans.__index = trans

local function linear(current_time, start_point, change, duration)
    return change * current_time / duration + start_point
end

local function easeIn(current_time, start_point, change, duration) -- accelerating from zero velocity 
    return change * math.pow(2, 10 * (current_time / duration - 1) + start_point)
end

local function easeOut(current_time, start_point, change, duration) -- decelerating to zero velocity
    return change * (-math.pow(2, -10 * current_time / duration) + 1) + start_point
end

local function easeInOut(current_time, start_point, change, duration) -- accelerating until halfway, then decelerating 
    current_time = current_time / (duration / 2)
    if current_time < 1 then return change / 2 * math.pow(2, 10 * (current_time - 1)) + start_point end
    current_time = current_time - 1
    return change / 2 * (-math.pow(2, -10 * current_time) + 2) + start_point
end

function NewTransition(start_point, end_point, duration, type)
    local t = {}
    t.type = type or "linear"
    t.current_point = start_point
    t.start_point = start_point
    t.end_point = end_point
    t.time_elapsed = 0
    t.duration = duration or 1
    t.done = false

    return setmetatable(t, trans)
end

function trans:update(dt)
    local values = {self.time_elapsed, self.start_point, self.end_point - self.start_point, self.duration}
    
    if self.type == "inOut" then
        self.current_point = math.min(easeInOut(unpack(values)), self.end_point)
    elseif self.type == "in" then
        self.current_point = math.min(easeIn(unpack(values)), self.end_point)
    elseif self.type == "out" then
        self.current_point = math.min(easeOut(unpack(values)), self.end_point)
    else
        self.current_point = math.min(linear(unpack(values)), self.end_point)
    end
    
    self.time_elapsed = self.time_elapsed + dt
    
    if self.time_elapsed >= self.duration then
        self.done = true
        return
    end
end

function trans:GetProgress()
    return self.current_point, self.time_elapsed
end

function trans:isDone() return self.done end