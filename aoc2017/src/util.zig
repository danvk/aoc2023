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

fn ReturnTypeOf(comptime callable_type: type) type {
    const info = @typeInfo(callable_type);
    return switch (info) {
        .Fn => info.Fn.return_type.?,
        .Type => @compileError("unsupporte type Type "),
        .Void => @compileError("unsupported type Void "),
        .Bool => @compileError("unsupported type Bool "),
        .NoReturn => @compileError("unsupported type NoReturn "),
        .Int => @compileError("unsupported type Int "),
        .Float => @compileError("unsupported type Float "),
        .Pointer => @compileError("unsupported type Pointer "),
        .Array => @compileError("unsupported type Array "),
        .Struct => @compileError("unsupported type Struct " ++ @typeName(callable_type)),
        .ComptimeFloat => @compileError("unsupported type ComptimeFloat "),
        .ComptimeInt => @compileError("unsupported type ComptimeInt "),
        .Undefined => @compileError("unsupported type Undefined "),
        .Null => @compileError("unsupported type Null "),
        .Optional => @compileError("unsupported type Optional "),
        .ErrorUnion => @compileError("unsupported type ErrorUnion "),
        .ErrorSet => @compileError("unsupported type ErrorSet "),
        .Enum => @compileError("unsupported type Enum "),
        .Union => @compileError("unsupported type Union "),
        .Opaque => @compileError("unsupported type Opaque "),
        .Frame => @compileError("unsupported type Frame "),
        .AnyFrame => @compileError("unsupported type AnyFrame "),
        .Vector => @compileError("unsupported type Vector "),
        .EnumLiteral => @compileError("unsupported type EnumLiteral "),

        // This seems to not be a thing anymore:
        // .BoundFn => info.BoundFn.return_type.?,
        // else => @compileError("unsupported type " ++ @typeName(callable_type)),
    };
}

fn ReadByLineIterator(comptime ReaderType: type) type {
    return struct {
        // Should be customizable! But also if you have lines of more than 64k you have other problems.
        pub const MaxBufferSize: usize = 64 * 1024;

        allocator: std.mem.Allocator,
        reader: ReaderType,
        last_read: ?[]const u8,

        pub fn deinit(self: @This()) void {
            if (self.last_read) |buf|
                self.allocator.free(buf);
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

pub fn readByLine(allocator: std.mem.Allocator, file: anytype) ReadByLineIterator(@TypeOf(file.reader())) {
    return .{
        .allocator = allocator,
        .reader = file.reader(),
        .last_read = null,
    };
}
