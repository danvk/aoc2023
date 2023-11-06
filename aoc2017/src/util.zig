const std = @import("std");

// Read u32s delimited by spaces or tabs from a line of text.
pub fn readInts(line: []const u8, nums: *std.ArrayList(u32)) !void {
    var it = std.mem.splitAny(u8, line, " \t");
    while (it.next()) |split| {
        if (split.len == 0) {
            continue;
        }
        const num = try std.fmt.parseInt(u32, split, 10);
        try nums.append(num);
    }
}

const LineIterator = struct {
    file: std.fs.File,
    read_fn: fn (*std.ArrayList(u8), u8, usize) anyerror!void,
    buf: std.ArrayList(u8),

    pub fn next(self: *LineIterator) ?[]const u8 {
        self.read_fn(&self.buf, '\n', 4096) catch |err| switch (err) {
            error.EndOfStream => if (self.buf.items.len == 0) {
                return null;
            },
            else => |e| return e,
        };
        return self.buf.items;
    }

    pub fn deinit(self: *LineIterator) void {
        self.file.close();
        self.buf.deinit(); // is this right, should it be allocator.free?
    }
};

const MemoryLineIterator = struct {
    allocator: std.mem.Allocator,
    buf: []const u8,
    iter: std.mem.TokenIterator(u8, .any),

    const Self = @This();

    pub fn next(self: *Self) ?[]const u8 {
        return self.iter.next();
    }

    pub fn deinit(self: *Self) void {
        self.allocator.free(self.buf);
    }
};

pub fn readInputFile(filename: []const u8, allocator: std.mem.Allocator) ![]const u8 {
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();
    const stat = try file.stat();
    const fileSize = stat.size;
    return try file.reader().readAllAlloc(allocator, fileSize);
}

fn SuccessTypeOf(comptime callable_type: type) type {
    const info = @typeInfo(callable_type);
    return switch (info) {
        .ErrorUnion => info.ErrorUnion.payload,
        else => @compileError("unsupported type " ++ @typeName(callable_type)),
    };
}

pub fn iterLines(filename: []const u8, allocator: std.mem.Allocator) !MemoryLineIterator {
    const content = try readInputFile(filename, allocator);

    var readIter = std.mem.tokenize(u8, content, "\n");

    return MemoryLineIterator{
        .allocator = allocator,
        .buf = content,
        .iter = readIter,
    };
}

pub fn getBufferedReader(file: std.fs.File) @TypeOf(while (true)
{
    var raw_reader = file.reader();
    var buf_reader = std.io.bufferedReader(raw_reader);
    var r = buf_reader.reader();
    break r;
}) {
    var raw_reader = file.reader();
    var buf_reader = std.io.bufferedReader(raw_reader);
    return buf_reader.reader();
}

pub fn iterLines2(filename: []const u8, allocator: std.mem.Allocator) !ReadByLineIterator(@TypeOf(getBufferedReader(std.fs.cwd().openFile(filename, .{}) catch unreachable))) {
    var file = try std.fs.cwd().openFile(filename, .{});
    // var raw_reader = file.reader();
    // var buf_reader = std.io.bufferedReader(raw_reader);
    var buf_reader = getBufferedReader(file);
    return readByLine(allocator, &file, buf_reader);
}

fn ReadByLineIterator(comptime ReaderType: type) type {
    return struct {
        // Should be customizable! But also if you have lines of more than 64k you have other problems.
        pub const MaxBufferSize: usize = 64 * 1024;

        allocator: std.mem.Allocator,
        file_to_close: *std.fs.File,
        reader: ReaderType,
        last_read: ?[]const u8,

        pub fn deinit(self: @This()) void {
            if (self.last_read) |buf|
                self.allocator.free(buf);
            self.file_to_close.close();
        }

        pub fn next(self: *@This()) !?[]const u8 {
            if (self.last_read) |buf| {
                self.allocator.free(buf);
                self.last_read = null;
            }

            const line = try self.reader.readUntilDelimiterOrEofAlloc(self.allocator, '\n', MaxBufferSize);
            self.last_read = line;
            return line;
        }
    };
}

pub fn readByLine(allocator: std.mem.Allocator, fileToClose: *std.fs.File, reader: anytype) ReadByLineIterator(@TypeOf(reader)) {
    return .{
        .allocator = allocator,
        .reader = reader,
        .last_read = null,
        .file_to_close = fileToClose,
    };
}
