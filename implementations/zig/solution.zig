const std = @import("std");
const json = std.json;

const Result = struct {
    errors: usize,
    warnings: usize,
    total: usize,
};

fn isAlnum(byte: u8) bool {
    return (byte >= '0' and byte <= '9') or
           (byte >= 'A' and byte <= 'Z') or
           (byte >= 'a' and byte <= 'z');
}

fn containsWord(line: []const u8, word: []const u8) bool {
    if (word.len == 0 or line.len < word.len) {
        return false;
    }

    var start: usize = 0;
    while (start < line.len) {
        const idx_opt = std.mem.indexOf(u8, line[start..], word);
        if (idx_opt == null) {
            return false;
        }
        const idx = start + idx_opt.?;

        const start_ok = idx == 0 or !isAlnum(line[idx - 1]);
        const end_ok = idx + word.len >= line.len or !isAlnum(line[idx + word.len]);

        if (start_ok and end_ok) {
            return true;
        }

        start = idx + 1;
    }

    return false;
}

const WorkerContext = struct {
    lines: [][]const u8,
    start: usize,
    end: usize,
    errors: *std.atomic.Value(usize),
    warnings: *std.atomic.Value(usize),
};

fn workerThread(ctx: *WorkerContext) void {
    var local_errors: usize = 0;
    var local_warnings: usize = 0;

    var i = ctx.start;
    while (i < ctx.end) : (i += 1) {
        const line = ctx.lines[i];
        if (std.mem.indexOfScalar(u8, line, 'E') != null and containsWord(line, "ERROR")) {
            local_errors += 1;
        } else if (std.mem.indexOfScalar(u8, line, 'W') != null and containsWord(line, "WARN")) {
            local_warnings += 1;
        }
    }

    _ = ctx.errors.fetchAdd(local_errors, .monotonic);
    _ = ctx.warnings.fetchAdd(local_warnings, .monotonic);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len != 2) {
        const stderr = std.io.getStdErr().writer();
        try stderr.print("Usage: {s} <logfile>\n", .{args[0]});
        std.process.exit(1);
    }

    const filename = args[1];

    // Read file
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    const content = try file.readToEndAlloc(allocator, 1024 * 1024 * 1024); // 1GB max
    defer allocator.free(content);

    // Split into lines
    var lines = std.ArrayList([]const u8).init(allocator);
    defer lines.deinit();

    var iter = std.mem.splitScalar(u8, content, '\n');
    while (iter.next()) |line| {
        if (line.len > 0) {
            try lines.append(line);
        }
    }

    if (lines.items.len == 0) {
        const stdout = std.io.getStdOut().writer();
        try stdout.print("{{\"errors\":0,\"warnings\":0,\"total\":0}}\n", .{});
        return;
    }

    // Determine number of threads
    const cpu_count = try std.Thread.getCpuCount();
    const num_threads = @min(cpu_count, lines.items.len);
    const chunk_size = (lines.items.len + num_threads - 1) / num_threads;

    // Atomic counters
    var errors = std.atomic.Value(usize).init(0);
    var warnings = std.atomic.Value(usize).init(0);

    // Create threads
    var threads = try allocator.alloc(std.Thread, num_threads);
    defer allocator.free(threads);

    var contexts = try allocator.alloc(WorkerContext, num_threads);
    defer allocator.free(contexts);

    var i: usize = 0;
    while (i < num_threads) : (i += 1) {
        const start = i * chunk_size;
        if (start >= lines.items.len) break;
        const end = @min(start + chunk_size, lines.items.len);

        contexts[i] = WorkerContext{
            .lines = lines.items,
            .start = start,
            .end = end,
            .errors = &errors,
            .warnings = &warnings,
        };

        threads[i] = try std.Thread.spawn(.{}, workerThread, .{&contexts[i]});
    }

    // Join threads
    const actual_threads = @min(num_threads, (lines.items.len + chunk_size - 1) / chunk_size);
    i = 0;
    while (i < actual_threads) : (i += 1) {
        threads[i].join();
    }

    const final_errors = errors.load(.monotonic);
    const final_warnings = warnings.load(.monotonic);
    const total = final_errors + final_warnings;

    // Output JSON
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{{\"errors\":{d},\"warnings\":{d},\"total\":{d}}}\n", .{ final_errors, final_warnings, total });
}
