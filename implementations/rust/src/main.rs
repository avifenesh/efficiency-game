use std::env;
use std::fs::File;
use std::io::{self, BufRead};
use std::path::Path;
use rayon::prelude::*;
use serde::{Serialize};

#[derive(Serialize)]
struct Results {
    errors: usize,
    warnings: usize,
    total: usize,
}

#[inline]
fn is_ascii_alnum(b: u8) -> bool {
    (b'0'..=b'9').contains(&b) || (b'A'..=b'Z').contains(&b) || (b'a'..=b'z').contains(&b)
}

fn contains_word(line: &str, word: &str) -> bool {
    let bytes = line.as_bytes();
    let w = word.as_bytes();
    if w.is_empty() || bytes.len() < w.len() { return false; }
    let mut start = 0;
    while let Some(pos) = memchr::memmem::find(&bytes[start..], w) {
        let idx = start + pos;
        let before_ok = idx == 0 || !is_ascii_alnum(bytes[idx - 1]);
        let after_idx = idx + w.len();
        let after_ok = after_idx >= bytes.len() || !is_ascii_alnum(bytes[after_idx]);
        if before_ok && after_ok { return true; }
        start = idx + 1;
    }
    false
}

fn process_chunk(chunk: &[String]) -> (usize, usize) {
    chunk.iter().fold((0, 0), |(mut errors, mut warnings), line| {
        if contains_word(line, "ERROR") {
            errors += 1;
        } else if contains_word(line, "WARN") {
            warnings += 1;
        }
        (errors, warnings)
    })
}

fn main() -> io::Result<()> {
    let args: Vec<String> = env::args().collect();
    if args.len() != 2 {
        eprintln!("Usage: {} <logfile>", args[0]);
        std::process::exit(1);
    }

    let path = Path::new(&args[1]);
    let file = File::open(&path)?;
    let lines: Vec<String> = io::BufReader::new(file).lines().collect::<Result<_, _>>()?;

    let (total_errors, total_warnings) = lines
        .par_chunks(1000)
        .map(process_chunk)
        .reduce(|| (0, 0), |a, b| (a.0 + b.0, a.1 + b.1));

    let results = Results {
        errors: total_errors,
        warnings: total_warnings,
        total: total_errors + total_warnings,
    };

    let json_output = serde_json::to_string(&results).unwrap();
    println!("{}", json_output);

    Ok(())
}
