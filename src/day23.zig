const std = @import("std");
const bufIter = @import("./buf-iter.zig");
const util = @import("./util.zig");
const gridMod = @import("./grid.zig");
const dirMod = @import("./dir.zig");
const queue = @import("./queue.zig");

const Coord = dirMod.Coord;

const assert = std.debug.assert;

// alternative with arena allocator:
// pub fn main(in_allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
//     var arena = std.heap.ArenaAllocator.init(in_allocator);
//     defer arena.deinit();
//     var allocator = arena.allocator();

const State = struct {
    pos: Coord,
    prev: ?*State,
};

fn hasVisited(state: *State, pos: Coord) bool {
    if (state.pos.x == pos.x and state.pos.y == pos.y) {
        return true;
    }
    if (state.prev) |prev| {
        return hasVisited(prev, pos);
    }
    return false;
}

fn nextStates(gr: gridMod.GridResult, state: *State, nextBuf: []*State, isPart2: bool) ![]*State {
    const pos = state.pos;
    const grid = gr.grid;
    const cur = grid.get(pos);
    const allocator = grid.allocator;
    var i: usize = 0;

    for (dirMod.DIRS) |d| {
        const np = pos.move(d);
        const next = grid.get(np) orelse '#';
        if (next == '#') {
            continue; // blocked
        }
        if (!isPart2) {
            if ((cur == '>' and d != .right) or
                (cur == '<' and d != .left) or
                (cur == '^' and d != .up) or
                (cur == 'v' and d != .down))
            {
                continue;
            }
        }
        if (hasVisited(state, np)) {
            continue;
        }
        var statePtr = try allocator.create(State);
        statePtr.* = State{
            .pos = np,
            .prev = state,
        };
        nextBuf[i] = statePtr;
        i += 1;
    }
    return nextBuf[0..i];
}

fn pathLen(state: *State) usize {
    if (state.prev) |prev| {
        return 1 + pathLen(prev);
    }
    return 0;
}

fn find(allocator: std.mem.Allocator, start: Coord, end: Coord, gr: gridMod.GridResult) !usize {
    var fringe = queue.Queue(*State).init(allocator);
    var initState = State{ .pos = start, .prev = null };
    try fringe.enqueue(&initState);

    var lens = std.ArrayList(usize).init(allocator);
    defer lens.deinit();

    var nextsBuf: [4]*State = undefined;

    while (fringe.dequeue()) |statePtr| {
        var nexts = try nextStates(gr, statePtr, &nextsBuf, false);
        for (nexts) |next| {
            if (next.pos.x == end.x and next.pos.y == end.y) {
                const len = pathLen(next);
                std.debug.print("Reached finish in {d} steps.\n", .{len});
                try lens.append(len);
            } else {
                try fringe.enqueue(next);
            }
        }
    }
    return std.mem.max(usize, lens.items);
}

fn countChoices(gr: gridMod.GridResult) !std.ArrayList(Coord) {
    const grid = gr.grid;
    var num: usize = 0;
    var numChoices: usize = 0;
    var numForced: usize = 0;
    var numJunctions: usize = 0;
    var nodes = std.ArrayList(Coord).init(grid.allocator);
    for (1..gr.maxX) |x| {
        for (1..gr.maxY) |y| {
            var numNexts: usize = 0;
            const p = Coord{ .x = @intCast(x), .y = @intCast(y) };
            if (grid.get(p) == '#') {
                continue;
            }
            num += 1;
            for (dirMod.DIRS) |d| {
                const np = p.move(d);
                if (grid.get(np) != '#') {
                    numNexts += 1;
                }
            }
            if (numNexts == 0) {
                std.debug.print("isolated! {any}\n", .{p});
            } else if (numNexts == 1) {
                std.debug.print("dead end! {any}\n", .{p});
            } else if (numNexts == 2) {
                // std.debug.print("forced: {any}", .{p});
                numForced += 1;
            } else if (numNexts == 3) {
                numChoices += 1;
            } else {
                numJunctions += 1;
            }
            if (numNexts >= 3) {
                try nodes.append(p);
            }
        }
    }

    std.debug.print("num squares: {d}\n", .{num});
    std.debug.print("forced: {d}, choice: {d}, junction: {d}\n", .{ numForced, numChoices, numJunctions });

    return nodes;
}

const Connection = struct {
    from: usize,
    to: usize,
    len: usize,
};

fn isNode(pos: Coord, coords: []Coord) ?usize {
    for (coords, 0..) |c, i| {
        if (c.x == pos.x and c.y == pos.y) {
            return i;
        }
    }
    return null;
}

