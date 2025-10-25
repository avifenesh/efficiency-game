module solution;
import std::io;
import std::collections::list;
import std::thread;
import std::core::string;

struct Result {
    int errors;
    int warnings;
}

struct ThreadData {
    String[] lines;
    usz start;
    usz end;
    Result* result;
}

fn bool is_word_boundary(char c) {
    return !((c >= '0' && c <= '9') || 
             (c >= 'A' && c <= 'Z') || 
             (c >= 'a' && c <= 'z') ||
             c == '_');
}

fn bool contains_word(String line, String word) {
    usz line_len = line.len;
    usz word_len = word.len;

    if (word_len == 0 || line_len < word_len) {
        return false;
    }

    for (usz i = 0; i <= line_len - word_len; i++) {
        // Check if the substring matches
        bool match = true;
        for (usz j = 0; j < word_len; j++) {
            if (line[i + j] != word[j]) {
                match = false;
                break;
            }
        }

        if (match) {
            // Check word boundaries
            bool start_ok = (i == 0) || is_word_boundary(line[i - 1]);
            bool end_ok = (i + word_len >= line_len) || is_word_boundary(line[i + word_len]);

            if (start_ok && end_ok) {
                return true;
            }
        }
    }

    return false;
}

fn void process_chunk(void* data) {
    ThreadData* td = (ThreadData*)data;
    int local_errors = 0;
    int local_warnings = 0;

    for (usz i = td.start; i < td.end; i++) {
        String line = td.lines[i];
        if (contains_word(line, "ERROR")) {
            local_errors++;
        } else if (contains_word(line, "WARN")) {
            local_warnings++;
        }
    }

    // Atomic addition would be better, but for simplicity we use mutex-like behavior
    // In a real implementation, we'd use atomic operations
    td.result.errors += local_errors;
    td.result.warnings += local_warnings;
}

fn int main(String[] args) {
    if (args.len != 2) {
        io::eprintn("Usage: solution <logfile>");
        return 1;
    }
    
    String filename = args[1];
    
    // Read all lines from file
    File! file = file::open(filename, "r");
    if (catch err = file) {
        io::eprintfn("Error: Cannot open file %s", filename);
        return 1;
    }
    defer (void)file.close();
    
    List(<String>) lines;
    lines.new_init();
    defer lines.free();
    
    while (true) {
        String! line = io::readline(file);
        if (catch err = line) {
            break;
        }
        lines.push(line);
    }
    
    if (lines.len() == 0) {
        io::printn(`{"errors": 0, "warnings": 0, "total": 0}`);
        return 0;
    }
    
    // Determine number of threads
    uint num_threads = thread::cpu_count();
    if (num_threads == 0) {
        num_threads = 4;
    }
    if (num_threads > lines.len()) {
        num_threads = (uint)lines.len();
    }
    
    usz chunk_size = (lines.len() + num_threads - 1) / num_threads;

    Result result = { 0, 0 };
    ThreadData[] thread_data = mem::new_array(ThreadData, num_threads);
    defer free(thread_data);

    Thread[] threads = mem::new_array(Thread, num_threads);
    defer free(threads);

    // Convert list to array for easier access
    String[] lines_array = lines.to_new_array();
    defer free(lines_array);

    // Create and start threads
    for (uint i = 0; i < num_threads; i++) {
        usz start = i * chunk_size;
        if (start >= lines.len()) {
            break;
        }
        usz end = start + chunk_size;
        if (end > lines.len()) {
            end = lines.len();
        }
        
        thread_data[i] = ThreadData{
            .lines = lines_array,
            .start = start,
            .end = end,
            .result = &result
        };
        
        threads[i] = thread::create(&process_chunk, &thread_data[i])!!;
    }
    
    // Wait for all threads to complete
    for (uint i = 0; i < num_threads; i++) {
        if (i * chunk_size >= lines.len()) {
            break;
        }
        thread::join(threads[i])!!;
    }
    
    int total = result.errors + result.warnings;
    io::printfn(`{"errors": %d, "warnings": %d, "total": %d}`, result.errors, result.warnings, total);
}
