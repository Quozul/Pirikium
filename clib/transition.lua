local transitions = {}

function NewTransition(name, start_point, end_point, duration)
    local t = {}
    t.current_point = start_point
    t.end_point = end_point
    t.time_elapsed = 0
    t.duration = duration

    table.insert(t, transitions, name)
end

function UpdateTransitions(dt)
    for name, trans in pairs(transitions) do
        math.min(trans.current_point + dt, trans.end_point)
        trans.time_elapsed = trans.time_elapsed + dt

        if trans.time_elapsed >= duration then
            table.remove(transitions, name)
        end
    end
end

function GetProgress(name)
    return transitions[name].current_point
end