const std = @import("std");
const util = @import("./util.zig");

const assert = std.debug.assert;

pub fn getScore(line: []const u8) u32 {
    var depth: u32 = 0;
    // var in_garbage = false;
    var score: u32 = 0;
    var i: usize = 0;

    while (i < line.len) {
        const c = line[i];
        switch (c) {
            '{' => {
                depth += 1;
            },
            '}' => {
                score += depth;
                depth -= 1;
            },
            ',' => {},
            else => {
                unreachable;
            },
        }
        i += 1;
    }

    return score;
}

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    const filename = args[0];
    const contents = try util.readInputFile(filename, allocator);
    std.debug.print("part1: {d}\n", .{getScore(contents)});
}

const expectEqual = std.testing.expectEqual;

test "samples" {
    try expectEqual(@as(u32, 1), getScore("{}"));
    // {{},{}}, score of 1 + 2 + 2 = 5.
    try expectEqual(@as(u32, 5), getScore("{{},{}}"));
    // {{{}}}, score of 1 + 2 + 3 = 6.
    try expectEqual(@as(u32, 6), getScore("{{{}}}"));
    // {{{},{},{{}}}}, score of 1 + 2 + 3 + 3 + 3 + 4 = 16.
    try expectEqual(@as(u32, 16), getScore("{{{},{},{{}}}}"));

    // {<a>,<a>,<a>,<a>}, score of 1.
    // {{<ab>},{<ab>},{<ab>},{<ab>}}, score of 1 + 2 + 2 + 2 + 2 = 9.
    // {{<!!>},{<!!>},{<!!>},{<!!>}}, score of 1 + 2 + 2 + 2 + 2 = 9.
    // {{<a!>},{<a!>},{<a!>},{<ab>}}, score of 1 + 2 = 3.
}
