const std = @import("std");

pub fn WithCost(comptime State: type) type {
    return struct { state: State, cost: u32 };
}

fn stateLossLessThan(comptime State: type) fn (void, WithCost(State), WithCost(State)) bool {
    // XXX this copies a pattern in sort.zig and is kinda weird. Why not allow returning a function?
    return struct {
        pub fn inner(_: void, a: WithCost(State), b: WithCost(State)) bool {
            return a.cost < b.cost;
        }
    }.inner;
}

pub fn dijkstra(
    comptime State: type, //
    allocator: std.mem.Allocator,
    context: anytype,
    seeds: []const State, //
    neighbors: fn (@TypeOf(context), WithCost(State), *std.ArrayList(WithCost(State))) std.mem.Allocator.Error!void, //
    isDone: fn (@TypeOf(context), WithCost(State)) bool,
) !?WithCost(State) {
    const StateWithCost = WithCost(State);
    const cmp = stateLossLessThan(State);

    var seen = std.AutoHashMap(State, u32).init(allocator);
    defer seen.deinit();

    var fringe = std.ArrayList(StateWithCost).init(allocator);
    defer fringe.deinit();

    for (seeds) |state| {
        const seed = StateWithCost{ .cost = 0, .state = state };
        try fringe.append(seed);
    }

    while (fringe.items.len > 0) {
        const idx = std.sort.argMin(StateWithCost, fringe.items, {}, cmp).?;

        const stateCost = fringe.orderedRemove(idx); // XXX this is O(N)

        if (seen.get(stateCost.state)) |cost| {
            if (cost <= stateCost.cost) {
                continue;
            }
        }

        if (isDone(context, stateCost)) {
            return stateCost;
        }

        try seen.put(stateCost.state, stateCost.cost);
        var nexts = std.ArrayList(StateWithCost).init(allocator);
        defer nexts.deinit();
        try neighbors(context, stateCost, &nexts);
        try fringe.appendSlice(nexts.items);
    }
    return null;
}
