const std = @import("std");
const util = @import("../util.zig");

const assert = std.debug.assert;

const Component = struct {
    id: usize,
    pins: [2]u32,
    used: bool,
};

const Result = struct {
    length: usize,
    strength: usize,
};

fn findStrongest(components: *[]Component, startPin: u32) Result {
    var best = Result{ .length = 0, .strength = 0 };
    var i: usize = 0;
    // var bestI: usize = 0;
    // XXX how can I write this as a for loop?
    while (i < components.len) : (i += 1) {
        var component = components.*[i];
        // std.debug.print("try component {d}: {any}\n", .{ i, component });
        if (component.used) {
            continue;
        }
        const pins = component.pins;
        if (pins[0] != startPin and pins[1] != startPin) {
            continue;
        }

        components.*[i].used = true;
        const strength = pins[0] + pins[1];
        const otherPin = strength - startPin;
        const rec = findStrongest(components, otherPin);
        const thisBest = Result{ .length = 1 + rec.length, .strength = rec.strength + strength };
        if (thisBest.length > best.length or (thisBest.length == best.length and thisBest.strength >= best.strength)) {
            best = thisBest;
        }
        // if (best == thisBest) {
        //     bestI = i;
        // }
        components.*[i].used = false;
    }

    if (startPin == 0) {
        // std.debug.print("best: {any} {d}\n", .{ components.*[bestI], best });
    }
    return best;
}

fn part1(components: *[]Component) Result {
    return findStrongest(components, 0);
}

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

    var components = std.ArrayList(Component).init(allocator);
    defer components.deinit();

    var i: usize = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        // I guess fixed-size arrays are copied by value?
        var pin_buf: [2]u32 = undefined;
        var pins = try util.extractIntsIntoBuf(u32, line, &pin_buf);
        assert(pins.len == 2);
        try components.append(Component{
            .id = i,
            .pins = pin_buf,
            .used = false,
        });
        i += 1;
    }

    std.debug.print("components: {any}\n", .{components.items});

    // std.debug.print("part 1: {d}\n", .{part1(&components.items)});
    std.debug.print("part 2: {any}\n", .{part1(&components.items)});
}
