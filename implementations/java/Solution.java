import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.stream.Stream;

public class Solution {
    private static boolean isAsciiAlnum(char c) {
        return (c >= '0' && c <= '9') || (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z');
    }

    private static boolean containsWord(String line, String word) {
        int n = word.length();
        int m = line.length();
        if (n == 0 || m < n) return false;
        int start = 0;
        while (true) {
            int idx = line.indexOf(word, start);
            if (idx == -1) return false;
            int before = idx - 1;
            int after = idx + n;
            boolean startOk = before < 0 || !isAsciiAlnum(line.charAt(before));
            boolean endOk = after >= m || !isAsciiAlnum(line.charAt(after));
            if (startOk && endOk) return true;
            start = idx + 1;
        }
    }
    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("Usage: java Solution <logfile>");
            System.exit(1);
        }

        String logFile = args[0];
        AtomicInteger errors = new AtomicInteger(0);
        AtomicInteger warnings = new AtomicInteger(0);

        try (Stream<String> stream = new BufferedReader(new FileReader(logFile)).lines().parallel()) {
            stream.forEach(line -> {
                if (containsWord(line, "ERROR")) {
                    errors.incrementAndGet();
                } else if (containsWord(line, "WARN")) {
                    warnings.incrementAndGet();
                }
            });
        } catch (IOException e) {
            e.printStackTrace();
            System.exit(1);
        }

        int total = errors.get() + warnings.get();
        System.out.printf("{\"errors\": %d, \"warnings\": %d, \"total\": %d}\n", errors.get(), warnings.get(), total);
    }
}
