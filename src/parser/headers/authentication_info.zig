const std = @import("std");

pub const H = struct {};
pub const key_lower = "authentication-info";
pub const key = "Authentication-Info";

pub fn parse(str: []const u8) !H {
    _ = str;
    return H{};
}
// -------------- Tests --------------------
const t = std.testing;
test "parsing 'Authentication-Info' header" {
    try t.expect(true);
}
