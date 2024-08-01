const std = @import("std");
const from = @import("from.zig");

pub const H = from.H;
pub const key_lower = "contact";
pub const key_short = 'm';
pub const key = "Contact";

pub fn parse(str: []const u8, allocator: std.mem.Allocator, opts: anytype) !H {
    return from.parse(str, allocator, opts);
}

// -------------- Tests --------------------
const t = std.testing;
test "parsing 'Contact' header" {
    try t.expect(true);
}
