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

test "Set operations test" {
    std.debug.print("\r\n+++++++++++++++++++++++++++++\r\n", .{});
    // import the namespace.
    const set = @import("zigset");

    // Create a set of u32s called A
    var A = set.Set(u32).init(std.testing.allocator);
    defer A.deinit();

    // Add some data
    _ = try A.add(5);
    _ = try A.add(6);
    _ = try A.add(7);

    // Add more data; single shot, duplicate data is ignored.
    _ = try A.appendSlice(&.{ 5, 3, 0, 9 });

    // Create another set called B
    var B = set.Set(u32).init(std.testing.allocator);
    defer B.deinit();

    // Add data to B
    _ = try B.appendSlice(&.{ 50, 30, 20 });

    // Get the union of A | B
    var un = try A.unionOf(B);
    defer un.deinit();

    var diff = try A.differenceOf(B);
    defer diff.deinit();

    // Grab an iterator and dump the contents.
    var iter = un.iterator();
    while (iter.next()) |el| {
        std.debug.print("element: {d}, ", .{el.*});
    }
    std.debug.print("\n", .{});

    var iter2 = diff.iterator();
    while (iter2.next()) |el| {
        std.debug.print("element: {d}, ", .{el.*});
    }
    std.debug.print("\n", .{});
}

test "Regex match test" {
    var re = try regex.compile(std.testing.allocator, "\\w+");
    defer re.deinit();

    debug.assert(try re.match("hej") == true);
}

test "Basic config parsing test" {
    std.debug.print("\r\n+++++++++++++++++++++++++++++\r\n", .{});
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

test "ESP config file parsing test" {
    std.debug.print("\r\n+++++++++++++++++++++++++++++\r\n", .{});
    const ini = @import("ini");
    const file = try std.fs.cwd().openFile("./test/esptool.cfg", .{});
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
    std.debug.print("\r\n+++++++++++++++++++++++++++++\r\n", .{});
    const conf = @import("esptool/config.zig");

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() != .ok) @panic("memory leaked");

    var conf_obj = conf.Config.init(gpa.allocator());
    defer conf_obj.deinit();

    const res = try conf_obj.validateConfigFile("./test/esptool.cfg", false);

    try std.testing.expect(res);
}
