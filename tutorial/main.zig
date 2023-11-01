const std = @import("std");
const expect = @import("std").testing.expect;

pub fn main() void {
    std.debug.print("Hello, {s}!\n", .{"World"});
}

test "if statement" {
    const a = true;
    var x: u16 = 0;
    if (a) {
        x += 1;
    } else {
        x += 2;
    }
    try expect(x == 1);
}

test "error union if" {
    var ent_num: error{UnknownEntity}!u32 = 5;
    if (ent_num) |entity| {
        try expect(@TypeOf(entity) == u32);
        try expect(entity == 5);
    } else |_| {
        unreachable;
    }
}
