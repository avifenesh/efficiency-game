import java.nio.file.Files
import java.nio.file.Paths
import java.util.concurrent.atomic.AtomicInteger
import kotlin.system.exitProcess

private fun isAsciiAlnum(c: Char): Boolean =
    (c in '0'..'9') || (c in 'A'..'Z') || (c in 'a'..'z')

private fun containsWord(line: String, word: String): Boolean {
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

fun main(args: Array<String>) {
    if (args.size != 1) {
        System.err.println("Usage: kotlin SolutionKt <logfile>")
        exitProcess(1)
    }

    val logFile = args[0]
    val path = Paths.get(logFile)
    if (!Files.exists(path)) {
        System.err.println("Error: File not found: $logFile")
        exitProcess(1)
    }

    val errors = AtomicInteger(0)
    val warnings = AtomicInteger(0)

    Files.lines(path).use { stream ->
        stream.parallel().forEach { line ->
            when {
                containsWord(line, "ERROR") -> errors.incrementAndGet()
                containsWord(line, "WARN") -> warnings.incrementAndGet()
            }
        }
    }

    val total = errors.get() + warnings.get()
    println("{" + "\"errors\": ${errors.get()}, \"warnings\": ${warnings.get()}, \"total\": $total" + "}")
}
