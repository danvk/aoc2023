const std = @import("std");
const bufIter = @import("./buf-iter.zig");
const util = @import("./util.zig");

const assert = std.debug.assert;

// alternative with arena allocator:
// pub fn main(in_allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
//     var arena = std.heap.ArenaAllocator.init(in_allocator);
//     defer arena.deinit();
//     var allocator = arena.allocator();

// Determine the ASCII code for the current character of the string.
// Increase the current value by the ASCII code you just determined.
// Set the current value to itself multiplied by 17.
// Set the current value to the remainder of dividing itself by 256.
fn hash(str: []const u8) u8 {
    var val: u16 = 0;
    for (str) |c| {
        val += c;
        val *= 17;
        val = val & 0xff;
    }
    return @intCast(val);
}

const Lens = struct { label: []const u8, focalLen: u8 };

fn printLens(lens: Lens) void {
    std.debug.print("[{s} {d}] ", .{ lens.label, lens.focalLen });
}

pub fn main(in_allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    var arena = std.heap.ArenaAllocator.init(in_allocator);
    defer arena.deinit();
    var allocator = arena.allocator();
    const filename = args[0];

    const contents = try util.readInputFile(allocator, filename);
    defer allocator.free(contents);

    var sum: u64 = 0;
    var sum2: u64 = 0;
    var parts = std.ArrayList([]const u8).init(allocator);
    defer parts.deinit();

    const line = std.mem.trimRight(u8, contents, "\r\n");
    try util.splitIntoArrayList(line, ",", &parts);
    assert(parts.items.len > 1);
    for (parts.items) |part| {
        const v = hash(part);
        sum += v;
    }

    var boxes: [256]std.ArrayList(Lens) = undefined;
    for (0..256) |i| {
        boxes[i] = std.ArrayList(Lens).init(allocator);
    }

    for (parts.items) |part| {
        std.debug.print("After \"{s}\"\n", .{part});

        var partsBuf: [2][]const u8 = undefined;
        const partParts = util.splitAnyIntoBuf(part, "-=", &partsBuf);
        const label = partParts[0];
        const v = hash(label);
        if (std.mem.endsWith(u8, part, "-")) {
            var maybeIdx: ?usize = null;
            var items = boxes[v].items;
            for (items, 0..) |lens, i| {
                if (std.mem.eql(u8, lens.label, label)) {
                    maybeIdx = i;
                    break;
                }
            }
            if (maybeIdx) |idx| {
                for (idx..items.len - 1) |i| {
                    items[i] = items[i + 1];
                }
                _ = boxes[v].pop();
            }
        } else if (part[part.len - 2] == '=') {
            // insert
            const focalLen = try std.fmt.parseInt(u8, part[part.len - 1 ..], 10);
            var items = boxes[v].items;
            var maybeIdx: ?usize = null;
            for (items, 0..) |lens, i| {
                if (std.mem.eql(u8, lens.label, label)) {
                    maybeIdx = i;
                    break;
                }
            }
            const lens = Lens{ .label = label, .focalLen = focalLen };
            if (maybeIdx) |idx| {
                items[idx] = lens;
            } else {
                try boxes[v].append(lens);
            }
        } else {
            unreachable;
        }
        // for (boxes, 0..) |box, i| {
        //     if (box.items.len > 0) {
        //         std.debug.print("Box {d}: ", .{i});
        //         for (box.items) |item| {
        //             printLens(item);
        //         }
        //         std.debug.print("\n", .{});
        //     }
        // }
        // std.debug.print("\n", .{});
    }

    for (boxes, 1..) |box, boxNum| {
        for (box.items, 1..) |lens, slotNum| {
            const power = boxNum * slotNum * lens.focalLen;
            std.debug.print("{s}: {d} * {d} * {d} = {d}\n", .{ lens.label, boxNum, slotNum, lens.focalLen, power });
            sum2 += power;
        }
    }

    std.debug.print("part 1: {d}\n", .{sum});
    std.debug.print("part 2: {d}\n", .{sum2});
}

const expectEqualDeep = std.testing.expectEqualDeep;
const expectEqual = std.testing.expectEqual;
const expect = std.testing.expect;

test "hash" {
    try expectEqual(hash("HASH"), 52);
}
