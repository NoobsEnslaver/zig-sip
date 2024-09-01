const std = @import("std");
const message = @import("./message.zig");
const utils = @import("./utils.zig");
const Allocator = std.mem.Allocator;

// ------------- Declarations -------------
pub const Parser = struct {
    allocator: Allocator,
    opts: utils.ParseOptions,
    pub fn init(allocator: Allocator, opts: utils.ParseOptions) @This() {
        return .{
            .allocator = allocator,
            .opts = opts,
        };
    }

    pub fn parseFromSlice(self: @This(), s: []const u8) !utils.Msg {
        var stream = std.io.fixedBufferStream(s);
        const r = stream.reader();
        return self.parseFromReader(r);
    }

    pub fn parseFromReader(self: @This(), reader: anytype) !utils.Msg {
        // parse first line
        //   if request_line -> create Req
        //   if status_line -> create Resp
        // parse headers
        // if content_len > 0 -> parse sdp

        var first_line: []const u8 = try reader.readUntilDelimiterAlloc(self.allocator, '\n', self.options.max_line_len);
        first_line = std.mem.trim(u8, first_line, &std.ascii.whitespace);
        if (first_line.len < 12) {
            return error.TooShort;
        }

        if (std.mem.startsWith(u8, first_line, "SIP/")) { // RESP
            var resp = utils.Resp{};
            try self.parseStatusLine(first_line, &resp);
            resp.headers = try headers.parse(allocator, r, options);
            // TODO: add body
            return utils.Msg{ .resp = resp };
        } else { // REQ
            var req = utils.Req{};
            try parseRequestLine(first_line, &req, options);
            req.headers = try headers.parse(allocator, r, options);
            return utils.Msg{ .req = req };
        }
    }
};
