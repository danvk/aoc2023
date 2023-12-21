const std = @import("std");
const bufIter = @import("./buf-iter.zig");
const util = @import("./util.zig");
const dirMod = @import("./dir.zig");
const gridMod = @import("./grid.zig");

const Coord = dirMod.Coord;

const assert = std.debug.assert;

// alternative with arena allocator:
// pub fn main(in_allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
//     var arena = std.heap.ArenaAllocator.init(in_allocator);
//     defer arena.deinit();
//     var allocator = arena.allocator();

fn findStart(grid: std.AutoHashMap(Coord, u8)) Coord {
    var it = grid.iterator();
    while (it.next()) |entry| {
        if (entry.value_ptr.* == 'S') {
            return entry.key_ptr.*;
        }
    }
    unreachable;
}

fn step(gr: *gridMod.GridResult, spots: std.AutoHashMap(Coord, void), nexts: *std.AutoHashMap(Coord, void)) !void {
    nexts.clearAndFree();
    var it = spots.keyIterator();
    var grid = gr.grid;
    while (it.next()) |pos| {
        for (dirMod.DIRS) |d| {
            var p = pos.move(d);
            if ((grid.get(p) orelse '.') == '.') {
                try nexts.put(p, undefined);
            }
        }
    }
}

fn step2(gr: *gridMod.GridResult, spots: std.AutoHashMap(Coord, void), nexts: *std.AutoHashMap(Coord, void)) !void {
    const maxX: i32 = @intCast(gr.maxX + 1);
    const maxY: i32 = @intCast(gr.maxY + 1);
    nexts.clearAndFree();
    var it = spots.keyIterator();
    var grid = gr.grid;
    while (it.next()) |pos| {
        for (dirMod.DIRS) |d| {
            const p = pos.move(d);
            const m = Coord{ .x = @mod(p.x, maxX), .y = @mod(p.y, maxY) };
            if ((grid.get(m) orelse '.') == '.') {
                try nexts.put(p, undefined);
            }
        }
    }
}

fn printKeys(grid: std.AutoHashMap(Coord, void)) void {
    var it = grid.keyIterator();
    while (it.next()) |pos| {
        std.debug.print("{any} ", .{pos});
    }
    std.debug.print("\n", .{});
}

fn printGarden(gr: gridMod.GridResult, spots: std.AutoHashMap(Coord, void)) void {
    const maxX: i32 = @intCast(gr.maxX + 1);
    const maxY: i32 = @intCast(gr.maxY + 1);
    const grid = gr.grid;
    for (0..@intCast(maxY)) |yu| {
        const y: i32 = @intCast(yu);
        for (0..@intCast(maxX)) |xu| {
            const x: i32 = @intCast(xu);
            const m = Coord{ .x = x, .y = y };
            const p = Coord{ .x = x, .y = y + maxY };
            if (spots.contains(p)) {
                std.debug.print("O", .{});
            } else {
                std.debug.print("{c}", .{grid.get(m) orelse '.'});
            }
        }
        std.debug.print("\n", .{});
    }
}

const TileHash = struct {
    hash: u64,
    count: usize,
};

fn tileHash(gr: gridMod.GridResult, spots: std.AutoHashMap(Coord, void), tile: Coord) TileHash {
    var count: usize = 0;
    const maxX: i32 = @intCast(gr.maxX + 1);
    const maxY: i32 = @intCast(gr.maxY + 1);
    var buf = [2]u32{ 0, 0 };
    var bufAddr: [*]u8 = @ptrCast(&buf);
    var bufSlice = bufAddr[0..8];
    var hasher = std.hash.Wyhash.init(42);
    for (0..@intCast(maxY)) |yu| {
        const y: i32 = @intCast(yu);
        for (0..@intCast(maxX)) |xu| {
            const x: i32 = @intCast(xu);
            const p = Coord{ .x = x + tile.x * maxX, .y = y + tile.y * maxY };
            if (spots.contains(p)) {
                count += 1;
                buf[0] = @intCast(xu);
                buf[1] = @intCast(yu);
                hasher.update(bufSlice);
            }
        }
    }
    return TileHash{ .count = count, .hash = hasher.final() };
}

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    const filename = args[0];

    var gr = try gridMod.readGrid(allocator, filename, null);
    var grid = gr.grid;
    defer grid.deinit();

    const start = findStart(grid);
    try grid.put(start, '.');

    std.debug.print("start: {any}\n", .{start});

    var spots = std.AutoHashMap(Coord, void).init(allocator);
    try spots.put(start, undefined);
    for (0..64) |i| {
        var nextSpots = std.AutoHashMap(Coord, void).init(allocator);
        try step(&gr, spots, &nextSpots);
        // std.debug.print("{d}: {d}\n", .{ i, nextSpots.count() });
        // printKeys(nextSpots);
        std.debug.print("{d}: {any}\n", .{ i, tileHash(gr, nextSpots, Coord{ .x = 0, .y = 0 }) });
        spots.deinit();
        spots = nextSpots;
    }
    std.debug.print("part 1: {d}\n", .{spots.count()});

    // spots.clearAndFree();
    // try spots.put(start, undefined);
    //
    // var timer = try std.time.Timer.start();
    // for (1..5001) |i| {
    //     var nextSpots = std.AutoHashMap(Coord, void).init(allocator);
    //
    //     try step2(&gr, spots, &nextSpots);
    //     const elapsed = timer.read() / 1_000_000_000;
    //     std.debug.print("{d}: {d} ({d} s)\n", .{ i, nextSpots.count(), elapsed });
    //     // printKeys(nextSpots);
    //     printGarden(gr, nextSpots);
    //
    //     spots.deinit();
    //     spots = nextSpots;
    // }
    spots.deinit();

    // std.debug.print("part 2: {d}\n", .{sum2});
}

const expectEqualDeep = std.testing.expectEqualDeep;
const expectEqual = std.testing.expectEqual;
const expect = std.testing.expect;

test "sample test" {
    try expectEqualDeep(true, true);
}
