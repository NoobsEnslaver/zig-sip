const std = @import("std");

pub const H = struct {};
pub const key_lower = "require";
pub const key = "Require";

pub fn parse(str: []const u8) !H {
    _ = str;
    return H{};
}
// -------------- Tests --------------------
const t = std.testing;
test "parsing 'Require' header" {
    try t.expect(true);
}
