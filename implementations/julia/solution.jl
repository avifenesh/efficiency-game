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

@inline function is_ascii_alnum(c::Char)
    return ('0' <= c <= '9') || ('A' <= c <= 'Z') || ('a' <= c <= 'z')
end

function contains_word(line::AbstractString, word::AbstractString)
    n = length(word)
    m = length(line)
    if n == 0 || m < n
        return false
    end
    start = 1
    while start <= m - n + 1
        idx = findnext(word, line, start)
        if idx === nothing
            return false
        end
        # idx is a range, get the first index
        first_idx = first(idx)
        last_idx = last(idx)
        before = first_idx - 1
        after = last_idx + 1
        start_ok = (before < 1) || !is_ascii_alnum(line[before])
        end_ok = (after > m) || !is_ascii_alnum(line[after])
        if start_ok && end_ok
            return true
        end
        start = first_idx + 1
    end
    return false
end

function process_chunk(lines::Vector{String}, start_idx::Int, end_idx::Int)
    errors = 0
    warnings = 0
    for i in start_idx:end_idx
        line = lines[i]
        if contains_word(line, "ERROR")
            errors += 1
        elseif contains_word(line, "WARN")
            warnings += 1
        end
    end
    return errors, warnings
end

function process_log_file(logfile::AbstractString)
    lines = readlines(logfile)
    n = length(lines)
    if n == 0
        return 0, 0
    end

    nthreads = min(Threads.nthreads(), n)
    chunk_size = cld(n, nthreads)
    tasks = Task[]

    for t in 1:nthreads
        start_idx = (t - 1) * chunk_size + 1
        if start_idx > n
            break
        end
        end_idx = min(t * chunk_size, n)
        task = Threads.@spawn process_chunk(lines, start_idx, end_idx)
        push!(tasks, task)
    end

    total_errors = 0
    total_warnings = 0
    for task in tasks
        errors, warnings = fetch(task)
        total_errors += errors
        total_warnings += warnings
    end

    return total_errors, total_warnings
end

main()
