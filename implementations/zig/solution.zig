const std = @import("std");

const WorkerResult = struct {
    errors: usize,
    warnings: usize,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    _ = args.next(); // skip exe name
    const logfile = args.next() orelse {
        try std.io.getStdErr().writer().print("Usage: solution <logfile>\n", .{});
        return error.MissingArgument;
    };

    const file = try std.fs.cwd().openFile(logfile, .{});
    defer file.close();

    const stat = try file.stat();
    const file_size = @intCast(usize, stat.size);
    const data = try file.readToEndAlloc(allocator, file_size);
    defer allocator.free(data);

    var lines = std.ArrayList([]const u8).init(allocator);
    defer lines.deinit();

    var splitter = std.mem.splitScalar(u8, data, '\n');
    while (splitter.next()) |raw| {
        const line = std.mem.trimRight(u8, raw, "\r");
        try lines.append(line);
    }

    if (lines.items.len == 0) {
        try outputResult(0, 0);
        return;
    }

    const cpu_count = std.Thread.getCpuCount() catch 1;
    const desired_threads = @intCast(usize, cpu_count);
    const worker_count = if (desired_threads == 0) 1 else @min(desired_threads, lines.items.len);
    const chunk_size = std.math.divCeil(usize, lines.items.len, worker_count) catch unreachable;

    var thread_handles = std.ArrayList(std.Thread).init(allocator);
    defer thread_handles.deinit();

    var start: usize = 0;
    while (start < lines.items.len) {
        const end = @min(lines.items.len, start + chunk_size);
        const chunk = lines.items[start..end];
        const handle = try std.Thread.spawn(.{}, worker, .{chunk});
        try thread_handles.append(handle);
        start = end;
    }

    var total_errors: usize = 0;
    var total_warnings: usize = 0;
    for (thread_handles.items) |handle| {
        const result = handle.join();
        total_errors += result.errors;
        total_warnings += result.warnings;
    }

    try outputResult(total_errors, total_warnings);
}

fn worker(chunk: []const []const u8) WorkerResult {
    var result = WorkerResult{ .errors = 0, .warnings = 0 };
    for (chunk) |line| {
        if (containsWord(line, "ERROR")) {
            result.errors += 1;
        } else if (containsWord(line, "WARN")) {
            result.warnings += 1;
        }
    }
    return result;
}

fn outputResult(errors: usize, warnings: usize) !void {
    const total = errors + warnings;
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{{\"errors\": {d}, \"warnings\": {d}, \"total\": {d}}}\n", .{ errors, warnings, total });
}

fn isAsciiAlnum(c: u8) bool {
    return (c >= '0' and c <= '9') or (c >= 'A' and c <= 'Z') or (c >= 'a' and c <= 'z');
}

fn containsWord(line: []const u8, word: []const u8) bool {
    if (word.len == 0 or line.len < word.len) return false;
    var start: usize = 0;
    while (start <= line.len - word.len) {
        const idx_opt = std.mem.indexOfPos(u8, line, start, word);
        if (idx_opt) |idx| {
            const before_ok = (idx == 0) or !isAsciiAlnum(line[idx - 1]);
            const after = idx + word.len;
            const end_ok = (after >= line.len) or !isAsciiAlnum(line[after]);
            if (before_ok and end_ok) return true;
            start = idx + 1;
        } else break;
    }
    return false;
}
