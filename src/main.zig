const std = @import("std");
const day4 = @import("./day4.zig").main;
const day5 = @import("./day5.zig").main;
const day6 = @import("./day6.zig").main;
const day7 = @import("./day7.zig").main;
const day8 = @import("./day8.zig").main;
const day9 = @import("./day9.zig").main;
const day1 = @import("./day1.zig").main;
const day2 = @import("./day2.zig").main;
const day3 = @import("./day3.zig").main;

const Day = struct {
    name: []const u8,
    main: fn (std.mem.Allocator, [][:0]u8) anyerror!void,
};

const DAYS = [_]Day{
    Day{ .name = "day4", .main = day4 },
    Day{ .name = "day5", .main = day5 },
    Day{ .name = "day6", .main = day6 },
    Day{ .name = "day7", .main = day7 },
    Day{ .name = "day8", .main = day8 },
    Day{ .name = "day9", .main = day9 },
    Day{ .name = "day1", .main = day1 },
    Day{ .name = "day2", .main = day2 },
    Day{ .name = "day3", .main = day3 },
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
