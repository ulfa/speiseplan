-module(date_lib).
-compile(export_all).

%% "2012-10-30" -> {{2012, 10, 30},{00,00,00}}
create_date_from_string([]) ->
	{erlang:date(), {00,00,00}};
create_date_from_string(Date) ->
	[Y,M,D] = string:tokens(Date, "-"),
	{{erlang:list_to_integer(Y), erlang:list_to_integer(M) ,erlang:list_to_integer(D)}, {00,00,00}}.

create_date_string(Date) ->
	{{Year,Month,Day},{Hour,Min,Seconds}} = Date,
	Args = [Year, Month, Day],
	lists:flatten(io_lib:format("~B-~2.10.0B-~2.10B", Args)).
				
-include_lib("eunit/include/eunit.hrl").
-ifdef(TEST).
create_date_from_string_test() ->
	?assertEqual({{2012,10,30}, {00,00,00}}, create_date_from_string("2012-10-30")).
	
create_date_string_test() ->
	?assertEqual("2012-10-20", create_date_string({{2012,10,20}, {0,0,0}})).
	
-endif.
