const std = @import("std");
const bufIter = @import("./buf-iter.zig");
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

const Beam = struct {
    pos: Coord,
    dir: Dir,
};

fn printBeam(beam: Beam) void {
    std.debug.print(" ({d},{d}){any}", .{ beam.pos.x, beam.pos.y, beam.dir });
}
fn printBeams(beams: []Beam) void {
    std.debug.print("{d}", .{beams.len});
    for (beams) |beam| {
        printBeam(beam);
    }
    std.debug.print("\n", .{});
}

fn numEnergized(allocator: std.mem.Allocator, grid: *std.AutoHashMap(Coord, u8), maxX: usize, maxY: usize, initBeam: Beam) !usize {
    var beams = std.ArrayList(Beam).init(allocator);
    defer beams.deinit();

    var activated = std.AutoHashMap(Coord, void).init(allocator);
    defer activated.deinit();

    var prevBeams = std.AutoHashMap(Beam, void).init(allocator);
    defer prevBeams.deinit();

    try beams.append(initBeam);

    while (beams.items.len > 0) {
        //std.debug.print("beams: {any}\n", .{beams.items});
        // printBeams(beams.items);
        // advance the beam
        var toRemove = std.ArrayList(usize).init(allocator);
        defer toRemove.deinit();
        for (0..beams.items.len) |i| {
            const beam = beams.items[i];
            if (prevBeams.contains(beam)) {
                try toRemove.append(i);
                continue;
            }
            try prevBeams.put(beam, undefined);

            // std.debug.print("{d}: {any}\n", .{ i, beam });

            var pos = beam.pos;
            var dir = beam.dir;
            try activated.put(pos, undefined);

            pos = pos.move(dir);
            if (pos.x < 0 or pos.y < 0 or pos.x > maxX or pos.y > maxY) {
                // std.debug.print("removing, continuing\n", .{});
                try toRemove.append(i);
                continue;
            }

            const c = grid.get(pos).?;
            // std.debug.print("{c}\n", .{c});
            switch (c) {
                '.' => {
                    beams.items[i] = Beam{ .pos = pos, .dir = dir };
                },
                '\\' => {
                    dir = switch (dir) {
                        .left => .up,
                        .right => .down,
                        .up => .left,
                        .down => .right,
                    };
                    beams.items[i] = Beam{ .pos = pos, .dir = dir };
                },
                '/' => {
                    dir = switch (dir) {
                        .left => .down,
                        .right => .up,
                        .up => .right,
                        .down => .left,
                    };
                    beams.items[i] = Beam{ .pos = pos, .dir = dir };
                },
                '|' => {
                    if (dir == .down or dir == .up) {
                        beams.items[i] = Beam{ .pos = pos, .dir = dir };
                    } else {
                        beams.items[i] = Beam{ .pos = pos, .dir = .up };
                        try beams.append(Beam{ .pos = pos, .dir = .down });
                    }
                },
                '-' => {
                    if (dir == .left or dir == .right) {
                        beams.items[i] = Beam{ .pos = pos, .dir = dir };
                    } else {
                        beams.items[i] = Beam{ .pos = pos, .dir = .left };
                        try beams.append(Beam{ .pos = pos, .dir = .right });
                    }
                },
                else => unreachable,
            }
        }

        std.mem.reverse(usize, toRemove.items);
        for (toRemove.items) |i| {
            // std.debug.print("removing {d} from list of len {d}\n", .{ i, beams.items.len });
            _ = beams.swapRemove(i);
        }
    }

    return activated.count();
}

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    const filename = args[0];

    const gr = try gridMod.readGrid(allocator, filename, 'x');
    var grid = gr.grid;
    const maxX = gr.maxX;
    const maxY = gr.maxY;
    defer grid.deinit();

    const sum1 = try numEnergized(allocator, &grid, maxX, maxY, Beam{ .pos = Coord{ .x = 0, .y = 0 }, .dir = Dir.right });
    std.debug.print("part 1: {d}\n", .{sum1});

    var nums2 = std.ArrayList(usize).init(allocator);
    defer nums2.deinit();

    for (0..(1 + maxX)) |x| {
        const top = Beam{ .pos = Coord{ .x = @intCast(x), .y = 0 }, .dir = Dir.down };
        const bottom = Beam{ .pos = Coord{ .x = @intCast(x), .y = @intCast(maxY) }, .dir = Dir.up };

        try nums2.append(try numEnergized(allocator, &grid, maxX, maxY, top));
        try nums2.append(try numEnergized(allocator, &grid, maxX, maxY, bottom));
    }

    for (0..(1 + maxY)) |y| {
        const left = Beam{ .pos = Coord{ .x = 0, .y = @intCast(y) }, .dir = Dir.right };
        const right = Beam{ .pos = Coord{ .x = @intCast(maxX), .y = @intCast(y) }, .dir = Dir.left };

        try nums2.append(try numEnergized(allocator, &grid, maxX, maxY, left));
        try nums2.append(try numEnergized(allocator, &grid, maxX, maxY, right));
    }

    const sum2 = std.mem.max(usize, nums2.items);

    std.debug.print("part 2: {d}\n", .{sum2});
}

const expectEqualDeep = std.testing.expectEqualDeep;
const expectEqual = std.testing.expectEqual;
const expect = std.testing.expect;

test "sample test" {
    try expectEqualDeep(true, true);
}
