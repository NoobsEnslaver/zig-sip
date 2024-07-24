const std = @import("std");

pub const H = struct {};
pub const key_lower = "alert-info";
pub const key = "Alert-Info";

pub fn parse(str: []const u8) !H {
    _ = str;
    return H{};
}
// -------------- Tests --------------------
const t = std.testing;
test "parsing 'Alert-Info' header" {
    try t.expect(true);
}
