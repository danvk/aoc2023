const std = @import("std");
const util = @import("./util.zig");

const assert = std.debug.assert;

const Layer = struct {
    layer: u32,
    range: u32,
    pos: i32 = 0,
    dir: i32 = 1,

    fn next(self: *Layer) void {
        self.pos += self.dir;
        if (self.pos == self.range - 1) {
            self.dir = -1;
        } else if (self.pos == 0) {
            self.dir = 1;
        }
    }

    fn posAt(self: Layer, time: u32) u32 {
        // self.range = 3; 2 * range - 2 = 4
        // t=0, pos=0, return 0
        // t=1, pos=1, return 1
        // t=2, pos=2, return 2
        // t=3, pos=3, return 1
        // t=4, pos=0, return 0
        const pos = time % (2 * self.range - 2);
        if (pos >= self.range) {
            return 2 * self.range - 2 - pos;
        }
        return pos;
    }
};

fn parseLayer(line: []const u8) !Layer {
    var buf: [2]u32 = undefined;
    const ints = try util.extractIntsIntoBuf(u32, line, &buf);
    assert(ints.len == 2);

    return Layer{
        .layer = ints[0],
        .range = ints[1],
    };
}

fn printLayers(layers: std.AutoHashMap(u32, Layer), maxLayer: u32) void {
    for (0..(maxLayer + 1)) |layer| {
        if (layers.get(@as(u32, @intCast(layer)))) |scanner| {
            std.debug.print("{any}\n", .{scanner});
        }
    }
}

fn part1(layers: std.AutoHashMap(u32, Layer), maxLayer: u32) u32 {
    var damage: u32 = 0;
    for (0..(maxLayer + 1)) |layer| {
        const layeru32: u32 = @intCast(layer);
        if (layers.get(layeru32)) |scanner| {
            if (scanner.posAt(layeru32) == 0) {
                const d = scanner.layer * scanner.range;
                std.debug.print("take {d} damage at layer {d}\n", .{ d, layer });
                damage += d;
            }
        }
        // var it = layers.valueIterator();
        // while (it.next()) |val| {
        //     val.next();
        // }
        // std.debug.print("{d}:\n", .{layer});
        // printLayers(layers, maxLayer);
        // std.debug.print("\n", .{});
    }
    return damage;
}

fn resetLayers(layers: std.AutoHashMap(u32, Layer)) void {
    var it = layers.valueIterator();
    while (it.next()) |val| {
        val.pos = 0;
        val.dir = 1;
    }
}

fn doYouMakeIt(layers: std.AutoHashMap(u32, Layer), maxLayer: u32, delay: u32) bool {
    for (0..(maxLayer + 1)) |layer| {
        const layeru32: u32 = @intCast(layer);
        if (layers.get(layeru32)) |scanner| {
            if (scanner.posAt(layeru32 + delay) == 0) {
                return false;
            }
        }
    }
    return true;
}

fn part2(layers: std.AutoHashMap(u32, Layer), maxLayer: u32) u32 {
    // resetLayers(layers);
    var delay: u32 = 0;
    while (true) : (delay += 1) {
        if (delay % 10_000 == 0) {
            std.debug.print("delay={d}\n", .{delay});
        }
        // resetLayers(layers);
        if (doYouMakeIt(layers, maxLayer, delay)) {
            return delay;
        }
    }
    unreachable;
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

    var layers = std.AutoHashMap(u32, Layer).init(allocator);
    defer layers.deinit();

    var maxLayer: u32 = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        // std.debug.print("line: {s}\n", .{line});
        // Comment this out and the lines all look great:
        const layer = try parseLayer(line);
        // std.debug.print("{any}\n", .{program});
        try layers.putNoClobber(layer.layer, layer);
        maxLayer = @max(maxLayer, layer.layer);
    }

    std.debug.print("part 1: {d}\n", .{part1(layers, maxLayer)});
    std.debug.print("part 2: {d}\n", .{part2(layers, maxLayer)});
}
