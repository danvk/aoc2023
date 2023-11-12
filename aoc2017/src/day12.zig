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

pub fn findZeroClusterSize(allocator: std.mem.Allocator, programs: std.AutoHashMap(u32, Program)) !u32 {
    var seen = std.AutoHashMap(u32, void).init(allocator);
    defer seen.deinit();

    var fringe = std.ArrayList(u32).init(allocator);
    defer fringe.deinit();

    try fringe.append(0);
    while (fringe.popOrNull()) |id| {
        if (seen.contains(id)) {
            continue;
        }
        try seen.put(id, undefined);
        const prog = programs.get(id) orelse unreachable;
        for (prog.neighbors) |neighbor| {
            if (!seen.contains(neighbor)) {
                try fringe.append(neighbor);
            }
        }
    }

    return seen.count();
}

pub fn main(in_allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    var arena = std.heap.ArenaAllocator.init(in_allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    const filename = args[0];

    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;

    // var line_it = try util.iterLines(filename, allocator);
    // defer line_it.deinit();

    var programs = std.AutoHashMap(u32, Program).init(allocator);
    defer programs.deinit();

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        std.debug.print("line: {s}\n", .{line});
        // Comment this out and the lines all look great:
        const program = try parseProgram(allocator, line);
        // std.debug.print("{any}\n", .{program});
        try programs.putNoClobber(program.id, program);
    }

    std.debug.print("part 1: {d}\n", .{try findZeroClusterSize(allocator, programs)});
}
