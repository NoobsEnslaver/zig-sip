const std = @import("std");

pub const H = struct {};
pub const key_lower = "user-agent";
pub const key = "User-Agent";

pub fn parse(str: []const u8) !H {
    _ = str;
    return H{};
}
// -------------- Tests --------------------
const t = std.testing;
test "parsing 'User-Agent' header" {
    try t.expect(true);
}
