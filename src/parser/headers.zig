const std = @import("std");
const eql = @import("std").mem.eql;
const Allocator = std.mem.Allocator;
const utils = @import("./utils.zig");
// const ArrayList = (comptime T: type)

pub const Accept = @import("headers/accept.zig");
pub const AcceptEncoding = @import("headers/accept_encoding.zig");
pub const AcceptLanguage = @import("headers/accept_language.zig");
pub const AlertInfo = @import("headers/alert_info.zig");
pub const Allow = @import("headers/allow.zig");
pub const AuthenticationInfo = @import("headers/authentication_info.zig");
pub const Authorization = @import("headers/authorization.zig");

pub const CallId = @import("headers/call_id.zig");
pub const Contact = @import("headers/contact.zig");
pub const ContentType = @import("headers/content_type.zig");
pub const CSeq = @import("headers/cseq.zig");
pub const From = @import("headers/from.zig");
pub const To = @import("headers/to.zig");
pub const MaxForwards = @import("headers/max_forwards.zig");
pub const Route = @import("headers/route.zig");
pub const RecordRoute = @import("headers/record_route.zig");
pub const Require = @import("headers/require.zig");
pub const Supported = @import("headers/supported.zig");
pub const Server = @import("headers/server.zig");
pub const UserAgent = @import("headers/user_agent.zig");
pub const Via = @import("headers/via.zig");
pub const Warning = @import("headers/warning.zig");

pub const Tag = enum {
    accept,
    accept_encoding,
    accept_language,
    alert_info,
    allow,
    authentication_info,
    authorization,
    call_id,
    contact,
    content_type,
    cseq,
    from,
    to,
    max_forwards,
    route,
    record_route,
    require,
    supported,
    server,
    user_agent,
    via,
    warning,

    // pub fn parse(str: []const u8) ?@This() {
    //     return null;
    // }
};

pub const Header = union(Tag) {
    accept: Accept.H,
    accept_encoding: AcceptEncoding.H,
    accept_language: AcceptLanguage.H,
    alert_info: AlertInfo.H,
    allow: Allow.H,
    authentication_info: AuthenticationInfo.H,
    authorization: Authorization.H,
    call_id: CallId.H,
    contact: Contact.H,
    content_type: ContentType.H,
    cseq: CSeq.H,
    from: From.H,
    to: To.H,
    max_forwards: MaxForwards.H,
    route: Route.H,
    record_route: RecordRoute.H,
    require: Require.H,
    supported: Supported.H,
    server: Server.H,
    user_agent: UserAgent.H,
    via: Via.H,
    warning: Warning.H,
};

