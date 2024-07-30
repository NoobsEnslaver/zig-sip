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
pub const ContentEncoding = @import("headers/content_encoding.zig");
pub const ContentLength = @import("headers/content_length.zig");
pub const ContentType = @import("headers/content_type.zig");
pub const CSeq = @import("headers/cseq.zig");
pub const From = @import("headers/from.zig");
pub const To = @import("headers/to.zig");
pub const MaxForwards = @import("headers/max_forwards.zig");
pub const Route = @import("headers/route.zig");
pub const RecordRoute = @import("headers/record_route.zig");
pub const Require = @import("headers/require.zig");
pub const Supported = @import("headers/supported.zig");
pub const Subject = @import("headers/subject.zig");
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
    content_encoding,
    content_length,
    content_type,
    cseq,
    from,
    to,
    max_forwards,
    route,
    record_route,
    require,
    supported,
    subject,
    server,
    user_agent,
    via,
    warning,

    unknown,

    pub fn parse(str: []const u8) @This() {
        if (str.len > max_hdr_len) return Tag.unknown;
        if (str.len == 0) return Tag.unknown;

        if (str.len == 1) { // compressed header name
            return switch (std.ascii.toLower(str[0])) {
                CallId.key_short => Tag.call_id,
                Contact.key_short => Tag.contact,
                ContentEncoding.key_short => Tag.content_encoding,
                ContentLength.key_short => Tag.content_length,
                ContentType.key_short => Tag.content_type,
                From.key_short => Tag.from,
                To.key_short => Tag.to,
                Subject.key_short => Tag.subject,
                Via.key_short => Tag.via,
                else => Tag.unknown,
            };
        }

        var buf: [max_hdr_len]u8 = undefined;
        const lkey = std.ascii.lowerString(&buf, str);
        return switch (lkey[0]) {
            'a' => if (eql(u8, lkey, Accept.key_lower))
                Tag.accept
            else if (eql(u8, lkey, AcceptEncoding.key_lower))
                Tag.accept_encoding
            else if (eql(u8, lkey, AcceptLanguage.key_lower))
                Tag.accept_language
            else if (eql(u8, lkey, AlertInfo.key_lower))
                Tag.alert_info
            else if (eql(u8, lkey, Allow.key_lower))
                Tag.allow
            else if (eql(u8, lkey, AuthenticationInfo.key_lower))
                Tag.authentication_info
            else if (eql(u8, lkey, Authorization.key_lower))
                Tag.authorization
            else
                Tag.unknown,

            'c' => if (eql(u8, lkey, CallId.key_lower))
                Tag.call_id
            else if (eql(u8, lkey, Contact.key_lower))
                Tag.contact
            else if (eql(u8, lkey, ContentEncoding.key_lower))
                Tag.content_encoding
            else if (eql(u8, lkey, ContentLength.key_lower))
                Tag.content_length
            else if (eql(u8, lkey, ContentType.key_lower))
                Tag.content_type
            else if (eql(u8, lkey, CSeq.key_lower))
                Tag.cseq
            else
                Tag.unknown,

            'f' => if (eql(u8, lkey, From.key_lower))
                Tag.from
            else
                Tag.unknown,

            't' => if (eql(u8, lkey, To.key_lower))
                Tag.to
            else
                Tag.unknown,

            'u' => if (eql(u8, lkey, UserAgent.key_lower))
                Tag.user_agent
            else
                Tag.unknown,

            'm' => if (eql(u8, lkey, MaxForwards.key_lower))
                Tag.max_forwards
            else
                Tag.unknown,

            'r' => if (eql(u8, lkey, Route.key_lower))
                Tag.route
            else if (eql(u8, lkey, RecordRoute.key_lower))
                Tag.record_route
            else if (eql(u8, lkey, Require.key_lower))
                Tag.require
            else
                Tag.unknown,

            's' => if (eql(u8, lkey, Supported.key_lower))
                Tag.supported
            else if (eql(u8, lkey, Subject.key_lower))
                Tag.subject
            else if (eql(u8, lkey, Server.key_lower))
                Tag.server
            else
                Tag.unknown,

            'v' => if (eql(u8, lkey, Via.key_lower))
                Tag.via
            else
                Tag.unknown,

            'w' => if (eql(u8, lkey, Warning.key_lower))
                Tag.warning
            else
                Tag.unknown,

            else => blk: {
                std.debug.print("++++++++++ Unknown header: {s}+++++++++++++\n", .{lkey});
                break :blk Tag.unknown;
            },
        };
    }
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
    content_encoding: ContentEncoding.H,
    content_length: ContentLength.H,
    content_type: ContentType.H,
    cseq: CSeq.H,
    from: From.H,
    to: To.H,
    max_forwards: MaxForwards.H,
    route: Route.H,
    record_route: RecordRoute.H,
    require: Require.H,
    supported: Supported.H,
    subject: Subject.H,
    server: Server.H,
    user_agent: UserAgent.H,
    via: Via.H,
    warning: Warning.H,

    unknown: struct {},
};

