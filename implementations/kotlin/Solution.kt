import java.io.File
// No external dependencies; print JSON manually

fun main(args: Array<String>) {
    if (args.size != 1) {
        System.err.println("Usage: kotlin SolutionKt <logfile>")
        return
    }

    val logFile = args[0]
    var errors = 0
    var warnings = 0

    fun isAsciiAlnum(c: Char): Boolean =
        (c in '0'..'9') || (c in 'A'..'Z') || (c in 'a'..'z')

    fun containsWord(line: String, word: String): Boolean {
        val n = word.length
        val m = line.length
        if (n == 0 || m < n) return false
        var start = 0
        while (true) {
            val idx = line.indexOf(word, start)
            if (idx == -1) return false
            val before = idx - 1
            val after = idx + n
            val startOk = before < 0 || !isAsciiAlnum(line[before])
            val endOk = after >= m || !isAsciiAlnum(line[after])
            if (startOk && endOk) return true
            start = idx + 1
        }
    }

    File(logFile).forEachLine { line ->
        if (containsWord(line, "ERROR")) {
            errors++
        } else if (containsWord(line, "WARN")) {
            warnings++
        }
    }

    val total = errors + warnings
    println("{" + "\"errors\": $errors, \"warnings\": $warnings, \"total\": $total" + "}")
}
