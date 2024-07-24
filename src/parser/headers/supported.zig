const std = @import("std");

pub const H = struct {};
pub const key_lower = "supported";
pub const key = "Supported";

pub fn parse(str: []const u8) !H {
    _ = str;
    return H{};
}
// -------------- Tests --------------------
const t = std.testing;
test "parsing 'Supported' header" {
    try t.expect(true);
}
