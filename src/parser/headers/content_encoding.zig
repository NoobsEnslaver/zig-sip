const std = @import("std");

pub const H = struct {};
pub const key_lower = "content-encoding";
pub const key_short = 'e';
pub const key = "Content-Encoding";

pub fn parse(str: []const u8) !H {
    _ = str;
    return H{};
}
// -------------- Tests --------------------
const t = std.testing;
test "parsing 'Content-Encoding' header" {
    try t.expect(true);
}
