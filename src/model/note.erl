-module(note, [Id, CreatedDate, Ativ, Text, FromDate, ToDate]).
-compile(export_all).

created_date_as_string() ->
	date_lib:create_date_string(CreatedDate).

get_aktiv() ->
	get_aktiv(Ativ).
get_aktiv(true) ->
	"true";
get_aktiv(false) ->
	"false".	
	

