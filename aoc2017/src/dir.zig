pub const Dir = enum(u2) {
    right,
    up,
    left,
    down,
    pub fn ccw(self: Dir) Dir {
        const n: u32 = @intFromEnum(self);
        return @as(Dir, @enumFromInt((n + 1) % 4));
    }
    pub fn cw(self: Dir) Dir {
        const n: u32 = @intFromEnum(self);
        return @as(Dir, @enumFromInt((n + 3) % 4));
    }
    pub fn dx(this: Dir) i32 {
        return switch (this) {
            Dir.left => -1,
            Dir.right => 1,
            Dir.up => 0,
            Dir.down => 0,
        };
    }
    pub fn dy(this: Dir) i32 {
        return switch (this) {
            Dir.left => 0,
            Dir.right => 0,
            Dir.up => -1,
            Dir.down => 1,
        };
    }
};

pub const DIRS = [_]Dir{ .right, .up, .left, .down };

pub const Coord = struct {
    x: i32,
    y: i32,

    pub fn move(self: @This(), dir: Dir) Coord {
        return Coord{
            .x = self.x + dir.dx(),
            .y = self.y + dir.dy(),
        };
    }
};
