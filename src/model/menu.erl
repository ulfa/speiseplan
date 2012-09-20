-module(menu, [Id, CreatedDate, Date, DishId, Slots]).
-compile(export_all).
-belongs_to(dish).
-has({booking, many}).

is_in_time() ->
	(calendar:datetime_to_gregorian_seconds(Date) - calendar:datetime_to_gregorian_seconds({erlang:date(),{12,0,0}})) > 0.	

is_time_to_book() ->
	calendar:datetime_to_gregorian_seconds(Date) - calendar:datetime_to_gregorian_seconds({erlang:date(),{15,0,0}}) > 72000.
	
get_request_count() ->
	case boss_mq:poll(get_date_as_string()) of
		{ok, Timestamp, Eaters} -> Eaters;
		_ -> []
	end.

get_requester_names() ->
	EaterIds = case boss_mq:poll(get_date_as_string()) of
				{ok, Timestamp, Messages} -> Messages;
				_ -> []
			end,	
	get_req_names(EaterIds, []).

get_req_names([], Requester) ->
	Requester;
get_req_names([EaterId|EaterIds], Requester) ->
	Eater = boss_db:find(erlang:binary_to_list(EaterId)),
	get_req_names(EaterIds, [Eater:name()|Requester]).

get_requester() ->
	EaterIds = case boss_mq:poll(get_date_as_string()) of
					{ok, Timestamp, Messages} -> Messages;
					_ -> []
				end,	
	get_req(EaterIds, []).

get_req([], Requester) ->
	Requester;
get_req([EaterId|EaterIds], Requester) ->
	Eater = boss_db:find(erlang:binary_to_list(EaterId)),
	get_req(EaterIds, [Eater|Requester]).


is_eater_id_in_list(EaterId, List_of_EaterIds) ->
	case [X || X <- List_of_EaterIds, X =:= EaterId] of
		[] -> false;
		_ -> true
	end.
		
get_date_as_string() ->
	date_lib:create_date_string(Date).
	
get_slot_count() ->
	list_to_integer(Slots) - erlang:length(booking()).

get_all_eater() ->
	get_a_eater(booking(), []).

get_a_eater([], Eaters) ->
	Eaters;
get_a_eater([Booking|Bookings], Eaters) ->
	Eater = Booking:eater(),
	get_a_eater(Bookings, [Eater:id()|Eaters]).

get_vegetarian_count() ->
	get_v_count(booking()).

get_v_count([]) ->
	0;	
get_v_count([Booking|Bookings]) ->	
	get_v_count([Booking|Bookings], 0).

get_v_count([], Count) ->
			Count;			
get_v_count([Booking|Bookings], Count) ->
	get_v_count(Bookings, is_vegetarian(Booking, Count));
get_v_count(Booking, Count) ->
	is_vegetarian(Booking, Count).

is_vegetarian([], Count) ->
		Count;
is_vegetarian(Booking, Count) ->
	io:format("vegetarin : ~p~n", [Booking:vegetarian()]),
	case Booking:vegetarian() of
		true -> Count + 1;
		_ -> Count
	end.


get_normal_eater() ->
	get_n_eater(booking(), []).

get_n_eater([], Eaters) ->
	Eaters;	
get_n_eater([Booking|Bookings], Eaters) ->
	get_n_eater(Bookings, get_norm_eater(Booking, Eaters));
get_n_eater(Booking, Eaters) ->
	get_norm_eater(Booking, Eaters).
			
get_norm_eater([], Eaters) ->
	Eaters;
get_norm_eater(Booking, Eaters) ->
	case Booking:vegetarian() of
		false -> Eater = Booking:eater(), [Eater:name()|Eaters];
		_ -> Eaters
	end.

	
get_vegetarian_eater() ->
	get_v_eater(booking(), []).

get_v_eater([], Eaters) ->
	Eaters;	
get_v_eater([Booking|Bookings], Eaters) ->
	get_v_eater(Bookings, get_vegi_eater(Booking, Eaters));
get_v_eater(Booking, Eaters) ->
	get_vegi_eater(Booking, Eaters).
			
get_vegi_eater([], Eaters) ->
	Eaters;
get_vegi_eater(Booking, Eaters) ->
	case Booking:vegetarian() of
		true -> Eater = Booking:eater(), [Eater:name()|Eaters];
		_ -> Eaters
	end.
	
get_sum() ->
	get_s(booking(), 0).

get_s([], Sum) ->
	Sum;

get_s([Booking|Bookings], Sum) ->
	Eater = Booking:eater(),
	Sum1 = Sum + Eater:price_to_pay(),
	get_s(Bookings, Sum1).
