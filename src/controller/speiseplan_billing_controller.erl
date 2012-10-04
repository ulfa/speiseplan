-module(speiseplan_billing_controller, [Req]).
-compile(export_all).
-define(CSV_DIR, "priv/static/billing/").
before_(_) ->
	user_lib:require_login(admin, Req).

index('GET', [], Admin) ->	
	{ok, [{eater, Admin}]}.
	
search('POST', [], Admin) ->
	From_Date = Req:post_param("from_date"),
	To_Date = Req:post_param("to_date"),
	Bookings = boss_db:find(booking, [{date, 'gt', date_lib:create_from_date(From_Date)}, {date, 'lt', date_lib:create_to_date(To_Date)}], [{order_by, date}]),	
	Entries = create_billing(Bookings, From_Date, To_Date, []),
	{ok,CsvFile} = file:list_dir(?CSV_DIR),
	{ok, [{eater, Admin}, {from_date, From_Date}, {to_date, To_Date},{billings, Entries}, {act_date, date_lib:create_date_string_from_date(erlang:date())},
	{csvfiles, CsvFile}]}.

create_billing([], From_Date, To_Date, Acc) ->
	Acc1 = lists:keysort(1,Acc),
	File_Name = create_file_name(),
	{ok, FD} = file:open(?CSV_DIR ++ File_Name, [write]),
	write_header(FD, From_Date, To_Date) ,
	create_csv(FD, Acc1),
	file:close(FD),
	Acc1;
	
create_billing([Booking|Bookings], From_Date, To_Date,Acc) ->
	Menu  = Booking:menu(),
	Eater = Booking:eater(),
	Acc1  = case lists:keyfind(Eater:account(), 1, Acc) of
		false -> [{Eater:account(), [date_lib:create_date_string(Menu:date())]}|Acc];
		{Account, Dates} -> lists:keyreplace(Account, 1, Acc, {Account,[date_lib:create_date_string(Menu:date())|Dates]})
	end,	
	create_billing(Bookings, From_Date, To_Date, Acc1).

create_file_name() ->
	"billing-" ++ date_lib:create_date_string_from_date(erlang:date()) ++ ".csv".
			
create_full_name(Eater) ->
	Eater:forename() ++ " "++Eater:name().

write_header(FD, From_Date, To_Date) ->
	io:fwrite(FD, "#~s ~s~n", [From_Date, To_Date]).

create_csv(FD,[]) ->
	file:close(FD);
create_csv(FD, [{Name, Dates}|Billings]) ->
	io:fwrite(FD, "~s~n", [create_csv_line(Name, Dates)]),
	create_csv(FD, Billings).
	
create_csv_line(Name, Dates) ->
	string:join([Name|Dates], ",").	

	

	
	