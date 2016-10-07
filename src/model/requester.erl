-module(requester, [Id, CreatedDate, MenuDate, Vegetarian, MenuId, EaterId]).
-compile(export_all).
-belongs_to(menu).
-belongs_to(eater).

