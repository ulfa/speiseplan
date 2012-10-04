-module(speiseplan_actual_controller, [Req]).
-compile(export_all).

index('GET', [], Eater) ->
	D = {erlang:date(), {0,0,0}},
 	Date = date_lib:create_date_german_string(D),	
	case boss_db:find(menu, [{date,  D}]) of
		[] -> {ok, [{eater, Eater}, {text, "bleibt die K&Uuml;che kalt"}, {date, Date}]};
		[Menu] -> {ok, [{eater, Eater}, {text, "gibt es"}, {dish, Menu:dish()}, {date, Date}]}
	end.