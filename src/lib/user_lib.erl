-module(user_lib).
-compile(export_all).

hash_password(Password, Salt) ->
  mochihex:to_hex(erlang:md5(Salt ++ Password)).

hash_for(Name, Password) ->
  Salt = mochihex:to_hex(erlang:md5(Name)),
  hash_password(Password, Salt).

require_login(Req) ->
Account = case Req:header("REMOTE_USER") of 
    undefined -> "ua";
    Acc -> Acc
  end,  
  [E] = boss_db:find(eater, [{account, 'equals', Account}]),
  {ok, E}.

require_login(admin, Req) -> 
	require_login(Req).
