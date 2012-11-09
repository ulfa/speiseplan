-module(date_lib).
-compile(export_all).

-define(WOCHENTAG(Int), lists:nth(Int, ["Montag","Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag", "Sonntag"])).

is_date_in_range(Akt_date, Date) ->	
	calendar:datetime_to_gregorian_seconds(Akt_date) - calendar:datetime_to_gregorian_seconds(Date) < 0.

is_date_in_range(Date) ->
	is_date_in_range(calendar:universal_time(), Date).
		
day_of_week(Int) ->
	?WOCHENTAG(Int).

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

week_of_year() ->
	{_Year, Week} = calendar:iso_week_number(),
	Week.

complete_actual_date() ->	
	complete_date(erlang:date()).
	
complete_date(Date) ->
	{_Year, Week} = calendar:iso_week_number(Date),	
	{Date, Week, calendar:day_of_the_week(Date)}.
	
construct_date({Y, M, D}) ->
	lists:concat([Y ,"-" ,M ,"-", D]).
	
get_formated_date(Date) ->
	{{Year,Month,Day},{Hour,Min,Seconds}} = Date,
	Args = [Year, Month, Day, Hour, Min, Seconds],
	A = io_lib:format("~B-~2.10.0B-~2.10.0B ~2.10.0B:~2.10.0B:~2.10.0B", Args),
	lists:flatten(A).
	

get_first_day({Y, M, _D}) ->
	FromDate = date_lib:create_date_string({{Y, M, 1}, {0,0,0}}).
	
get_last_day({Y, M, D}) ->	
	Last_day = calendar:last_day_of_the_month(Y, M),
	ToDate = date_lib:create_date_string({{Y, M, Last_day}, {0,0,0}}).
	
					
-include_lib("eunit/include/eunit.hrl").
-ifdef(TEST).
create_date_from_string_test() ->
	?assertEqual({{2012,10,30}, {00,00,00}}, create_date_from_string("2012-10-30")).
	
create_date_string_test() ->
	?assertEqual("2012-10-20", create_date_string({{2012,10,20}, {0,0,0}})).
	
create_date_german_string_test() ->
		?assertEqual("20.10.2012", create_date_german_string({{2012,10,20}, {0,0,0}})).


-endif.
