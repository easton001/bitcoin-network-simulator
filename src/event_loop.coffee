_ = require('underscore')
Heap = require('heap')

exports.EventLoop = class EventLoop
    constructor: ->
        @queue = new Heap(({time:time_a},{time:time_b}) -> time_a - time_b)
        @ticks = 0

    next_event: (limit) =>
        if @queue.empty() or (limit? and ({time} = @queue.peek(); time) and time > limit)
            return
        next = @queue.pop()
        @ticks = Math.max(time,@ticks) if time?
        return next

    schedule: (event,delay) =>
        if delay < 0
            event()
        else
            @queue.push({event,time:@ticks+delay})

    run_synchronous: (limit) =>
        while @ticks < limit and ({event} = @next_event(limit) ? {}; event)?
            event()

exports.event_loop = new EventLoop()
