const std = @import("std");
const day1 = @import("./day1.zig").main;
const day2 = @import("./day2.zig").main;
const day3 = @import("./day3.zig").main;
const day4 = @import("./day4.zig").main;
const day5 = @import("./day5.zig").main;
const day6 = @import("./day6.zig").main;
const day7 = @import("./day7.zig").main;

const expect = std.testing.expect;
const eql = std.mem.eql;

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
    } else if (std.mem.eql(u8, day, "day3")) {
        try day3(allocator, args[2..]);
    } else if (std.mem.eql(u8, day, "day4")) {
        try day4(allocator, args[2..]);
    } else if (std.mem.eql(u8, day, "day5")) {
        try day5(allocator, args[2..]);
    } else if (std.mem.eql(u8, day, "day6")) {
        try day6(allocator, args[2..]);
    } else if (std.mem.eql(u8, day, "day7")) {
        try day7(allocator, args[2..]);
    } else {
        unreachable;
    }
}
