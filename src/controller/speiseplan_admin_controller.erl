-module(speiseplan_admin_controller, [Req]).
-compile(export_all).
before_(_) ->
	user_lib:require_login(admin, Req).
	
index('GET', [], Admin) ->
	Menus = boss_db:find(menu, [], [{order_by, date}, descending]),
	{ok, [{menus, Menus}, {eater, Admin}]}.

mahlzeit('POST', [], Admin) ->
	%%setze Kennzeichen, dass essen gelockt ist
	{redirect, [{'action', "index"}]}.
	
detail('GET', [Id], Admin) ->
	Menu = boss_db:find(Id),
	Eaters = boss_db:find(eater, []),
	Requesters = Menu:get_requester(),
	{ok, [{menu, Menu}, {eaters, Eaters}, {eater, Admin}, {requesters, Requesters}]}.	
	
edit('GET', [Id], Admin) ->
	Menu = boss_db:find(Id),
	Menus = boss_db:find(menu, []),
	{ok, [{menu, Menu}, {menus, Menus}, {eater, Admin}]}.

add('POST', [Id], Admin) ->
	Date = calendar:universal_time(),
	EaterId = Req:post_param("esser"),		
	case boss_db:find(booking, [{menu_id, 'equals', Id}, {eater_id , 'equals', EaterId}]) of
		[Result] -> 	{redirect, "/admin/detail/" ++ Id};
		_ ->	NewBooking = booking:new(id, Date, false, EaterId, Id),
				{ok, SavedBooking} = NewBooking:save(),
				{redirect, "/admin/detail/" ++ Id}
	end.
	
remove('POST', [Id], Admin) ->
	EaterId = Req:post_param("esser"),
	[Booking] = boss_db:find(booking, [{menu_id, 'equals', Id}, {eater_id , 'equals', EaterId}]),
	ok = boss_db:delete(Booking:id()),
	{redirect, "/admin/detail/" ++ Id}.

storno('POST', [], Admin) ->
	Menu_Id = Req:post_param("menu-id"),
	Menu = boss_db:find(Menu_Id),
	ok = send_mail(Menu:booking(), Menu),
	remove_bookings(Menu:booking()),
	boss_db:delete(Menu_Id),
	io:format("asdasdas"),
	{redirect, [{'action', "index"}]}.
	
remove_bookings([]) ->
	ok;
remove_bookings([Booking|Bookings]) ->
	boss_db:delete(Booking:id()),
	remove_bookings(Bookings).
	
create('POST', [], Admin) ->
	Date = Req:post_param("date"),
	Title = Req:post_param("title"),
	Details = Req:post_param("details"),
	Slots = Req:post_param("slots"),
	Vegetarian = Req:post_param("vegetarian"),
	NewDish = dish:new(id, Title, Details, handle_checkbox(Vegetarian)),	
	{ok, SavedDish} = NewDish:save(),
 	NewMenu = menu:new(id, date_lib:create_date_from_string(Date), SavedDish:id(), Slots),
	case NewMenu:save() of
		{ok, SavedMenu} -> {redirect, [{'action', "index"}]};
		{error, Errors} -> {ok, [{errors, Errors}, {menu, NewMenu}]}
	end.
					
update('POST', [Id], Admin) ->
	Menu = boss_db:find(Id),
	Dish = Menu:dish(),
	Date = Req:post_param("date"),
	Title = Req:post_param("title"),
	Details = Req:post_param("details"),
	Slots = Req:post_param("slots"),
	Vegetarian = Req:post_param("vegetarian"),	
	NewDish = Dish:set([{'title', Title}, {'details', Details}, {'vegetarian', handle_checkbox(Vegetarian)}]),
	NewMenu = Menu:set([{'date', date_lib:create_date_from_string(Date)}, {'slots', Slots}]),
	{ok, SavedDish} = NewDish:save(),
	{ok, SavedMenu} = NewMenu:save(),	
	{redirect, [{'action', "index"}]}.

handle_checkbox(Value) ->
	Value =:= "true". 
	
construct_date({Y, M, D}) ->
	lists:concat([Y ,"-" ,M ,"-", D]).
	
send_mail([], Menu) ->
	ok;
send_mail([Booking|Bookings], Menu) ->
	Eater = Booking:eater(),
	boss_mail:send("kuechenbulle@kiezkantine.de", Eater:mail(), Menu:date(), "Das Essen muss leider abgesagt werden."),
	send_mail(Bookings, Menu).
	
