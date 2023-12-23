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

fn nextStates(gr: gridMod.GridResult, state: *State, nextBuf: []*State) ![]*State {
    const pos = state.pos;
    const grid = gr.grid;
    const cur = grid.get(pos);
    const allocator = grid.allocator;
    var i: usize = 0;

    for (dirMod.DIRS) |d| {
        const np = state.pos.move(d);
        const next = grid.get(np) orelse '#';
        if (next == '#') {
            continue; // blocked
        }
        if ((cur == '>' and d != .right) or
            (cur == '<' and d != .left) or
            (cur == '^' and d != .up) or
            (cur == 'v' and d != .down))
        {
            continue;
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

fn find(allocator: std.mem.Allocator, start: Coord, end: Coord, gr: gridMod.GridResult) !void {
    var fringe = queue.Queue(*State).init(allocator);
    var initState = State{ .pos = start, .prev = null };
    try fringe.enqueue(&initState);

    var nextsBuf: [4]*State = undefined;

    while (fringe.dequeue()) |statePtr| {
        var nexts = try nextStates(gr, statePtr, &nextsBuf);
        for (nexts) |next| {
            if (next.pos.x == end.x and next.pos.y == end.y) {
                std.debug.print("Reached finish in {d} steps.\n", .{pathLen(next)});
            } else {
                try fringe.enqueue(next);
            }
        }
    }
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

    try find(allocator, start, end, gr);

    // std.debug.print("part 1: {d}\n", .{sum1});
    // std.debug.print("part 2: {d}\n", .{sum2});
}

const expectEqualDeep = std.testing.expectEqualDeep;
const expectEqual = std.testing.expectEqual;
const expect = std.testing.expect;

test "sample test" {
    try expectEqualDeep(true, true);
}
