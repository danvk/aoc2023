const std = @import("std");

// Read u32s delimited by spaces or tabs from a line of text.
pub fn readInts(comptime inttype: type, line: []const u8, nums: *std.ArrayList(inttype)) !void {
    var it = std.mem.splitAny(u8, line, ", \t");
    while (it.next()) |split| {
        if (split.len == 0) {
            continue;
        }
        const num = try std.fmt.parseInt(inttype, split, 10);
        try nums.append(num);
    }
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

pub fn splitIntoBuf(line: []const u8, delim: []const u8, out: [][]const u8) [][]const u8 {
    var buf = line;
    var i: usize = 0;
    while (splitOne(buf, delim)) |split| {
        out[i] = split.head;
        buf = split.rest;
        i += 1;
    }
    out[i] = buf;
    i += 1;
    return out[0..i];
}

pub fn readInputFile(filename: []const u8, allocator: std.mem.Allocator) ![]const u8 {
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();
    const stat = try file.stat();
    const fileSize = stat.size;
    return try file.reader().readAllAlloc(allocator, fileSize);
}

// TODO: standardize on allocator-first
pub fn iterLines(filename: []const u8, allocator: std.mem.Allocator) !ReadByLineIterator(@TypeOf(getBufferedReader(std.fs.cwd().openFile(filename, .{}) catch unreachable))) {
    var file = try std.fs.cwd().openFile(filename, .{});
    var buf_reader = getBufferedReader(file);
    return readByLine(allocator, &file, buf_reader);
}

pub fn getBufferedReader(file: std.fs.File) @TypeOf(blk: {
    var raw_reader = file.reader();
    var buf_reader = std.io.bufferedReader(raw_reader);
    var in_stream = buf_reader.reader();
    break :blk in_stream;
}) {
    var raw_reader = file.reader();
    var buf_reader = std.io.bufferedReader(raw_reader);
    var in_stream = buf_reader.reader();
    return in_stream;
}

fn ReadByLineIterator(comptime ReaderType: type) type {
    return struct {
        allocator: std.mem.Allocator,
        file_to_close: *std.fs.File,
        reader: ReaderType,
        buffer: []u8,

        pub fn deinit(self: @This()) void {
            self.allocator.free(self.buffer);
            self.file_to_close.close();
        }

        pub fn next(self: *@This()) !?[]const u8 {
            return self.reader.readUntilDelimiterOrEof(self.buffer, '\n');
        }
    };
}

pub fn readByLine(allocator: std.mem.Allocator, fileToClose: *std.fs.File, reader: anytype) !ReadByLineIterator(@TypeOf(reader)) {
    var buffer = try allocator.alloc(u8, 4096);
    std.debug.print("buffer: {s}\n", .{&buffer});
    return .{
        .allocator = allocator,
        .reader = reader,
        .buffer = buffer,
        .file_to_close = fileToClose,
    };
}

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
    // expectEqualDeep(expected, parts);
}
