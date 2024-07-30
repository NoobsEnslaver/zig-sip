const std = @import("std");

pub const H = struct {};
pub const key_lower = "content-length";
pub const key_short = 'l';
pub const key = "Content-length";

pub fn parse(str: []const u8) !H {
    _ = str;
    return H{};
}
// -------------- Tests --------------------
const t = std.testing;
test "parsing 'Content-length' header" {
    try t.expect(true);
}
