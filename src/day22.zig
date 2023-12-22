const std = @import("std");
const bufIter = @import("./buf-iter.zig");
const util = @import("./util.zig");

const assert = std.debug.assert;

const Coord3 = struct {
    x: i32,
    y: i32,
    z: i32,

    pub fn format(self: @This(), comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.fs.File.Writer) !void {
        _ = fmt;
        _ = options;
        try std.fmt.format(writer, "{d},{d},{d}", .{ self.x, self.y, self.z });
    }
};
const Brick = struct {
    a: Coord3,
    b: Coord3,

    pub fn format(self: @This(), comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.fs.File.Writer) !void {
        _ = fmt;
        _ = options;
        try std.fmt.format(writer, "{any}~{any}", .{ self.a, self.b });
    }

    pub fn dx(self: @This()) i32 {
        return self.b.x - self.a.x;
    }
    pub fn dy(self: @This()) i32 {
        return self.b.y - self.a.y;
    }
    pub fn dz(self: @This()) i32 {
        return self.b.z - self.a.z;
    }
};

// alternative with arena allocator:
// pub fn main(in_allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
//     var arena = std.heap.ArenaAllocator.init(in_allocator);
//     defer arena.deinit();
//     var allocator = arena.allocator();

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    const filename = args[0];

    var bricks = std.ArrayList(Brick).init(allocator);
    defer bricks.deinit();
    var iter = try bufIter.iterLines(filename);
    while (try iter.next()) |line| {
        var intBuf: [6]i32 = undefined;
        var ints = try util.extractIntsIntoBuf(i32, line, &intBuf);
        var a = Coord3{ .x = ints[0], .y = ints[1], .z = ints[2] };
        var b = Coord3{ .x = ints[3], .y = ints[4], .z = ints[5] };
        var brick = Brick{ .a = a, .b = b };
        try bricks.append(brick);
        assert(brick.a.z <= brick.b.z);
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
