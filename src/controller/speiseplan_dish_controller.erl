-module(speiseplan_dish_controller, [Req]).
-compile(export_all).
before_(_) ->
	user_lib:require_login(Req).
	
index('GET', [], Eater) ->
  Bookings = boss_db:find(booking, []),
  {ok, [{bookings, Bookings}, {eater, Eater}]}.

create('GET', []) ->
  ok;
