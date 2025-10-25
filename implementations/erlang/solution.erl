#!/usr/bin/env escript
%%% Erlang Concurrent Log Anomaly Counter
%%% Uses Erlang processes for parallel processing

-mode(compile).

main([Logfile]) ->
    case file:read_file(Logfile) of
        {ok, Content} ->
            Lines = binary:split(Content, <<"\n">>, [global, trim]),
            {Errors, Warnings} = process_log_lines(Lines),
            Total = Errors + Warnings,
            io:format("{\"errors\":~p,\"warnings\":~p,\"total\":~p}~n", 
                     [Errors, Warnings, Total]),
            halt(0);
        {error, Reason} ->
            io:format(standard_error, "Error reading file: ~p~n", [Reason]),
            halt(1)
    end;
main(_) ->
    io:format(standard_error, "Usage: escript solution.erl <logfile>~n", []),
    halt(1).

%% Check if byte is alphanumeric
is_alnum(Byte) when Byte >= $0, Byte =< $9 -> true;
is_alnum(Byte) when Byte >= $A, Byte =< $Z -> true;
is_alnum(Byte) when Byte >= $a, Byte =< $z -> true;
is_alnum(_) -> false.

%% Check if word exists with word boundaries in line
contains_word(Line, Word) ->
    contains_word(Line, Word, 0).

contains_word(Line, Word, Start) ->
    case binary:match(Line, Word, [{scope, {Start, byte_size(Line) - Start}}]) of
        nomatch ->
            false;
        {Pos, Len} ->
            StartOk = (Pos =:= 0) orelse (not is_alnum(binary:at(Line, Pos - 1))),
            EndPos = Pos + Len,
            EndOk = (EndPos >= byte_size(Line)) orelse 
                    (not is_alnum(binary:at(Line, EndPos))),
            case StartOk andalso EndOk of
                true -> true;
                false -> contains_word(Line, Word, Pos + 1)
            end
    end.

%% Process a chunk of lines
process_chunk(Lines, Parent) ->
    Result = lists:foldl(
        fun(Line, {E, W}) ->
            case {binary:match(Line, <<"E">>), binary:match(Line, <<"W">>)} of
                {nomatch, _} ->
                    {E, W};
                {{_, _}, _} ->
                    case contains_word(Line, <<"ERROR">>) of
                        true -> {E + 1, W};
                        false ->
                            case contains_word(Line, <<"WARN">>) of
                                true -> {E, W + 1};
                                false -> {E, W}
                            end
                    end;
                {_, {_, _}} ->
                    case contains_word(Line, <<"WARN">>) of
                        true -> {E, W + 1};
                        false -> {E, W}
                    end
            end
        end,
        {0, 0},
        Lines
    ),
    Parent ! {result, Result}.

%% Split list into chunks
split_into_chunks(List, ChunkSize) ->
    split_into_chunks(List, ChunkSize, []).

split_into_chunks([], _, Acc) ->
    lists:reverse(Acc);
split_into_chunks(List, ChunkSize, Acc) ->
    {Chunk, Rest} = lists:split(min(ChunkSize, length(List)), List),
    split_into_chunks(Rest, ChunkSize, [Chunk | Acc]).

%% Main processing function with parallel workers
process_log_lines([]) ->
    {0, 0};
process_log_lines(Lines) ->
    NumWorkers = min(erlang:system_info(schedulers), length(Lines)),
    ChunkSize = (length(Lines) + NumWorkers - 1) div NumWorkers,
    Chunks = split_into_chunks(Lines, ChunkSize),
    
    Parent = self(),
    
    % Spawn workers
    lists:foreach(
        fun(Chunk) ->
            spawn(fun() -> process_chunk(Chunk, Parent) end)
        end,
        Chunks
    ),
    
    % Collect results
    collect_results(length(Chunks), 0, 0).

%% Collect results from workers
collect_results(0, Errors, Warnings) ->
    {Errors, Warnings};
collect_results(N, Errors, Warnings) ->
    receive
        {result, {E, W}} ->
            collect_results(N - 1, Errors + E, Warnings + W)
    after 60000 ->
        io:format(standard_error, "Timeout waiting for workers~n", []),
        halt(1)
    end.
