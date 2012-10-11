-module(date_lib).
-compile(export_all).

%% "2012-10-30" -> {{2012, 10, 30},{00,00,00}}
create_date_from_string([]) ->
	{erlang:date(), {00,00,00}};
create_date_from_string(Date) ->
	[Y,M,D] = string:tokens(Date, "-"),
	{{erlang:list_to_integer(Y), erlang:list_to_integer(M) ,erlang:list_to_integer(D)}, {00,00,00}}.

create_simple_date_from_string([]) ->
	erlang:date();	
create_simple_date_from_string(Date) ->
	[Y,M,D] = string:tokens(Date, "-"),
	{erlang:list_to_integer(Y), erlang:list_to_integer(M) ,erlang:list_to_integer(D)}.


create_from_date(Date) ->
	D = create_simple_date_from_string(Date),
	{D, {0,0,0}}.

create_to_date(Date) ->
	D = create_simple_date_from_string(Date),
	{D, {23,59,59}}.
	
create_date_string(Date) ->
	{{Year,Month,Day},{Hour,Min,Seconds}} = Date,
	Args = [Year, Month, Day],
	lists:flatten(io_lib:format("~B-~.10.0B-~.10B", Args)).

create_date_string_from_date(Date) ->
	create_date_string({Date, {0,0,0}}).

create_date_german_string(Date) ->
	{{Year,Month,Day},{Hour,Min,Seconds}} = Date,
	Args = [Day,Month,Year],
	lists:flatten(io_lib:format("~.10B.~.10.0B.~B", Args)).
	
create_actual_date() ->
	calendar:local_time().
					
-include_lib("eunit/include/eunit.hrl").
-ifdef(TEST).
create_date_from_string_test() ->
	?assertEqual({{2012,10,30}, {00,00,00}}, create_date_from_string("2012-10-30")).
	
create_date_string_test() ->
	?assertEqual("2012-10-20", create_date_string({{2012,10,20}, {0,0,0}})).
	
create_date_german_string_test() ->
		?assertEqual("20.10.2012", create_date_string({{2012,10,20}, {0,0,0}})).
-endif.
