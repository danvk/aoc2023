const std = @import("std");
const util = @import("./util.zig");

const assert = std.debug.assert;

const Program = struct {
    id: u32,
    neighbors: []u32,
};

fn parseProgram(allocator: std.mem.Allocator, line: []const u8) !Program {
    var parts = std.ArrayList([]const u8).init(allocator);
    try util.splitIntoArrayList(line, " <-> ", &parts);
    assert(parts.items.len == 2);

    const id = try std.fmt.parseInt(u32, parts.items[0], 10);
    try util.splitIntoArrayList(parts.items[1], ", ", &parts);

    var neighbors = try allocator.alloc(u32, parts.items.len);
    for (parts.items, 0..) |part, i| {
        neighbors[i] = try std.fmt.parseInt(u32, part, 10);
    }

    return Program{
        .id = id,
        .neighbors = neighbors,
    };
}

pub fn main(in_allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    var arena = std.heap.ArenaAllocator.init(in_allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    const filename = args[0];

    var line_it = try util.iterLines(filename, allocator);
    defer line_it.deinit();

    var programs = std.AutoHashMap(u32, Program).init(allocator);
    defer programs.deinit();

    while (try line_it.next()) |line| {
        std.debug.print("line: {s}\n", .{line});
        // Comment this out and the lines all look great:
        const program = try parseProgram(allocator, line);
        _ = program;
        // std.debug.print("{any}\n", .{program});
        // try programs.putNoClobber(program.id, program);
    }
}
