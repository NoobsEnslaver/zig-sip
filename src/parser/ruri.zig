const std = @import("std");
const Allocator = std.mem.Allocator;
const utils = @import("./utils.zig");

pub const RURI = struct {
    user: ?[]const u8 = null,
    host: ?[]const u8 = null,
    value: []const u8 = undefined,
};

pub fn create(allocator: Allocator, s: []const u8, options: *const utils.ParseOptions) !RURI {
    _ = options;
    if (false) {
        // TODO
        return error.ParseError;
    }
    const buf = try allocator.alloc(u8, s.len);
    @memcpy(buf, s);
    return RURI{ .value = buf };
}
// -------------- Tests --------------------
const t = std.testing;
test "parsing Request URI" {
    try t.expect(true);
}
