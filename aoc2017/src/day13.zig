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
};

fn parseLayer(allocator: std.mem.Allocator, line: []const u8) !Layer {
    var parts = std.ArrayList([]const u8).init(allocator);
    try util.splitIntoArrayList(line, ": ", &parts);
    assert(parts.items.len == 2);

    const layer = try std.fmt.parseInt(u32, parts.items[0], 10);
    const range = try std.fmt.parseInt(u32, parts.items[1], 10);

    return Layer{
        .layer = layer,
        .range = range,
    };
}

fn printLayers(layers: std.AutoHashMap(u32, Layer), maxLayer: u32) void {
    for (0..(maxLayer + 1)) |layer| {
        if (layers.get(@as(u32, @intCast(layer)))) |scanner| {
            std.debug.print("{any}\n", .{scanner});
        }
    }
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
        const layer = try parseLayer(allocator, line);
        // std.debug.print("{any}\n", .{program});
        try layers.putNoClobber(layer.layer, layer);
        maxLayer = @max(maxLayer, layer.layer);
    }

    var damage: u32 = 0;
    for (0..(maxLayer + 1)) |layer| {
        if (layers.get(@as(u32, @intCast(layer)))) |scanner| {
            if (scanner.pos == 0) {
                const d = scanner.layer * scanner.range;
                std.debug.print("take {d} damage at layer {d}\n", .{ d, layer });
                damage += d;
            }
        }
        var it = layers.valueIterator();
        while (it.next()) |val| {
            val.next();
        }
        std.debug.print("{d}:\n", .{layer});
        printLayers(layers, maxLayer);
        std.debug.print("\n", .{});
    }

    std.debug.print("part 1: {d}\n", .{damage});
    // std.debug.print("part 2: {d}\n", .{try part2(allocator, programs)});
}
