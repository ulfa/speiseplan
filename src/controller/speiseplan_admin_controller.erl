-module(speiseplan_admin_controller, [Req]).
-compile(export_all).
before_(_) ->
	user_lib:require_login(admin, Req).
	
index('GET', [], Admin) ->
	Menus = boss_db:find(menu, [], [{order_by, date}, descending]),
	{ok, [{menus, Menus}, {eater, Admin}]}.

mahlzeit('POST', [], Admin) ->
	Menu_Id = Req:post_param("menu-id"),
	Menu = boss_db:find(Menu_Id),
	ok = send_mail(Menu:booking(), Menu, "Das Essen ist fertig!"),
	lager:info("uc : mahlzeit; menu-id : ~p", [Menu_Id]),
	{redirect, [{'action', "index"}]}.
	
detail('GET', [Id], Admin) ->
	Menu = boss_db:find(Id),
	Eaters = boss_db:find(eater, [{account, 'not_matches', "gast-*"}, {account, 'not_matches', "praktikant-*"}]),
	Requesters = Menu:get_requester(),
	{ok, [{menu, Menu}, {eaters, lists:keysort(6,Eaters)}, {eater, Admin}, {requesters, Requesters}]}.	
	
edit('GET', [Id], Admin) ->
	Menu = boss_db:find(Id),
	Menus = boss_db:find(menu, []),
	{ok, [{menu, Menu}, {menus, Menus}, {eater, Admin}]}.

add('POST', [Id], Admin) ->
	Date = calendar:universal_time(),
	EaterId = Req:post_param("esser"),
	Menu = boss_db:find(Id),
	case EaterId of 
		undefined -> {redirect, elib:get_full_path(speiseplan, "/admin/detail/" ++ Id)};
		_ ->	case boss_db:find(booking, [{menu_id, 'equals', Id}, {eater_id , 'equals', EaterId}]) of
					[Result] -> {redirect, elib:get_full_path(speiseplan, "/admin/detail/" ++ Id)};
							_->	NewBooking = booking:new(id, Date, Menu:date(), false, EaterId, Id),	
								{ok, SavedBooking} = NewBooking:save(),
								lager:info("uc : add; eater-id : ~p; menu: ~p; booking : ~p", [EaterId, Menu, NewBooking]),
								delete_requester(Id, EaterId),	
								Eater = boss_db:find(EaterId),
								Menu = boss_db:find(Id),
								send_a_mail(Eater, Menu, get_env(speiseplan, mail_bestaetigung, "")),								
								{redirect, elib:get_full_path(speiseplan, "/admin/detail/" ++ Id)}
				end
	end.
handle_requester('POST', [Id], Admin) ->
	Button = Req:post_param("button"),
	case Button of 
		"hinzufuegen" -> add('POST', [Id], Admin);
		"ablehnen" -> refuse('POST', [Id], Admin)
	end.

refuse('POST', [Id], Admin) ->	
	EaterId = Req:post_param("esser"),
	Eater = boss_db:find(EaterId),
	Menu = boss_db:find(Id),
	lager:info("uc : refuse; eater-id : ~p; menu: ~p", [EaterId, Menu]),
	delete_requester(Id, EaterId),	
	send_a_mail(Eater, Menu, get_env(speiseplan, mail_ablehnung, "")),		
	{redirect, elib:get_full_path(speiseplan, "/admin/detail/" ++ Id)}.

delete_requester(MenuId, EaterId) ->
	case boss_db:find(requester, [{menu_id, 'equals', MenuId}, {eater_id, 'equals', EaterId}]) of
		[] -> lager:info("can't delete requester : ~p", [EaterId]);
		[Requester] -> boss_db:delete(Requester:id())
	end.

%% add a count of guests to a menu	
add_guest('POST', [Id], Admin) ->
	Date = calendar:universal_time(),
	Count = Req:post_param("guest_count"),
	Menu = boss_db:find(Id),
	Bookings = find_all_bookings(Id, "gast-*"),
	delete(Bookings),
	add_guests(list_to_integer(Count), Date, Menu:date(), Id),
	lager:info("uc : add_guest; count : ~p; menu : ~p; date : ~p", [Count, Menu, Date]),
	{redirect, elib:get_full_path(speiseplan, "/admin/detail/" ++ Id)}.

%% add a count of praktikant to a menu	
add_praktikant('POST', [Id], Admin) ->
	Date = calendar:universal_time(),
	Count = Req:post_param("praktikant_count"),
	Menu = boss_db:find(Id),
	Bookings = find_all_bookings(Id, "praktikant-*"),
	delete(Bookings),
	add_praktikanten(list_to_integer(Count), Date, Menu:date(), Id),
	lager:info("uc : add_praktikant; count : ~p; menu : ~p; date : ~p", [Count, Menu, Date]),
	{redirect, elib:get_full_path(speiseplan, "/admin/detail/" ++ Id)}.

add_count_given('POST', [Id], Admin) ->	
	 Menu = boss_db:find(Id),
	 Count_Given = Req:post_param("count_given"),
	 MenuNew = Menu:set([{'count_given', Count_Given}]),
	 {ok, SavedMenu} = MenuNew:save(),
	 lager:info("uc : add_count_given; count_given : ~p; menu : ~p;", [Count_Given, Menu]),
	 {redirect, elib:get_full_path(speiseplan, "/admin/detail/" ++ Id)}.
	
