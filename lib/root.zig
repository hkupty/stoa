const std = @import("std");
pub const color = @import("./color.zig");

const Allocator = std.mem.Allocator;
const File = std.fs.File;

const databytes = [@sizeOf(RuntimeData)]u8;

pub const RuntimeData = packed struct {
    success: bool,
    in_git: bool,

    padding: u6,
};

pub fn getdata(file: File) !RuntimeData {
    var bulk: databytes = undefined;
    _ = try file.read(&bulk);
    var data: RuntimeData = std.mem.bytesToValue(RuntimeData, &bulk);
    data.padding = 0;
    return data;
}

pub fn touch(file: File) !void {
    var bulk: databytes = undefined;
    @memset(&bulk, 0);
    _ = try file.write(&bulk);
}

pub fn stamp(file: File, data: *const RuntimeData) !void {
    var buf: databytes = undefined;
    try file.setEndPos(0);

    var writer = file.writer(&buf);
    var io_writer = &writer.interface;

    const bulk: databytes = std.mem.asBytes(data).*;
    _ = try io_writer.write(&bulk);
    try io_writer.flush();
}

pub fn get_session_file(alloc: Allocator, mode: File.OpenMode) ?File {
    const key = std.process.getEnvVarOwned(alloc, "STOA_SESION") catch {
        return null;
    };
    return std.fs.openFileAbsolute(key, .{ .mode = mode }) catch {
        return null;
    };
}

pub fn atomic_read(alloc: Allocator) ?RuntimeData {
    var file = get_session_file(alloc, .read_only) orelse return null;
    defer file.close();

    return getdata(file) catch null;
}
