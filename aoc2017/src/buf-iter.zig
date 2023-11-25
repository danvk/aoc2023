const std = @import("std");

fn main(filename: []const u8) !void {
    std.debug.print("Filename: {s}\n", .{filename});

    // https://stackoverflow.com/a/68879352/388951
    var file = try std.fs.cwd().openFile(filename, .{});
    // file's type is std.fs.File
    defer file.close();

    var reader = file.reader();
    // reader's type is Reader(...)
    // pub const Reader = io.Reader(File, ReadError, read)
    // aka std.fs.File.Reader
    // const ReaderType = std.fs.File.Reader;

    var buf_reader = std.io.bufferedReader(reader);
    // const BufReaderType = std.io.BufferedReader(4096, ReaderType);

    var in_stream = buf_reader.reader();
    // const BufReaderReaderType = BufReaderType.Reader;
    var buf: [4096]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        _ = line;
    }
}

const ReaderType = std.fs.File.Reader;
const BufReaderType = std.io.BufferedReader(4096, ReaderType);
const BufReaderReaderType = BufReaderType.Reader;

pub const ReadByLineIterator = struct {
    file: std.fs.File,
    buf: [4096]u8,
    reader: ReaderType,
    buf_reader: BufReaderType,
    stream: BufReaderReaderType,

    fn next(self: *@This()) !?[]u8 {
        var slice = try self.stream.readUntilDelimiterOrEof(&self.buf, '\n');
        return slice;
    }

    fn deinit(self: *@This()) void {
        self.file.close();
    }
};

pub fn iterLines(filename: []const u8) !ReadByLineIterator {
    var file = try std.fs.cwd().openFile(filename, .{});
    var reader = file.reader();
    var buf_reader = std.io.bufferedReader(reader);
    var stream = buf_reader.reader();

    return ReadByLineIterator{
        .file = file,
        .reader = reader,
        .buf_reader = buf_reader,
        .stream = stream,
        .buf = undefined,
    };
}
