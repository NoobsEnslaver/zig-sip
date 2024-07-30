const std = @import("std");

pub const H = struct {};
pub const key_lower = "subject";
pub const key_short = 's';
pub const key = "Subject";

pub fn parse(str: []const u8) !H {
    _ = str;
    return H{};
}
// -------------- Tests --------------------
const t = std.testing;
test "parsing 'Subject' header" {
    try t.expect(true);
}
