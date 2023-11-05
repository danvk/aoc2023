const std = @import("std");

// Read u32s delimited by spaces or tabs from a line of text.
pub fn readInts(line: []u8, nums: *std.ArrayList(u32)) !void {
    var it = std.mem.splitAny(u8, line, " \t");
    while (it.next()) |split| {
        if (split.len == 0) {
            continue;
        }
        const num = try std.fmt.parseInt(u32, split, 10);
        try nums.append(num);
    }
}
