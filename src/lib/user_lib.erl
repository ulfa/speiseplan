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
        [] -> lager:warning("uc : login; account ~p is missing", [Account]), 
             {redirect, elib:get_full_path(speiseplan, "/error/viernullvier")}
    end.

require_login(admin, Req) -> 
	require_login(Req).

get_forename(Display_name) when is_list(Display_name) ->
  case string:rstr(Display_name, " ") of 
    0 -> Display_name;
    _ -> string:substr(Display_name, 1, string:str(Display_name," ") - 1)
  end;
get_forename(Eater) ->
    get_forename(Eater:display_name()).

get_lastname(Display_name) when is_list(Display_name) ->
    string:substr(Display_name, string:str(Display_name," ") + 1, erlang:length(Display_name));  
get_lastname(Eater) ->
    get_lastname(Eater:display_name()).

concat(Lastname, Forname) ->
    lists:flatten([Lastname, " ", Forname]).


%% --------------------------------------------------------------------
%%% Test functions
%% --------------------------------------------------------------------
-include_lib("eunit/include/eunit.hrl").
-ifdef(TEST).
-endif.
