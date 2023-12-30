const std = @import("std");
const bufIter = @import("./buf-iter.zig");
const util = @import("./util.zig");
const queue = @import("./queue.zig");
const dijkstra = @import("./dijkstra.zig");

const assert = std.debug.assert;

const Conn = struct {
    from: []const u8,
    to: []const u8,
};

fn compareStrings(_: void, lhs: []const u8, rhs: []const u8) bool {
    return std.mem.order(u8, lhs, rhs).compare(std.math.CompareOperator.lt);
}

const Graph = std.StringHashMap(std.ArrayList([]const u8));

// find all the nodes connected to the seed.
// caller must free returned slice
fn floodfill(seed: []const u8, conns: Graph) ![][]const u8 {
    var allocator = conns.allocator;
    var seen = std.StringHashMap(void).init(allocator);
    defer seen.deinit();

    var fringe = queue.Queue([]const u8).init(allocator);
    try fringe.enqueue(seed);
    while (fringe.dequeue()) |n| {
        if (seen.contains(n)) {
            continue;
        }
        try seen.put(n, undefined);

        if (conns.get(n)) |nextConns| {
            for (nextConns.items) |nextNode| {
                try fringe.enqueue(nextNode);
            }
        }
    }

    var component = std.ArrayList([]const u8).init(allocator);
    defer component.deinit();

    var it = seen.keyIterator();
    while (it.next()) |k| {
        try component.append(k.*);
    }
    return component.toOwnedSlice();
}

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

fn addEdge(g: *Graph, a: []const u8, b: []const u8) !void {
    var an: *std.ArrayList([]const u8) = undefined;
    if (g.getPtr(a)) |ap| {
        an = ap;
    } else {
        try g.putNoClobber(a, std.ArrayList([]const u8).init(g.allocator));
        an = g.getPtr(a).?; // XXX any more efficient way to do this?
    }
    if (util.indexOfStr(an.items, b) != null) {
        return;
    }
    try an.append(b);

    var bn: *std.ArrayList([]const u8) = undefined;
    if (g.getPtr(b)) |bp| {
        bn = bp;
    } else {
        try g.putNoClobber(b, std.ArrayList([]const u8).init(g.allocator));
        bn = g.getPtr(b).?; // XXX any more efficient way to do this?
    }
    try bn.append(a);
}

fn countComponents(g: Graph) ![]usize {
    var ally = g.allocator;
    var seen = std.StringHashMap(void).init(ally);
    defer seen.deinit();

    var counts = std.ArrayList(usize).init(ally);
    defer counts.deinit();

    var nodes = std.ArrayList([]const u8).init(ally);
    defer nodes.deinit();
    var it = g.keyIterator();
    while (it.next()) |n| {
        try nodes.append(n.*);
    }

    for (nodes.items) |n| {
        if (seen.contains(n)) {
            continue;
        }

        var component = try floodfill(n, g);
        defer ally.free(component);

        std.debug.print("component: [", .{});
        for (component) |c| {
            std.debug.print(" {s}", .{c});
        }
        std.debug.print(" ]\n", .{});

        try counts.append(component.len);
        for (component) |c| {
            try seen.put(c, undefined);
        }
    }

    return counts.toOwnedSlice();
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

    var connected = Graph.init(allocator);
    defer connected.deinit();
    connIt = conns.keyIterator();
    while (connIt.next()) |conn| {
        var partsBuf2: [2][]const u8 = undefined;
        var parts = util.splitIntoBuf(conn.*, ",", &partsBuf2);
        assert(parts.len == 2);
        var a = parts[0];
        var b = parts[1];

        var n = try countPaths(&connList, a, b);
        if (n > 3) {
            try addEdge(&connected, a, b);
            // std.debug.print("{s} and {s} are in the same component\n", .{ a, b });
        }
    }

    const part2 = try countComponents(connected);
    defer allocator.free(part2);
    std.debug.print("components: {any}\n", .{part2});
    std.debug.print("day 25: {d}\n", .{part2[0] * part2[1]});
}

const expectEqualDeep = std.testing.expectEqualDeep;
const expectEqual = std.testing.expectEqual;
const expect = std.testing.expect;

test "sample test" {
    try expectEqualDeep(true, true);
}
