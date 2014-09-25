-module(speiseplan_dish_controller, [Req]).
-compile(export_all).
before_(_) ->
	user_lib:require_login(admin,Req).
	
index('GET', [], Admin) ->
  Dishes = boss_db:find(dish, []),
  {ok, [{dishes, Dishes}, {eater, Admin}]}.

create('GET', []) ->
  ok;
