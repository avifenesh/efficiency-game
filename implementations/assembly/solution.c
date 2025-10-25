/*
 * Assembly-style C implementation
 * Low-level implementation using minimal abstractions
 * Optimized for performance with manual memory management
 */

#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/mman.h>

#define ERROR_LEN 5
#define WARN_LEN 4

static inline int is_alnum(char c) {
    return (c >= '0' && c <= '9') || (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z');
}

static inline int contains_word(const char *line, const char *word, int word_len) {
    const char *p = line;

    while (*p) {
        // Find first character
        while (*p && *p != word[0]) p++;
        if (!*p) return 0;

        // Check full word match
        const char *w = word;
        const char *l = p;
        int matched = 1;

        while (*w) {
            if (*l != *w) {
                matched = 0;
                break;
            }
            l++;
            w++;
        }

        if (matched) {
            // Check word boundaries
            int before_ok = (p == line) || !is_alnum(*(p - 1));
            int after_ok = !*l || !is_alnum(*l);

            if (before_ok && after_ok) return 1;
        }

        p++;
    }

    return 0;
}

static inline int has_char(const char *line, char c) {
    while (*line) {
        if (*line == c) return 1;
        line++;
    }
    return 0;
}

int main(int argc, char **argv) {
    if (argc != 2) {
        write(2, "Usage: solution <logfile>\n", 26);
        return 1;
    }

    // Open file
    int fd = open(argv[1], O_RDONLY);
    if (fd < 0) {
        write(2, "Error: Cannot open file\n", 24);
        return 1;
    }

    // Get file size
    struct stat st;
    if (fstat(fd, &st) < 0) {
        close(fd);
        return 1;
    }

    // Memory map file for fast access
    char *data = mmap(NULL, st.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
    if (data == MAP_FAILED) {
        close(fd);
        return 1;
    }

    int errors = 0;
    int warnings = 0;

    // Process file line by line
    char *line_start = data;
    char *p = data;
    char *end = data + st.st_size;
    char line_buf[4096];

    while (p < end) {
        // Find end of line
        char *line_end = p;
        while (line_end < end && *line_end != '\n') {
            line_end++;
        }

        // Copy line to buffer and null terminate
        int line_len = line_end - line_start;
        if (line_len >= 4096) line_len = 4095;

        char *dst = line_buf;
        char *src = line_start;
        for (int i = 0; i < line_len; i++) {
            *dst++ = *src++;
        }
        *dst = '\0';

        // Quick check for E or W before expensive word check
        if (has_char(line_buf, 'E')) {
            if (contains_word(line_buf, "ERROR", ERROR_LEN)) {
                errors++;
                goto next_line;
            }
        }

        if (has_char(line_buf, 'W')) {
            if (contains_word(line_buf, "WARN", WARN_LEN)) {
                warnings++;
            }
        }

next_line:
        if (line_end < end) {
            p = line_end + 1;
        } else {
            break;
        }
        line_start = p;
    }

    // Cleanup
    munmap(data, st.st_size);
    close(fd);

    // Output JSON
    int total = errors + warnings;
    printf("{\"errors\": %d, \"warnings\": %d, \"total\": %d}\n", errors, warnings, total);

    return 0;
}
