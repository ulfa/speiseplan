-module(user_lib).
-compile(export_all).

hash_password(Password, Salt) ->
  mochihex:to_hex(erlang:md5(Salt ++ Password)).

hash_for(Name, Password) ->
  Salt = mochihex:to_hex(erlang:md5(Name)),
  hash_password(Password, Salt).

require_login(Req) ->
error_logger:info_msg("X1... : ~p~n" , [Req:header("REMOTE_USER")]), 
Account = case Req:header("REMOTE_USER") of 
    undefined -> "guest";
    Acc -> Acc
  end,
  error_logger:info_msg("X1... : ~p~n" , [Account]), 
  [E] = boss_db:find(eater, [{account, 'equals', Account}]),
  {ok, E}.

require_login(admin, Req) -> 
  error_logger:info_msg("X2... : " , [Req:header("REMOTE_USER")]), 
	case require_login(Req) of
		{redirect, "/login/index"}	-> {redirect, "/login/index"};
		{ok, User} ->
			case User:admin() =:= true of
				true -> {ok, User};
				_ -> {redirect, "/login/index"}
			end
	end.	