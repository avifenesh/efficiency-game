open System
open System.IO
open System.Text.Json
open System.Threading

let isAsciiAlnum (c: char) =
    (c >= '0' && c <= '9') || (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z')

let containsWord (line: string) (word: string) =
    let n = word.Length
    let m = line.Length
    if n = 0 || m < n then
        false
    else
        let rec search start =
            match line.IndexOf(word, start, StringComparison.Ordinal) with
            | -1 -> false
            | idx ->
                let before = idx - 1
                let after = idx + n
                let startOk = before < 0 || not (isAsciiAlnum line.[before])
                let endOk = after >= m || not (isAsciiAlnum line.[after])
                if startOk && endOk then
                    true
                else
                    search (idx + 1)
        search 0

[<EntryPoint>]
let main args =
    if args.Length = 0 then
        eprintfn "Usage: dotnet run <logfile>"
        1
    else
        let logFile = args.[0]

        if not (File.Exists logFile) then
            eprintfn "Error: File not found: %s" logFile
            1
        else
            let lines = File.ReadLines(logFile)

            let mutable errors = 0
            let mutable warnings = 0

            lines
            |> Seq.toArray
            |> Array.Parallel.iter (fun line ->
                if line.Contains('E') && containsWord line "ERROR" then
                    Interlocked.Increment(&errors) |> ignore
                elif line.Contains('W') && containsWord line "WARN" then
                    Interlocked.Increment(&warnings) |> ignore
            )

            let total = errors + warnings
            let result = {| errors = errors; warnings = warnings; total = total |}
            let json = JsonSerializer.Serialize(result)

            printfn "%s" json
            0
