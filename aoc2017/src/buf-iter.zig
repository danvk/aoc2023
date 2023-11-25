const std = @import("std");

const ReaderType = std.fs.File.Reader;
const BufReaderType = std.io.BufferedReader(4096, ReaderType);
const BufReaderReaderType = BufReaderType.Reader;

pub const ReadByLineIterator = struct {
    file: std.fs.File,
    reader: ReaderType,
    buf_reader: BufReaderType,
    stream: ?BufReaderReaderType,
    buf: [4096]u8,

    pub fn next(self: *@This()) !?[]u8 {
        if (self.stream == null) {
            self.stream = self.buf_reader.reader();
        }
        if (self.stream) |stream| {
            var slice = try stream.readUntilDelimiterOrEof(&self.buf, '\n');
            return slice;
        }
        unreachable;
    }

    pub fn deinit(self: *@This()) void {
        self.file.close();
    }
};

pub fn iterLines(filename: []const u8) !ReadByLineIterator {
    var file = try std.fs.cwd().openFile(filename, .{});
    var reader = file.reader();
    var buf_reader = std.io.bufferedReader(reader);

    return ReadByLineIterator{
        .file = file,
        .reader = reader,
        .buf_reader = buf_reader,
        .stream = null,
        .buf = undefined,
    };
}
