const std = @import("std");
const ini = @import("ini");

const Section = struct {
    name: []const u8,
    values: []const ini.KeyValue = undefined,
    start_idx: u8 = 0,
    end_idx: u8 = 0,
};

pub const ConfigParser = struct {
    filepath: []const u8,
    allocator: std.mem.Allocator,
    sections: std.StringHashMap(Section),
    file: std.fs.File = undefined,
    values: std.ArrayList(ini.KeyValue),

    pub fn init(allocator: std.mem.Allocator, filepath: []const u8) !ConfigParser {
        return .{
            .allocator = allocator,
            .filepath = filepath,
            .sections = std.StringHashMap(Section).init(allocator),
            .file = try std.fs.cwd().openFile(filepath, .{}),
            .values = std.ArrayList(ini.KeyValue).init(allocator),
        };
    }

    pub fn deinit(self: *@This()) void {
        self.file.close();
        self.values.deinit();
        self.sections.deinit();
    }

    pub fn parse(self: *@This()) !void {
        var parser = ini.parse(self.allocator, self.file.reader());
        defer parser.deinit();

        var section_started: bool = false;
        var start_idx: u8 = 0;
        var tmp_header: []u8 = undefined;

        while (try parser.next()) |record| {
            switch (record) {
                .section => |heading| {
                    if (section_started) {
                        const sel: Section = .{
                            .name = heading[0..],
                            .start_idx = start_idx,
                            .end_idx = @intCast(self.values.items.len),
                        };
                        std.debug.print("Ending section...\n", .{});
                        std.debug.print("Ending: {s}\n", .{sel.name});
                        try self.sections.put(sel.name, sel);
                        section_started = false;
                        std.debug.print("Ending section part2 \n", .{});
                    }

                    std.debug.print("Starting section... {s}\n", .{heading});
                    section_started = true;
                    start_idx = @intCast(self.values.items.len);

                    const mutableSlice = try self.allocator.alloc(u8, heading.len);
                    //defer self.allocator.free(mutableSlice);
                    std.mem.copyBackwards(u8, mutableSlice, heading[0..]);
                    tmp_header = mutableSlice;
                },
                .property => |kv| {
                    try self.values.append(kv);
                },
                .enumeration => |value| _ = value, // TODO: Implement
            }
        }

        if (section_started) {
            std.debug.print("Ending last section: {s}...\n", .{tmp_header[0..]});
            const sel: Section = .{
                .name = tmp_header[0..],
                .start_idx = start_idx,
                .end_idx = @intCast(self.values.items.len),
            };
            std.debug.print("Ending section...\n", .{});
            std.debug.print("Ending: {s}\n", .{sel.name});
            try self.sections.put(sel.name, sel);
            section_started = false;
            std.debug.print("Ending section part2 \n", .{});
        }

        std.debug.print("Sections Map: {any}\n", .{self.sections.count()});
    }
};
