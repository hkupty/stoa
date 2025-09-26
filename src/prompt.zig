const std = @import("std");
const shell = @import("./shell.zon");
const stoa = @import("stoa");

const path = std.fs.path;
const Allocator = std.mem.Allocator;

var pathname: [std.fs.max_path_bytes]u8 = undefined;
var prompt: [2 * 1024]u8 = undefined;

pub fn is_git(alloc: Allocator, fpath: []const u8) bool {
    var iter = path.componentIterator(fpath) catch return false;

    // Skip /home
    _ = iter.next() orelse return false;

    // Skip /home/hkupty
    _ = iter.next() orelse return false;

    while (iter.next()) |component| {
        const target = path.join(alloc, &.{ component.path, ".git" }) catch return false;
        std.fs.accessAbsolute(target, .{}) catch continue;
        return true;
    }
    return false;
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

    // TODO: determine if should break line
    var cursor: usize = 0;
    prompt[cursor] = '\n';
    cursor += 1;

    @memcpy(prompt[cursor..][0..cwd.len], cwd);
    cursor += cwd.len;
    if (is_git(alloc, cwd)) {
        check: {
            if (session) |file| {
                defer file.close();
                var session_data = stoa.getdata(file) catch break :check;
                session_data.in_git = true;
                stoa.stamp(file, session_data) catch break :check;
            }
        }

        const were_in_git = " [git]";
        @memcpy(prompt[cursor..][0..were_in_git.len], were_in_git);
        cursor += were_in_git.len;
    }

    prompt[cursor] = '\n';
    cursor += 1;

    @memcpy(prompt[cursor..][0..shell.prompt.len], shell.prompt);
    cursor += shell.prompt.len;
    prompt[cursor] = ' ';
    cursor += 1;

    _ = std.fs.File.stdout().write(prompt[0..cursor]) catch unreachable;
}
