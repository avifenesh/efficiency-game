import gleam/io
import gleam/string
import gleam/list
import gleam/int
import gleam/result
import gleam/erlang
import gleam/json
import simplifile

pub fn main() {
  case erlang.start_arguments() {
    [logfile] -> {
      case simplifile.read(logfile) {
        Ok(content) -> {
          let lines = string.split(content, on: "\n")
          let #(errors, warnings) = process_lines(lines)
          let total = errors + warnings
          
          let json_str = 
            "{\"errors\":" <> int.to_string(errors) <>
            ",\"warnings\":" <> int.to_string(warnings) <>
            ",\"total\":" <> int.to_string(total) <> "}"
          
          io.println(json_str)
          erlang.halt(0)
        }
        Error(_) -> {
          io.println_error("Error: Cannot read file: " <> logfile)
          erlang.halt(1)
        }
      }
    }
    _ -> {
      io.println_error("Usage: gleam run <logfile>")
      erlang.halt(1)
    }
  }
}

fn is_alnum(char: String) -> Bool {
  case string.to_utf_codepoints(char) {
    [codepoint] -> {
      let code = string.utf_codepoint_to_int(codepoint)
      { code >= 48 && code <= 57 } ||  // 0-9
      { code >= 65 && code <= 90 } ||  // A-Z
      { code >= 97 && code <= 122 }    // a-z
    }
    _ -> False
  }
}

fn char_at(str: String, index: Int) -> String {
  str
  |> string.to_graphemes()
  |> list.drop(index)
  |> list.first()
  |> result.unwrap("")
}

fn contains_word(line: String, word: String) -> Bool {
  contains_word_loop(line, word, 0)
}

fn contains_word_loop(line: String, word: String, start: Int) -> Bool {
  case string.slice(line, start, string.length(line) - start)
       |> string.split_once(word) {
    Error(_) -> False
    Ok(#(before, after)) -> {
      let pos = start + string.length(before)
      let before_char = case pos > 0 {
        True -> char_at(line, pos - 1)
        False -> ""
      }
      let after_start = pos + string.length(word)
      let after_char = case after_start < string.length(line) {
        True -> char_at(line, after_start)
        False -> ""
      }
      
      let start_ok = pos == 0 || !is_alnum(before_char)
      let end_ok = after_start >= string.length(line) || !is_alnum(after_char)
      
      case start_ok && end_ok {
        True -> True
        False -> contains_word_loop(line, word, pos + 1)
      }
    }
  }
}

fn process_line(line: String) -> #(Int, Int) {
  case string.contains(line, "E"), string.contains(line, "W") {
    True, _ -> 
      case contains_word(line, "ERROR") {
        True -> #(1, 0)
        False -> 
          case contains_word(line, "WARN") {
            True -> #(0, 1)
            False -> #(0, 0)
          }
      }
    False, True ->
      case contains_word(line, "WARN") {
        True -> #(0, 1)
        False -> #(0, 0)
      }
    _, _ -> #(0, 0)
  }
}

fn process_lines(lines: List(String)) -> #(Int, Int) {
  lines
  |> list.filter(fn(line) { string.length(line) > 0 })
  |> list.map(process_line)
  |> list.fold(#(0, 0), fn(acc, counts) {
    #(acc.0 + counts.0, acc.1 + counts.1)
  })
}
