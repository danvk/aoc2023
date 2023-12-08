const std = @import("std");
const bufIter = @import("./buf-iter.zig");
const util = @import("./util.zig");

const assert = std.debug.assert;

// alternative with arena allocator:

const Node = struct {
    left: [3]u8,
    right: [3]u8,
};

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
    if (false) {
        var node = [3]u8{ 'A', 'A', 'A' };
        const end = [3]u8{ 'Z', 'Z', 'Z' };
        while (true) {
            var dir = rlLine[steps % rlLine.len];
            var spot = nodes.get(&node).?;
            if (dir == 'L') {
                node = spot.left;
            } else if (dir == 'R') {
                node = spot.right;
            } else {
                unreachable;
            }
            steps += 1;
            if (std.mem.eql(u8, &node, &end)) {
                break;
            }
        }
        std.debug.print("part 1: {d}\n", .{steps});
    }

    var curNodes = std.StringHashMap(void).init(allocator);
    var initIt = nodes.keyIterator();
    while (initIt.next()) |key| {
        if (key.*[2] == 'A') {
            try curNodes.put(key.*, undefined);
            std.debug.print("{s}\n", .{key.*});
        }
    }
    std.debug.print("starting keys: {d}\n", .{curNodes.count()});

    steps = 0;
    while (true) {
        var newNodes = std.StringHashMap(void).init(allocator);
        var dir = rlLine[steps % rlLine.len];
        var it = curNodes.keyIterator();
        var allZ = true;
        if (steps < 20) {
            std.debug.print("{c} ", .{dir});
        }
        while (it.next()) |key| {
            var spot = nodes.get(key.*).?;
            var nextKeyX = if (dir == 'L') spot.left else if (dir == 'R') spot.right else unreachable;
            var nextKey = try allocator.dupe(u8, &nextKeyX);
            try newNodes.put(nextKey, undefined);
            if (nextKey[2] != 'Z') {
                allZ = false;
            }
            if (steps < 20) {
                std.debug.print("{s} -> {s},", .{ key.*, nextKey });
            }
        }
        if (steps < 20) {
            std.debug.print("\n", .{});
        }
        steps += 1;
        curNodes.deinit();
        curNodes = newNodes;

        if (steps % 100_000 == 0) {
            std.debug.print("{d}...\n", .{steps});
        }

        if (allZ) {
            break;
        }
    }

    curNodes.deinit();

    std.debug.print("part 2: {d}\n", .{steps});
}

const expectEqualDeep = std.testing.expectEqualDeep;

test "sample test" {
    try expectEqualDeep(true, true);
}
