-module(user_lib).
-compile(export_all).

hash_password(Password, Salt) ->
  mochihex:to_hex(erlang:md5(Salt ++ Password)).

hash_for(Name, Password) ->
  Salt = mochihex:to_hex(erlang:md5(Name)),
  hash_password(Password, Salt).

require_login(Req) ->
    Account = case Req:header("REMOTE_USER") of
        undefined -> lager:warning("SOMEONE IS ABLE TO LOGIN WITH NO REMOTE HEADER SET"),
                     "ua";
        User -> User        
    end,
    case boss_db:find(eater, [{account, 'equals', Account}]) of 
        [E] -> {ok, E};
        [] -> {redirect, elib:get_full_path(speiseplan, "/error/viernulleins")}
    end.

require_login(admin, Req) -> 
	require_login(Req).
