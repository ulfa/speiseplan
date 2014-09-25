-module(speiseplan_billing_controller, [Req]).
-compile(export_all).
-define(CSV_DIR, "priv/static/billing/").
before_(_) ->
	user_lib:require_login(admin, Req).

index('GET', [], Admin) ->	
	Date = erlang:date(),
	ToDate = date_lib:get_last_day(Date),
	FromDate = date_lib:get_first_day(Date),		
	{ok, [{eater, Admin}, {from_date, FromDate}, {to_date, ToDate}]}.
	
search('GET', [], Admin) ->
	From_Date = Req:query_param("from_date"),
	To_Date = Req:query_param("to_date"),
	Bookings = boss_db:find(booking, [{menu_date, 'gt', date_lib:create_from_date(From_Date)}, {menu_date, 'lt', date_lib:create_to_date(To_Date)}], [{order_by, menu_date}]),	
	lager:info(".... Boookings : ~p", [Bookings]),
	Entries = create_billing(Bookings, From_Date, To_Date, []),
	{ok, CsvFiles} = file:list_dir(?CSV_DIR),
	{ok, [{eater, Admin}, {from_date, From_Date}, {to_date, To_Date},{billings, Entries}, {act_date, date_lib:create_date_string_from_date(erlang:date())},
	{csvfiles, lists:sort(CsvFiles)}]}.

create_billing([], From_Date, To_Date, Acc) ->
	Acc1 = lists:keysort(1,Acc),
	File_Name = create_file_name(),
	{ok, FD} = file:open(?CSV_DIR ++ File_Name, [write]),
	write_header(FD, From_Date, To_Date) ,
	create_csv(FD, Acc1),
	file:close(FD),
	Acc1;
create_billing([Booking|Bookings], From_Date, To_Date, Acc) ->
	Menu  = Booking:menu(),
	Dish = Menu:dish(),
	Eater = Booking:eater(),
	Acc1  = case lists:keyfind(Eater:display_name(), 1, Acc) of
		false -> [{Eater:display_name(), Eater:intern(), [date_lib:create_date_string(Menu:date())]}|Acc];
		{FullName, Intern, Dates} -> lists:keyreplace(FullName, 1, Acc, {Eater:display_name(), Eater:intern(),[date_lib:create_date_string(Menu:date())|Dates]})
	end,	
	create_billing(Bookings, From_Date, To_Date, Acc1).

create_file_name() ->
	"billing-" ++ date_lib:create_date_string_from_date(erlang:date()) ++ ".csv".
			
write_header(FD, From_Date, To_Date) ->
	io:fwrite(FD, "#~s ~s~n", [From_Date, To_Date]),
	io:fwrite(FD, "#Name, Intern, [Datum], Summe~n", []).
	
create_csv(FD,[]) ->
	file:close(FD);
create_csv(FD, [{Name, Intern, Dates}|Billings]) ->
	io:fwrite(FD, "~s~n", [create_csv_line(Name, Intern, Dates)]),
	create_csv(FD, Billings).
	
create_csv_line(Name, Intern, Dates) ->
	string:join([string:join([string:join([Name, erlang:atom_to_list(Intern)], ",")|Dates], ","), create_sum(Intern, length(Dates))], ",").
	
create_sum(Intern, Day_Count) ->
	erlang:integer_to_list(Day_Count * elib:intern(Intern)).

	
-include_lib("eunit/include/eunit.hrl").
-ifdef(TEST).
create_sum_test() ->
	?assertEqual(6.0, create_sum(true, 2)).
-endif.


	
	