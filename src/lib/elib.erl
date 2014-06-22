-module(elib).
-compile(export_all).

convert_to_boolean(Value) ->
	Value =:= "true".

get_price(true) ->
	3.0;
get_price(false) ->
	5.0.	

intern(true) ->
	3;
intern(false) ->
	5.	

handle_checkbox(Value) ->	
	Value =:= "true". 

get_full_path(App, Path) ->
	Base_url = boss_env:get_env(App, base_url, "/"),
	lists:flatten([Base_url, Path]).