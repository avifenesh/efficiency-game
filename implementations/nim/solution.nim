import os, json, threadpool, std/cpuinfo, strutils

type
  WorkerResult = tuple[errors: int, warnings: int]

{.push inline.}
proc isAsciiAlnum(c: char): bool =
  (c >= '0' and c <= '9') or (c >= 'A' and c <= 'Z') or (c >= 'a' and c <= 'z')
{.pop.}

# Import C's strstr for optimized string search
proc c_strstr(haystack, needle: cstring): cstring {.importc: "strstr", header: "<string.h>".}

proc containsWord(line: string, word: string): bool =
  let wordCstr = cstring(word)
  let lineCstr = cstring(line)
  let n = word.len
  let m = line.len

  if n == 0 or m < n:
    return false

  # Use C's strstr which is often SIMD-optimized
  var pos = c_strstr(lineCstr, wordCstr)
  while pos != nil:
    let idx = cast[int](pos) - cast[int](lineCstr)
    let before = idx - 1
    let after = idx + n
    let startOk = before < 0 or not isAsciiAlnum(line[before])
    let endOk = after >= m or not isAsciiAlnum(line[after])

    if startOk and endOk:
      return true

    # Search from next position
    pos = c_strstr(cast[cstring](cast[int](pos) + 1), wordCstr)

  return false

proc processChunk(lines: seq[string], startIdx: int, endIdx: int): WorkerResult =
  var errors = 0
  var warnings = 0

  for i in startIdx..endIdx:
    let line = lines[i]
    # Early exit: check if chars exist before expensive boundary check
    if 'E' in line and containsWord(line, "ERROR"):
      errors += 1
    elif 'W' in line and containsWord(line, "WARN"):
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

  # Use CPU count for thread pool
  let numThreads = min(max(1, countProcessors()), n)
  let chunkSize = (n + numThreads - 1) div numThreads

  var results = newSeq[FlowVar[WorkerResult]](numThreads)
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
