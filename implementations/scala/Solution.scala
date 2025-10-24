import scala.io.Source
import scala.util.Using
import scala.collection.parallel.CollectionConverters._
// Avoid external deps; print JSON manually

object Solution {
  def main(args: Array[String]): Unit = {
    if (args.length != 1) {
      System.err.println("Usage: scala Solution <logfile>")
      System.exit(1)
    }

    val logFile = args(0)

    val lines = Using.resource(Source.fromFile(logFile))(_.getLines().toVector)
    val (errors, warnings) = lines.par
      .map(countLine)
      .foldLeft((0, 0)) { case ((eAcc, wAcc), (e, w)) => (eAcc + e, wAcc + w) }

    val total = errors + warnings
    println(s"{" + s"\"errors\": $errors, \"warnings\": $warnings, \"total\": $total" + s"}")
  }

  private def isAsciiAlnum(c: Char): Boolean =
    (c >= '0' && c <= '9') || (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z')

  private def containsWord(line: String, word: String): Boolean = {
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

  private def countLine(line: String): (Int, Int) = {
    if (containsWord(line, "ERROR")) (1, 0)
    else if (containsWord(line, "WARN")) (0, 1)
    else (0, 0)
  }
}
