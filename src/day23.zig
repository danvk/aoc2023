const std = @import("std");
const bufIter = @import("./buf-iter.zig");
const util = @import("./util.zig");
const gridMod = @import("./grid.zig");
const dirMod = @import("./dir.zig");

const Coord = dirMod.Coord;

const assert = std.debug.assert;

// alternative with arena allocator:
// pub fn main(in_allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
//     var arena = std.heap.ArenaAllocator.init(in_allocator);
//     defer arena.deinit();
//     var allocator = arena.allocator();

pub fn main(in_allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    var arena = std.heap.ArenaAllocator.init(in_allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    const filename = args[0];
    var gr = try gridMod.readGrid(allocator, filename, 'x');
    var grid = gr.grid;
    var maxX = gr.maxX;
    var maxY = gr.maxY;
    defer grid.deinit();

    const start = Coord{ .x = 1, .y = 0 };
    const end = Coord{ .x = @intCast(maxX - 1), .y = @intCast(maxY) };
    // std.debug.print("1,0: {?c}\n", .{grid.get(start)});
    // std.debug.print("1,0: {?c}\n", .{grid.get(start)});

    assert(grid.get(start) == '.');
    assert(grid.get(end) == '.');

    // std.debug.print("part 1: {d}\n", .{sum1});
    // std.debug.print("part 2: {d}\n", .{sum2});
}

const expectEqualDeep = std.testing.expectEqualDeep;
const expectEqual = std.testing.expectEqual;
const expect = std.testing.expect;

test "sample test" {
    try expectEqualDeep(true, true);
}
