const std = @import("std");
const Allocator = std.mem.Allocator;
const utils = @import("./utils.zig");

pub const CallId = @import("headers/call_id.zig");
pub const Contact = @import("headers/contact.zig");
pub const Cseq = @import("headers/cseq.zig");
pub const From = @import("headers/from.zig");
pub const To = @import("headers/to.zig");
pub const MaxForwards = @import("headers/max_forwards.zig");
pub const Supported = @import("headers/supported.zig");
pub const Via = @import("headers/via.zig");

pub fn parse(allocator: Allocator, r: anytype, options: utils.ParseOptions) ![][]u8 {
    _ = allocator;
    _ = r;
    _ = options;

    const arr = [_][]u8{};
    return arr[0..];
}

// -------------- Tests --------------------
const t = std.testing;
test "parsing headers" {
    _ = @import("headers/call_id.zig");
    _ = @import("headers/contact.zig");
    _ = @import("headers/cseq.zig");
    _ = @import("headers/from.zig");
    _ = @import("headers/to.zig");
    _ = @import("headers/require.zig");
    _ = @import("headers/route.zig");
    _ = @import("headers/max_forwards.zig");
    _ = @import("headers/supported.zig");
    _ = @import("headers/via.zig");
}
