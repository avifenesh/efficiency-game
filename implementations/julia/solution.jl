using Printf
using Base.Threads

function main()
    if length(ARGS) != 1
        println(stderr, "Usage: julia solution.jl <logfile>")
        exit(1)
    end

    logfile = ARGS[1]
    errors, warnings = process_log_file(logfile)

    total = errors + warnings
    @printf("{\"errors\": %d, \"warnings\": %d, \"total\": %d}\n", errors, warnings, total)
end

@inline function is_ascii_alnum(b::UInt8)
    return (UInt8('0') <= b <= UInt8('9')) ||
           (UInt8('A') <= b <= UInt8('Z')) ||
           (UInt8('a') <= b <= UInt8('z'))
end

function contains_word(line::String, word::String)
    line_bytes = codeunits(line)
    word_bytes = codeunits(word)
    word_len = length(word_bytes)
    line_len = length(line_bytes)

    if word_len == 0 || line_len < word_len
        return false
    end

    i = 1
    @inbounds while i <= line_len - word_len + 1
        # Check for match
        matched = true
        for j in 1:word_len
            if line_bytes[i + j - 1] != word_bytes[j]
                matched = false
                break
            end
        end

        if matched
            # Check boundaries
            before_ok = (i == 1) || !is_ascii_alnum(line_bytes[i - 1])
            after = i + word_len
            after_ok = (after > line_len) || !is_ascii_alnum(line_bytes[after])

            if before_ok && after_ok
                return true
            end
        end
        i += 1
    end
    return false
end

function process_log_file(logfile::String)
    lines = readlines(logfile)
    n = length(lines)
    if n == 0
        return 0, 0
    end

    nthreads = min(Threads.nthreads(), n)

    # Preallocate results arrays to avoid race conditions
    errors_per_thread = zeros(Int, nthreads)
    warnings_per_thread = zeros(Int, nthreads)

    Threads.@threads for tid in 1:nthreads
        chunk_size = cld(n, nthreads)
        start_idx = (tid - 1) * chunk_size + 1
        if start_idx > n
            continue
        end
        end_idx = min(tid * chunk_size, n)

        local_errors = 0
        local_warnings = 0

        @inbounds for i in start_idx:end_idx
            line = lines[i]
            if contains_word(line, "ERROR")
                local_errors += 1
            elseif contains_word(line, "WARN")
                local_warnings += 1
            end
        end

        errors_per_thread[tid] = local_errors
        warnings_per_thread[tid] = local_warnings
    end

    return sum(errors_per_thread), sum(warnings_per_thread)
end

main()
