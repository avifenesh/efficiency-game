const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    _ = args.next(); // skip exe name
    const logfile = args.next() orelse {
        try std.io.getStdErr().writer().print("Usage: solution <logfile>\n", .{});
        return;
    };

    const file = try std.fs.cwd().openFile(logfile, .{});
    defer file.close();

    var errors: usize = 0;
    var warnings: usize = 0;

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buffer: [1024]u8 = undefined;

    while (try in_stream.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        if (containsWord(line, "ERROR")) {
            errors += 1;
        } else if (containsWord(line, "WARN")) {
            warnings += 1;
        }
    }

    const total = errors + warnings;
    const json_out = try std.json.stringify(
        .{ .errors = errors, .warnings = warnings, .total = total },
        .{ .allocator = allocator },
    );
    defer allocator.free(json_out);

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{s}\n", .{json_out});
}

fn isAsciiAlnum(c: u8) bool {
    return (c >= '0' and c <= '9') or (c >= 'A' and c <= 'Z') or (c >= 'a' and c <= 'z');
}

fn containsWord(line: []const u8, word: []const u8) bool {
    if (word.len == 0 or line.len < word.len) return false;
    var start: usize = 0;
    while (start <= line.len - word.len) : (start += 1) {
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
