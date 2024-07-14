const std = @import("std");
const ini = @import("ini");

pub const ConfigParser = struct {
    filepath: []const u8,
    allocator: std.mem.Allocator,
    fields: std.StringHashMap([]const u8) = undefined,
    file: std.fs.File = undefined,

    pub fn init(allocator: std.mem.Allocator, filepath: []const u8) !ConfigParser {
        return .{
            .allocator = allocator,
            .filepath = filepath,
            .fields = std.StringHashMap([]const u8).init(allocator),
            .file = try std.fs.cwd().openFile(filepath, .{}),
        };
    }

    pub fn deinit(self: *@This()) void {
        self.file.close();
        self.fields.deinit();
    }

    pub fn parse(self: *@This()) !void {
        var parser = ini.parse(self.allocator, self.file.reader());
        defer parser.deinit();

        while (try parser.next()) |record| {
            //const record = try parser.next() orelse break;

            switch (record) {
                .section => |heading| std.debug.print("[{s}]\n", .{heading}),
                .property => |kv| std.debug.print("{s} = {s}\n", .{ kv.key, kv.value }),
                .enumeration => |value| std.debug.print("{s}\n", .{value}),
            }
        }
    }
};
