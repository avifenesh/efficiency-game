#!/usr/bin/env lua
--[[
Lua Concurrent Log Anomaly Counter

Uses LuaLanes for parallel processing
]]

local lanes = require("lanes").configure()
local json = require("dkjson")

-- Helper function to check if byte is alphanumeric
local function is_alnum(byte)
    return (byte >= 48 and byte <= 57) or   -- 0-9
           (byte >= 65 and byte <= 90) or   -- A-Z
           (byte >= 97 and byte <= 122)     -- a-z
end

-- Check if word exists with word boundaries
local function contains_word(line, word)
    local len_word = #word
    local len_line = #line
    
    if len_word == 0 or len_line < len_word then
        return false
    end
    
    local start = 1
    while true do
        local idx = string.find(line, word, start, true)
        if not idx then
            return false
        end
        
        local before = idx - 1
        local after = idx + len_word
        
        local start_ok = before < 1 or not is_alnum(string.byte(line, before))
        local end_ok = after > len_line or not is_alnum(string.byte(line, after))
        
        if start_ok and end_ok then
            return true
        end
        
        start = idx + 1
    end
end

-- Worker function to process a chunk of lines
local function process_chunk(lines)
    local errors = 0
    local warnings = 0
    
    for _, line in ipairs(lines) do
        if string.find(line, "E", 1, true) and contains_word(line, "ERROR") then
            errors = errors + 1
        elseif string.find(line, "W", 1, true) and contains_word(line, "WARN") then
            warnings = warnings + 1
        end
    end
    
    return {errors, warnings}
end

-- Main processing function
local function process_log_file(filepath)
    -- Read all lines
    local file = io.open(filepath, "r")
    if not file then
        io.stderr:write("Error: Cannot open file: " .. filepath .. "\n")
        os.exit(1)
    end
    
    local lines = {}
    for line in file:lines() do
        table.insert(lines, line)
    end
    file:close()
    
    if #lines == 0 then
        return 0, 0
    end
    
    -- Determine number of workers (use 4 for Lua)
    local num_workers = 4
    local chunk_size = math.ceil(#lines / num_workers)
    
    -- Create chunks and spawn workers
    local workers = {}
    for i = 1, num_workers do
        local start_idx = (i - 1) * chunk_size + 1
        local end_idx = math.min(i * chunk_size, #lines)
        
        if start_idx <= #lines then
            local chunk = {}
            for j = start_idx, end_idx do
                table.insert(chunk, lines[j])
            end
            
            local worker = lanes.gen("*", process_chunk)(chunk)
            table.insert(workers, worker)
        end
    end
    
    -- Collect results
    local total_errors = 0
    local total_warnings = 0
    
    for _, worker in ipairs(workers) do
        local result = worker[1]
        total_errors = total_errors + result[1]
        total_warnings = total_warnings + result[2]
    end
    
    return total_errors, total_warnings
end

-- Main entry point
local function main()
    if #arg ~= 1 then
        io.stderr:write("Usage: lua solution.lua <logfile>\n")
        os.exit(1)
    end
    
    local logfile = arg[1]
    
    -- Check if file exists
    local file = io.open(logfile, "r")
    if not file then
        io.stderr:write("Error: File not found: " .. logfile .. "\n")
        os.exit(1)
    end
    file:close()
    
    local errors, warnings = process_log_file(logfile)
    local total = errors + warnings
    
    -- Output JSON
    local result = {
        errors = errors,
        warnings = warnings,
        total = total
    }
    
    local json_output = json.encode(result, {indent = false})
    print(json_output)
    os.exit(0)
end

main()
