-module(speiseplan_booking_controller, [Req]).
-compile(export_all).

before_(_) ->
	user_lib:require_login(Req).
	
index('GET', [], Eater) ->
	Menus = boss_db:find(menu, [{date, 'ge', date_lib:create_date_from_string([])}], [{order_by, date}, descending]),
	{ok, [{menus, Menus}, {eater, Eater}, {week, date_lib:week_of_year()}]}.	
		
book('POST', [], Eater) ->
	EaterId = Req:post_param("eater-id"),
	MenuId = Req:post_param("menu-id"),	
	Vegetarian = Req:post_param("vegetarian"),
	case is_allready_booked(MenuId, EaterId) and is_in_time(MenuId) of
		true -> true;
		false -> NewBooking = booking:new(id, erlang:localtime(), is_vegetarian(Vegetarian), EaterId, MenuId),
				 {ok, SavedBooking} = NewBooking:save()
	end,
	{redirect, elib:get_full_path(speiseplan, "/booking/index")}.

request('POST', [], Eater) ->
	EaterId = Req:post_param("eater-id"),	
	MenuId = Req:post_param("menu-id"),
	Menu = boss_db:find(MenuId),	
	case has_allready_requested(Menu:get_date_as_string(), EaterId, MenuId) of
		false -> NewRequest = requester:new(id, erlang:localtime(), Menu:get_date_as_string(), MenuId, EaterId),
				{ok, SavedRequest} = NewRequest:save(),
				 send_mail(EaterId, Menu);
		true -> lager:info("Eater : ~p already requested", [EaterId])
	end,
	{redirect, elib:get_full_path(speiseplan,"/booking/index")}.

has_allready_requested(Date, EaterId, MenuId) ->
	case boss_db:find(requester, [{menu_date, 'equals', Date}, {eater_id, 'equals', EaterId}, {menu_id, 'equals', MenuId}]) of 
		[] -> false;
		[Eater] -> true
	end.

detail('POST' ,[Id], Eater) ->
	Menus = boss_db:find(menu, []),
	{ok, [{menus, Menus}]}.		

storno('POST', [], Eater) ->
	EaterId = Req:post_param("eater-id"),
	MenuId = Req:post_param("menu-id"),		
	case is_in_time(MenuId) of
		false -> false;
		true -> [Booking] = boss_db:find(booking, [{menu_id, 'equals', MenuId}, {eater_id , 'equals', EaterId}]),
				ok = boss_db:delete(Booking:id())
	end,		
	{redirect, elib:get_full_path(speiseplan, "/booking/index")}.

is_in_time(Menu_Id) ->
	Menu = boss_db:find(Menu_Id),
	Menu:is_in_time().		

	
is_vegetarian(Vegetarian) ->
	Vegetarian =:= "true".

send_mail(EaterId, Menu) ->
	To = get_env(speiseplan, mail_anfrage_to, "anja.angermann@innoq.com"),	
	Anfrage =get_env(speiseplan, mail_anfrage, ""),	
	Eater = boss_db:find(EaterId),
	boss_mail:send(Eater:mail(), To,  date_lib:create_date_string(Menu:date()), "Anfrage von: " ++ Eater:display_name() ++ Anfrage).

is_allready_booked(MenuId, EaterId) ->
	is_already_booked(boss_db:find(booking, [{menu_id, MenuId}, {eater_id, EaterId}])).

is_already_booked([]) ->
	false;
is_already_booked([Menu]) ->	
	true.
		
billing('GET', [Eater_id], Eater) ->
	% TODO We have to check, if the user who wants to see his bill is the same as in the cookie.
	FromDate = get_first_date(Req, "from_date"),
	ToDate = get_last_date(Req, "to_date"),
	Bookings = boss_db:find(booking, [{eater_id, 'eq', Eater:id()},{date, 'gt', date_lib:create_from_date(FromDate)}, {date, 'lt', date_lib:create_to_date(ToDate)}], [{order_by, date}]),	
	Billings = create_billing(Bookings, [], Eater),
	{ok, [{eater, Eater}, {from_date, FromDate}, {to_date, ToDate},{billings, Billings}, {sum, lists:foldl(fun({X, Y, Z}, Acc0) -> Acc0 + Z end, 0, Billings)}]}.
%% Sum of bookings	lists:foldl(fun({X, Y}, Acc0) -> Acc0 + Y end, 0, O).

get_first_date(Req, Key) ->
	Date = erlang:date(),
	case Req:query_param(Key) of
		undefined -> date_lib:get_first_day(Date);
		_ -> Req:query_param(Key)
	end.

get_last_date(Req, Key) ->
	Date = erlang:date(),
	case Req:query_param(Key) of
		undefined -> date_lib:get_last_day(Date);
		_ -> Req:query_param(Key)
	end.

create_billing([], Acc, Eater) ->
	Acc;
create_billing([Booking|Bookings], Acc, Eater) ->
	Menu = Booking:menu(),
	Price = elib:get_price(Eater:intern()),
	Dish = Menu:dish(),
	create_billing(Bookings, [{date_lib:create_date_string(Menu:date()), Dish:title(), Price}|Acc], Eater).		

get_env(App, Key, Default) ->
	boss_env:get_env(App, Key, Default).		
