#!/usr/bin/env node
/**
 * Node.js Concurrent Log Anomaly Counter
 * Uses worker threads for parallel processing
 */

const fs = require('fs');
const { Worker } = require('worker_threads');
const os = require('os');

// Worker code as a string to avoid separate file
const workerCode = `
const { parentPort, workerData } = require('worker_threads');

function isAlnum(code) {
    return (
        (code >= 48 && code <= 57) || // 0-9
        (code >= 65 && code <= 90) || // A-Z
        (code >= 97 && code <= 122)   // a-z
    );
}

function containsWord(line, word) {
    const target = Buffer.from(word);
    const bytes = Buffer.from(line);
    const n = target.length;
    const m = bytes.length;
    if (n === 0 || m < n) return false;
    // naive scan; Node's Buffer.indexOf is optimized, but we need boundary checks
    let idx = -1;
    // Use Buffer.indexOf for speed
    let start = 0;
    while ((idx = bytes.indexOf(target, start)) !== -1) {
        const before = idx - 1;
        const after = idx + n;
        const startOk = before < 0 || !isAlnum(bytes[before]);
        const endOk = after >= m || !isAlnum(bytes[after]);
        if (startOk && endOk) return true;
        start = idx + 1;
    }
    return false;
}

function countAnomalies(lines) {
    let errors = 0;
    let warnings = 0;
    for (const line of lines) {
        if (containsWord(line, 'ERROR')) {
            errors++;
        } else if (containsWord(line, 'WARN')) {
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
    const content = fs.readFileSync(filepath, 'utf-8');
    const lines = content.split('\n').filter(line => line.length > 0);
    
    const numWorkers = os.cpus().length;
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
