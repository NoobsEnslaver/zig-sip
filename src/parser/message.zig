const std = @import("std");
const utils = @import("./utils.zig");
const headers = @import("./headers.zig");
const ruri = @import("./ruri.zig");
const Allocator = std.mem.Allocator;
const Arena = std.heap.ArenaAllocator;

pub const MsgTag = enum { req, resp };

pub const Msg = struct {
    method: utils.Method = undefined,
    headers: std.ArrayList(headers.RawHeader) = undefined,
    body: ?[]const u8 = null,
    tag: MsgTag,

    code: ?u10 = null,
    reason: ?[]const u8 = null,
    ruri: ?ruri.RURI = null,

    arena: *std.heap.ArenaAllocator = undefined,
    parse_opts: *const utils.ParseOptions,

    pub fn findRawHeader(self: @This(), tag: headers.Tag) ?*headers.RawHeader {
        for (self.headers.items) |*h| {
            if (h.tag == tag) return *h;
        }
        return null;
    }

    pub fn walkRawHeader(self: @This(), tag: headers.Tag) RawHeadersIterator {
        return .{
            .index = 0,
            .headers = &self.headers,
            .tag = tag,
        };
    }

    pub fn findHeader(self: @This(), tag: headers.Tag) !?*headers.Header {
        for (self.headers.items) |*h| {
            if (h.tag == tag) {
                return h.parse();
            }
        }
        return null;
    }

    pub fn deinit(self: @This()) void {
        const allocator = self.arena.child_allocator;
        self.arena.deinit();
        allocator.destroy(self.arena);
    }
};

pub const RawHeadersIterator = struct {
    index: usize,
    tag: headers.Tag,
    headers: *const std.ArrayList(headers.RawHeader),

    // const Self = @This();

    pub fn next(self: *@This()) ?*headers.RawHeader {
        while (self.index < self.headers.items.len) {
            std.debug.print("+++++++++ index: {d} of {d}\n", .{ self.index, self.headers.items.len });
            if (self.headers.items[self.index].tag == self.tag) {
                const res = &self.headers.items[self.index];
                self.index += 1;
                return res;
            }
            self.index += 1;
        }
        return null;
    }

    pub fn peek(self: *@This()) ?*headers.Header {
        if (self.headers.items[self.index].tag == self.tag) {
            return &self.headers.items[self.index];
        } else {
            return self.next();
        }
    }

    pub fn rest(self: *@This()) []headers.Header {
        return self.headers.items[self.index..];
    }

    pub fn reset(self: *@This()) void {
        self.index = 0;
    }
};

// -------------- Functions ---------------
pub fn parseFromSlice(allocator: Allocator, s: []const u8, options: *const utils.ParseOptions) !Msg {
    var stream = std.io.fixedBufferStream(s);
    const r = stream.reader();
    return parseFromReader(allocator, r, options);
}

pub fn parseFromReader(allocator: Allocator, reader: anytype, options: *const utils.ParseOptions) !Msg {
    var arena = try allocator.create(Arena);
    arena.* = Arena.init(allocator);
    const arena_alloc = arena.allocator();
    errdefer arena.deinit();

    var early_stream = std.io.LimitedReader(@TypeOf(reader)){
        .bytes_left = options.max_message_size,
        .inner_reader = reader,
    };
    const lim_reader = early_stream.reader();

    const buf = try arena_alloc.alloc(u8, options.max_line_len);
    defer arena_alloc.free(buf);

    var first_line: []const u8 = try reader.readUntilDelimiter(buf, '\n');
    first_line = std.mem.trim(u8, first_line, &std.ascii.whitespace);
    if (first_line.len < 12) {
        return error.TooShort;
    }

    if (std.mem.startsWith(u8, first_line, "SIP/")) { // RESP
        var resp = try parseStatusLine(arena, first_line, options);
        resp.headers = try headers.parse(&resp, lim_reader);
        // TODO: set method from CSeq or error
        // TODO: add body
        return resp;
    } else { // REQ
        var req = try parseRequestLine(arena, first_line, options);
        req.headers = try headers.parse(&req, lim_reader);
        // TODO: body
        return req;
    }
}

// -------------- Tests --------------------
const t = std.testing;
test {
    _ = @import("./ruri.zig");
    _ = @import("./headers.zig");
}

// Request-Line = Method SP Request-URI SP SIP-Version CRLF
fn parseRequestLine(arena: *Arena, first_line: []const u8, options: *const utils.ParseOptions) !Msg {
    var it = std.mem.tokenizeScalar(u8, first_line, ' ');
    var pos: u8 = 0;
    var m: utils.Method = undefined;
    var r: ruri.RURI = undefined;
    while (it.next()) |token| : (pos += 1) {
        switch (pos) {
            0 => m = try utils.Method.parseFromSlice(token, options.on_parse_method_error),
            1 => r = try ruri.create(arena.allocator(), token, options),
            2 => if (!options.ignore_sip_version and !std.mem.eql(u8, token, "SIP/2.0"))
                return error.UnexpectedSIPVer,
            else => return error.UnexpectedToken,
        }
    }
    if (pos != 3) return error.UnexpectedToken;

    return Msg{
        .arena = arena,
        .parse_opts = options,
        .tag = .req,
        .method = m,
        .ruri = r,
    };
}

// Status-Line = SIP-Version SP Status-Code SP Reason-Phrase CRLF
fn parseStatusLine(arena: *Arena, first_line: []const u8, options: *const utils.ParseOptions) !Msg {
    var it = std.mem.tokenizeScalar(u8, first_line, ' ');
    var pos: u8 = 0;
    var code: u10 = undefined;
    var reason: []const u8 = undefined;
    while (it.next()) |token| : (pos += 1) {
        switch (pos) {
            0 => if (!options.ignore_sip_version and !std.mem.eql(u8, token, "SIP/2.0"))
                return error.UnexpectedSIPVer,
            1 => {
                code = try std.fmt.parseUnsigned(u10, token, 10);
                const buf = try arena.allocator().alloc(u8, it.rest().len);
                @memcpy(buf, it.rest());
                reason = buf;
                break; // stop tokenization there to don't tokenize Reason-Phrase
            },
            else => unreachable,
        }
    }
    if (pos != 1) return error.UnexpectedToken;

    return Msg{
        .arena = arena,
        .tag = .resp,
        .parse_opts = options,
        .code = code,
        .reason = reason,
    };
}
