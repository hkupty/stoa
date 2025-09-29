const std = @import("std");
const shell = @import("./shell.zon");
const stoa = @import("stoa");
const git = @import("./extras/git.zig");

const path = std.fs.path;
const Allocator = std.mem.Allocator;

var pathname: [std.fs.max_path_bytes]u8 = undefined;
const stdout = std.fs.File.stdout();
var prompt: [2 * 1024]u8 = undefined;
var stdout_fwriter = stdout.writer(&prompt);
var out = &stdout_fwriter.interface;

fn session_file(alloc: Allocator) ?std.fs.File {
    const key = std.process.getEnvVarOwned(alloc, "STOA_SESION") catch {
        // TODO: Must not spill errors
        return null;
    };
    return std.fs.createFileAbsolute(key, .{}) catch {
        return null;
    };
}

pub fn main() void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const session = session_file(alloc).?;

    const cwd = std.fs.cwd().realpath(".", &pathname) catch data: {
        // TODO: Must not spill errors
        break :data "./?";
    };

    out.writeByte('\n') catch unreachable;
    _ = out.write(cwd) catch unreachable;

    has_git: {
        var path_iter = path.componentIterator(cwd) catch break :has_git;
        defer session.close();
        var session_data = stoa.getdata(session) catch unreachable;
        session_data.in_git = false;

        if (git.is_in_git(alloc, &path_iter)) |git_path| {
            session_data.in_git = true;

            var full_git_path = git_path;

            if (path_iter.next()) |component| x: {
                const target = path.join(alloc, &.{ git_path, "worktrees", component.name }) catch break :x;
                std.fs.accessAbsolute(target, .{}) catch break :x;
                full_git_path = target;
            }

            _ = out.write("\x1B[38;5;") catch unreachable;
            _ = out.write(shell.git_color) catch unreachable;
            _ = out.write("m [ ") catch unreachable;
            git.parseHeadInto(alloc, full_git_path, out);
            _ = out.write(" ]\x1B[0m") catch unreachable;
        }

        stoa.stamp(session, session_data) catch unreachable;
    }

    out.writeByte('\n') catch unreachable;
    _ = out.write(shell.prompt) catch unreachable;
    out.writeByte(' ') catch unreachable;

    out.flush() catch unreachable;
}
