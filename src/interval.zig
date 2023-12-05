const std = @import("std");

// Half-open interval
pub fn Interval(comptime IntType: type) type {
    return struct {
        low: IntType,
        high: IntType,

        fn intersects(self: @This(), other: @This()) bool {
            return !(self.low >= other.high or self.high <= other.low);
        }

        fn intersection(self: @This(), other: @This()) ?@This() {
            var low = @max(self.low, other.low);
            var high = @min(self.high, other.high);
            return if (low < high) @This(){ .low = low, .high = high } else null;
        }

        fn includes(self: @This(), val: IntType) bool {
            return val >= self.low and val < self.high;
        }

        fn len(self: @This()) IntType {
            return self.high - self.low;
        }
    };
}

const assert = std.debug.assert;
const expectEqual = std.testing.expectEqual;
const expectDeepEqual = std.testing.expectEqualDeep;

const Iv32 = Interval(u32);

test "interval intersects" {
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

test "interval intersection" {
    const a = Iv32{ .low = 10, .high = 20 };
    const b = Iv32{ .low = 15, .high = 25 };
    const c = Iv32{ .low = 20, .high = 30 };

    try expectDeepEqual(a.intersection(b), Iv32{ .low = 15, .high = 20 });
    try expectDeepEqual(b.intersection(a), Iv32{ .low = 15, .high = 20 });
    try expectDeepEqual(a.intersection(c), null);
}

test "interval contains and length" {
    const a = Iv32{ .low = 10, .high = 20 };
    assert(a.includes(10));
    assert(a.includes(15));
    assert(!a.includes(20));
    assert(!a.includes(0));
    try expectEqual(a.len(), 10);
}
