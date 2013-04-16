-module(speiseplan_actual_controller, [Req]).
-compile(export_all).

	before_(_) ->
		user_lib:require_login(Req).

	index('GET', [], Eater) ->
		D = date_lib:create_date_from_string([]),
		Date = date_lib:create_date_german_string(D),	
		show_menu(boss_db:find(menu, [{date,  D}]), Date, Eater).
		
	show_menu([], Date, Eater) ->
		case boss_db:find(note, [{ativ, true}]) of
			[] -> {ok, [{eater, Eater}, {text, "bleibt die K&Uuml;che kalt"}, {date, Date}]};
			[Note] -> {ok, [{eater, Eater}, {text, Note:text()}, {date, Date}]}
		end;

	show_menu([Menu], Date, Eater) ->
		{ok, [{eater, Eater}, {text, "gibt es"}, {dish, Menu:dish()}, {date, Date}]}.
				
	show_note([], Date, Eater) ->
			