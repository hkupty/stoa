const std = @import("std");
const shell = @import("./shell.zon");
const stoa = @import("stoa");
const git = @import("./git.zig");

const path = std.fs.path;
const Allocator = std.mem.Allocator;

var pathname: [std.fs.max_path_bytes]u8 = undefined;
const stdout = std.fs.File.stdout();
var prompt: [2 * 1024]u8 = undefined;
var stdout_fwriter = stdout.writer(&prompt);
var out = &stdout_fwriter.interface;

pub fn is_git(alloc: Allocator, fpath: []const u8) ?[]const u8 {
    var iter = path.componentIterator(fpath) catch return null;

    // Skip /home
    _ = iter.next() orelse return null;

    // Skip /home/hkupty
    _ = iter.next() orelse return null;

    while (iter.next()) |component| {
        const target = path.join(alloc, &.{ component.path, ".git" }) catch return null;
        std.fs.accessAbsolute(target, .{}) catch continue;
        return target;
    }
    return null;
}
fn session_file(alloc: Allocator) ?std.fs.File {
    const key = std.process.getEnvVarOwned(alloc, "STOA_SESION") catch {
        // TODO: Must not spill errors
        return null;
    };
    return std.fs.openFileAbsolute(key, .{ .mode = .read_only }) catch {
        return null;
    };
}

pub fn main() void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const session = session_file(alloc);

    const cwd = std.fs.cwd().realpath(".", &pathname) catch data: {
        // TODO: Must not spill errors
        break :data "./?";
    };

    out.writeByte('\n') catch unreachable;
    _ = out.write(cwd) catch unreachable;

    if (is_git(alloc, cwd)) |git_path| {
        check: {
            if (session) |file| {
                defer file.close();
                var session_data = stoa.getdata(file) catch break :check;
                session_data.in_git = true;
                stoa.stamp(file, session_data) catch break :check;
            }
        }

        _ = out.write("\x1B[38;5;") catch unreachable;
        _ = out.write(shell.git_color) catch unreachable;
        _ = out.write("m [ ") catch unreachable;
        git.parseHeadInto(alloc, git_path, out);
        _ = out.write(" ]\x1B[0m") catch unreachable;
    }

    out.writeByte('\n') catch unreachable;
    _ = out.write(shell.prompt) catch unreachable;
    out.writeByte(' ') catch unreachable;

    out.flush() catch unreachable;
}
