const std = @import("std");
const from = @import("from.zig");

pub const H = from.H;
pub const key_lower = "to";
pub const key_short = 't';
pub const key = "To";

pub fn parse(str: []const u8, allocator: std.mem.Allocator, opts: anytype) !H {
    return from.parse(str, allocator, opts);
}
