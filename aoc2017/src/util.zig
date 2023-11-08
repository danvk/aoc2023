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
