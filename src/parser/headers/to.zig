const std = @import("std");

pub const H = struct {};
pub const key_lower = "to";
pub const key = "To";

pub fn parse(str: []const u8) !H {
    _ = str;
    return H{};
}
// -------------- Tests --------------------
const t = std.testing;
test "parsing 'To' header" {
    try t.expect(true);
}