pub const RawHeader = struct {
    key: []const u8,
    value: []const u8,
    tag: Tag = Tag.unknown,
    parsed: ?Header = null,
    parent: *const utils.Msg,

    pub fn parse(self: *@This()) !Header {
        if (self.parsed) |h| return h;
        if (self.tag == Tag.unknown) return error.UnknownHeader;

        const options = self.parent.parse_opts;
        const allocator = self.parent.arena.allocator();

        self.parsed =
            switch (self.tag) {
            .accept => Header{ .accept = try Accept.parse(self.value) },
            .accept_encoding => Header{ .accept_encoding = try AcceptEncoding.parse(self.value) },
            .accept_language => Header{ .accept_language = try AcceptLanguage.parse(self.value) },
            .alert_info => Header{ .alert_info = try AlertInfo.parse(self.value) },
            .allow => Header{ .allow = try Allow.parse(self.value) },
            .authentication_info => Header{ .authentication_info = try AuthenticationInfo.parse(self.value) },
            .authorization => Header{ .authorization = try Authorization.parse(self.value) },
            .call_id => Header{ .call_id = try CallId.parse(self.value) },
            .contact => Header{ .contact = try Contact.parse(self.value, allocator, options) },
            .content_encoding => Header{ .content_encoding = try ContentEncoding.parse(self.value) },
            .content_length => Header{ .content_length = try ContentLength.parse(self.value) },
            .content_type => Header{ .content_type = try ContentType.parse(self.value) },
            .cseq => Header{ .cseq = try CSeq.parse(self.value, options) },
            .from => Header{ .from = try From.parse(self.value, allocator, options) },
            .to => Header{ .to = try To.parse(self.value, allocator, options) },
            .max_forwards => Header{ .max_forwards = try MaxForwards.parse(self.value) },
            .route => Header{ .route = try Route.parse(self.value) },
            .record_route => Header{ .record_route = try RecordRoute.parse(self.value) },
            .require => Header{ .require = try Require.parse(self.value) },
            .supported => Header{ .supported = try Supported.parse(self.value) },
            .subject => Header{ .subject = try Subject.parse(self.value) },
            .server => Header{ .server = try Server.parse(self.value) },
            .user_agent => Header{ .user_agent = try UserAgent.parse(self.value) },
            .via => Header{ .via = try Via.parse(self.value) },
            .warning => Header{ .warning = try Warning.parse(self.value) },
            else => null,
        };

        return if (self.parsed) |h| h else error.UnknownHeader;
    }
};

pub fn parse(parent: *const utils.Msg, reader: anytype) !std.ArrayList(RawHeader) {
    const options = parent.parse_opts;
    const allocator = parent.arena.allocator();
    var hs = std.ArrayList(RawHeader).init(allocator);
    const buf = try allocator.alloc(u8, options.max_line_len);
    defer allocator.free(buf);

    var i: u8 = 0;
    while (true) : (i += 1) {
        var value: []const u8 = undefined;
        var key: []const u8 = undefined;
        if (i >= options.max_headers) return error.LimitHeadersCount;
        const raw_line = try reader.readUntilDelimiter(buf, '\n');
        var line = std.mem.trim(u8, raw_line, &std.ascii.whitespace);

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
        const hdr = RawHeader{
            .key = k,
            .value = v,
            .parent = parent,
            .tag = Tag.parse(key),
        };

        try hs.append(hdr);
    }

    // TODO: доработать
    if (!options.lazy_parsing) {
        for (hs.items, 0..) |*h, pos| {
            _ = h.*.parse() catch |err| {
                if (err == error.UnknownHeader) {
                    switch (options.on_unknown_header) {
                        .err => return err,
                        .remove => {
                            allocator.free(h.key);
                            allocator.free(h.value);
                            _ = hs.orderedRemove(pos); // FIXME: это работает?
                            continue;
                        },
                        .skip_parsing => {},
                        .callback => |f| try f(h),
                    }
                } else {
                    return err;
                }
            };
        }
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

// TODO: assert hdr_modules.len == size(Tag)
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
    ContentEncoding,
    ContentLength,
    ContentType,
    CSeq,
    From,
    To,
    MaxForwards,
    Route,
    RecordRoute,
    Require,
    Supported,
    Subject,
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
// TODO: actualize
const t = std.testing;
test {
    _ = @import("headers/call_id.zig");
    _ = @import("headers/contact.zig");
    _ = @import("headers/cseq.zig");
    _ = @import("headers/content_encoding.zig");
    _ = @import("headers/content_length.zig");
    _ = @import("headers/content_type.zig");
    _ = @import("headers/from.zig");
    _ = @import("headers/to.zig");
    _ = @import("headers/require.zig");
    _ = @import("headers/route.zig");
    _ = @import("headers/record_route.zig");
    _ = @import("headers/max_forwards.zig");
    _ = @import("headers/supported.zig");
    _ = @import("headers/subject.zig");
    _ = @import("headers/via.zig");
}
