import scala.io.Source
import scala.util.Using
// Avoid external deps; print JSON manually

object Solution {
  def main(args: Array[String]): Unit = {
    if (args.length != 1) {
      System.err.println("Usage: scala Solution <logfile>")
      System.exit(1)
    }

    val logFile = args(0)
    var errors = 0
    var warnings = 0

    def isAsciiAlnum(c: Char): Boolean =
      (c >= '0' && c <= '9') || (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z')

    def containsWord(line: String, word: String): Boolean = {
      val n = word.length
      val m = line.length
      if (n == 0 || m < n) return false
      var start = 0
      var found = false
      while (!found && start <= m - n) {
        val idx = line.indexOf(word, start)
        if (idx == -1) return false
        val before = idx - 1
        val after = idx + n
        val startOk = before < 0 || !isAsciiAlnum(line.charAt(before))
        val endOk = after >= m || !isAsciiAlnum(line.charAt(after))
        if (startOk && endOk) found = true
        start = idx + 1
      }
      found
    }

    Using(Source.fromFile(logFile)) { source =>
      for (line <- source.getLines()) {
        if (containsWord(line, "ERROR")) {
          errors += 1
        } else if (containsWord(line, "WARN")) {
          warnings += 1
        }
      }
    }

    val total = errors + warnings
    println(s"{" + s"\"errors\": $errors, \"warnings\": $warnings, \"total\": $total" + s"}")
  }
}
