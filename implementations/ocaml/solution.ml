(*
 * OCaml Concurrent Log Anomaly Counter
 * Sequential implementation (for Domainslib parallel version, install: opam install domainslib)
 *)

let is_alnum c =
  (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9')

let contains_word line word =
  let len = String.length word in
  let line_len = String.length line in
  let rec search pos =
    try
      let idx = String.index_from line pos (String.get word 0) in
      if idx + len > line_len then false
      else if String.sub line idx len = word then
        let before_ok = idx = 0 || not (is_alnum (String.get line (idx - 1))) in
        let after_ok = idx + len >= line_len || not (is_alnum (String.get line (idx + len))) in
        if before_ok && after_ok then true
        else search (idx + 1)
      else search (idx + 1)
    with Not_found -> false
  in
  search 0

let count_anomalies_in_chunk lines =
  let errors = ref 0 in
  let warnings = ref 0 in
  List.iter (fun line ->
    if String.contains line 'E' && contains_word line "ERROR" then
      incr errors
    else if String.contains line 'W' && contains_word line "WARN" then
      incr warnings
  ) lines;
  (!errors, !warnings)

let process_file filename =
  let ic = open_in filename in
  let lines = ref [] in
  try
    while true do
      lines := input_line ic :: !lines
    done;
    (0, 0) (* never reached *)
  with End_of_file ->
    close_in ic;
    let all_lines = List.rev !lines in
    (* Sequential processing *)
    count_anomalies_in_chunk all_lines

let () =
  if Array.length Sys.argv <> 2 then (
    Printf.eprintf "Usage: %s <logfile>\n" Sys.argv.(0);
    exit 1
  );

  let filename = Sys.argv.(1) in
  if not (Sys.file_exists filename) then (
    Printf.eprintf "Error: File not found: %s\n" filename;
    exit 1
  );

  let (errors, warnings) = process_file filename in
  let total = errors + warnings in

  Printf.printf "{\"errors\": %d, \"warnings\": %d, \"total\": %d}\n" errors warnings total;
  exit 0
