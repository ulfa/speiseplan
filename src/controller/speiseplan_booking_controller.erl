-module(speiseplan_booking_controller, [Req]).
-compile(export_all).

before_(_) ->
	user_lib:require_login(Req).
	
index('GET', [], Eater) ->
	Menus = boss_db:find(menu, [{date, 'le', {erlang:date(), {0,0,0}}}], [{order_by, date}, descending]),
	{ok, [{menus, Menus}, {eater, Eater}]}.	
	
book('POST', [], Eater) ->
	EaterId = Req:post_param("eater-id"),
	MenuId = Req:post_param("menu-id"),	
	Vegetarian = Req:post_param("vegetarian"),
	case is_allready_booked(MenuId, EaterId) of
		true -> true;
		false -> NewBooking = booking:new(id, erlang:localtime(), is_vegetarian(Vegetarian), EaterId, MenuId),
				 {ok, SavedBooking} = NewBooking:save()
	end,
	{redirect, "/booking/index"}.

request('POST', [], Eater) ->
	EaterId = Req:post_param("eater-id"),	
	MenuId = Req:post_param("menu-id"),
	Menu = boss_db:find(MenuId),
	{ok, Timestamp} = boss_mq:push(Menu:get_date_as_string(), erlang:list_to_binary(EaterId)),
	{redirect, "/booking/index"}.

detail('POST' ,[Id], Eater) ->
	Menus = boss_db:find(menu, []),
	{ok, [{menus, Menus}]}.		

storno('POST', [], Eater) ->
	EaterId = Req:post_param("eater-id"),
	MenuId = Req:post_param("menu-id"),	
	[Booking] = boss_db:find(booking, [{menu_id, 'equals', MenuId}, {eater_id , 'equals', EaterId}]),
	ok = boss_db:delete(Booking:id()),		
	{redirect, "/booking/index"}.
	
is_vegetarian(Vegetarian) ->
	Vegetarian =:= "true".

send_mail(EaterId, Menu) ->
	Eater = boss_db:find(EaterId),
	boss_mail:send(Eater:mail(), "uangermann@googlemail.com",  Menu:date(), "Anfrage von ").

is_allready_booked(MenuId, EaterId) ->
	case boss_db:find(booking, [{menu_id, MenuId}, {eater_id, EaterId}]) of
		[] -> false;
		Menu -> true
	end.
	
billing('GET', [], Eater) ->
	{Y, M, _} = erlang:date(),
	Last_day = calendar:last_day_of_the_month(Y, M),
	ToDate = date_lib:create_date_string({{Y, M, Last_day}, {0,0,0}}),
	FromDate = date_lib:create_date_string({{Y, M, 1}, {0,0,0}}),		
	{ok, [{eater, Eater}, {from_date, FromDate}, {to_date, ToDate}]};
billing('POST', [], Eater) ->
	FromDate = Req:post_param("from_date"),
	ToDate = Req:post_param("to_date"),
	Bookings = boss_db:find(booking, [{eater_id, 'eq', Eater:id()},{date, 'gt', date_lib:create_from_date(FromDate)}, {date, 'lt', date_lib:create_to_date(ToDate)}], [{order_by, date}]),	
	Billings = create_billing(Bookings, [], Eater),
	{ok, [{eater, Eater}, {from_date, FromDate}, {to_date, ToDate},{billings, Billings}, {sum, lists:foldl(fun({X, Y}, Acc0) -> Acc0 + Y end, 0, Billings)}]}.
%% Sum of bookings	lists:foldl(fun({X, Y}, Acc0) -> Acc0 + Y end, 0, O).

create_billing([], Acc, Eater) ->
	Acc;
create_billing([Booking|Bookings], Acc, Eater) ->
	Menu = Booking:menu(),
	Price = get_price(Eater),
	create_billing(Bookings, [{date_lib:create_date_string(Menu:date()), Price}|Acc], Eater).	
get_price(Eater) ->
	case Eater:intern() of
		true -> 3;
		false -> 5
	end.
		
	
	
