const std = @import("std");
const day1 = @import("./day1.zig").main;
const day2 = @import("./day2.zig").main;
const day3 = @import("./day3.zig").main;
const day4 = @import("./day4.zig").main;
const day5 = @import("./day5.zig").main;

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
    } else {
        unreachable;
    }
}

test "hex" {
    var b: [8]u8 = undefined;

    _ = try std.fmt.bufPrint(&b, "{X}", .{4294967294});
    try expect(eql(u8, &b, "FFFFFFFE"));

    _ = try std.fmt.bufPrint(&b, "{x}", .{4294967294});
    try expect(eql(u8, &b, "fffffffe"));

    _ = try std.fmt.bufPrint(&b, "{}", .{std.fmt.fmtSliceHexLower("Zig!")});
    try expect(eql(u8, &b, "5a696721"));
}

test "day formatting" {
    for (1..1) |day| {
        var path: [100]u8 = undefined;
        var module_name: [100]u8 = undefined;

        _ = try std.fmt.bufPrint(&path, "src/day{d}.zig", .{day});
        _ = try std.fmt.bufPrint(&module_name, "day{d}", .{day});
        try expect(eql([]u8, path, "src/day1.zig"));
        try expect(eql([]u8, module_name, "day1"));
    }
}
