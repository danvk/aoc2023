const std = @import("std");
const util = @import("./util.zig");
const dir = @import("./dir.zig");
const Dir = dir.Dir;
const Coord = dir.Coord;

const assert = std.debug.assert;

fn part1(allocator: std.mem.Allocator, maze: std.AutoHashMap(Coord, u8), x0: i32) !void {
    var d = Dir.down;
    var pos = Coord{ .x = x0, .y = 0 };
    var letters = std.ArrayList(u8).init(allocator);
    defer letters.deinit();

    while (true) {
        const c = maze.get(pos).?;
        if (c == '+') {
            // var goal: u8 = '|';
            // if (d == Dir.down or d == Dir.up) {
            //     goal = '-';
            // }
            var newDs = [_]Dir{ d.ccw(), d.cw() };
            var ok = false;
            // std.debug.print("At {any} dir {any}, looking for {s}, will try {any}\n", .{ pos, d, [_]u8{goal}, newDs });
            for (newDs) |newD| {
                var nextPos = pos.move(newD);
                if (maze.contains(nextPos)) {
                    d = newD;
                    pos = nextPos;
                    ok = true;
                    break;
                }
            }
            if (!ok) {
                unreachable;
            }
        } else if (c >= 'A' and c <= 'Z') {
            // collect letter, possibly end.
            try letters.append(c);
            pos = pos.move(d);
            if (!maze.contains(pos)) {
                break;
            }
        } else if (c == '|' or c == '-') {
            pos = pos.move(d);
        } else {
            unreachable;
        }
    }

    std.debug.print("part 1: {s}\n", .{letters.items});
}

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    const filename = args[0];

    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;

    var maze = std.AutoHashMap(Coord, u8).init(allocator);
    defer maze.deinit();

    var y: i32 = 0;
    var x0: i32 = -1;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        for (line, 0..) |c, i| {
            if (c == ' ') {
                continue;
            }
            try maze.putNoClobber(Coord{ .x = @intCast(i), .y = y }, c);
            if (y == 0) {
                assert(x0 == -1);
                x0 = @intCast(i);
            }
        }
        y += 1;
    }

    try part1(allocator, maze, x0);

    // std.debug.print("part 1: {d}\n", .{part1(instructions.items)});
    // std.debug.print("part 2: {d}\n", .{try part2(allocator, instructions.items)});
}
