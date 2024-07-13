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

test "Regex" {
    var re = try regex.compile(std.testing.allocator, "\\w+");
    defer re.deinit();

    debug.assert(try re.match("hej") == true);
}
