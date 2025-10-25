package main

import (
    "bufio"
    "encoding/json"
    "fmt"
    "os"
    "runtime"
    "strings"
    "sync"
    "sync/atomic"
)

type result struct {
    Errors   int `json:"errors"`
    Warnings int `json:"warnings"`
    Total    int `json:"total"`
}

func isAsciiAlnum(b byte) bool {
    return (b >= '0' && b <= '9') || (b >= 'A' && b <= 'Z') || (b >= 'a' && b <= 'z')
}

func containsWord(line, word string) bool {
    if len(word) == 0 || len(line) < len(word) {
        return false
    }
    lower := 0
    for {
        idx := strings.Index(line[lower:], word)
        if idx == -1 {
            return false
        }
        idx += lower
        before := idx - 1
        after := idx + len(word)
        startOk := before < 0 || !isAsciiAlnum(line[before])
        endOk := after >= len(line) || !isAsciiAlnum(line[after])
        if startOk && endOk {
            return true
        }
        lower = idx + 1
        if lower >= len(line) {
            return false
        }
    }
}

func worker(lines []string, start, end int, wg *sync.WaitGroup, errors, warnings *int64) {
    defer wg.Done()
    var localErrors, localWarnings int64
    for i := start; i < end; i++ {
        line := lines[i]
        if strings.IndexByte(line, 'E') != -1 && containsWord(line, "ERROR") {
            localErrors++
        } else if strings.IndexByte(line, 'W') != -1 && containsWord(line, "WARN") {
            localWarnings++
        }
    }
    if localErrors != 0 {
        atomic.AddInt64(errors, localErrors)
    }
    if localWarnings != 0 {
        atomic.AddInt64(warnings, localWarnings)
    }
}

func main() {
    if len(os.Args) != 2 {
        fmt.Fprintln(os.Stderr, "Usage: solution <logfile>")
        os.Exit(1)
    }

    file, err := os.Open(os.Args[1])
    if err != nil {
        fmt.Fprintf(os.Stderr, "Error: %v\n", err)
        os.Exit(1)
    }
    defer file.Close()

    scanner := bufio.NewScanner(file)
    buf := make([]byte, 0, 1024)
    scanner.Buffer(buf, 1<<20) // allow up to ~1MB lines
    lines := make([]string, 0, 1024)
    for scanner.Scan() {
        lines = append(lines, scanner.Text())
    }
    if err := scanner.Err(); err != nil {
        fmt.Fprintf(os.Stderr, "Error reading file: %v\n", err)
        os.Exit(1)
    }

    if len(lines) == 0 {
        output := result{}
        json.NewEncoder(os.Stdout).Encode(output)
        return
    }

    workers := runtime.NumCPU()
    if workers < 1 {
        workers = 1
    }
    if workers > len(lines) {
        workers = len(lines)
    }

    chunk := (len(lines) + workers - 1) / workers
    var wg sync.WaitGroup
    var errors, warnings int64

    for i := 0; i < workers; i++ {
        start := i * chunk
        if start >= len(lines) {
            break
        }
        end := start + chunk
        if end > len(lines) {
            end = len(lines)
        }
        wg.Add(1)
        go worker(lines, start, end, &wg, &errors, &warnings)
    }

    wg.Wait()

    output := result{
        Errors:   int(errors),
        Warnings: int(warnings),
        Total:    int(errors + warnings),
    }
    encoded, _ := json.Marshal(output)
    fmt.Println(string(encoded))
}
