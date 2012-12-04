-module(speiseplan_analysis_controller, [Req]).
-compile(export_all).

-define (YEAR, "'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Okt','Nov','Dez'").
-define (SUBTITLE_YEAR(Year), "Jahr : " ++ Year).
-define (SUBTITLE_MONTH(Year), "Monat : " ++ Year).


before_(_) ->
	user_lib:require_login(admin, Req).

index('GET', [Year], Admin) -> 
	Menus = get_menus_for_year(Year),	
	{Intern, Extern} = analyse_menus(year, Menus, array:new(12, {default,0}), array:new(12, {default,0})),
	{ok, [{eater, Admin}, {categories, ?YEAR}, {subtitle, ?SUBTITLE_YEAR(Year)}, {year, Year}, {intern, Intern}, {extern, Extern}]};
	
index('GET', [Year, Month], Admin) -> 
	Menus = get_menus_for_month(Year, Month),	
	Day_count = calendar:last_day_of_the_month(list_to_integer(Year), list_to_integer(Month)),
	{Intern, Extern} = analyse_menus(month,Menus, array:new(Day_count, {default,0}), array:new(Day_count, {default,0})),
	{ok, [{eater, Admin}, {categories, date_lib:get_days_of_month(Year, Month)},
	 {subtitle, ?SUBTITLE_MONTH(Month)}, {intern, Intern}, {extern, Extern}]}.
		
analyse_menus(year,[], Intern, Extern) ->
	{list_of_integer_to_string(array:to_list(Intern)), list_of_integer_to_string(array:to_list(Extern))};	
analyse_menus(year, [H|T], Intern, Extern) ->
	{{_Y, Month, _D}, _Time} = H:date(),
	{Int_count, Ext_count} = count_bookings(H:booking()),
	analyse_menus(year,T, add(Month, Int_count, Intern), add(Month, Ext_count, Extern));

analyse_menus(month,[], Intern, Extern) ->
	{list_of_integer_to_string(array:to_list(Intern)), list_of_integer_to_string(array:to_list(Extern))};	
analyse_menus(month, [H|T], Intern, Extern) ->
	{{_Y, _M, Day}, _Time} = H:date(),
	{Int_count, Ext_count} = count_bookings(H:booking()),
	analyse_menus(month,T, add(Day, Int_count, Intern), add(Day, Ext_count, Extern)).

count_bookings(Bookings) ->
	count_bookings(Bookings, 0, 0).	
count_bookings([], Intern, Extern) ->
	{Intern, Extern};
count_bookings([H|T], Intern, Extern) ->
	Eater = H:eater(),
	case Eater:intern() of
		true -> count_bookings(T, Intern + 1, Extern);
		false ->count_bookings(T, Intern, Extern + 1)
	end.
get_menus_for_month(Year, Month) when is_list(Year) ->	
	get_menus_for_month(list_to_integer(Year), list_to_integer(Month));
get_menus_for_month(Year, Month) ->	
	boss_db:find(menu, [{date, 'ge', {{Year, Month,1}, {0,0,0}}}, {date, 'le', {{Year, Month, calendar:last_day_of_the_month(Year, Month)}, {0,0,0}}}]).
	
get_menus_for_year(Year) when is_list(Year) ->
	get_menus_for_year(list_to_integer(Year));
get_menus_for_year(Year) ->
	boss_db:find(menu, [{date, 'ge', {{Year, 1,1}, {0,0,0}}}, {date, 'le', {{Year, 12, 31}, {0,0,0}}}]).
	
add(Month, Value, Array) ->
	Index = Month - 1,
	Act_value = array:get(Index, Array),
	array:set(Index, Act_value + Value, Array).

list_of_integer_to_string(List_of_integer) ->
	string:join([integer_to_list(S) || S <- List_of_integer],",").
-include_lib("eunit/include/eunit.hrl").
-ifdef(TEST).

%%add_test() ->
%%	NewList = array:set(3, 5, array:new(11. {default,0})),
%%	?asserEqual(6, add(4, 1, NewList)).
	
-endif.


	
	