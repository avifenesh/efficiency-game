/*
 * C Concurrent Log Anomaly Counter
 * Uses pthreads for parallel processing
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>
#include <unistd.h>

#define MAX_LINE_LENGTH 1024

typedef struct {
    char **lines;
    int start;
    int end;
    int errors;
    int warnings;
} ThreadData;

int contains_word(const char *line, const char *word) {
    const char *pos = strstr(line, word);
    if (pos == NULL) return 0;
    
    int len = strlen(word);
    int start_ok = (pos == line || !((pos[-1] >= 'A' && pos[-1] <= 'Z') || 
                                      (pos[-1] >= 'a' && pos[-1] <= 'z') ||
                                      (pos[-1] >= '0' && pos[-1] <= '9')));
    int end_ok = (pos[len] == '\0' || !((pos[len] >= 'A' && pos[len] <= 'Z') || 
                                         (pos[len] >= 'a' && pos[len] <= 'z') ||
                                         (pos[len] >= '0' && pos[len] <= '9')));
    
    return start_ok && end_ok;
}

void* process_chunk(void *arg) {
    ThreadData *data = (ThreadData*)arg;
    data->errors = 0;
    data->warnings = 0;
    
    for (int i = data->start; i < data->end; i++) {
        if (contains_word(data->lines[i], "ERROR")) {
            data->errors++;
        } else if (contains_word(data->lines[i], "WARN")) {
            data->warnings++;
        }
    }
    
    return NULL;
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <logfile>\n", argv[0]);
        return 1;
    }
    
    FILE *file = fopen(argv[1], "r");
    if (file == NULL) {
        fprintf(stderr, "Error: Cannot open file %s\n", argv[1]);
        return 1;
    }
    
    char **lines = NULL;
    int num_lines = 0;
    int capacity = 100000;
    lines = (char**)malloc(capacity * sizeof(char*));
    
    char buffer[MAX_LINE_LENGTH];
    while (fgets(buffer, sizeof(buffer), file)) {
        if (num_lines >= capacity) {
            capacity *= 2;
            lines = (char**)realloc(lines, capacity * sizeof(char*));
        }
        
        int len = strlen(buffer);
        if (len > 0 && buffer[len-1] == '\n') {
            buffer[len-1] = '\0';
        }
        
        lines[num_lines] = strdup(buffer);
        num_lines++;
    }
    fclose(file);
    
    int num_threads = sysconf(_SC_NPROCESSORS_ONLN);
    if (num_threads < 1) num_threads = 4;
    if (num_threads > num_lines) num_threads = num_lines;
    
    pthread_t *threads = (pthread_t *)malloc(num_threads * sizeof(pthread_t));
    ThreadData *thread_data = (ThreadData *)malloc(num_threads * sizeof(ThreadData));
    
    int lines_per_thread = num_lines / num_threads;
    
    for (int i = 0; i < num_threads; i++) {
        thread_data[i].lines = lines;
        thread_data[i].start = i * lines_per_thread;
        thread_data[i].end = (i == num_threads - 1) ? num_lines : (i + 1) * lines_per_thread;
        pthread_create(&threads[i], NULL, process_chunk, &thread_data[i]);
    }
    
    int total_errors = 0;
    int total_warnings = 0;
    
    for (int i = 0; i < num_threads; i++) {
        pthread_join(threads[i], NULL);
        total_errors += thread_data[i].errors;
        total_warnings += thread_data[i].warnings;
    }
    
    printf("{\"errors\": %d, \"warnings\": %d, \"total\": %d}\n", 
           total_errors, total_warnings, total_errors + total_warnings);
    
    for (int i = 0; i < num_lines; i++) {
        free(lines[i]);
    }
    free(lines);
    free(threads);
    free(thread_data);
    
    return 0;
}
