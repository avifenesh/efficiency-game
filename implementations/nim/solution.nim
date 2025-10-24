import os, strutils, json, threadpool

type
  WorkerResult = tuple[errors: int, warnings: int]

proc isAsciiAlnum(c: char): bool =
  (c >= '0' and c <= '9') or (c >= 'A' and c <= 'Z') or (c >= 'a' and c <= 'z')

proc containsWord(line: string, word: string): bool =
  let n = word.len
  let m = line.len
  if n == 0 or m < n:
    return false

  var start = 0
  while start <= m - n:
    let idx = line.find(word, start)
    if idx == -1:
      return false

    let before = idx - 1
    let after = idx + n
    let startOk = before < 0 or not isAsciiAlnum(line[before])
    let endOk = after >= m or not isAsciiAlnum(line[after])

    if startOk and endOk:
      return true

    start = idx + 1

  return false

proc processChunk(lines: seq[string], startIdx: int, endIdx: int): WorkerResult =
  var errors = 0
  var warnings = 0

  for i in startIdx..endIdx:
    if containsWord(lines[i], "ERROR"):
      errors += 1
    elif containsWord(lines[i], "WARN"):
      warnings += 1

  return (errors, warnings)

proc main() =
  if paramCount() != 1:
    stderr.writeLine("Usage: solution <logfile>")
    quit(1)

  let logfile = paramStr(1)

  if not fileExists(logfile):
    stderr.writeLine("Error: File not found: " & logfile)
    quit(1)

  # Read all lines
  let lines = readFile(logfile).splitLines()
  let n = lines.len

  if n == 0:
    echo """{"errors": 0, "warnings": 0, "total": 0}"""
    quit(0)

  # Use 4 threads for processing
  const numThreads = 4
  let chunkSize = (n + numThreads - 1) div numThreads

  var results: array[numThreads, FlowVar[WorkerResult]]
  var threadCount = 0

  for t in 0..<numThreads:
    let startIdx = t * chunkSize
    if startIdx >= n:
      break

    let endIdx = min((t + 1) * chunkSize - 1, n - 1)
    results[t] = spawn processChunk(lines, startIdx, endIdx)
    threadCount += 1

  # Collect results
  var totalErrors = 0
  var totalWarnings = 0

  for t in 0..<threadCount:
    let (errors, warnings) = ^results[t]
    totalErrors += errors
    totalWarnings += warnings

  let total = totalErrors + totalWarnings
  let jsonObj = %* {"errors": totalErrors, "warnings": totalWarnings, "total": total}
  echo $jsonObj

when isMainModule:
  main()
