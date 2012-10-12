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
