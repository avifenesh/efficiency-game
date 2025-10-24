using Printf

function main()
    if length(ARGS) != 1
        println(stderr, "Usage: julia solution.jl <logfile>")
        exit(1)
    end

    logfile = ARGS[1]
    errors = 0
    warnings = 0

    for line in eachline(logfile)
        if contains_word(line, "ERROR")
            errors += 1
        elseif contains_word(line, "WARN")
            warnings += 1
        end
    end

    total = errors + warnings
    @printf("{\"errors\": %d, \"warnings\": %d, \"total\": %d}\n", errors, warnings, total)
end

@inline function is_ascii_alnum(c::Char)
    return ('0' <= c <= '9') || ('A' <= c <= 'Z') || ('a' <= c <= 'z')
end

function contains_word(line::AbstractString, word::AbstractString)
    n = lastindex(word)
    m = lastindex(line)
    if n == 0 || m < n
        return false
    end
    start = firstindex(line)
    while true
        idx = findnext(word, line, start)
        if idx === nothing
            return false
        end
        before = prevind(line, idx)
        after = nextind(line, idx + n - 1)
        start_ok = (idx == firstindex(line)) || !is_ascii_alnum(line[before])
        end_ok = (after > lastindex(line)) || !is_ascii_alnum(line[after])
        if start_ok && end_ok
            return true
        end
        start = nextind(line, idx)
    end
end

main()
