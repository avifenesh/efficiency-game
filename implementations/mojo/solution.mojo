import sys
import json
from pathlib import Path

fn is_ascii_alnum(c: UInt8) -> Bool:
    return (c >= 48 and c <= 57) or (c >= 65 and c <= 90) or (c >= 97 and c <= 122)

fn contains_word(line: String, word: String) -> Bool:
    let bytes = line.bytes()
    let w = word.bytes()
    if w.size == 0 or bytes.size < w.size:
        return False
    var start: Int = 0
    while start <= bytes.size - w.size:
        var match = True
        for i in range(0, w.size):
            if bytes[start + i] != w[i]:
                match = False
                break
        if match:
            let before_ok = (start == 0) or (not is_ascii_alnum(bytes[start - 1]))
            let after = start + w.size
            let end_ok = (after >= bytes.size) or (not is_ascii_alnum(bytes[after]))
            if before_ok and end_ok:
                return True
        start += 1
    return False

fn count_words(line: String) -> (Int, Int):
    var errors = 0
    var warnings = 0
    if contains_word(line, "ERROR"):
        errors = 1
    elif contains_word(line, "WARN"):
        warnings = 1
    return (errors, warnings)

fn process_file(path: String) -> (Int, Int):
    var errors = 0
    var warnings = 0
    with open(path, "r") as f:
        for line in f:
            let (e, w) = count_words(line)
            errors += e
            warnings += w
    return (errors, warnings)

fn main() raises:
    let args = sys.argv()
    if len(args) != 2:
        print("Usage: mojo solution.mojo <logfile>", file=sys.stderr)
        sys.exit(1)

    let logfile = args[1]
    if not Path(logfile).exists():
        print(f"Error: File not found: {logfile}", file=sys.stderr)
        sys.exit(1)

    let (errors, warnings) = process_file(logfile)
    let total = errors + warnings
    let result = {"errors": errors, "warnings": warnings, "total": total}
    print(json.dumps(result))
