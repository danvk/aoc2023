const std = @import("std");
const day1 = @import("./aoc2017/day1.zig").main;
const day2 = @import("./aoc2017/day2.zig").main;
const day3 = @import("./aoc2017/day3.zig").main;
const day4 = @import("./aoc2017/day4.zig").main;
const day5 = @import("./aoc2017/day5.zig").main;
const day6 = @import("./aoc2017/day6.zig").main;
const day7 = @import("./aoc2017/day7.zig").main;
const day8 = @import("./aoc2017/day8.zig").main;
const day9 = @import("./aoc2017/day9.zig").main;
const day10 = @import("./aoc2017/day10.zig").main;
const day11 = @import("./aoc2017/day11.zig").main;
const day12 = @import("./aoc2017/day12.zig").main;
const day13 = @import("./aoc2017/day13.zig").main;
const day14 = @import("./aoc2017/day14.zig").main;
const day15 = @import("./aoc2017/day15.zig").main;
const day16 = @import("./aoc2017/day16.zig").main;
const day17 = @import("./aoc2017/day17.zig").main;
const day18 = @import("./aoc2017/day18.zig").main;
const day19 = @import("./aoc2017/day19.zig").main;
const day20 = @import("./aoc2017/day20.zig").main;
const day21 = @import("./aoc2017/day21.zig").main;
const day22 = @import("./aoc2017/day22.zig").main;
const day23 = @import("./aoc2017/day23.zig").main;
const day24 = @import("./aoc2017/day24.zig").main;
const day25 = @import("./aoc2017/day25.zig").main;

const Day = struct {
    name: []const u8,
    main: fn (std.mem.Allocator, [][:0]u8) anyerror!void,
};

const DAYS = [_]Day{
    Day{ .name = "day1", .main = day1 },
    Day{ .name = "day2", .main = day2 },
    Day{ .name = "day3", .main = day3 },
    Day{ .name = "day4", .main = day4 },
    Day{ .name = "day5", .main = day5 },
    Day{ .name = "day6", .main = day6 },
    Day{ .name = "day7", .main = day7 },
    Day{ .name = "day8", .main = day8 },
    Day{ .name = "day9", .main = day9 },
    Day{ .name = "day10", .main = day10 },
    Day{ .name = "day11", .main = day11 },
    Day{ .name = "day12", .main = day12 },
    Day{ .name = "day13", .main = day13 },
    Day{ .name = "day14", .main = day14 },
    Day{ .name = "day15", .main = day15 },
    Day{ .name = "day16", .main = day16 },
    Day{ .name = "day17", .main = day17 },
    Day{ .name = "day18", .main = day18 },
    Day{ .name = "day19", .main = day19 },
    Day{ .name = "day20", .main = day20 },
    Day{ .name = "day21", .main = day21 },
    Day{ .name = "day22", .main = day22 },
    Day{ .name = "day23", .main = day23 },
    Day{ .name = "day24", .main = day24 },
    Day{ .name = "day25", .main = day25 },
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // args[0] is the executable
    const day = args[1];
    var has_run = false;
    inline for (DAYS) |day_entry| {
        if (std.mem.eql(u8, day, day_entry.name)) {
            try day_entry.main(allocator, args[2..]);
            has_run = true;
            break;
        }
    }
    std.debug.assert(has_run);
}
