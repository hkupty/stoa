const std = @import("std");

const databytes = [@bitSizeOf(RuntimeData) / 8]u8;

pub const RuntimeData = packed struct {
    in_git: bool,
    padding: u7,
};

pub fn getdata(file: std.fs.File) !RuntimeData {
    var bulk: databytes = undefined;
    _ = try file.read(&bulk);
    const data: RuntimeData = @bitCast(bulk);
    return data;
}

pub fn touch(file: std.fs.File) !void {
    var bulk: databytes = undefined;
    @memset(&bulk, 0);
    _ = try file.write(&bulk);
}

pub fn stamp(file: std.fs.File, data: RuntimeData) !void {
    var bulk: databytes = @bitCast(data);
    _ = try file.write(&bulk);
}
