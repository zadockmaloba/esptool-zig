const std = @import("std");
const ini = @import("ini");

const Section = struct {
    name: []const u8,
    options: []const ini.KeyValue,
};

pub const ConfigParser = struct {
    filepath: []const u8,
    allocator: std.mem.Allocator,
    fields: std.StringHashMap(Section) = undefined,
    file: std.fs.File = undefined,
    kv_buffer: std.ArrayList(ini.KeyValue),

    pub fn init(allocator: std.mem.Allocator, filepath: []const u8) !ConfigParser {
        return .{
            .allocator = allocator,
            .filepath = filepath,
            .fields = std.StringHashMap(Section).init(allocator),
            .file = try std.fs.cwd().openFile(filepath, .{}),
            .kv_buffer = std.ArrayList(ini.KeyValue).init(allocator),
        };
    }

    pub fn deinit(self: *@This()) void {
        self.file.close();
        self.kv_buffer.deinit();
        self.fields.deinit();
    }

    pub fn parse(self: *@This()) !void {
        var parser = ini.parse(self.allocator, self.file.reader());
        defer parser.deinit();

        var current_section: Section = .{
            .name = "NAN",
            .options = &[_]ini.KeyValue{},
        };
        var section_started: bool = false;

        while (try parser.next()) |record| {
            //const record = try parser.next() orelse break;

            switch (record) {
                .section => |heading| {
                    if (section_started) {
                        std.debug.print("Ending section...\n", .{});
                        //current_section.options = try self.kv_buffer.toOwnedSlice();
                        //tmp.clearAndFree();
                        //std.debug.print("Section: \n {any}\n", .{current_section});
                        //try self.fields.put(current_section.name, current_section);
                        section_started = false;
                        std.debug.print("Ending section part2\n", .{});
                    }

                    std.debug.print("Starting section...\n", .{});
                    current_section.name = heading;
                    section_started = true;
                },
                .property => |kv| {
                    std.debug.print("Key: {s}\n", .{kv.key});
                    try self.kv_buffer.append(kv);
                },
                .enumeration => |value| _ = value, //TODO: Implement
            }
        }
    }
};
