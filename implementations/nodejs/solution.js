#!/usr/bin/env node
/**
 * Node.js Log Anomaly Counter - Optimized Version
 *
 * Optimizations:
 * 1. Single-threaded for small/medium files (avoids worker overhead)
 * 2. Native string operations (faster than Buffer conversions)
 * 3. Early exit optimizations
 * 4. Only uses workers for files > 500k lines
 */

const fs = require('fs');
const { Worker } = require('worker_threads');
const os = require('os');

// Inline fast pattern matching using native string operations
function containsWordFast(line, word) {
    let pos = line.indexOf(word);

    while (pos !== -1) {
        const before = pos - 1;
        const after = pos + word.length;

        // Check word boundaries using string charCodeAt (faster than Buffer)
        const startOk = before < 0 || !isAlnumChar(line.charCodeAt(before));
        const endOk = after >= line.length || !isAlnumChar(line.charCodeAt(after));

        if (startOk && endOk) return true;

        pos = line.indexOf(word, pos + 1);
    }

    return false;
}

// Inline for V8 optimization
function isAlnumChar(code) {
    return (code >= 48 && code <= 57) ||   // 0-9
           (code >= 65 && code <= 90) ||   // A-Z
           (code >= 97 && code <= 122);    // a-z
}

function countAnomaliesSync(lines) {
    let errors = 0;
    let warnings = 0

    for (const line of lines) {
        if (containsWordFast(line, 'ERROR')) {
            errors++;
        } else if (containsWordFast(line, 'WARN')) {
            warnings++;
        }
    }

    return { errors, warnings };
}

// Worker code with optimized string operations (for large files only)
const workerCode = `
const { parentPort, workerData } = require('worker_threads');

function containsWordFast(line, word) {
    let pos = line.indexOf(word);

    while (pos !== -1) {
        const before = pos - 1;
        const after = pos + word.length;

        const startOk = before < 0 || !isAlnumChar(line.charCodeAt(before));
        const endOk = after >= line.length || !isAlnumChar(line.charCodeAt(after));

        if (startOk && endOk) return true;
        pos = line.indexOf(word, pos + 1);
    }

    return false;
}

function isAlnumChar(code) {
    return (code >= 48 && code <= 57) ||
           (code >= 65 && code <= 90) ||
           (code >= 97 && code <= 122);
}

function countAnomalies(lines) {
    let errors = 0;
    let warnings = 0;

    for (const line of lines) {
        if (containsWordFast(line, 'ERROR')) {
            errors++;
        } else if (containsWordFast(line, 'WARN')) {
            warnings++;
        }
    }

    parentPort.postMessage({ errors, warnings });
}

countAnomalies(workerData.lines);
`;

function splitIntoChunks(array, numChunks) {
    const chunks = [];
    const chunkSize = Math.ceil(array.length / numChunks);

    for (let i = 0; i < array.length; i += chunkSize) {
        chunks.push(array.slice(i, i + chunkSize));
    }

    return chunks;
}

function processWithWorker(lines) {
    return new Promise((resolve, reject) => {
        const worker = new Worker(workerCode, {
            eval: true,
            workerData: { lines }
        });

        worker.on('message', resolve);
        worker.on('error', reject);
        worker.on('exit', (code) => {
            if (code !== 0) {
                reject(new Error(`Worker stopped with exit code ${code}`));
            }
        });
    });
}

async function processLogFile(filepath) {
    const stats = fs.statSync(filepath);
    const content = fs.readFileSync(filepath, 'utf-8');
    const lines = content.split('\n').filter(line => line.length > 0);

    // Only use workers for files > 50MB or > 500k lines
    const USE_WORKERS = stats.size > 50_000_000 || lines.length > 500_000;

    if (!USE_WORKERS) {
        // Process in main thread for small/medium files
        return countAnomaliesSync(lines);
    }

    // Calculate optimal worker count for large files
    const LINES_PER_WORKER = 25000;
    const maxWorkersNeeded = Math.ceil(lines.length / LINES_PER_WORKER);
    const numWorkers = Math.min(os.cpus().length, maxWorkersNeeded, 4);

    const chunks = splitIntoChunks(lines, numWorkers);
    const promises = chunks.map(chunk => processWithWorker(chunk));
    const results = await Promise.all(promises);

    const totalErrors = results.reduce((sum, r) => sum + r.errors, 0);
    const totalWarnings = results.reduce((sum, r) => sum + r.warnings, 0);

    return { errors: totalErrors, warnings: totalWarnings };
}

async function main() {
    if (process.argv.length !== 3) {
        console.error('Usage: node solution.js <logfile>');
        process.exit(1);
    }

    const logfile = process.argv[2];

    if (!fs.existsSync(logfile)) {
        console.error(`Error: File not found: ${logfile}`);
        process.exit(1);
    }

    try {
        const { errors, warnings } = await processLogFile(logfile);
        const total = errors + warnings;

        const result = { errors, warnings, total };
        console.log(JSON.stringify(result));
        process.exit(0);
    } catch (error) {
        console.error('Error:', error.message);
        process.exit(1);
    }
}

main();
