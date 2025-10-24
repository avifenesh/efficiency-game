require 'json'
require 'etc'

if ARGV.length != 1
  STDERR.puts "Usage: ruby solution.rb <logfile>"
  exit 1
end

logfile = ARGV[0]

unless File.exist?(logfile)
  STDERR.puts "Error: File not found: #{logfile}"
  exit 1
end

def ascii_alnum?(ch)
  ch >= '0' && ch <= '9' || ch >= 'A' && ch <= 'Z' || ch >= 'a' && ch <= 'z'
end

def contains_word(line, word)
  idx = -1
  n = word.length
  while (idx = line.index(word, idx + 1))
    before = idx - 1
    after = idx + n
    start_ok = before < 0 || !ascii_alnum?(line[before])
    end_ok = after >= line.length || !ascii_alnum?(line[after])
    return true if start_ok && end_ok
  end
  false
end

lines = File.foreach(logfile, chomp: true).to_a
if lines.empty?
  puts JSON.generate({ errors: 0, warnings: 0, total: 0 })
  exit 0
end

worker_count = [Etc.nprocessors, lines.length].min
chunk_size = (lines.length.to_f / worker_count).ceil

threads = []
results = []
mutex = Mutex.new

lines.each_slice(chunk_size).with_index do |chunk, i|
  threads << Thread.new do
    local_errors = 0
    local_warnings = 0
    chunk.each do |line|
      if contains_word(line, "ERROR")
        local_errors += 1
      elsif contains_word(line, "WARN")
        local_warnings += 1
      end
    end
    mutex.synchronize do
      results[i] = [local_errors, local_warnings]
    end
  end
end

threads.each(&:join)

errors = results.sum { |r| r[0] }
warnings = results.sum { |r| r[1] }
total = errors + warnings

puts JSON.generate({ errors: errors, warnings: warnings, total: total })
