-module(speiseplan_booking_controller, [Req]).
-compile(export_all).

before_(_) ->
	user_lib:require_login(Req).
	
index('GET', [], Eater) ->
	Menus = boss_db:find(menu, [], [{order_by, date}, descending]),
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
	
actual('GET', [], Eater) ->
	Date = date_lib:create_date_german_string({erlang:date(), {0,0,0}}),	
	case boss_db:find(menu, [{date,  {erlang:date(), {0,0,0}}}]) of
		[] -> {ok, [{eater, Eater}, {text, "bleibt die Küche kalt"}, {date, Date}]};
		[Menu] -> {ok, [{eater, Eater}, {text, "gibt es"}, {dish, Menu:dish()}, {date, Date}]}
	end.
	
is_vegetarian(Vegetarian) ->
	Vegetarian =:= "true".

send_mail(EaterId, Menu) ->
	io:format("1.. : ~n~p", [EaterId]),
	Eater = boss_db:find(EaterId),
	boss_mail:send(Eater:mail(), "uangermann@googlemail.com",  Menu:date(), "Anfrage von ").

is_allready_booked(MenuId, EaterId) ->
	case boss_db:find(booking, [{menu_id, MenuId}, {eater_id, EaterId}]) of
		[] -> false;
		Menu -> true
	end.
	
		
	
	
