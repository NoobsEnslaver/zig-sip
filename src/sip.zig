const std = @import("std");
const parser = @import("./parser/message.zig");
const utils = @import("./parser/utils.zig");
// const sdp = @import("./sdp/sdp.zig");

// ---------------- Interfaces --------------------
pub const Msg = utils.Msg;
pub const MsgTag = utils.MsgTag;

// ---------------- Testing -----------------------
const t = std.testing;
test {
    _ = @import("./parser/message.zig");
}

const good = [_][]const u8{
    @embedFile("./tests/own0.txt"),
    @embedFile("./tests/own1.txt"),
    @embedFile("./tests/own2.txt"),
    @embedFile("./tests/own3.txt"),
    @embedFile("./tests/own4.txt"),
    @embedFile("./tests/own5.txt"),
    @embedFile("./tests/own6.txt"),
    @embedFile("./tests/test1.txt"),
    @embedFile("./tests/test2.txt"),
    @embedFile("./tests/test3.txt"),
    @embedFile("./tests/test4.txt"),
    @embedFile("./tests/test5.txt"),
    @embedFile("./tests/test6.txt"),
    @embedFile("./tests/test9.txt"),
    @embedFile("./tests/test14.txt"),
    @embedFile("./tests/test20.txt"),
    @embedFile("./tests/test23.txt"),
    @embedFile("./tests/test24.txt"),
    @embedFile("./tests/test31.txt"),

    // ugly
    @embedFile("./tests/test25.txt"),
    @embedFile("./tests/test27.txt"),
    @embedFile("./tests/test28.txt"),
    @embedFile("./tests/test30.txt"),
    @embedFile("./tests/test32.txt"),
    @embedFile("./tests/test34.txt"),
    @embedFile("./tests/test36.txt"),
    @embedFile("./tests/test37.txt"),
    @embedFile("./tests/test38.txt"),
    @embedFile("./tests/test39.txt"),
    @embedFile("./tests/test41.txt"),
    @embedFile("./tests/test42.txt"),
};

test {
    var arena = std.heap.ArenaAllocator.init(t.allocator);
    defer arena.deinit();

    //These are messages that the parser should pass
    // const good = [_][]const u8{
    // "test1.txt",
    // "test2.txt",  "test3.txt",  "test4.txt",
    // "test5.txt",  "test6.txt",  "test9.txt",
    // "test14.txt", "test20.txt", "test23.txt",
    // "test24.txt", "test31.txt",

    // These are ugly messages that parser should pass
    //   "test25.txt",
    // "test27.txt", "test28.txt", "test30.txt",
    // "test32.txt", "test34.txt", "test36.txt",
    // "test37.txt", "test38.txt",
    // "test39.txt",
    // "test41.txt", "test42.txt",
    // };

    // These are messages that the parser should fail
    // const bad = [_][]const u8{
    //     "test7.txt", "test8.txt", // "test10.txt", "test11.txt",
    // "test12.txt",
    // "test13.txt",
    // "test15.txt",
    // "test16.txt",
    // "test17.txt",
    // "test18.txt",
    // "test19.txt",
    // "test21.txt",
    //"test22.txt", // "test26.txt",
    // "test29.txt",
    // "test33.txt",
    // "test35.txt",
    // "test40.txt",
    //};

    for (good, 0..) |raw_msg, i| {
        const msg = parser.parseFromSlice(arena.allocator(), raw_msg, &.{ .max_line_len = 512 }) catch |err| {
            std.debug.print("{d}| unexpected parsing error: {any}\n", .{ i, err });
            try t.expect(false);
            continue;
        };
        if (msg.tag == .req) {
            std.debug.print("{d}++++++++++++++\nRuri: {s}\n", .{ i, msg.ruri.?.value });
            for (msg.headers.items) |hdr| {
                std.debug.print("{s}: {s}\n", .{ hdr.key, hdr.value });
            }
            std.debug.print("\n\n", .{});
        }

        try t.expect(true);
    }

    // for (bad) |file| {
    //     const fd = try tests_dir.openFile(file, .{});
    //     defer fd.close();
    //     _ = parser.parseFromReader(arena.allocator(), fd.reader(), &.{}) catch {
    //         try t.expect(true);
    //         continue;
    //     };
    //     std.debug.print("{s}: unexpected parsing success (should fail)\n", .{file});
    //     try t.expect(false);
    // }
}

// test "test2.txt" {
//     const raw_msg = @embedFile("./tests/test2.txt");
//     var arena = std.heap.ArenaAllocator.init(t.allocator);
//     defer arena.deinit();
//     const msg = try parser.parseFromSlice(arena.allocator(), raw_msg, &.{});
//     try t.expectEqual(utils.MessageType.req, @as(utils.MessageType, msg));

