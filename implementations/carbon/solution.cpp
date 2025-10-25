#include <atomic>
#include <cctype>
#include <cstring>
#include <fstream>
#include <iostream>
#include <string>
#include <thread>
#include <vector>

namespace {
constexpr const char* kErrorToken = "ERROR";
constexpr const char* kWarnToken = "WARN";

inline bool IsAsciiAlnum(unsigned char c) {
  return (c >= '0' && c <= '9') || (c >= 'A' && c <= 'Z') ||
         (c >= 'a' && c <= 'z');
}

bool ContainsWord(const std::string& line, const char* word) {
  const size_t needle = std::strlen(word);
  const size_t haystack = line.size();
  if (needle == 0 || haystack < needle) {
    return false;
  }
  size_t start = 0;
  while (true) {
    size_t idx = line.find(word, start);
    if (idx == std::string::npos) {
      return false;
    }
    const long before = static_cast<long>(idx) - 1;
    const size_t after = idx + needle;
    const bool start_ok = before < 0 || !IsAsciiAlnum(line[before]);
    const bool end_ok = after >= haystack || !IsAsciiAlnum(line[after]);
    if (start_ok && end_ok) {
      return true;
    }
    start = idx + 1;
  }
}

void ProcessChunk(const std::vector<std::string>& lines, size_t begin,
                  size_t end, std::atomic<int>& errors,
                  std::atomic<int>& warnings) {
  int local_errors = 0;
  int local_warnings = 0;
  for (size_t i = begin; i < end; ++i) {
    const std::string& line = lines[i];
    if (ContainsWord(line, kErrorToken)) {
      ++local_errors;
    } else if (ContainsWord(line, kWarnToken)) {
      ++local_warnings;
    }
  }
  errors.fetch_add(local_errors, std::memory_order_relaxed);
  warnings.fetch_add(local_warnings, std::memory_order_relaxed);
}
}  // namespace

int main(int argc, char* argv[]) {
  if (argc != 2) {
    std::cerr << "Usage: " << argv[0] << " <logfile>" << std::endl;
    return 1;
  }

  std::ifstream input(argv[1]);
  if (!input.is_open()) {
    std::cerr << "Error: Cannot open file " << argv[1] << std::endl;
    return 1;
  }

  std::vector<std::string> lines;
  std::string buffer;
  while (std::getline(input, buffer)) {
    lines.push_back(buffer);
  }

  if (lines.empty()) {
    std::cout << "{\"errors\": 0, \"warnings\": 0, \"total\": 0}" << std::endl;
    return 0;
  }

  unsigned int threads = std::thread::hardware_concurrency();
  if (threads == 0) {
    threads = 4;
  }
  if (threads > lines.size()) {
    threads = static_cast<unsigned int>(lines.size());
  }

  const size_t chunk = (lines.size() + threads - 1) / threads;
  std::vector<std::thread> pool;
  pool.reserve(threads);

  std::atomic<int> errors{0};
  std::atomic<int> warnings{0};

  for (unsigned int t = 0; t < threads; ++t) {
    const size_t begin = t * chunk;
    if (begin >= lines.size()) {
      break;
    }
    const size_t end = std::min(lines.size(), begin + chunk);
    pool.emplace_back(ProcessChunk, std::cref(lines), begin, end,
                      std::ref(errors), std::ref(warnings));
  }

  for (auto& worker : pool) {
    worker.join();
  }

  const int total = errors.load(std::memory_order_relaxed) +
                    warnings.load(std::memory_order_relaxed);
  std::cout << "{\"errors\": " << errors << ", \"warnings\": " << warnings
            << ", \"total\": " << total << "}" << std::endl;
  return 0;
}
