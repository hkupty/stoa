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

pub fn main() void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const session = stoa.get_session_file(alloc, .read_write).?;
    defer session.close();
    var session_data = stoa.getdata(session) catch unreachable;
    session_data.in_git = false;

    out.writeByte('\n') catch unreachable;

    has_git: {
        const cwd = std.fs.cwd().realpath(".", &pathname) catch {
            _ = out.write("./?") catch unreachable;
            break :has_git;
        };

        var path_iter = path.componentIterator(cwd) catch break :has_git;

        if (git.is_in_git(alloc, &path_iter)) |git_path| {
            const folder = path.basename(git_path);
            stoa.color.write_color(out, shell.repo_color);
            _ = out.write(" ") catch unreachable;
            _ = out.write(folder) catch unreachable;
            stoa.color.clear_format(out);
            out.writeByte(' ') catch unreachable;

            var relative_path = cwd[git_path.len..];

            session_data.in_git = true;

            var full_git_path = path.join(alloc, &.{ git_path, ".git" }) catch unreachable;

            if (path_iter.next()) |component| x: {
                const target = path.join(alloc, &.{ full_git_path, "worktrees", component.name }) catch break :x;
                std.fs.accessAbsolute(target, .{}) catch break :x;
                relative_path = cwd[component.path.len..];
                full_git_path = target;

                stoa.color.write_color(out, shell.worktree_color);
                _ = out.write(" ") catch unreachable;
                _ = out.write(component.name) catch unreachable;
                stoa.color.clear_format(out);
                out.writeByte(' ') catch unreachable;
            }

            out.writeByte('.') catch unreachable;
            if (relative_path.len == 0) {
                out.writeByte('/') catch unreachable;
            } else {
                _ = out.write(relative_path) catch unreachable;
            }

            stoa.color.write_color(out, shell.git_color);
            _ = out.write(" [ ") catch unreachable;
            git.parseHeadInto(alloc, full_git_path, out);
            _ = out.write(" ]") catch unreachable;
            stoa.color.clear_format(out);
        } else {
            _ = out.write(cwd) catch unreachable;
        }

        stoa.stamp(session, &session_data) catch unreachable;
    }
    const prompt_color: u8 = if (session_data.success) 101 else 130;

    out.writeByte('\n') catch unreachable;
    stoa.color.write_color(out, prompt_color);
    _ = out.write(shell.prompt) catch unreachable;
    stoa.color.clear_format(out);
    out.writeByte(' ') catch unreachable;

    out.flush() catch unreachable;
}
