const std = @import("std");
const debug = std.debug;
const regex = @import("regex").Regex;

pub fn main() !void {
    const args = std.os.argv;
    _ = args;
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "Regex match test" {
    var re = try regex.compile(std.testing.allocator, "\\w+");
    defer re.deinit();

    debug.assert(try re.match("hej") == true);
}

test "Basic config parsing test" {
    const ini = @import("ini");
    const file = try std.fs.cwd().openFile("./test/example.ini", .{});
    defer file.close();

    std.debug.print("Test file opened\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() != .ok) @panic("memory leaked");
    var parser = ini.parse(gpa.allocator(), file.reader());
    defer parser.deinit();

    const writer = std.debug;

    while (try parser.next()) |record| {
        //const record = try parser.next() orelse break;
        switch (record) {
            .section => |heading| writer.print("[{s}]\n", .{heading}),
            .property => |kv| writer.print("{s} = {s}\n", .{ kv.key, kv.value }),
            .enumeration => |value| writer.print("{s}\n", .{value}),
        }
    }
}

test "Validate config file" {
    const conf = @import("esptool/config.zig");

    const res = try conf.validateConfigFile("./test/example.ini", false);

    std.debug.assert(res);
}
