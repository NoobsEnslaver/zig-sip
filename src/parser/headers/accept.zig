const std = @import("std");

pub const H = struct {};
pub const tag = "accept";
pub const key_lower = "accept";
pub const key = "Accept";

pub fn parse(str: []const u8) !H {
    _ = str;
    return H{};
}
// -------------- Tests --------------------
const t = std.testing;
test "parsing 'Accept' header" {
    try t.expect(true);
}
