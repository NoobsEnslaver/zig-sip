const std = @import("std");

pub const H = struct {};
pub const key_lower = "via";
pub const key_short = 'v';
pub const key = "Via";

pub fn parse(str: []const u8) !H {
    _ = str;
    return H{};
}
// -------------- Tests --------------------
const t = std.testing;
test "parsing 'Via' header" {
    try t.expect(true);
}
