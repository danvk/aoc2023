const std = @import("std");
const bufIter = @import("./buf-iter.zig");
const util = @import("./util.zig");

const assert = std.debug.assert;

// alternative with arena allocator:
// pub fn main(in_allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
//     var arena = std.heap.ArenaAllocator.init(in_allocator);
//     defer arena.deinit();
//     var allocator = arena.allocator();

// Determine the ASCII code for the current character of the string.
// Increase the current value by the ASCII code you just determined.
// Set the current value to itself multiplied by 17.
// Set the current value to the remainder of dividing itself by 256.
fn hash(str: []const u8) u8 {
    var val: u16 = 0;
    for (str) |c| {
        val += c;
        val *= 17;
        val = val & 0xff;
    }
    return @intCast(val);
}

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    const filename = args[0];

    var iter = try bufIter.iterLines(filename);
    var sum: u64 = 0;
    while (try iter.next()) |line| {
        var parts = std.ArrayList([]const u8).init(allocator);
        defer parts.deinit();

        try util.splitIntoArrayList(line, ",", &parts);
        assert(parts.items.len > 1);
        for (parts.items) |part| {
            const v = hash(part);
            sum += v;
        }
    }

    std.debug.print("part 1: {d}\n", .{sum});
    // std.debug.print("part 2: {d}\n", .{sum2});
}

const expectEqualDeep = std.testing.expectEqualDeep;
const expectEqual = std.testing.expectEqual;
const expect = std.testing.expect;

test "hash" {
    try expectEqual(hash("HASH"), 52);
}
