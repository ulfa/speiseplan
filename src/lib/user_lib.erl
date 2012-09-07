-module(user_lib).
-compile(export_all).

hash_password(Password, Salt) ->
  mochihex:to_hex(erlang:md5(Salt ++ Password)).

hash_for(Name, Password) ->
  Salt = mochihex:to_hex(erlang:md5(Name)),
  hash_password(Password, Salt).

require_login(Req) ->
	case Req:cookie("user_id") of
    	undefined -> {redirect, "/eater/login"};
    	Id ->
      		case boss_db:find(Id) of
        		undefined -> {redirect, "/eater/login"};
        		Eater ->
          			case Eater:session_identifier() =:= Req:cookie("session_id") of
            			false -> {redirect, "/eater/login"};
            			true -> {ok, Eater}
          			end
      			end
  			end.

require_login(admin, Req) -> 
	{ok, User} = require_login(Req),
	case User:admin() =:= true of
		true -> {ok, User};
		_ -> {redirect, "/eater/login"}
	end.