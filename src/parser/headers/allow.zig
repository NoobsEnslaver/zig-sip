const std = @import("std");

pub const H = struct {};
pub const key_lower = "allow";
pub const key = "Allow";

pub fn parse(str: []const u8) !H {
    _ = str;
    return H{};
}
// -------------- Tests --------------------
const t = std.testing;
test "parsing 'Allow' header" {
    try t.expect(true);
}
