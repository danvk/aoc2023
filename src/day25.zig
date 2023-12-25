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

    var partsBuf: [20][]const u8 = undefined;
    var it = std.mem.tokenize(u8, contents, "\n");
    while (it.next()) |line| {
        var parts = util.splitAnyIntoBuf(line, ": ", &partsBuf);
        var left = parts[0];
        for (parts[1..]) |right| {
            const keyBuf = try allocator.alloc(u8, 7);
            var key = try std.fmt.bufPrint(keyBuf, "{s},{s}", if (std.mem.order(u8, left, right) == .lt) .{ left, right } else .{ right, left });
            try conns.put(key, undefined);
        }
    }

    std.debug.print("{d} connections\n", .{conns.count()});
    var kit = conns.keyIterator();
    while (kit.next()) |k| {
        std.debug.print("  {s}\n", .{k.*});
    }

    // std.debug.print("part 1: {d}\n", .{sum1});
    // std.debug.print("part 2: {d}\n", .{sum2});
}

const expectEqualDeep = std.testing.expectEqualDeep;
const expectEqual = std.testing.expectEqual;
const expect = std.testing.expect;

test "sample test" {
    try expectEqualDeep(true, true);
}
