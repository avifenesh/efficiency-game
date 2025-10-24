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

$lines = file($logfile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
$n = count($lines);

if ($n === 0) {
    echo json_encode(['errors' => 0, 'warnings' => 0, 'total' => 0]) . "\n";
    exit(0);
}

$totalErrors = 0;
$totalWarnings = 0;

for ($i = 0; $i < $n; $i++) {
    if (preg_match('/\bERROR\b/', $lines[$i])) {
        $totalErrors++;
    } elseif (preg_match('/\bWARN\b/', $lines[$i])) {
        $totalWarnings++;
    }
}

$total = $totalErrors + $totalWarnings;
echo json_encode(['errors' => $totalErrors, 'warnings' => $totalWarnings, 'total' => $total]) . "\n";
