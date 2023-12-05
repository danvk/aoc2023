const std = @import("std");

// Half-open interval
pub fn Interval(comptime IntType: type) type {
    return struct {
        low: IntType,
        high: IntType,

        fn intersects(self: @This(), other: @This()) bool {
            return !(self.low >= other.high or self.high <= other.low);
        }
    };
}

const assert = std.debug.assert;

test "interval intersects" {
    const Iv32 = Interval(u32);
    const a = Iv32{ .low = 10, .high = 20 };
    const b = Iv32{ .low = 15, .high = 25 };
    const c = Iv32{ .low = 20, .high = 30 };
    assert(a.intersects(b));
    assert(!a.intersects(c));
    assert(b.intersects(c));
    assert(!c.intersects(a));
    assert(b.intersects(a));
    assert(a.intersects(a));
}
