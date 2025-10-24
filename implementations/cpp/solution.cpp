#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <thread>
#include <atomic>
#include <numeric>

static inline bool is_alnum(unsigned char c) {
    return (c >= '0' && c <= '9') || (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z');
}

static bool contains_word(const std::string& line, const char* word) {
    const size_t n = std::strlen(word);
    const size_t m = line.size();
    if (n == 0 || m < n) return false;
    size_t start = 0;
    while (true) {
        size_t idx = line.find(word, start);
        if (idx == std::string::npos) return false;
        long before = static_cast<long>(idx) - 1;
        size_t after = idx + n;
        bool start_ok = (before < 0) || !is_alnum(static_cast<unsigned char>(line[before]));
        bool end_ok = (after >= m) || !is_alnum(static_cast<unsigned char>(line[after]));
        if (start_ok && end_ok) return true;
        start = idx + 1;
    }
}

void process_chunk(const std::vector<std::string>& lines, size_t start, size_t end, std::atomic<int>& errors, std::atomic<int>& warnings) {
    int local_errors = 0;
    int local_warnings = 0;
    for (size_t i = start; i < end; ++i) {
        const std::string& s = lines[i];
        if (contains_word(s, "ERROR")) {
            local_errors++;
        } else if (contains_word(s, "WARN")) {
            local_warnings++;
        }
    }
    errors += local_errors;
    warnings += local_warnings;
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::cerr << "Usage: " << argv[0] << " <logfile>" << std::endl;
        return 1;
    }

    std::ifstream file(argv[1]);
    if (!file.is_open()) {
        std::cerr << "Error: Cannot open file " << argv[1] << std::endl;
        return 1;
    }

    std::vector<std::string> lines;
    std::string line;
    while (std::getline(file, line)) {
        lines.push_back(line);
    }

    unsigned int num_threads = std::thread::hardware_concurrency();
    if (num_threads == 0) {
        num_threads = 4;
    }
    if (num_threads > lines.size()) {
        num_threads = lines.size();
    }

    std::vector<std::thread> threads;
    std::atomic<int> total_errors(0);
    std::atomic<int> total_warnings(0);
    size_t chunk_size = lines.size() / num_threads;

    for (unsigned int i = 0; i < num_threads; ++i) {
        size_t start = i * chunk_size;
        size_t end = (i == num_threads - 1) ? lines.size() : (i + 1) * chunk_size;
        threads.emplace_back(process_chunk, std::ref(lines), start, end, std::ref(total_errors), std::ref(total_warnings));
    }

    for (auto& t : threads) {
        t.join();
    }

    int total = total_errors + total_warnings;
    std::cout << "{\"errors\": " << total_errors << ", \"warnings\": " << total_warnings << ", \"total\": " << total << "}" << std::endl;

    return 0;
}
