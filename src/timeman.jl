mutable struct TimeManagement
    move_overhead::Int # UCI can set a move overhead value.
    isinfinite::Bool # Has UCI told us we have infinite thinking time?
    movetime::Int # Has UCI specified a move time?
    depth::Int # Has UCI specified a depth?

    start_time::Float64 # Grab the search start time.
    clock_time::Int # Grab the clock time of the turn to move.
    inc_time::Int # Get the time increment
    movestogo::Int # Get the number of moves to go.

    ideal_time::Int # Ideal time we should aim for
    max_time::Int # Maximum time available
end


TimeManagement() = TimeManagement(100, false, 0, 0, 0, 0, 0, 0, 0, 0)


elapsedtime(timeman::TimeManagement) = (time() - timeman.start_time) * 1000


# Not all time management features are supported yet.
function initTimeManagement!(timeman::TimeManagement)
    if timeman.movestogo == -1
        timeman.ideal_time = fld(timeman.clock_time + 20*timeman.inc_time, 45)
        timeman.max_time = 10 * fld(timeman.clock_time + 20*timeman.inc_time, 45)
    else
        timeman.ideal_time = fld(timeman.clock_time, timeman.movestogo + 5) + timeman.inc_time
        timeman.max_time = 10 * fld(timeman.clock_time, timeman.movestogo + 10) + timeman.inc_time
    end
    timeman.ideal_time = min(timeman.ideal_time, timeman.clock_time - timeman.move_overhead)
    timeman.max_time = min(timeman.max_time, timeman.clock_time - timeman.move_overhead)
    if timeman.movetime > 0
        timeman.ideal_time = timeman.movetime
        timeman.max_time = timeman.movetime
    end
end


function istermination(timeman::TimeManagement)
    timeman.depth == 0 && elapsedtime(timeman) > timeman.ideal_time
end
