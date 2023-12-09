const std = @import("std");
const bufIter = @import("./buf-iter.zig");
const util = @import("./util.zig");

const assert = std.debug.assert;

// alternative with arena allocator:

const Node = struct {
    left: [3]u8,
    right: [3]u8,
};

fn ghostCycle(allocator: std.mem.Allocator, nodes: std.StringHashMap(Node), rlLine: []const u8, ghost: []u8) !usize {
    var steps: usize = 0;
    var node = ghost;

    var prev = std.StringHashMap(void).init(allocator);
    defer prev.deinit();

    var numEnds: usize = 0;
    while (numEnds < 10) {
        var dir = rlLine[steps % rlLine.len];
        var spot = nodes.get(node).?;
        if (dir == 'L') {
            node = &spot.left;
        } else if (dir == 'R') {
            node = &spot.right;
        } else {
            unreachable;
        }
        steps += 1;
        // std.debug.print("  {s}\n", .{node});

        if (node[2] == 'Z') {
            std.debug.print(" {d}  end state\n", .{steps});
            numEnds += 1;
        }
    }
    return numEnds;
}

pub fn main(in_allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    var arena = std.heap.ArenaAllocator.init(in_allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    const filename = args[0];

    var iter = try bufIter.iterLines(filename);

    var rlLineIn = try iter.next();
    var rlLine = try allocator.dupe(u8, rlLineIn.?);

    var nodes = std.StringHashMap(Node).init(allocator);
    defer nodes.deinit();

    while (try iter.next()) |line| {
        if (std.mem.indexOfScalar(u8, line, '=') == null) {
            continue;
        }

        var strBuf: [6][]u8 = undefined;
        var parts = util.splitAnyIntoBuf(line, " =(,)", &strBuf);
        assert(parts.len == 3);

        // std.debug.print("{any}\n", .{parts});

        var left: [3]u8 = undefined;
        var right: [3]u8 = undefined;
        @memcpy(&left, parts[1]);
        @memcpy(&right, parts[2]);
        var n = Node{ .left = left, .right = right };
        // std.debug.print("{any}\n", .{n});
        var name = try allocator.dupe(u8, parts[0]);
        try nodes.putNoClobber(name, n);
    }

    var steps: usize = 0;

    var ghosts = std.ArrayList([]u8).init(allocator);
    defer ghosts.deinit();
    var initIt = nodes.keyIterator();
    while (initIt.next()) |key| {
        if (key.*[2] == 'A') {
            var name = try allocator.dupe(u8, key.*);
            try ghosts.append(name);
            std.debug.print("{s}\n", .{key.*});
        }
    }
    std.debug.print("starting keys: {any}\n", .{ghosts.items});

    for (ghosts.items) |ghost| {
        std.debug.print("ghost {s}\n", .{ghost});
        _ = try ghostCycle(allocator, nodes, rlLine, ghost);
    }

    var timer = try std.time.Timer.start();

    steps = 0;
    while (true) {
        var dir = rlLine[steps % rlLine.len];
        var allZ = true;
        if (steps < 20) {
            std.debug.print("{c} ", .{dir});
        }
        for (ghosts.items, 0..) |key, i| {
            var spot = nodes.get(key).?;
            var nextKey = if (dir == 'L') spot.left else if (dir == 'R') spot.right else unreachable;
            if (nextKey[2] != 'Z') {
                allZ = false;
            }
            if (steps < 20) {
                std.debug.print("{s} -> {s},", .{ key, nextKey });
            }
            @memcpy(ghosts.items[i], &nextKey);
        }
        if (steps < 20) {
            std.debug.print("\n", .{});
        }
        steps += 1;

        if (steps % 1_000_000 == 0) {
            // timer.read() returns nanoseconds. This converts to ms.
            const elapsed = timer.read() / 1_000_000;
            std.debug.print("{d} ms {d}...\n", .{ elapsed, steps });
        }

        if (allZ) {
            break;
        }
    }

    std.debug.print("part 2: {d}\n", .{steps});
}

const expectEqualDeep = std.testing.expectEqualDeep;

test "sample test" {
    try expectEqualDeep(true, true);
}