pub const RawHeader = struct {
    key: []const u8,
    value: []const u8,
    parsed: ?Header = null,

    pub fn parse(self: *@This(), options: *const utils.ParseOptions) !Header {
        if (self.parsed != null) return self.parsed.?;
        if (self.key.len > max_hdr_len) return error.UnknownHeader;
        if (self.key.len == 0) return error.EmptyString; // or self.value.len == 0 ?

        var buf: [max_hdr_len]u8 = undefined;
        const lkey = std.ascii.lowerString(&buf, self.key);
        self.parsed =
            switch (lkey[0]) {
            'a' => if (eql(u8, lkey, Accept.key_lower))
                Header{ .accept = try Accept.parse(self.value) }
            else if (eql(u8, lkey, AcceptEncoding.key_lower))
                Header{ .accept_encoding = try AcceptEncoding.parse(self.value) }
            else if (eql(u8, lkey, AcceptLanguage.key_lower))
                Header{ .accept_language = try AcceptLanguage.parse(self.value) }
            else if (eql(u8, lkey, AlertInfo.key_lower))
                Header{ .alert_info = try AlertInfo.parse(self.value) }
            else if (eql(u8, lkey, Allow.key_lower))
                Header{ .allow = try Allow.parse(self.value) }
            else if (eql(u8, lkey, AuthenticationInfo.key_lower))
                Header{ .authentication_info = try AuthenticationInfo.parse(self.value) }
            else if (eql(u8, lkey, Authorization.key_lower))
                Header{ .authorization = try Authorization.parse(self.value) }
            else
                null,

            'c' => if (eql(u8, lkey, CallId.key_lower))
                Header{ .call_id = try CallId.parse(self.value) }
            else if (eql(u8, lkey, Contact.key_lower))
                Header{ .contact = try Contact.parse(self.value) }
            else if (eql(u8, lkey, ContentType.key_lower))
                Header{ .content_type = try ContentType.parse(self.value) }
            else if (eql(u8, lkey, CSeq.key_lower))
                Header{ .cseq = try CSeq.parse(self.value) }
            else
                null,

            'f' => if (eql(u8, lkey, From.key_lower))
                Header{ .from = try From.parse(self.value) }
            else
                null,

            't' => if (eql(u8, lkey, To.key_lower))
                Header{ .to = try To.parse(self.value) }
            else
                null,

            'm' => if (eql(u8, lkey, MaxForwards.key_lower))
                Header{ .max_forwards = try MaxForwards.parse(self.value) }
            else
                null,

            'r' => if (eql(u8, lkey, Route.key_lower))
                Header{ .route = try Route.parse(self.value) }
            else if (eql(u8, lkey, RecordRoute.key_lower))
                Header{ .record_route = try RecordRoute.parse(self.value) }
            else if (eql(u8, lkey, Require.key_lower))
                Header{ .require = try Require.parse(self.value) }
            else
                null,

            's' => if (eql(u8, lkey, Supported.key_lower))
                Header{ .supported = try Supported.parse(self.value) }
            else if (eql(u8, lkey, Server.key_lower))
                Header{ .server = try Server.parse(self.value) }
            else
                null,

            'v' => if (eql(u8, lkey, Via.key_lower))
                Header{ .via = try Via.parse(self.value) }
            else
                null,

            'w' => if (eql(u8, lkey, Warning.key_lower))
                Header{ .warning = try Warning.parse(self.value) }
            else
                null,

            else => null,
        };

        _ = options;

        return if (self.parsed) |h| h else error.UnknownHeader;
    }
};

pub fn parse(allocator: Allocator, reader: anytype, options: *const utils.ParseOptions) !std.ArrayList(RawHeader) {
    var hs = std.ArrayList(RawHeader).init(allocator);
    var i: u8 = 0;
    while (true) : (i += 1) {
        var value: []const u8 = undefined;
        var key: []const u8 = undefined;
        if (i >= options.max_headers) return error.LimitHeadersCount;
        var buf: [options.max_line_len]u8 = undefined;
        const raw_line = try reader.readUntilDelimiter(&buf, '\n');
        var line = std.mem.trim(u8, raw_line, &std.ascii.whitespace);

        // std.debug.print(">>>>>: {s}\n", .{line});
        if (line.len == 0) { // empty line - end of headers
            break;
        }

        if (std.ascii.isWhitespace(raw_line[0]) and options.allow_multiline and hs.items.len > 0) { // multiline (not first)
            const lastHdr = &hs.items[hs.items.len - 1];
            const oldVal = lastHdr.value;
            lastHdr.value = try std.mem.concat(allocator, u8, &[_][]const u8{ oldVal, line });
            allocator.free(oldVal);
            continue;
        }

        if (std.mem.indexOfScalar(u8, line, ':')) |sepIdx| {
            key = std.mem.trimRight(u8, line[0..sepIdx], &std.ascii.whitespace);
            if (!utils.isValidHeaderName(key)) {
                // TODO: check config, call callback etc. Multiline?
            }
            value = std.mem.trimLeft(u8, line[sepIdx + 1 ..], &std.ascii.whitespace);
        } else { // no separator ':' and it is not multiline - error
            // std.debug.print("unexpected token: {s}\n", .{line});
            return error.UnexpectedToken;
        }

        const k = try allocator.alloc(u8, key.len);
        const v = try allocator.alloc(u8, value.len);
        @memcpy(k, key);
        @memcpy(v, value);
        var hdr = RawHeader{ .key = k, .value = v };

        if (!options.lazy_parsing) {
            _ = hdr.parse(options) catch |err| {
                if (err == error.UnknownHeader) {
                    switch (options.on_unknown_header) {
                        .err => |e| {
                            allocator.free(hdr.key);
                            allocator.free(hdr.value);
                            return e;
                        },
                        .remove => {
                            allocator.free(hdr.key);
                            allocator.free(hdr.value);
                            continue;
                        },
                        .skip_parsing => {},
                        .callback => |f| try f(&hdr),
                    }
                } else {
                    return err;
                }
            };
        }
        try hs.append(hdr);
    }

    return hs;
}

