-module(json_util).
-compile(export_all).

get_menu_json(Menus) ->
	{menus,[[{menu, Menu}, {dish, Menu:dish()}, get_all_eater_json(Menu), get_all_eater_names_json(Menu), get_free_slots_json(Menu), get_requester_json(Menu), get_vegetarian_json(Menu)]||Menu<-Menus]}.

get_all_eater_json(Menu) ->
	{bookings, [[{eater, Eater}]||Eater <- Menu:get_all_eater()]}.

get_all_eater_names_json(Menu) ->
	Result = case Menu:get_all_eater_names() of
		[] -> "";
		Any -> Any
	end,
	{eater_name, Result}.

get_free_slots_json(Menu) ->
	{free_slots, Menu:get_slot_count()}.

get_vegetarian_json(Menu) ->
	{vegetarian, Menu:get_vegetarian_count()}.

get_requester_json(Menu) ->
	{requesters, [[{requester, Requester:id()}]||Requester <- Menu:get_requester()]}.
