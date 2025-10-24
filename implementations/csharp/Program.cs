using System.Text.Json;

var logFile = args.Length > 0 ? args[0] : "../../data/synthetic/medium.log";

var lines = File.ReadLines(logFile);

var errors = 0;
var warnings = 0;

static bool IsAsciiAlnum(char c)
    => (c >= '0' && c <= '9') || (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z');

static bool ContainsWord(string line, string word)
{
    int n = word.Length;
    int m = line.Length;
    if (n == 0 || m < n) return false;
    int start = 0;
    while (true)
    {
        int idx = line.IndexOf(word, start, StringComparison.Ordinal);
        if (idx == -1) return false;
        int before = idx - 1;
        int after = idx + n;
        bool startOk = before < 0 || !IsAsciiAlnum(line[before]);
        bool endOk = after >= m || !IsAsciiAlnum(line[after]);
        if (startOk && endOk) return true;
        start = idx + 1;
    }
}

Parallel.ForEach(lines, line =>
{
    if (ContainsWord(line, "ERROR"))
    {
        Interlocked.Increment(ref errors);
    }
    else if (ContainsWord(line, "WARN"))
    {
        Interlocked.Increment(ref warnings);
    }
});

var total = errors + warnings;
var result = new { errors, warnings, total };
var json = JsonSerializer.Serialize(result);

Console.WriteLine(json);
