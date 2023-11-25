const std = @import("std");

// Read u32s delimited by spaces or tabs from a line of text.
pub fn readInts(comptime IntType: type, line: []const u8, nums: *std.ArrayList(IntType)) !void {
    var it = std.mem.splitAny(u8, line, ", \t");
    while (it.next()) |split| {
        if (split.len == 0) {
            continue;
        }
        const num = try std.fmt.parseInt(IntType, split, 10);
        try nums.append(num);
    }
}

fn isDigit(c: u8) bool {
    return c == '-' or (c >= '0' and c <= '9');
}

pub fn extractIntsIntoBuf(comptime IntType: type, str: []const u8, buf: []IntType) ![]IntType {
    var i: usize = 0;
    var n: usize = 0;

    while (i < str.len) {
        const c = str[i];
        if (isDigit(c)) {
            const start = i;
            i += 1;
            while (i < str.len) {
                const c2 = str[i];
                if (!isDigit(c2)) {
                    break;
                }
                i += 1;
            }
            buf[n] = try std.fmt.parseInt(IntType, str[start..i], 10);
            n += 1;
        } else {
            i += 1;
        }
    }
    return buf[0..n];
}

pub fn splitOne(line: []const u8, delim: []const u8) ?struct { head: []const u8, rest: []const u8 } {
    const maybeIdx = std.mem.indexOf(u8, line, delim);
    // XXX is there a more idiomatic way to write this pattern?
    if (maybeIdx) |idx| {
        return .{ .head = line[0..idx], .rest = line[(idx + delim.len)..] };
    } else {
        return null;
    }
}

pub fn splitIntoArrayList(input: []const u8, delim: []const u8, array_list: *std.ArrayList([]const u8)) !void {
    array_list.clearAndFree();
    var it = std.mem.splitSequence(u8, input, delim);
    while (it.next()) |part| {
        try array_list.append(part);
    }
    // std.fmt.bufPrint(buf: []u8, comptime fmt: []const u8, args: anytype)
    // std.fmt.bufPrintIntToSlice(buf: []u8, value: anytype, base: u8, case: Case, options: FormatOptions)
}

// Split the string into a pre-allocated buffer of slices.
// The buffer must be large enough to accommodate the number of parts.
// The returned slices point into the input string.
pub fn splitIntoBuf(str: []const u8, delim: []const u8, buf: [][]const u8) [][]const u8 {
    var rest = str;
    var i: usize = 0;
    while (splitOne(rest, delim)) |split| {
        buf[i] = split.head;
        rest = split.rest;
        i += 1;
    }
    buf[i] = rest;
    i += 1;
    return buf[0..i];
}

pub fn readInputFile(filename: []const u8, allocator: std.mem.Allocator) ![]const u8 {
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();
    const stat = try file.stat();
    const fileSize = stat.size;
    return try file.reader().readAllAlloc(allocator, fileSize);
}

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualDeep = std.testing.expectEqualDeep;

test "splitIntoBuf" {
    var buf: [8][]const u8 = undefined;
    const parts = splitIntoBuf("abc,def,,gh12", ",", &buf);
    try expectEqual(@as(usize, 4), parts.len);
    try expectEqualDeep(@as([]const u8, "abc"), parts[0]);
    try expectEqualDeep(@as([]const u8, "def"), parts[1]);
    try expectEqualDeep(@as([]const u8, ""), parts[2]);
    try expectEqualDeep(@as([]const u8, "gh12"), parts[3]);
    // const expected = [_][]const u8{ "abc", "def", "", "gh12" };
    // expectEqualDeep(@as([][]const u8, &[_][]const u8{ "abc", "def", "", "gh12" }), parts);
}

const eql = std.mem.eql;

test "extractIntsIntoBuf" {
    var buf: [8]i32 = undefined;
    var ints = try extractIntsIntoBuf(i32, "12, 38, -233", &buf);
    try expect(eql(i32, &[_]i32{ 12, 38, -233 }, ints));

    ints = try extractIntsIntoBuf(i32, "zzz343344ddkd", &buf);
    try expect(eql(i32, &[_]i32{343344}, ints));

    ints = try extractIntsIntoBuf(i32, "not a number", &buf);
    try expect(eql(i32, &[_]i32{}, ints));
}
