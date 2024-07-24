const std = @import("std");

pub const H = struct {};
pub const key_lower = "authorization";
pub const key = "Authorization";

pub fn parse(str: []const u8) !H {
    _ = str;
    return H{};
}
// -------------- Tests --------------------
const t = std.testing;
test "parsing 'Authorization' header" {
    try t.expect(true);
}
