const std = @import("std");
const bufIter = @import("./buf-iter.zig");
const util = @import("./util.zig");
const queue = @import("./queue.zig");
const dijkstra = @import("./dijkstra.zig");

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

fn floodfill(seed: []const u8, conns: std.StringHashMap(std.ArrayList([]const u8))) !void {
    var allocator = conns.allocator;
    var counts = std.StringHashMap(usize).init(allocator);
    defer counts.deinit();

    var used = std.StringHashMap(void).init(allocator);
    defer used.deinit();

    var fringe = queue.Queue(Conn).init(allocator);
    var seedConns = conns.get(seed).?;
    for (seedConns.items) |next| {
        // XXX use our own arena here?
        // const keyBuf = try allocator.alloc(u8, 7);
        // const left = seed;
        // const right = next;
        // var key = try std.fmt.bufPrint(keyBuf, "{s},{s}", .{ left, right });
        // if (std.mem.order(u8, left, right) == .lt) .{ left, right } else .{ right, left }) catch unreachable;
        try fringe.enqueue(Conn{ .from = seed, .to = next });
    }

    while (fringe.dequeue()) |conn| {
        // var parts = util.splitOne(conn, ",").?;
        var prev = conn.from;
        var next = conn.to;

        var keyBuf: [7]u8 = undefined;
        var key = try std.fmt.bufPrint(&keyBuf, "{s},{s}", if (std.mem.order(u8, prev, next) == .lt) .{ prev, next } else .{ next, prev });
        if (used.contains(key)) {
            continue;
        }
        var keyDupe = try allocator.dupe(u8, key);
        try used.put(keyDupe, undefined);

        try counts.put(next, (counts.get(next) orelse 0) + 1);
        if (conns.get(next)) |nextConns| {
            for (nextConns.items) |nextNode| {
                // const keyBufN = try allocator.alloc(u8, 7);
                // var keyN = try std.fmt.bufPrint(keyBufN, "{s},{s}", .{ next, nextNode });
                try fringe.enqueue(Conn{
                    .from = next,
                    .to = nextNode,
                });
            }
        }
    }

    var it = counts.iterator();
    while (it.next()) |entry| {
        std.debug.print("  {s} {d}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
    }
}

const Graph = std.StringHashMap(std.ArrayList([]const u8));

// this temporarily mutates g but returns it unaltered.
fn countPaths(
    g: *Graph,
    from: []const u8,
    to: []const u8,
) !usize {
    var allocator = g.allocator;
    var maybePath = try dijkstra.shortestPath([]const u8, std.hash_map.StringContext, allocator, g.*, from, dijkstra.graph_neighbors, to);
    if (maybePath) |path| {
        defer allocator.free(path);
        for (path[1..], 1..) |nodeCost2, j| {
            const nodeCost1 = path[j - 1];
            var a = nodeCost1.state;
            var b = nodeCost2.state;
            // Remove the edge from a -> b and b -> a
            var an = g.getPtr(a).?;
            var bi = util.indexOfStr(an.items, b).?;
            _ = an.swapRemove(bi);
            var bn = g.getPtr(b).?;
            var ai = util.indexOfStr(bn.items, a).?;
            _ = bn.swapRemove(ai);
        }

        var result = 1 + try countPaths(g, from, to);

        // restore the snipped edges
        for (path[1..], 1..) |nodeCost2, j| {
            const nodeCost1 = path[j - 1];
            var a = nodeCost1.state;
            var b = nodeCost2.state;
            var an = g.getPtr(a).?;
            try an.append(b);
            var bn = g.getPtr(b).?;
            try bn.append(a);
        }
        return result;
    } else {
        return 0;
    }
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
            const keyBuf = try allocator.alloc(u8, 7);
            var key = std.fmt.bufPrint(keyBuf, "{s},{s}", if (std.mem.order(u8, left, right) == .lt) .{ left, right } else .{ right, left }) catch unreachable;
            try conns.put(key, undefined);

            // var key1 = try std.fmt.bufPrint(keyBuf1, "{s},{s}", .{ left, right });
            // try conns.put(key1, undefined);
            // const keyBuf2 = try allocator.alloc(u8, 7);
            // var key2 = try std.fmt.bufPrint(keyBuf2, "{s},{s}", .{ right, left });
            // try conns.put(key2, undefined);

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
    var isPrinting = components.items.len < 30;
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
        if (!connList.contains(b)) {
            try connList.put(b, std.ArrayList([]const u8).init(allocator));
        }
        try connList.getPtr(a).?.append(b);
        try connList.getPtr(b).?.append(a);
        if (isPrinting) {
            std.debug.print("  {s} -- {s}\n", .{ a, b });
        }
    }
    if (!isPrinting) {
        std.debug.print("  ... # elided\n", .{});
    }
    std.debug.print("}}\n", .{});

    var g = try connList.clone();
    var n = try countPaths(&g, "jqt", "rsh");
    std.debug.print("jqt -> rsh: {d}\n", .{n});

    // g = try connList.clone();
    n = try countPaths(&g, "jqt", "rhn");
    std.debug.print("jqt -> rhn: {d}\n", .{n});

    // const seed = components.items[0];
    // std.debug.print("flood fill from {s}\n", .{seed});
    // try floodfill(seed, connList);

    // const comps = components.items;
    // for (comps, 0..) |a, i| {
    //     for (comps[(i + 1)..], (i + 1)..) |b, j| {
    //         var numConns: usize = 0;
    //         if (areConnected(a, b, conns)) {
    //             numConns += 1;
    //         }
    //
    //         for (comps, 0..) |c, k| {
    //             if (k == i or k == j) {
    //                 continue;
    //             }
    //             if (areConnected(a, c, conns) and areConnected(b, c, conns)) {
    //                 numConns += 1;
    //             }
    //         }
    //
    //         if (numConns >= 4) {
    //             std.debug.print("{s} and {s} are strongly connected ({d})\n", .{ a, b, numConns });
    //         }
    //     }
    // }

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
