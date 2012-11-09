-module(menu_tests).
-include_lib("eunit/include/eunit.hrl").

-module(menu, [Id, CreatedDate, Date, DishId, Slots, CountGiven]).

create_test() ->
	Dish = dish:new().
	Menu = menu:new(id, calendar:universal_time(), {{2012,11,11}, {00,00,00}},)