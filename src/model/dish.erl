-module(dish, [Id, Title, Details, Vegetarian]).
-compile(export_all).

validation_tests() ->
	[{fun() -> length(Title) > 0 end,
		"Please enter a title"}].

