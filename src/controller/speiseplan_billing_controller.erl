-module(speiseplan_billing_controller, [Req]).
-compile(export_all).

before_(_) ->
	user_lib:require_login(admin, Req).

index('GET', [], Admin) ->	
	{ok, [{eater, Admin}]}.
	
search('POST', [], Admin) ->
	FromDate = Req:post_param("from_date"),
	ToDate = Req:post_param("to_date"),
	Bookings = boss_db:find(booking, [{date, 'gt', date_lib:create_from_date(FromDate)}, {date, 'lt', date_lib:create_to_date(ToDate)}], [{order_by, date}]),	
	{ok, [{eater, Admin}, {from_date, FromDate}, {to_date, ToDate},{billings, create_billing(Bookings, [])}]}.

create_billing([], Acc) ->
	Acc1 = lists:keysort(1,Acc),
	{ok, FD} = file:open("/tmp/billing.csv", [write]),
	create_csv(FD, Acc1),
	file:close(FD),
	Acc1;
	
create_billing([Booking|Bookings], Acc) ->
	Menu  = Booking:menu(),
	Eater = Booking:eater(),
	Acc1  = case lists:keyfind(Eater:account(), 1, Acc) of
		false -> [{Eater:account(), [date_lib:create_date_string(Menu:date())]}|Acc];
		{Account, Dates} -> lists:keyreplace(Account, 1, Acc, {Account,[date_lib:create_date_string(Menu:date())|Dates]})
	end,	
	create_billing(Bookings, Acc1).
	
create_full_name(Eater) ->
	Eater:forename() ++ " "++Eater:name().

create_csv(FD,[]) ->
	file:close(FD);
create_csv(FD, [{Name, Dates}|Billings]) ->
	io:fwrite(FD, "~s~n", [create_csv_line(Name, Dates)]),
	create_csv(FD, Billings).
	
create_csv_line(Name, Dates) ->
	string:join([Name|Dates], ",").	

	

	
	