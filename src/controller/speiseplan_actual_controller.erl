-module(speiseplan_actual_controller, [Req]).
-compile(export_all).

index('GET', [], Eater) ->
	Date = date_lib:create_date_german_string({erlang:date(), {0,0,0}}),	
	case boss_db:find(menu, [{date,  {erlang:date(), {0,0,0}}}]) of
		[] -> {ok, [{eater, Eater}, {text, "bleibt die Küche kalt"}, {date, Date}]};
		[Menu] -> {ok, [{eater, Eater}, {text, "gibt es"}, {dish, Menu:dish()}, {date, Date}]}
	end.