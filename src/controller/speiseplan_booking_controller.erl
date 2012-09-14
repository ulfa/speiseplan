-module(speiseplan_booking_controller, [Req]).
-compile(export_all).

before_(_) ->
	user_lib:require_login(Req).
	
index('GET', [], Eater) ->
	Menus = boss_db:find(menu, [], [{order_by, date}, descending]),
	{ok, [{menus, Menus}, {eater, Eater}]}.	
	
book('POST', [], Eater) ->
	Vegetarian = Req:post_param("vegetarian"),
	EaterId = Req:post_param("eater-id"),
	MenuId = Req:post_param("menu-id"),
	NewBooking = booking:new(id, erlang:localtime(), is_vegetarian(Vegetarian), EaterId, MenuId),
	{ok, SavedBooking} = NewBooking:save(),
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

delete('POST', [], Eater) ->
	EaterId = Req:post_param("eater-id"),
	MenuId = Req:post_param("menu-id"),	
	[Booking] = boss_db:find(booking, [{menu_id, 'equals', MenuId}, {eater_id , 'equals', EaterId}]),
	ok = boss_db:delete(Booking:id()),		
	{redirect, "/booking/index"}.
	
is_vegetarian(Vegetarian) ->
	Vegetarian =:= "true".

send_mail(EaterId, Menu) ->
	io:format("1.. : ~n~p", [EaterId]),
	Eater = boss_db:find(EaterId),
	boss_mail:send(Eater:mail(), "uangermann@googlemail.com",  Menu:date(), "Anfrage von ").

	
		
	
	
