const std = @import("std");

// -------------- Tests --------------------
const t = std.testing;
test "parsing sip message" {
    _ = @import("./ruri.zig");
    _ = @import("./headers.zig");

    try t.expect(true);
}
