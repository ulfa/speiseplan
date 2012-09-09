-module(booking, [Id, Date, Vegetarian, EaterId, MenuId]).
-compile(export_all).
-belongs_to(menu).
-belongs_to(eater).

get_formated_date() ->
	{{Year,Month,Day},{Hour,Min,Seconds}} = Date,
	Args = [Year, Month, Day, Hour, Min, Seconds],
	A = io_lib:format("~B-~2.10.0B-~2.10.0B ~2.10.0B:~2.10.0B:~2.10.0B", Args),
	lists:flatten(A).