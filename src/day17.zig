const std = @import("std");
const dirMod = @import("./dir.zig");
const util = @import("./util.zig");
const gridMod = @import("./grid.zig");
const dijkstra = @import("./dijkstra.zig");

const Coord = dirMod.Coord;
const Dir = dirMod.Dir;

const assert = std.debug.assert;

// alternative with arena allocator:
// pub fn main(in_allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
//     var arena = std.heap.ArenaAllocator.init(in_allocator);
//     defer arena.deinit();
//     var allocator = arena.allocator();

const State = struct {
    pos: Coord,
    dir: Dir,
    numStraight: usize,
    hasTurned: bool,
};

const StateWithCost = dijkstra.WithCost(State);

fn nextStates(gr: gridMod.GridResult, sc: StateWithCost, out: *std.ArrayList(StateWithCost)) !void {
    out.clearAndFree();
    var grid = gr.grid;
    var maxX = gr.maxX;
    var maxY = gr.maxY;

    const state = sc.state;
    const cost = sc.cost;
    var pos = state.pos;
    var dir = state.dir;
    var n = state.numStraight;
    // options are:
    // 1. turn left
    // 2. turn right
    // 3. go straight (if permitted)

    if (!state.hasTurned and n >= 4) {
        // turns are free
        try out.append(StateWithCost{ .state = State{ .pos = pos, .dir = dir.cw(), .numStraight = 0, .hasTurned = true }, .cost = cost });
        try out.append(StateWithCost{ .state = State{ .pos = pos, .dir = dir.ccw(), .numStraight = 0, .hasTurned = true }, .cost = cost });
    }
    if (n < 10) {
        pos = pos.move(dir);
        if (pos.x >= 0 and pos.y >= 0 and pos.x <= maxX and pos.y <= maxY) {
            const lossChar = grid.get(state.pos).?;
            const loss = lossChar - '0';
            try out.append(StateWithCost{ .state = State{ .pos = pos, .dir = dir, .numStraight = n + 1, .hasTurned = false }, .cost = cost + loss });
        }
    }
}

fn printStateLoss(sl: StateWithCost) void {
    const s = sl.state;
    std.debug.print("{d}:({d},{d}){any}({d},{any})\n", .{
        sl.cost,
        s.pos.x,
        s.pos.y,
        s.dir,
        s.numStraight,
        s.hasTurned,
    });
}

fn isDone(gr: gridMod.GridResult, sl: StateWithCost) bool {
    const state = sl.state;
    const pos = state.pos;
    if (pos.x == gr.maxX and pos.y == gr.maxY and state.numStraight >= 4) {
        return true; // we're done!
    }
    return false;
}

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    const filename = args[0];

    var gr = try gridMod.readGrid(allocator, filename, 'x');
    var grid = gr.grid;
    defer grid.deinit();

    const seed = State{ .pos = Coord{ .x = 0, .y = 0 }, .dir = .right, .numStraight = 0, .hasTurned = false };
    var seeds = [_]State{seed};
    const winningState = (try dijkstra.dijkstra(State, allocator, gr, &seeds, nextStates, isDone)).?;
    // const sum1 = try floodfill(allocator, &gr);
    const sum1 = winningState.cost;

    std.debug.print("part 1: {d}\n", .{sum1});
    // std.debug.print("part 2: {d}\n", .{sum2});
}

const expectEqualDeep = std.testing.expectEqualDeep;
const expectEqual = std.testing.expectEqual;
const expect = std.testing.expect;

test "sample test" {
    try expectEqualDeep(true, true);
}
