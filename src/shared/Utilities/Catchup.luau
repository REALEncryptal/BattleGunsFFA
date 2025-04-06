return function (initial, goal, increment)
    if initial == goal then
        return goal
    end

    if initial < goal then
        return math.min(initial + increment, goal)
    else
        return math.max(initial - increment, goal)
    end
end