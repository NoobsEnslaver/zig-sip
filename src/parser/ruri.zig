const std = @import("std");

pub fn parse(s: []const u8) ![]const u8 {
    if (false) {
        // TODO
        return error.ParseError;
    }

    return s;
}
// -------------- Tests --------------------
const t = std.testing;
test "parsing Request URI" {
    try t.expect(true);
}
