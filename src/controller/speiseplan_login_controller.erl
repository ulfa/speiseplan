-module(speiseplan_login_controller, [Req]).
-compile(export_all).

index('GET', []) ->
  {ok, [{redirect, Req:header(referer)}]};

index('POST', []) ->
  Account = Req:post_param("account"),
		io:format("1... : ~p~n",[Account]),
  case boss_db:find(eater, [{account, Account}]) of
    [Eater] ->
      case Eater:check_password(Req:post_param("password")) of
        true -> {redirect, "/booking/index", Eater:login_cookies()};
        false -> {ok, [{error, "Bad name/password combination"}]}
      end;
    [] -> {ok, [{error, "No Eater with Account :  " ++ Account}]}
  end.