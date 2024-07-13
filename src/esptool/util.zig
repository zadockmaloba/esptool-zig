const std = @import("std");

const RuntimeError = error{
    OutOfMemory,
    InvalidArgument,
    InvalidState,
    InvalidSize,
    ResourceNotFound,
    OperationNotSupported,
    OperationTimedOut,
    InvalidResponse,
    InvalidCRC,
    InvalidVersion,
    InvalidMAC,
    FlashOperationFailed,
    FlashOperationTimedOut,
    FlashNotInitialized,
    OperationNotSupportedByHostSPI,
    OperationNotSupportedByFlash,
    WriteProtectionEnabled,
    BadDataLength,
    BadDataChecksum,
    BadBlockSize,
    InvalidCommand,
    FailedSPI,
    FailedSPIUnlock,
    NotInFlashMode,
    InflateError,
    NotEnoughData,
    TooMuchData,
    CommandNotImplemented,
    SecureDownloadMode,
};

fn byte(bitstr: []const u8, index: usize) u8 {
    return bitstr[index];
}

fn maskToShift(mask: u32) u32 {
    var shift: u32 = 0;
    while (mask & 0x1 == 0) {
        shift += 1;
        mask >>= 1;
    }
    return shift;
}

fn divRoundup(a: usize, b: usize) usize {
    return (a + b - 1) / b;
}

fn flashSizeBytes(size: ?[]const u8) ?usize {
    if (size == null) return null;
    const s = size.*;
    if (std.mem.endsWith(u8, s, "MB")) {
        return std.fmt.parseInt(usize, s[0 .. s.len - 2], 10) catch unreachable;
    } else if (std.mem.endsWith(u8, s, "KB")) {
        return std.fmt.parseInt(usize, s[0 .. s.len - 2], 10) * 1024 catch unreachable;
    } else {
        return null;
    }
}

fn hexify(s: []const u8, uppercase: bool) ![]u8 {
    var buf: [1024]u8 = undefined;
    const format_str = if (uppercase) "%02X" else "%02x";
    var index: usize = 0;
    for (s) |c| {
        index += try std.fmt.bufPrint(buf[index..], format_str, .{c});
    }
    return buf[0..index];
}

fn padTo(data: []u8, alignment: usize, padCharacter: u8) []u8 {
    //FIXME: Do something with this parameter
    _ = padCharacter;
    const pad_mod = data.len % alignment;
    if (pad_mod != 0) {
        const pad_length = alignment - pad_mod;
        return data ++ std.mem.zeroes(u8, pad_length);
    }
    return data;
}

fn printOverwrite(message: []const u8, lastLine: bool) void {
    if (std.io.getStdOut().isatty()) {
        std.debug.print("\r{any}", .{message});
        if (lastLine) std.debug.print("\n", .{});
    } else {
        std.debug.print("{any}\n", .{message});
    }
}

//FIXME: Use regex library
fn expandChipName(chipName: []const u8) []u8 {
    var result: []u8 = chipName[0..];
    result = std.mem.replaceSlice(u8, result, "esp32", "ESP32-");
    result = std.mem.replaceSlice(u8, result, "beta", "(beta");
    result = std.mem.replaceSlice(u8, result, "2", "2)");
    return result;
}

//FIXME: Use regex library
fn stripChipName(chipName: []const u8) []u8 {
    var result: []u8 = chipName[0..];
    result = std.mem.replaceSlice(u8, result, "-", "");
    result = std.mem.replaceSlice(u8, result, "(", "");
    result = std.mem.replaceSlice(u8, result, ")", "");
    return result;
}

fn getFileSize(pathToFile: []const u8) !usize {
    var file = try std.fs.cwd().openFile(pathToFile, .{});
    defer file.close();
    return try file.getEndPos();
}

const PrintOnce = struct {
    alreadyPrinted: bool,

    pub fn init() PrintOnce {
        return PrintOnce{
            .alreadyPrinted = false,
        };
    }

    pub fn print(self: *PrintOnce, text: []const u8) void {
        if (!self.alreadyPrinted) {
            std.debug.print("{s}\n", .{text});
            self.alreadyPrinted = true;
        }
    }
};

//TODO: Improve on error handling
const FatalError = error{};

fn WithResult(message: []const u8, result: []const u8) FatalError {
    const errDefs = [_]u8{
        // ROM error codes
        "Out of memory",
        "Invalid argument",
        "Invalid state",
        "Invalid size",
        "Requested resource not found",
        "Operation or feature not supported",
        "Operation timed out",
        "Received response was invalid",
        "CRC or checksum was invalid",
        "Version was invalid",
        "MAC address was invalid",
        "Flash operation failed",
        "Flash operation timed out",
        "Flash not initialised properly",
        "Operation not supported by the host SPI bus",
        "Operation not supported by the flash chip",
        "Can't write, protection enabled",
        // Flasher stub error codes
        "Bad data length",
        "Bad data checksum",
        "Bad blocksize",
        "Invalid command",
        "Failed SPI operation",
        "Failed SPI unlock",
        "Not in flash mode",
        "Inflate error",
        "Not enough data",
        "Too much data",
        "Command not implemented",
    };

    const errCode = (result[0] << 8) | result[1];
    const errMsg = errDefs[errCode];
    const finalMessage = std.mem.concat(u8, &[_][]const u8{
        message,
        " (result was ",
        result,
        ": ",
        errMsg,
        ")",
    });

    //FIXME: Do something with this value
    _ = finalMessage;
    return error.FatalError;
}

test "Expand chip name" {}
