const std = @import("std");

// --------------- Types -------------------
pub const Method = enum {
    INVITE,
    ACK,
    OPTIONS,
    BYE,
    CANCEL,
    REGISTER,

    UNEXPECTED,
    USER1,
    USER2,
    USER3,
    USER4,

    pub fn parseFromSlice(s: []const u8, opts: ParseMethodErrBehavior) !Method {
        if (std.mem.eql(u8, s, "INVITE")) return Method.INVITE;
        if (std.mem.eql(u8, s, "ACK")) return Method.ACK;
        if (std.mem.eql(u8, s, "OPTIONS")) return Method.OPTIONS;
        if (std.mem.eql(u8, s, "BYE")) return Method.BYE;
        if (std.mem.eql(u8, s, "CANCEL")) return Method.CANCEL;
        if (std.mem.eql(u8, s, "REGISTER")) return Method.REGISTER;

        switch (opts) {
            ParseMethodErrBehaviorTag.err => |e| return e,
            ParseMethodErrBehaviorTag.replace => |res| {
                return res;
            },
            ParseMethodErrBehaviorTag.callback => |f| {
                return f(s);
            },
        }

        return error.BadMethod;
    }
};

pub const Req = struct {
    ruri: []const u8 = undefined,
    headers: [][]const u8 = undefined,
    method: Method = undefined,
    body: ?[]const u8 = null,
};

pub const Resp = struct {
    code: u10 = undefined,
    reason: []const u8 = undefined,
    headers: [][]const u8 = undefined,
    method: Method = undefined,
    body: ?[]const u8 = null,
};

pub const MessageType = enum { req, resp };
pub const Msg = union(MessageType) {
    req: Req,
    resp: Resp,
};

pub const AllocWhen = enum { alloc_if_needed, alloc_always };
pub const ParseMethodErrBehaviorTag = enum { err, replace, callback };
pub const ParseMethodErrBehavior = union(ParseMethodErrBehaviorTag) {
    err: anyerror,
    replace: Method,
    callback: fn ([]const u8) anyerror!Method,
};
pub const ParseOptions = struct {
    // duplicate_field_behavior: enum {
    //     use_first,
    //     @"error",
    //     use_last,
    // } = .@"error",

    /// If false, finding an unknown header returns `error.UnknownHeader`.
    ignore_unknown_headers: bool = true,
    on_parse_method_error: ParseMethodErrBehavior = ParseMethodErrBehavior{ .err = error.BadMethod },

    // limits
    max_body_len: ?usize = 8192,
    max_message_len: ?usize = 4096,
    max_line_len: usize = 256,

    /// This determines whether strings should always be copied,
    /// or if a reference to the given buffer should be preferred if possible.
    allocate: AllocWhen = AllocWhen.alloc_always,
};

// --------------- Functions -------------------

pub fn readUntilDelimiterAlloc(allocator: std.mem.Allocator, r: anytype, delimiter: []const u8, max_size: ?usize) ![]u8 {
    var array_list = std.ArrayList(u8).init(allocator);
    defer array_list.deinit();
    const w = array_list.writer();
    const delim_prefix = delimiter[0 .. delimiter.len - 1];
    const delim_end = delimiter[delimiter.len - 1];
    try r.streamUntilDelimiter(w, delim_end, max_size);
    while (!std.mem.eql(u8, array_list.items[array_list.items.len - (delimiter.len - 1) .. array_list.items.len], delim_prefix)) {
        try r.streamUntilDelimiter(w, delimiter[delimiter.len - 1], null);
    }
    for (0..delimiter.len - 1) |_| {
        _ = array_list.pop();
    }

    return try array_list.toOwnedSlice();
}
