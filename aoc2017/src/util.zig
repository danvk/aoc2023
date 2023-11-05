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

pub fn iterLines(filename: []const u8, allocator: std.mem.Allocator) !MemoryLineIterator {
    const content = try readInputFile(filename, allocator);

    var readIter = std.mem.tokenize(u8, content, "\n");

    return MemoryLineIterator{
        .allocator = allocator,
        .buf = content,
        .iter = readIter,
    };
}
