-module(menu, [Id, Date, DishId, Slots]).
-compile(export_all).
-belongs_to(dish).
-has({booking, many}).

