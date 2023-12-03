const std = @import("std");
const day1 = @import("./day1.zig").main;
const day2 = @import("./day2.zig").main;
const day3 = @import("./day3.zig").main;

const Day = struct {
    name: []const u8,
    main: fn (std.mem.Allocator, [][:0]u8) anyerror!void,
};

const DAYS = [_]Day{
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