//     const req = msg.req;
//     try t.expectEqual(utils.Method.INVITE, req.method);
//     try t.expectEqualStrings("sip:user@company.com", req.ruri);
//     try t.expectEqual(null, req.body);
// }

// test "test7.txt" {
//     const raw_msg = @embedFile("./tests/test7.txt");
//     var arena = std.heap.ArenaAllocator.init(t.allocator);
//     defer arena.deinit();
//     const parse_opts = .{ .on_parse_method_error = utils.ParseMethodErrBehavior{ .replace = utils.Method.UNEXPECTED } };
//     const msg = try parser.parseFromSlice(arena.allocator(), raw_msg, &parse_opts);
//     try t.expectEqual(utils.MessageType.req, @as(utils.MessageType, msg));

//     const req = msg.req;
//     try t.expectEqual(utils.Method.UNEXPECTED, req.method);
//     try t.expectEqualStrings("sip:user@comapny.com", req.ruri);
//     // try t.expectEqual(null, req.body);
// }

// fn test8FixMethodCallback(s: []const u8) anyerror!utils.Method {
//     try t.expectEqualStrings("NEWMETHOD", s);
//     return utils.Method.USER1;
// }

// test "test8.txt" {
//     const raw_msg = @embedFile("./tests/test8.txt");
//     var arena = std.heap.ArenaAllocator.init(t.allocator);
//     defer arena.deinit();

//     const parse_opts = .{ .on_parse_method_error = utils.ParseMethodErrBehavior{ .callback = test8FixMethodCallback } };
//     const msg = try parser.parseFromSlice(arena.allocator(), raw_msg, &parse_opts);
//     try t.expectEqual(utils.MessageType.req, @as(utils.MessageType, msg));

//     const req = msg.req;
//     try t.expectEqual(utils.Method.USER1, req.method);
//     try t.expectEqualStrings("sip:user@comapny.com", req.ruri);
//     // try t.expectEqual(null, req.body);
// }

test "own2.txt" {
    const raw_msg = @embedFile("./tests/own2.txt");
    var arena = std.heap.ArenaAllocator.init(t.allocator);
    defer arena.deinit();
    const msg = try parser.parseFromSlice(arena.allocator(), raw_msg, &.{});
    try t.expectEqual(utils.MsgTag.resp, msg.tag);

    try t.expectEqual(401, msg.code);
    try t.expectEqualStrings("Unauthorized", msg.reason.?);
    try t.expectEqual(null, msg.body);
    try t.expectEqual(9, msg.headers.items.len);

    const hdr5 = try msg.headers.items[5].parse();
    try t.expectEqualStrings(hdr5.call_id.localid, "982773899-reg");
    try t.expectEqualStrings(hdr5.call_id.host.?, "172.21.9.155");

    const hdr6 = try msg.headers.items[6].parse();
    try t.expectEqual(hdr6.cseq.method, utils.Method.REGISTER);
    try t.expectEqual(hdr6.cseq.seq, 1);
}

// test "test41.txt" {
//     const raw_msg = @embedFile("./tests/test41.txt");
//     var arena = std.heap.ArenaAllocator.init(t.allocator);
//     defer arena.deinit();

//     try t.expectEqual(error.UnexpectedSIPVer, parser.parseFromSlice(arena.allocator(), raw_msg, &.{}));
// }

test "own0.txt" {
    const raw_msg = @embedFile("./tests/own0.txt");
    var arena = std.heap.ArenaAllocator.init(t.allocator);
    defer arena.deinit();
    const msg = try parser.parseFromSlice(arena.allocator(), raw_msg, &.{});
    try t.expectEqual(utils.MsgTag.req, msg.tag);

    try t.expectEqualStrings("sip:garage.sr.ntc.nokia.com", msg.ruri.?.value);
    try t.expectEqual(utils.Method.REGISTER, msg.method);
}

test "self captured good" {
    var arena = std.heap.ArenaAllocator.init(t.allocator);
    defer arena.deinit();

    var tests_dir = try std.fs.cwd().openDir("src/tests/my/", .{ .iterate = true });
    defer tests_dir.close();
    var it = tests_dir.iterate();
    while (try it.next()) |file| {
        const fd = try tests_dir.openFile(file.name, .{});
        defer fd.close();
        const msg = parser.parseFromReader(arena.allocator(), fd.reader(), &.{}) catch |err| {
            std.debug.print("{s}: unexpected parsing error: {any}\n", .{ file.name, err });
            try t.expect(false);
            continue;
        };

        if (msg.tag == .req) {
            // std.debug.print("++++++{s}++++++++\nRuri: {s}\n", .{ file.name, msg.req.ruri.value });
            // for (msg.req.headers.items) |hdr| {
            //     std.debug.print("{s}: {s}\n", .{ hdr.key, hdr.value });
            // }
            // std.debug.print("\n\n", .{});
        }

        try t.expect(true);
    }
}
