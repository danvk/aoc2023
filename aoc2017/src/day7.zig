const std = @import("std");
const util = @import("./util.zig");

const assert = std.debug.assert;

const Program = struct {
    name: []const u8,
    value: u32,
    parent: ?*Program,
    children: [][]const u8,
};

pub fn main(parent_allocator: std.mem.Allocator, args: []const [:0]u8) !void {
    const filename = args[0];
    var arena = std.heap.ArenaAllocator.init(parent_allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    var line_it = try util.iterLines(filename, allocator);
    defer line_it.deinit();

    var programs = std.StringHashMap(Program).init(allocator);
    defer programs.deinit();
    var parents = std.StringHashMap([]const u8).init(allocator);
    defer parents.deinit();

    while (line_it.next()) |line| {
        // vpryah (310) -> iedlpkf, epeain
        // xnoux (41)
        var parts_it = std.mem.splitSequence(u8, line, " -> ");
        const name_value = parts_it.next() orelse unreachable;
        const l_paren = std.mem.indexOf(u8, name_value, "(") orelse unreachable;
        const name = name_value[0 .. l_paren - 1];
        const my_name = try allocator.dupe(u8, name);
        const r_paren = name_value.len - 1;
        std.debug.print("{s} / {s} {d} {d} {}\n", .{ name_value, name, l_paren, r_paren, name_value[r_paren] });
        assert(name_value[r_paren] == ')');
        const val_slice = name_value[l_paren + 1 .. r_paren];
        std.debug.print("{s}\n", .{val_slice});
        const value = try std.fmt.parseInt(u32, val_slice, 10);

        var child_array = std.ArrayList([]const u8).init(allocator);

        if (parts_it.next()) |children| {
            var children_it = std.mem.splitSequence(u8, children, ", ");
            while (children_it.next()) |child| {
                const my_child = try allocator.dupe(u8, child);
                try child_array.append(my_child);
                try parents.put(my_child, my_name);
            }
        }

        try programs.put(my_name, Program{
            .name = my_name,
            .value = value,
            .parent = null,
            .children = child_array.items,
        });
    }

    // Attach parents
    var parents_it = parents.iterator();
    while (parents_it.next()) |entry| {
        const child = entry.key_ptr;
        const parent = entry.value_ptr;
        std.debug.print("{s}'s parent is {s}\n", .{ child.*, parent.* });
        if (programs.getPtr(child.*)) |child_ptr| {
            if (programs.getPtr(parent.*)) |parent_ptr| {
                child_ptr.parent = parent_ptr;
            } else {
                unreachable;
            }
        } else {
            unreachable;
        }
    }

    var prog_iter = programs.valueIterator();
    var prog_it = prog_iter.next();
    while (prog_it) |prog| {
        std.debug.print("{s}: {any}\n", .{ prog.name, prog.* });
        const parent = prog.parent;
        prog_it = parent;
    }
}
