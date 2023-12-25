const std = @import("std");
const bufIter = @import("./buf-iter.zig");
const util = @import("./util.zig");

const assert = std.debug.assert;

// alternative with arena allocator:
// pub fn main(in_allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
//     var arena = std.heap.ArenaAllocator.init(in_allocator);
//     defer arena.deinit();
//     var allocator = arena.allocator();

const Conn = struct {
    from: []const u8,
    to: []const u8,
};

fn compareStrings(_: void, lhs: []const u8, rhs: []const u8) bool {
    return std.mem.order(u8, lhs, rhs).compare(std.math.CompareOperator.lt);
}

fn areConnected(a: []const u8, b: []const u8, conns: std.StringHashMap(void)) bool {
    var keyBuf: [7]u8 = undefined;
    var key = std.fmt.bufPrint(&keyBuf, "{s},{s}", .{ a, b }) catch unreachable;
    return conns.contains(key);
}

pub fn main(in_allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    var arena = std.heap.ArenaAllocator.init(in_allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    const filename = args[0];
    var contents = try util.readInputFile(allocator, filename);
    defer allocator.free(contents);

    // a,b pairs
    var conns = std.StringHashMap(void).init(allocator);
    defer conns.deinit();
    var componentsSet = std.StringHashMap(void).init(allocator);
    defer componentsSet.deinit();

    var partsBuf: [20][]const u8 = undefined;
    var it = std.mem.tokenize(u8, contents, "\n");
    while (it.next()) |line| {
        var parts = util.splitAnyIntoBuf(line, ": ", &partsBuf);
        var left = parts[0];
        for (parts[1..]) |right| {
            const keyBuf1 = try allocator.alloc(u8, 7);
            var key1 = try std.fmt.bufPrint(keyBuf1, "{s},{s}", .{ left, right });
            try conns.put(key1, undefined);
            const keyBuf2 = try allocator.alloc(u8, 7);
            var key2 = try std.fmt.bufPrint(keyBuf2, "{s},{s}", .{ right, left });
            try conns.put(key2, undefined);

            try componentsSet.put(left, undefined);
            try componentsSet.put(right, undefined);
        }
    }

    var components = std.ArrayList([]const u8).init(allocator);
    var cit = componentsSet.keyIterator();
    while (cit.next()) |c| {
        try components.append(c.*);
    }
    std.mem.sort([]const u8, components.items, {}, compareStrings);

    std.debug.print("graph G {{\n", .{});
    var connIt = conns.keyIterator();
    var connList = std.StringHashMap(std.ArrayList([]const u8)).init(allocator);
    defer connList.deinit();
    while (connIt.next()) |conn| {
        var partsBuf2: [2][]const u8 = undefined;
        var parts = util.splitIntoBuf(conn.*, ",", &partsBuf2);
        assert(parts.len == 2);
        var a = parts[0];
        var b = parts[1];
        if (!connList.contains(a)) {
            try connList.put(a, std.ArrayList([]const u8).init(allocator));
        }
        try connList.getPtr(a).?.append(b);
        if (compareStrings({}, a, b)) {
            std.debug.print("  {s} -- {s}\n", .{ a, b });
        }
    }
    std.debug.print("}}\n", .{});
    const comps = components.items;
    for (comps, 0..) |a, i| {
        for (comps[(i + 1)..], (i + 1)..) |b, j| {
            var numConns: usize = 0;
            if (areConnected(a, b, conns)) {
                numConns += 1;
            }

            for (comps, 0..) |c, k| {
                if (k == i or k == j) {
                    continue;
                }
                if (areConnected(a, c, conns) and areConnected(b, c, conns)) {
                    numConns += 1;
                }
            }

            if (numConns >= 4) {
                std.debug.print("{s} and {s} are strongly connected ({d})\n", .{ a, b, numConns });
            }
        }
    }

    // std.debug.print("{d} components:\n", .{components.items.len});
    // for (components.items) |c| {
    //     std.debug.print("  {s}\n", .{c});
    // }
    //
    // std.debug.print("{d} connections\n", .{conns.count()});
    // var kit = conns.keyIterator();
    // while (kit.next()) |k| {
    //     std.debug.print("  {s}\n", .{k.*});
    // }

    // Which components are only connected to one other?

    // std.debug.print("part 1: {d}\n", .{sum1});
    // std.debug.print("part 2: {d}\n", .{sum2});
}

const expectEqualDeep = std.testing.expectEqualDeep;
const expectEqual = std.testing.expectEqual;
const expect = std.testing.expect;

test "sample test" {
    try expectEqualDeep(true, true);
}
