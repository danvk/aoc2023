const std = @import("std");
const dirMod = @import("./dir.zig");
const util = @import("./util.zig");
const gridMod = @import("./grid.zig");

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

const StateLoss = struct {
    state: State,
    loss: u32,
};

fn nextStates(state: State, gr: *gridMod.GridResult, out: *std.ArrayList(State)) !void {
    out.clearAndFree();
    var grid = gr.grid;
    _ = grid;
    var maxX = gr.maxX;
    var maxY = gr.maxY;

    var pos = state.pos;
    var dir = state.dir;
    var n = state.numStraight;
    // options are:
    // 1. turn left
    // 2. turn right
    // 3. go straight (if permitted)

    if (!state.hasTurned and n >= 4) {
        try out.append(State{ .pos = pos, .dir = dir.cw(), .numStraight = 0, .hasTurned = true });
        try out.append(State{ .pos = pos, .dir = dir.ccw(), .numStraight = 0, .hasTurned = true });
    }
    if (n < 10) {
        pos = pos.move(dir);
        if (pos.x >= 0 and pos.y >= 0 and pos.x <= maxX and pos.y <= maxY) {
            try out.append(State{ .pos = pos, .dir = dir, .numStraight = n + 1, .hasTurned = false });
        }
    }
}

fn stateLossLessThan(_: void, a: StateLoss, b: StateLoss) bool {
    return a.loss < b.loss;
}

fn printStateLoss(sl: StateLoss) void {
    const s = sl.state;
    std.debug.print("{d}:({d},{d}){any}({d},{any})\n", .{
        sl.loss,
        s.pos.x,
        s.pos.y,
        s.dir,
        s.numStraight,
        s.hasTurned,
    });
}

fn floodfill(allocator: std.mem.Allocator, gr: *gridMod.GridResult) !u32 {
    const grid = gr.grid;
    var seen = std.AutoHashMap(State, u32).init(allocator);
    defer seen.deinit();

    var fringe = std.ArrayList(StateLoss).init(allocator);
    defer fringe.deinit();

    const seed = StateLoss{ .loss = 0, .state = State{ .pos = Coord{ .x = 0, .y = 0 }, .dir = .right, .numStraight = 0, .hasTurned = false } };
    try fringe.append(seed);

    while (fringe.items.len > 0) {
        const idx = std.sort.argMin(StateLoss, fringe.items, {}, stateLossLessThan).?;

        const stateLoss = fringe.orderedRemove(idx); // XXX this is O(N)
        // printStateLoss(stateLoss);

        if (stateLoss.loss % 100 == 0) {
            printStateLoss(stateLoss);
        }

        if (seen.get(stateLoss.state)) |loss| {
            if (loss <= stateLoss.loss) {
                continue;
            }
        }

        const pos = stateLoss.state.pos;
        if (pos.x == gr.maxX and pos.y == gr.maxY and stateLoss.state.numStraight >= 4) {
            return stateLoss.loss; // we're done!
        }

        try seen.put(stateLoss.state, stateLoss.loss);
        var nexts = std.ArrayList(State).init(allocator);
        defer nexts.deinit();
        try nextStates(stateLoss.state, gr, &nexts);
        for (nexts.items) |state| {
            const lossChar = grid.get(state.pos).?;
            const loss = lossChar - '0';
            const nextLoss = stateLoss.loss + if (state.hasTurned) 0 else loss;
            try fringe.append(StateLoss{ .state = state, .loss = nextLoss });
        }
    }
    unreachable;
}

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    const filename = args[0];

    var gr = try gridMod.readGrid(allocator, filename, 'x');
    var grid = gr.grid;
    defer grid.deinit();

    const sum1 = try floodfill(allocator, &gr);

    std.debug.print("part 1: {d}\n", .{sum1});
    // std.debug.print("part 2: {d}\n", .{sum2});
}

const expectEqualDeep = std.testing.expectEqualDeep;
const expectEqual = std.testing.expectEqual;
const expect = std.testing.expect;

test "sample test" {
    try expectEqualDeep(true, true);
}
