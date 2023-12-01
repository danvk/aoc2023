const std = @import("std");
const util = @import("../util.zig");
const bufIter = @import("../buf-iter.zig");

const assert = std.debug.assert;

const Program = struct {
    id: u32,
    neighbors: []u32,
};

fn parseProgram(allocator: std.mem.Allocator, line: []const u8) !Program {
    var parts = std.ArrayList([]const u8).init(allocator);
    defer parts.deinit();
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

// Caller is responsible for freeing the returned Arraylist.
pub fn findCluster(allocator: std.mem.Allocator, programs: std.AutoHashMap(u32, Program), seed: u32) !std.ArrayList(u32) {
    var seen = std.AutoHashMap(u32, void).init(allocator);
    defer seen.deinit();

    var fringe = std.ArrayList(u32).init(allocator);

    try fringe.append(seed);
    while (fringe.popOrNull()) |id| {
        if (seen.contains(id)) {
            continue;
        }
        try seen.put(id, undefined);
        const prog = programs.get(id).?;
        for (prog.neighbors) |neighbor| {
            if (!seen.contains(neighbor)) {
                try fringe.append(neighbor);
            }
        }
    }

    var it = seen.keyIterator();
    while (it.next()) |id| {
        try fringe.append(id.*);
    }

    return fringe;
}

pub fn part2(allocator: std.mem.Allocator, programs: std.AutoHashMap(u32, Program)) !u32 {
    var seen = std.AutoHashMap(u32, void).init(allocator);
    defer seen.deinit();

    var numClusters: u32 = 0;
    var it = programs.keyIterator();
    while (it.next()) |id| {
        if (seen.contains(id.*)) {
            continue;
        }
        numClusters += 1;

        var cluster = try findCluster(allocator, programs, id.*);
        defer cluster.deinit();
        std.debug.print("Cluster: {any}\n", .{cluster.items});
        for (cluster.items) |cluster_id| {
            try seen.put(cluster_id, undefined);
        }
    }
    return numClusters;
}

pub fn main(in_allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    var arena = std.heap.ArenaAllocator.init(in_allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    const filename = args[0];

    // var file = try std.fs.cwd().openFile(filename, .{});
    // defer file.close();
    // var buf_reader = std.io.bufferedReader(file.reader());
    // var in_stream = buf_reader.reader();
    // var buf: [1024]u8 = undefined;

    var line_it = try bufIter.iterLines(filename);
    defer line_it.deinit();

    var programs = std.AutoHashMap(u32, Program).init(allocator);
    defer programs.deinit();

    // while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
    while (try line_it.next()) |line| {
        std.debug.print("line: {s}\n", .{line});
        // Comment this out and the lines all look great:
        var program = try parseProgram(allocator, line);
        // const heapProgram = try allocator.create(Program);
        // heapProgram.* = program;

        // std.debug.print("{any}\n", .{program});
        try programs.putNoClobber(program.id, program);
    }

    var zeroCluster = try findCluster(allocator, programs, 0);
    defer zeroCluster.deinit();
    std.debug.print("part 1: {d}\n", .{zeroCluster.items.len});
    std.debug.print("part 2: {d}\n", .{try part2(allocator, programs)});
}