fn findConnections(gr: gridMod.GridResult, nodes: []Coord) !std.ArrayList(Connection) {
    const grid = gr.grid;
    const allocator = grid.allocator;
    var conns = std.ArrayList(Connection).init(allocator);

    for (nodes, 0..) |node, i| {
        // For each node, do flood fill in each direction until we hit another node.
        var initState = State{ .pos = node, .prev = null };

        var fringe = queue.Queue(*State).init(allocator);
        try fringe.enqueue(&initState);

        var nextsBuf: [4]*State = undefined;

        while (fringe.dequeue()) |statePtr| {
            var nexts = try nextStates(gr, statePtr, &nextsBuf, true);
            if (nexts.len > 1 and statePtr != &initState) {
                unreachable;
            }
            for (nexts) |next| {
                if (isNode(next.pos, nodes)) |j| {
                    const len = pathLen(next);
                    std.debug.print("Unique walk from {any} -> {any} in {d} steps.\n", .{ node, next.pos, len });
                    try conns.append(Connection{ .from = i, .to = j, .len = len });
                } else {
                    try fringe.enqueue(next);
                }
            }
        }
    }

    std.debug.print("found {d} connections\n", .{conns.items.len});

    return conns;
}

const State2 = struct {
    idx: usize,
    prev: ?*State2,
    len: usize,
};

fn hasVisited2(state: *State2, idx: usize) bool {
    if (state.idx == idx) {
        return true;
    }
    if (state.prev) |prev| {
        return hasVisited2(prev, idx);
    }
    return false;
}

fn nextStates2(allocator: std.mem.Allocator, state: *State2, connections: []Connection, nextBuf: []*State2) ![]*State2 {
    var idx = state.idx;
    var i: usize = 0;
    for (connections) |conn| {
        if (conn.from != idx) {
            continue;
        }
        if (hasVisited2(state, conn.to)) {
            continue;
        }
        var statePtr = try allocator.create(State2);
        statePtr.* = State2{
            .idx = conn.to,
            .prev = state,
            .len = conn.len,
        };
        nextBuf[i] = statePtr;
        i += 1;
    }
    return nextBuf[0..i];
}

fn pathLen2(state: *State2) usize {
    if (state.prev) |prev| {
        return state.len + pathLen2(prev);
    }
    return state.len;
}

fn part2(allocator: std.mem.Allocator, start: usize, end: usize, connections: []Connection) !usize {
    var fringe = queue.Queue(*State2).init(allocator);
    var initState = State2{ .idx = start, .prev = null, .len = 0 };
    try fringe.enqueue(&initState);

    var lens = std.ArrayList(usize).init(allocator);
    defer lens.deinit();

    var nextsBuf: [4]*State2 = undefined;

    while (fringe.dequeue()) |statePtr| {
        var nexts = try nextStates2(allocator, statePtr, connections, &nextsBuf);
        for (nexts) |next| {
            if (next.idx == end) {
                const len = pathLen2(next);
                std.debug.print("Reached finish in {d} steps.\n", .{len});
                try lens.append(len);
            } else {
                try fringe.enqueue(next);
            }
        }
    }

    return std.mem.max(usize, lens.items);
}

pub fn main(in_allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    var arena = std.heap.ArenaAllocator.init(in_allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    const filename = args[0];
    var gr = try gridMod.readGrid(allocator, filename, 'x');
    var grid = gr.grid;
    var maxX = gr.maxX;
    var maxY = gr.maxY;
    defer grid.deinit();

    const start = Coord{ .x = 1, .y = 0 };
    const end = Coord{ .x = @intCast(maxX - 1), .y = @intCast(maxY) };
    // std.debug.print("1,0: {?c}\n", .{grid.get(start)});
    // std.debug.print("1,0: {?c}\n", .{grid.get(start)});

    assert(grid.get(start) == '.');
    assert(grid.get(end) == '.');

    const answer1 = try find(allocator, start, end, gr);
    std.debug.print("part 1: {d}\n", .{answer1});

    var nodes = try countChoices(gr);
    try nodes.append(start);
    try nodes.append(end);
    defer nodes.deinit();

    std.debug.print("# nodes: {d}\n", .{nodes.items.len});

    const conns = try findConnections(gr, nodes.items);
    defer conns.deinit();

    const answer2 = try part2(allocator, nodes.items.len - 2, nodes.items.len - 1, conns.items);

    std.debug.print("part 1: {d}\n", .{answer1});
    std.debug.print("part 2: {d}\n", .{answer2});
}

const expectEqualDeep = std.testing.expectEqualDeep;
const expectEqual = std.testing.expectEqual;
const expect = std.testing.expect;

test "sample test" {
    try expectEqualDeep(true, true);
}
