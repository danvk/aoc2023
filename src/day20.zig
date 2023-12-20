const std = @import("std");
const bufIter = @import("./buf-iter.zig");
const util = @import("./util.zig");

const assert = std.debug.assert;

// alternative with arena allocator:

const ModuleType = enum { broadcast, flipFlop, conjunction };

const Module = struct {
    name: []const u8,
    typ: ModuleType,
    inputs: [][]const u8,
    values: []u32,
    nexts: []*Module,
};

fn parseModule(allocator: std.mem.Allocator, line: []const u8) !Module {
    var sides = util.splitOne(line, " -> ").?;
    const nameType = sides.head;
    var mod: Module = undefined;
    if (nameType[0] == '%') {
        // flip-flop
        mod.name = nameType[1..];
        mod.typ = .flipFlop;
    } else if (nameType[0] == '&') {
        mod.name = nameType[1..];
        mod.typ = .conjunction;
    } else if (std.mem.eql(u8, nameType, "broadcaster")) {
        mod.name = nameType;
        mod.typ = .broadcast;
    } else {
        unreachable;
    }
    var inputs = std.ArrayList([]const u8).init(allocator);
    try util.splitIntoArrayList(sides.rest, ", ", &inputs);
    mod.inputs = inputs.items;
    return mod;
}

pub fn main(in_allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    var arena = std.heap.ArenaAllocator.init(in_allocator);
    defer arena.deinit();
    var allocator = arena.allocator();
    const filename = args[0];

    const contents = try util.readInputFile(allocator, filename);
    defer allocator.free(contents);

    var modules = std.StringHashMap(Module).init(allocator);
    defer modules.deinit();
    var it = std.mem.tokenize(u8, contents, "\n");
    while (it.next()) |line| {
        var module = try parseModule(allocator, line);
        try modules.put(module.name, module);
    }

    // std.debug.print("part 1: {d}\n", .{sum1});
    // std.debug.print("part 2: {d}\n", .{sum2});
}

const expectEqualDeep = std.testing.expectEqualDeep;
const expectEqual = std.testing.expectEqual;
const expect = std.testing.expect;

test "sample test" {
    try expectEqualDeep(true, true);
}
