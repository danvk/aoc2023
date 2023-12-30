const std = @import("std");

pub fn WithCost(comptime State: type) type {
    return struct { state: State, cost: u32 };
}

fn stateLossOrder(comptime State: type) fn (void, WithCost(State), WithCost(State)) std.math.Order {
    // XXX this copies a pattern in sort.zig and is kinda weird. Why not allow returning a function?
    return struct {
        pub fn inner(_: void, a: WithCost(State), b: WithCost(State)) std.math.Order {
            return std.math.order(a.cost, b.cost);
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

    var seen = std.AutoHashMap(State, u32).init(allocator);
    defer seen.deinit();

    var fringe = std.PriorityQueue(StateWithCost, void, stateLossOrder(State)).init(allocator, {});
    // std.ArrayList(StateWithCost).init(allocator);
    defer fringe.deinit();

    for (seeds) |state| {
        const seed = StateWithCost{ .cost = 0, .state = state };
        try fringe.add(seed);
    }

    while (fringe.removeOrNull()) |stateCost| {
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
        try fringe.addSlice(nexts.items);
    }
    return null;
}

pub fn WithCostAndPrev(comptime State: type) type {
    return struct {
        state: State,
        cost: u32,
        prev: ?*WithCostAndPrev(State),
    };
}

fn stateCostPrevOrder(comptime State: type) fn (void, *WithCostAndPrev(State), *WithCostAndPrev(State)) std.math.Order {
    return struct {
        pub fn inner(_: void, a: *WithCostAndPrev(State), b: *WithCostAndPrev(State)) std.math.Order {
            return std.math.order(a.cost, b.cost);
        }
    }.inner;
}

pub fn shortestPath(
    comptime State: type, //
    in_allocator: std.mem.Allocator,
    context: anytype,
    start: State, //
    neighbors: fn (@TypeOf(context), WithCost(State), *std.ArrayList(WithCost(State))) std.mem.Allocator.Error!void, //
    dest: State,
) !?[]WithCost(State) {
    var arena = std.heap.ArenaAllocator.init(in_allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    const StateWithCost = WithCost(State);
    const StateWithCostPrev = WithCostAndPrev(State);

    var seen = std.AutoHashMap(State, u32).init(allocator);
    defer seen.deinit();

    var fringe = std.PriorityQueue(*StateWithCostPrev, void, stateCostPrevOrder(State)).init(allocator, {});
    defer fringe.deinit();

    var seed = StateWithCostPrev{ .cost = 0, .state = start, .prev = null };
    try fringe.add(&seed);

    while (fringe.removeOrNull()) |stateCostPrevPtr| {
        const state = stateCostPrevPtr.state;
        const cost = stateCostPrevPtr.cost;
        if (seen.get(state)) |prev_cost| {
            if (prev_cost <= cost) {
                continue;
            }
        }

        if (std.meta.eql(dest, state)) {
            var path = std.ArrayList(StateWithCost).init(in_allocator);
            var curPtr: ?*StateWithCostPrev = stateCostPrevPtr;
            while (curPtr) |cur| {
                try path.append(StateWithCost{ .state = cur.state, .cost = cur.cost });
                curPtr = cur.prev;
            }
            std.mem.reverse(StateWithCost, path.items);
            return try path.toOwnedSlice();
        }

        try seen.put(state, cost);
        var nexts = std.ArrayList(StateWithCost).init(in_allocator);
        defer nexts.deinit();
        try neighbors(context, StateWithCost{ .state = state, .cost = cost }, &nexts);
        var nextPrevs = try std.ArrayList(*StateWithCostPrev).initCapacity(in_allocator, nexts.items.len);
        defer nextPrevs.deinit();
        for (nexts.items) |next| {
            var nextPrev = try allocator.create(StateWithCostPrev);
            nextPrev.* = StateWithCostPrev{
                .cost = next.cost,
                .state = next.state,
                .prev = stateCostPrevPtr,
            };
            try nextPrevs.append(nextPrev);
        }
        try fringe.addSlice(nextPrevs.items);
    }
    return null;
}

const StrWithCost = WithCost([]const u8);
fn graph_neighbors(
    g: std.StringHashMap(std.ArrayList([]const u8)),
    node: StrWithCost,
    out: *std.ArrayList(StrWithCost),
) !void {
    if (g.get(node.state)) |nexts| {
        const cost = node.cost;
        for (nexts.items) |n| {
            try out.append(StrWithCost{ .state = n, .cost = cost + 1 });
        }
    }
}

test "shortest path" {
    var g = std.StringHashMap(std.ArrayList([]const u8)).init(std.testing.allocator);
    defer g.deinit();
    var an = std.ArrayList([]const u8).init(std.testing.allocator);
    defer an.deinit();
    try an.append("B");
    try an.append("C");
    try g.put("A", an);

    var bn = std.ArrayList([]const u8).init(std.testing.allocator);
    defer bn.deinit();
    try bn.append("D");

    var path = try shortestPath([]const u8, std.testing.allocator, g, "A", graph_neighbors, "D");
    std.debug.print("path: {any}\n", .{path});
}
