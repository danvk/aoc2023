const std = @import("std");
const day1 = @import("day1").main;
const day2 = @import("day2").main;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // args[0] is the executable
    const day = args[1];
    if (std.mem.eql(u8, day, "day1")) {
        try day1(allocator, args[2..]);
    } else if (std.mem.eql(u8, day, "day2")) {
        try day2(allocator, args[2..]);
    } else {
        unreachable;
    }
}
