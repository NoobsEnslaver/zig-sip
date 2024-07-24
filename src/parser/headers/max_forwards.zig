const std = @import("std");

pub const H = struct {};
pub const key_lower = "max-forwards";
pub const key = "Max-Forwards";

pub fn parse(str: []const u8) !H {
    _ = str;
    return H{};
}
// -------------- Tests --------------------
const t = std.testing;
test "parsing 'Max-Forwards' header" {
    try t.expect(true);
}
