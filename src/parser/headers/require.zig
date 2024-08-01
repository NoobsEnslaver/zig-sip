const std = @import("std");
const allow = @import("allow.zig");
const utils = @import("../utils.zig");

pub const H = allow.H;
pub const key_lower = "require";
pub const key = "Require";

pub fn parse(str: []const u8, opts: *const utils.ParseOptions) !H {
    return allow.parse(str, opts);
}
