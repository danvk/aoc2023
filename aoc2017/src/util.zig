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

fn LineIterator(comptime StreamType: type, in_stream: StreamType, file: std.fs.File, buf: std.ArrayList(u8)) type {
    return struct {
        file: std.fs.File = file,
        in_stream: StreamType = in_stream,
        buf: std.ArrayList(u8) = buf,

        pub fn next(self: *LineIterator) ?[]const u8 {
            self.in_stream.readUntilDelimiterArrayList(&self.buf, '\n', 4096) catch |err| switch (err) {
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
}

pub fn iterLines(filename: []const u8, allocator: std.mem.Allocator) !LineIterator {
    // https://stackoverflow.com/a/68879352/388951
    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    return LineIterator(
        @TypeOf(in_stream),
        file,
        .in_stream,
        std.ArrayList(u8).init(allocator),
    );
}
