const std = @import("std");
const util = @import("./util.zig");

const assert = std.debug.assert;

pub fn main(parent_allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    var arena = std.heap.ArenaAllocator.init(parent_allocator);
    defer arena.deinit();
    var allocator = arena.allocator();
    const filename = args[0];

    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;

    var components = std.ArrayList([2]u32).init(allocator);
    defer components.deinit();

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        // I guess fixed-size arrays are copied by value?
        var pin_buf: [2]u32 = undefined;
        var pins = try util.extractIntsIntoBuf(u32, line, &pin_buf);
        assert(pins.len == 2);
        try components.append(pin_buf);
    }

    std.debug.print("components: {any}\n", .{components.items});

    // try part1(allocator, maze, x0);

    // std.debug.print("part 1: {d}\n", .{part1(instructions.items)});
    // std.debug.print("part 2: {d}\n", .{try part2(allocator, instructions.items)});
}
