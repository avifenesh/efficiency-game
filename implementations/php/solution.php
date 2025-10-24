<?php

if ($argc !== 2) {
    fwrite(STDERR, "Usage: php solution.php <logfile>\n");
    exit(1);
}

$logfile = $argv[1];

if (!file_exists($logfile)) {
    fwrite(STDERR, "Error: File not found: $logfile\n");
    exit(1);
}

function isAsciiAlnum($c) {
    return ($c >= '0' && $c <= '9') || ($c >= 'A' && $c <= 'Z') || ($c >= 'a' && $c <= 'z');
}

function containsWord($line, $word) {
    $n = strlen($word);
    $m = strlen($line);

    if ($n === 0 || $m < $n) {
        return false;
    }

    $start = 0;
    while (true) {
        $idx = strpos($line, $word, $start);
        if ($idx === false) {
            return false;
        }

        $before = $idx - 1;
        $after = $idx + $n;
        $startOk = $before < 0 || !isAsciiAlnum($line[$before]);
        $endOk = $after >= $m || !isAsciiAlnum($line[$after]);

        if ($startOk && $endOk) {
            return true;
        }

        $start = $idx + 1;
    }

    return false;
}

function processChunk($lines, $startIdx, $endIdx) {
    $errors = 0;
    $warnings = 0;

    for ($i = $startIdx; $i <= $endIdx; $i++) {
        if (containsWord($lines[$i], 'ERROR')) {
            $errors++;
        } elseif (containsWord($lines[$i], 'WARN')) {
            $warnings++;
        }
    }

    return [$errors, $warnings];
}

// Read all lines
$lines = file($logfile, FILE_IGNORE_NEW_LINES);
$n = count($lines);

if ($n === 0) {
    echo json_encode(['errors' => 0, 'warnings' => 0, 'total' => 0]) . "\n";
    exit(0);
}

// Check if parallel extension is available
if (extension_loaded('parallel')) {
    $numThreads = 4;
    $chunkSize = (int)ceil($n / $numThreads);
    $futures = [];

    for ($t = 0; $t < $numThreads; $t++) {
        $startIdx = $t * $chunkSize;
        if ($startIdx >= $n) {
            break;
        }
        $endIdx = min(($t + 1) * $chunkSize - 1, $n - 1);

        $runtime = new \parallel\Runtime();
        $chunk = array_slice($lines, $startIdx, $endIdx - $startIdx + 1);

        $futures[] = $runtime->run(function($chunk) {
            $errors = 0;
            $warnings = 0;

            foreach ($chunk as $line) {
                if (strpos($line, 'ERROR') !== false) {
                    $errors++;
                } elseif (strpos($line, 'WARN') !== false) {
                    $warnings++;
                }
            }

            return [$errors, $warnings];
        }, [$chunk]);
    }

    $totalErrors = 0;
    $totalWarnings = 0;

    foreach ($futures as $future) {
        list($errors, $warnings) = $future->value();
        $totalErrors += $errors;
        $totalWarnings += $warnings;
    }
} else {
    // Fallback: single-threaded processing
    list($totalErrors, $totalWarnings) = processChunk($lines, 0, $n - 1);
}

$total = $totalErrors + $totalWarnings;
echo json_encode(['errors' => $totalErrors, 'warnings' => $totalWarnings, 'total' => $total]) . "\n";
