-module(speiseplan_eater_controller, [Req]).
-compile(export_all).
before_(_) ->
	user_lib:require_login(Req).

login('GET', []) ->
  {ok, [{redirect, Req:header(referer)}]};

login('POST', []) ->
  Account = Req:post_param("account"),
  case boss_db:find(eater, [{account, Account}]) of
    [Eater] ->
      case Eater:check_password(Req:post_param("password")) of
        true -> {redirect, "/booking/index", Eater:login_cookies()};
        false -> {ok, [{error, "Bad name/password combination"}]}
      end;
    [] -> {ok, [{error, "No Eater with Account :  " ++ Account}]}
  end.

index('GET', [], Admin) ->
  Eaters = boss_db:find(eater, []),
  {ok, [{eaters, Eaters}, {eater, Admin}]}.

edit('POST', [Id], Admin) ->
	Eater = boss_db:find(Id),
	{ok, [{edit_eater, Eater},{eater, Admin}]}.
	
delete('POST', [Id]) ->
	ok = boss_db:delete(Id),
	{redirect, "/eater/index"}.		

update('POST', [Id]) ->
	Eater = boss_db:find(Id),
	Account = Req:post_param("account"),
	Name = Req:post_param("name"),
	Mail = Req:post_param("mail"),
	Forename = Req:post_param("forename"),
	Intern = convert_to_boolean(Req:post_param("intern")),
	Admin = convert_to_boolean(Req:post_param("admin")),
	PriceToPay = Req:post_param("priceToPay"),
	NewEater = Eater:set([{'account', Account}, {'forename', Forename}, {'name', Name}, {'price_to_pay', PriceToPay}, {'intern', Intern}, {'admin', Admin}, {'mail', Mail}]),
  {ok, SavedEater} = NewEater:save(),
  {redirect, [{'action', "index"}]}.
	
	
create('POST', []) ->
  Account = Req:post_param("account"),
  Name = Req:post_param("name"),
  Mail = Req:post_param("mail"),
  Forename = Req:post_param("forename"),
  Password = Req:post_param("password"),
  Intern = convert_to_boolean(Req:post_param("intern")),
  Admin = convert_to_boolean(Req:post_param("admin")),	
  NewEater = eater:new(id, Account, user_lib:hash_for(Account, Password), Forename, Name, Intern, "0.0", Admin, Mail),
  {ok, SavedEater} = NewEater:save(),
  {redirect, [{'action', "index"}]}.

convert_to_boolean(Value) ->
	io:format("1.. : ~p~n", [Value]),
	Value =:= "true".
