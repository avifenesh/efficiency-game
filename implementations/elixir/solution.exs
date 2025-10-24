defmodule Solution do
  def main(args) do
    case args do
      [logfile] ->
        error_re = ~r/(?<![A-Za-z0-9])ERROR(?![A-Za-z0-9])/u
        warn_re = ~r/(?<![A-Za-z0-9])WARN(?![A-Za-z0-9])/u
        {errors, warnings} =
          File.stream!(logfile)
          |> Enum.reduce({0, 0}, fn line, {errors, warnings} ->
            cond do
              Regex.match?(error_re, line) -> {errors + 1, warnings}
              Regex.match?(warn_re, line) -> {errors, warnings + 1}
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
end

Solution.main(System.argv())
