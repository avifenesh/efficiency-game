require 'json'

if ARGV.length != 1
  STDERR.puts "Usage: ruby solution.rb <logfile>"
  exit 1
end

logfile = ARGV[0]
errors = 0
warnings = 0

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

File.foreach(logfile) do |line|
  if contains_word(line, "ERROR")
    errors += 1
  elsif contains_word(line, "WARN")
    warnings += 1
  end
end

total = errors + warnings
puts JSON.generate({ errors: errors, warnings: warnings, total: total })