remove('POST', [Id], Admin) ->
	EaterId = Req:post_param("esser"),
	[Booking] = boss_db:find(booking, [{menu_id, 'equals', Id}, {eater_id , 'equals', EaterId}]),
	ok = boss_db:delete(Booking:id()),
	lager:info("uc : remove; eater-id : ~p; bookin : ~p;", [EaterId, Booking]),
	{redirect, elib:get_full_path(speiseplan, "/admin/detail/" ++ Id)}.

storno('POST', [], Admin) ->
	Menu_Id = Req:post_param("menu-id"),
	Menu = boss_db:find(Menu_Id),
	ok = send_mail(Menu:booking(), Menu, "Das Essen muss leider abgesagt werden."),
	remove_bookings(Menu:booking()),
	boss_db:delete(Menu_Id),
	lager:info("uc : storno; menu : ~p", [Menu]),
	{redirect, elib:get_full_path(speiseplan, "/admin/index")}.	
	
remove_bookings([]) ->
	ok;
remove_bookings([Booking|Bookings]) ->
	boss_db:delete(Booking:id()),
	remove_bookings(Bookings).
	
create('POST', [], Admin) ->
	CreatedDate = date_lib:create_actual_date(),
	Date = Req:post_param("date"),
	Title = Req:post_param("title"),
	Details = Req:post_param("details"),
	Slots = Req:post_param("slots"),
	Vegetarian = Req:post_param("vegetarian"),
	
	NewDish = dish:new(id, Title, Details, elib:handle_checkbox(Vegetarian)),	
	case NewDish:save() of
		{error, Errors} -> {redirect, [{'action', "index"}]};
		{ok, SavedDish} -> NewMenu = menu:new(id, CreatedDate, date_lib:create_date_from_string(Date), SavedDish:id(), Slots, "0"),
						   case NewMenu:save() of
								{ok, SavedMenu} -> {redirect, [{'action', "index"}]};
								{error, Errors} -> {redirect, [{'action', "edit"}]}
							end
	end.

update('POST', [], Admin) ->
	Id = Req:post_param("id"),
	Menu = boss_db:find(Id),
	Dish = Menu:dish(),
	Date = Req:post_param("date"),
	Title = Req:post_param("title"),
	Details = Req:post_param("details"),
	Slots = Req:post_param("slots"),
	Vegetarian = Req:post_param("vegetarian"),	
	NewDish = Dish:set([{'title', Title}, {'details', Details}, {'vegetarian', elib:handle_checkbox(Vegetarian)}]),
	NewMenu = Menu:set([{'date', date_lib:create_date_from_string(Date)}, {'slots', Slots}]),
	{ok, SavedDish} = NewDish:save(),
	case NewMenu:save() of
		{ok, SavedMenu} -> {redirect, [{'action', "index"}]};
		{error, Errors} -> {redirect, [{'action', "edit"}, {menu, Menu}, {eater, Admin}, {errors, Errors}]}
	end.

readyMail('POST', [], Admin) ->	
	send_ready_mail(),	
	{redirect, [{'action', "index"}]}.

		
send_mail([], Menu, Text) ->
	ok;
send_mail([Booking|Bookings], Menu, Text) ->
	Eater = Booking:eater(),
	send_a_mail(Eater, Menu, Text),
	send_mail(Bookings, Menu, Text).

send_a_mail(Eater, Menu, Text) ->
	From = get_env(speiseplan, mail_from, "anja.angermann@innoq.com"),
	boss_mail:send(From, Eater:mail(), Menu:get_date_as_string(), unicode:characters_to_list(Text, utf8)).

send_ready_mail() ->
	From = get_env(speiseplan, mail_from, "anja.angermann@innoq.com"),
	To = get_env(speiseplan, mail_to, "monheim@lists.innoq.com"),
	Text = get_env(speiseplan, mail_ready, ""),
	lager:info("sending ready Mail from : ~p to : ~p", [From, To]),
	boss_mail:send(From, To, "Mittag für die nächste Woche ist eingestellt.", Text).

get_env(App, Key, Default) ->
	boss_env:get_env(App, Key, Default).

find_all_bookings(Menu_id, RegExp) ->
	find_all(Menu_id, RegExp).

find_all(Menu_id, RegExp) ->
	Bookings = boss_db:find(booking, [{menu_id, 'eq', Menu_id}]),	
	[Booking||Booking <- Bookings, is_guest_booking(Booking:eater(), RegExp)].
	
is_guest_booking(Eater, RegExp) ->
	case boss_db:find(eater, [{id, eq, Eater:id()}, {account, matches, RegExp}]) of 
		[] -> false;
		_ -> true 
	end.

delete(Bookings) ->
	[boss_db:delete(Booking:id()) || Booking <- Bookings].

add_praktikanten(0, Date, Menu_date, Id) ->
	ok;
add_praktikanten(Count, Date, Menu_date, Id) ->
	save_guest_or_prakt("praktikant-", Count, Date, Menu_date, Id),
	add_praktikanten(Count - 1, Date, Menu_date, Id).


add_guests(0, Date, Menu_date, Id) ->
	ok;
add_guests(Count, Date, Menu_date, Id) ->
	save_guest_or_prakt("gast-", Count, Date, Menu_date, Id),
	add_guests(Count - 1, Date, Menu_date, Id).

save_guest_or_prakt(Sign, Count, Date, Menu_date, Id) ->
	[Eater] =boss_db:find(eater, [{account, eq, Sign ++ integer_to_list(Count)}]),
	NewBooking_ = booking:new(id, Date, Menu_date, false, Eater:id(), Id),	
	{ok, SavedBooking} = NewBooking_:save().