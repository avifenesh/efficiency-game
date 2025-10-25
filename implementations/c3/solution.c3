module solution;
import std::io;
import std::io::file;

fn bool is_alnum(char c) {
    return (c >= '0' && c <= '9') ||
           (c >= 'A' && c <= 'Z') ||
           (c >= 'a' && c <= 'z');
}

fn bool contains_word(String line, String word) {
    usz line_len = line.len;
    usz word_len = word.len;

    if (word_len == 0 || line_len < word_len) {
        return false;
    }

    for (usz i = 0; i <= line_len - word_len; i++) {
        bool match = true;
        for (usz j = 0; j < word_len; j++) {
            if (line[i + j] != word[j]) {
                match = false;
                break;
            }
        }

        if (match) {
            bool start_ok = (i == 0) || !is_alnum(line[i - 1]);
            bool end_ok = (i + word_len >= line_len) || !is_alnum(line[i + word_len]);

            if (start_ok && end_ok) {
                return true;
            }
        }
    }

    return false;
}

fn int main(String[] args) {
    if (args.len != 2) {
        io::eprintn("Usage: solution <logfile>");
        return 1;
    }

    String filename = args[1];

    // Open file
    File? file_result = file::open(filename, "r");
    if (catch err = file_result) {
        io::eprintfn("Error: Cannot open file %s", filename);
        return 1;
    }
    File file = file_result;

    int errors = 0;
    int warnings = 0;

    // Read and process file line by line
    while (!file.eof()) {
        String? line_opt = io::treadline(&file);
        if (catch line_opt) {
            break;
        }
        String line = line_opt;

        // Quick check for 'E' or 'W' before expensive word check
        bool has_e = false;
        bool has_w = false;

        foreach (char c : line) {
            if (c == 'E') has_e = true;
            if (c == 'W') has_w = true;
            if (has_e && has_w) break;
        }

        if (has_e && contains_word(line, "ERROR")) {
            errors++;
        } else if (has_w && contains_word(line, "WARN")) {
            warnings++;
        }
    }

    // Close file
    file.close()!!;

    int total = errors + warnings;
    io::printfn("{\"errors\": %d, \"warnings\": %d, \"total\": %d}", errors, warnings, total);

    return 0;
}
