# C3 Implementation

## About C3

C3 is a systems programming language based on C, designed to be an evolution of C rather than a completely new language. It aims to provide modern features while maintaining C's simplicity and performance characteristics.

**Website**: https://c3-lang.org/

## Features

- **Modern Syntax**: Improved C syntax with better readability
- **Safety Features**: Optional safety checks and better error handling
- **Module System**: Built-in module system
- **Defer Statements**: Automatic resource cleanup
- **Generic Programming**: Compile-time generics
- **Performance**: Compiles to native code with LLVM backend

## Implementation Details

### Concurrency Approach
Single-threaded. Reads the file line by line with `io::treadline` and keeps running counts.

### Pattern Matching
- Manual string search with word boundary checking
- No regex overhead for maximum performance
- Efficient character-by-character comparison
- Skips the word check when a line has no `E` or `W`

### Memory Management
- Reads one line at a time into the temp allocator
- The file is closed explicitly after the loop

## Requirements

### Installation

Download and install C3 from the official website:
- macOS: Download from https://c3-lang.org/
- Linux: Follow installation instructions at https://c3-lang.org/
- Building from source: https://github.com/c3lang/c3c

### Verify Installation

```bash
c3c --version
```

## Building

```bash
cd implementations/c3
./build.sh
```

This compiles the C3 solution with `-O5` optimization level.

## Running

```bash
./run.sh ../../data/synthetic/medium.log
```

Output format:
```json
{"errors": 123, "warnings": 456, "total": 579}
```

## Performance Characteristics

**Expected Performance:**
- **Speed**: Very fast - comparable to C/C++/Rust
- **Memory**: Low memory footprint
- **CPU**: One core (no threads)

C3 is a compiled language that generates native code through LLVM, so it should perform similarly to C and C++ implementations.

## Code Structure

```c3
module solution;

// Main components:
// 1. is_alnum() - Character classification
// 2. contains_word() - Pattern matching with boundaries
// 3. main() - File reading, counting and JSON output
```

## Notes

- C3 is a relatively new language, so the ecosystem is still developing
- The implementation is sequential and uses no threads
- Word boundary checking is manual for performance

## Troubleshooting

**Build fails with "c3c: command not found"**
- Install C3 from https://c3-lang.org/
- Ensure c3c is in your PATH

**Runtime errors**
- Check that the log file path is correct
- Verify the compiled `solution` binary exists
- Run `./build.sh` first if needed

## Comparison with C

C3 offers several improvements over C while maintaining similar performance:

| Feature | C | C3 |
|---------|---|-----|
| Memory Safety | Manual | Optional checks |
| Error Handling | Return codes | Optionals (`?`) |
| Modules | Header files | Built-in modules |
| Generics | Macros | Compile-time generics |
| Resource Cleanup | Manual | `defer` statements |
| Performance | Excellent | Excellent (LLVM) |

## References

- C3 Documentation: https://c3-lang.org/getting-started/introduction/
- C3 GitHub: https://github.com/c3lang/c3c
- Language Specification: https://c3-lang.org/implementation-details/specification/
