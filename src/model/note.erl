-module(note, [Id, CreatedDate, Ativ, Text, FromDate, ToDate]).
-compile(export_all).

created_date_as_string() ->
	date_lib:create_date_string(CreatedDate).