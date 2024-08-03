const std = @import("std");
const configparser = @import("configparser.zig").ConfigParser;

const CONFIG_OPTIONS = [_][]const u8{
    "timeout",
    "chip_erase_timeout",
    "max_timeout",
    "sync_timeout",
    "md5_timeout_per_mb",
    "erase_region_timeout_per_mb",
    "erase_write_timeout_per_mb",
    "mem_end_rom_timeout",
    "serial_write_timeout",
    "connect_attempts",
    "write_block_attempts",
    "reset_delay",
    "custom_reset_sequence",
};

//TODO: Improve on error handling
pub const ConfFileError = error{
    UnicodeDecodeError,
};

pub const Config = struct {
    //allocator: std.mem.Allocator,
    arena: std.heap.ArenaAllocator,

    pub fn init(allocator: std.mem.Allocator) Config {
        return .{
            //.allocator = allocator,
            .arena = std.heap.ArenaAllocator.init(allocator), //NOTE: We need to use an arena allocator due to the string operations in the parser
        };
    }

    pub fn deinit(self: *@This()) void {
        self.arena.deinit();
    }

    pub fn validateConfigFile(self: *@This(), filePath: []const u8, verbose: bool) !bool {
        //TODO: Implement verbose and non-verbose mode
        _ = verbose;

        var cfg = configparser.init(self.arena.allocator(), filePath) catch |err| switch (err) {
            std.fs.File.OpenError.FileNotFound => {
                std.debug.print("File: {s} not found \n", .{filePath});
                return false;
            },
            else => {
                return err;
            },
        };
        defer cfg.deinit();

        std.debug.print("Starting to parse the file\n", .{});
        try cfg.parse();

        return true;
    }
};
