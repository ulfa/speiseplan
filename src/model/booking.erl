-module(booking, [Id, Date, MenuDate, Vegetarian, EaterId, MenuId]).
-compile(export_all).
-belongs_to(menu).
-belongs_to(eater).

get_formated_date() ->
	date_lib:get_formated_date(Date). 
	
get_vegetarian() ->
	get_vegetarian(Vegetarian).

get_vegetarian(true) ->
	"vegetarisch";
get_vegetarian(false) ->
	"Fleisch".
	
	