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

# Pre-compiled frozen regex patterns for optimal performance
ERROR_REGEX = /\bERROR\b/.freeze
WARN_REGEX = /\bWARN\b/.freeze

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
      if ERROR_REGEX.match?(line)
        local_errors += 1
      elsif WARN_REGEX.match?(line)
        local_warnings += 1
      end
    end
    mutex.synchronize do
      results[i] = [local_errors, local_warnings]
    end
  end
end

threads.each(&:join)

# Direct iteration is faster than sum with block for small result sets
errors = 0
warnings = 0
results.each do |r|
  errors += r[0]
  warnings += r[1]
end
total = errors + warnings

puts JSON.generate({ errors: errors, warnings: warnings, total: total })
