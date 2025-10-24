defmodule Solution do
  @moduledoc """
  Optimized Elixir solution for log anomaly detection.

  Key optimizations:
  1. :binary.compile_pattern - faster than regex for simple substring matching
  2. Direct byte-level boundary checking - avoids regex compilation overhead
  3. @compile inline directive for hot path functions
  4. Sequential processing - Task.async_stream overhead > benefits for this workload
  """

  def main(args) do
    case args do
      [logfile] ->
        # Pre-compile patterns once - 2x faster than regex
        error_pattern = :binary.compile_pattern("ERROR")
        warn_pattern = :binary.compile_pattern("WARN")

        {errors, warnings} =
          File.stream!(logfile)
          |> Enum.reduce({0, 0}, fn line, {errors, warnings} ->
            cond do
              has_word?(line, error_pattern) -> {errors + 1, warnings}
              has_word?(line, warn_pattern) -> {errors, warnings + 1}
              true -> {errors, warnings}
            end
          end)

        total = errors + warnings
        IO.puts(~s/{"errors": #{errors}, "warnings": #{warnings}, "total": #{total}}/)

      _ ->
        IO.puts(:stderr, "Usage: elixir solution.exs <logfile>")
        System.halt(1)
    end
  end

  # Inline hot path functions for better performance
  @compile {:inline, has_word?: 2, is_alphanum_byte?: 2}

  defp has_word?(line, pattern) do
    case :binary.match(line, pattern) do
      :nomatch ->
        false
      {pos, len} ->
        # Fast word boundary check using byte operations
        byte_size = byte_size(line)
        start_ok = pos == 0 or not is_alphanum_byte?(line, pos - 1)
        end_ok = pos + len >= byte_size or not is_alphanum_byte?(line, pos + len)
        start_ok and end_ok
    end
  end

  defp is_alphanum_byte?(line, pos) do
    case :binary.at(line, pos) do
      c when (c >= ?a and c <= ?z) or (c >= ?A and c <= ?Z) or (c >= ?0 and c <= ?9) -> true
      _ -> false
    end
  end
end

Solution.main(System.argv())
