use std::env;
use std::fs::File;
use std::io::{self, BufRead, BufReader};
use std::sync::{Arc, Mutex};
use std::thread;

#[inline]
fn is_ascii_alnum(b: u8) -> bool {
    (b'0'..=b'9').contains(&b) || (b'A'..=b'Z').contains(&b) || (b'a'..=b'z').contains(&b)
}

fn contains_word(line: &str, word: &str) -> bool {
    let bytes = line.as_bytes();
    let w = word.as_bytes();
    if w.is_empty() || bytes.len() < w.len() {
        return false;
    }
    
    let mut start = 0;
    while start <= bytes.len() - w.len() {
        if let Some(pos) = bytes[start..].iter().position(|&b| b == w[0]) {
            let idx = start + pos;
            // Check if full word matches
            if bytes[idx..].starts_with(w) {
                let before_ok = idx == 0 || !is_ascii_alnum(bytes[idx - 1]);
                let after_idx = idx + w.len();
                let after_ok = after_idx >= bytes.len() || !is_ascii_alnum(bytes[after_idx]);
                if before_ok && after_ok {
                    return true;
                }
            }
            start = idx + 1;
        } else {
            break;
        }
    }
    false
}

fn process_chunk(lines: &[String], errors: Arc<Mutex<usize>>, warnings: Arc<Mutex<usize>>) {
    let mut local_errors = 0;
    let mut local_warnings = 0;
    
    for line in lines {
        if contains_word(line, "ERROR") {
            local_errors += 1;
        } else if contains_word(line, "WARN") {
            local_warnings += 1;
        }
    }
    
    *errors.lock().unwrap() += local_errors;
    *warnings.lock().unwrap() += local_warnings;
}

fn main() -> io::Result<()> {
    let args: Vec<String> = env::args().collect();
    if args.len() != 2 {
        eprintln!("Usage: {} <logfile>", args[0]);
        std::process::exit(1);
    }

    let file = File::open(&args[1])?;
    let reader = BufReader::new(file);
    let lines: Vec<String> = reader.lines().collect::<Result<_, _>>()?;

    let num_threads = thread::available_parallelism()
        .map(|n| n.get())
        .unwrap_or(4);
    let chunk_size = (lines.len() + num_threads - 1) / num_threads;

    let errors = Arc::new(Mutex::new(0));
    let warnings = Arc::new(Mutex::new(0));
    let mut handles = vec![];

    for i in 0..num_threads {
        let start = i * chunk_size;
        if start >= lines.len() {
            break;
        }
        let end = ((i + 1) * chunk_size).min(lines.len());
        
        let chunk: Vec<String> = lines[start..end].to_vec();
        let errors_clone = Arc::clone(&errors);
        let warnings_clone = Arc::clone(&warnings);
        
        let handle = thread::spawn(move || {
            process_chunk(&chunk, errors_clone, warnings_clone);
        });
        handles.push(handle);
    }

    for handle in handles {
        handle.join().unwrap();
    }

    let total_errors = *errors.lock().unwrap();
    let total_warnings = *warnings.lock().unwrap();
    let total = total_errors + total_warnings;

    // Manual JSON output (no serde dependency)
    println!(
        r#"{{"errors": {}, "warnings": {}, "total": {}}}"#,
        total_errors, total_warnings, total
    );

    Ok(())
}
