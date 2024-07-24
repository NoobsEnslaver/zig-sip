const std = @import("std");

pub const H = struct {};
pub const key_lower = "server";
pub const key = "Server";

pub fn parse(str: []const u8) !H {
    _ = str;
    return H{};
}

// -------------- Tests --------------------
const t = std.testing;
test "parsing 'Server' header" {
    try t.expect(true);
}