// --------------- Rest -------------------------
const tag_map = std.StringHashMap(Tag).init(std.heap.PageAllocator{});
const max_hdr_len = blk: {
    var res = 0;
    for (hdr_modules) |m| {
        res = @max(res, m.key.len);
    }
    break :blk res;
};

const hdr_modules = [_]type{
    Accept,
    AcceptEncoding,
    AcceptLanguage,
    AlertInfo,
    Allow,
    AuthenticationInfo,
    Authorization,
    CallId,
    Contact,
    ContentType,
    CSeq,
    From,
    To,
    MaxForwards,
    Route,
    RecordRoute,
    Require,
    Supported,
    Server,
    UserAgent,
    Via,
    Warning,
};

const TagE = blk: {
    var fields: [hdr_modules.len]std.builtin.Type.EnumField = undefined;

    for (&fields, hdr_modules, 0..) |*field, m, i| {
        const name = m.tag;
        field.* = .{
            .name = name,
            .value = i,
        };
    }

    break :blk @Type(.{
        .Enum = .{
            .tag_type = u8,
            .fields = fields,
            .decls = &.{},
        },
    });
};

// const declInfo = blk: {
//     const info = @typeInfo(Tag);
//     var tmp = "";

//     // const newEF: std.EnumField = std.EnumField{};
//     // info.Enum.fields = info.Enum.fields ++ newEF;
//     for (info.Enum.fields) |d| {
//         tmp = tmp ++ d.name ++ "\n";
//     }
//     break :blk tmp;
// };
// comptime {

//     // for (hdr_modules) |m| {

//     //     tag_map.put(m.key, value: V)
//     // }
// }

// const max_hdr_len = utils.max(&[_]usize{
//     Accept.key.len,
//     AcceptEncoding.key.len,
//     AcceptLanguage.key.len,
//     AlertInfo.key.len,
//     Allow.key.len,
//     AuthenticationInfo.key.len,
//     Authorization.key.len,
//     CallId.key.len,
//     Contact.key.len,
//     ContentType.key.len,
//     CSeq.key.len,
//     From.key.len,
//     To.key.len,
//     MaxForwards.key.len,
//     Route.key.len,
//     RecordRoute.key.len,
//     Require.key.len,
//     Supported.key.len,
//     Server.key.len,
//     UserAgent.key.len,
//     Via.key.len,
//     Warning.key.len,
// });

// -------------- Tests --------------------
const t = std.testing;
test {
    _ = @import("headers/call_id.zig");
    _ = @import("headers/contact.zig");
    _ = @import("headers/cseq.zig");
    _ = @import("headers/from.zig");
    _ = @import("headers/to.zig");
    _ = @import("headers/require.zig");
    _ = @import("headers/route.zig");
    _ = @import("headers/record_route.zig");
    _ = @import("headers/max_forwards.zig");
    _ = @import("headers/supported.zig");
    _ = @import("headers/via.zig");
}
