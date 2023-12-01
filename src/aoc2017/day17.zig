const std = @import("std");
const util = @import("../util.zig");

const assert = std.debug.assert;

const Value = struct {
    num: usize,
    next: usize, // how to make this *Value?
};

fn printBuffer(vals: []Value, pos: usize) void {
    var i: usize = 0;
    while (true) {
        const v = vals[i];
        if (i != 0) {
            std.debug.print(" ", .{});
        }
        if (i == pos) {
            std.debug.print("({d})", .{v.num});
        } else {
            std.debug.print("{d}", .{v.num});
        }
        i = v.next;

        if (i == 0) {
            std.debug.print("\n", .{});
            break;
        }
    }
}

fn part1(allocator: std.mem.Allocator, step: usize) !usize {
    var vals = std.ArrayList(Value).init(allocator);
    defer vals.deinit();
    try vals.append(Value{ .num = 0, .next = 0 });
    var i: usize = 0;

    printBuffer(vals.items, i);

    for (1..2018) |n| {
        // advance _step_ steps
        for (0..step) |_| {
            i = vals.items[i].next;
        }
        // insert the number
        const v = &vals.items[i];
        // std.debug.print("inserting {d} after {d}: {any}\n", .{ n, i, v });
        try vals.append(Value{ .num = n, .next = v.next });
        vals.items[i].next = vals.items.len - 1;

        // advance to the new item
        i = vals.items[i].next;

        // printBuffer(vals.items, i);
        // std.debug.print("buf: {any}\n", .{vals.items});
    }

    const last = vals.items[vals.items.len - 1];
    assert(last.num == 2017);
    return vals.items[last.next].num;
}

fn part2(allocator: std.mem.Allocator, step: usize) !usize {
    var vals = std.ArrayList(Value).init(allocator);
    defer vals.deinit();
    try vals.append(Value{ .num = 0, .next = 0 });
    var i: usize = 0;

    printBuffer(vals.items, i);

    for (1..50_000_001) |n| {
        // advance _step_ steps
        for (0..step) |_| {
            i = vals.items[i].next;
        }
        // insert the number
        const v = &vals.items[i];
        // std.debug.print("inserting {d} after {d}: {any}\n", .{ n, i, v });
        try vals.append(Value{ .num = n, .next = v.next });
        vals.items[i].next = vals.items.len - 1;

        // advance to the new item
        i = vals.items[i].next;

        // printBuffer(vals.items, i);
        // std.debug.print("buf: {any}\n", .{vals.items});

        if (n % 100_000 == 0) {
            std.debug.print("{d}...\n", .{n});
        }
    }

    const last = vals.items[vals.items.len - 1];
    assert(last.num == 50_000_000);
    return vals.items[vals.items[0].next].num;
}

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    const step = try std.fmt.parseInt(usize, args[0], 10);

    std.debug.print("part 1: {d}\n", .{try part1(allocator, step)});
    std.debug.print("part 2: {d}\n", .{try part2(allocator, step)});
}
