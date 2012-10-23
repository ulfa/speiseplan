-module(speiseplan_eater_controller, [Req]).
-compile(export_all).

before_(_) ->
	user_lib:require_login(admin, Req).

index('GET', [], Admin) ->
  Eaters = boss_db:find(eater, []),
  {ok, [{eaters, Eaters}, {eater, Admin}]}.

edit('GET', [Id], Admin) ->
	Eaters = boss_db:find(eater, []),
	Eater = boss_db:find(Id),
	{ok, [{edit_eater, Eater},{eater, Admin}, {eaters, Eaters}]}.
	
delete('POST', [Id], Admin) ->
	ok = boss_db:delete(Id),
	{redirect, "/eater/index"}.

verfied('POST', [Id], Admin) ->
	Eater = boss_db:find(Id),
	Verified = elib:convert_to_boolean(Req:post_param("verified")),
	NewEater = Eater:set([{verified, Verified}]),
	{ok, SavedEater} = NewEater:save(),
	{redirect, [{'action', "index"}]}.
						
update('POST', [Id]) ->
	Eater = boss_db:find(Id),
	Account = Req:post_param("account"),
	Name = Req:post_param("name"),
	Mail = Req:post_param("mail"),
	Forename = Req:post_param("forename"),
	Intern = elib:convert_to_boolean(Req:post_param("intern")),
	Admin = elib:convert_to_boolean(Req:post_param("admin")),
	Verified = elib:convert_to_boolean(Req:post_param("verified")),
	PriceToPay = Req:post_param("priceToPay"),
	NewEater = Eater:set([{'account', Account}, {'forename', Forename}, {'name', Name}, {'price_to_pay', PriceToPay}, {'intern', Intern}, {'admin', Admin}, {'mail', Mail}, {'verified', Verified}]),
	{ok, SavedEater} = NewEater:save(),
	{redirect, [{'action', "index"}]}.
	
	
create('POST', []) ->
	Account = Req:post_param("account"),
	Name = Req:post_param("name"),
	Mail = Req:post_param("mail"),
	Forename = Req:post_param("forename"),
	Password = Req:post_param("password"),
	Intern = elib:convert_to_boolean(Req:post_param("intern")),
	Admin = elib:convert_to_boolean(Req:post_param("admin")),	
	NewEater = eater:new(id, Account, user_lib:hash_for(Account, Password), Forename, Name, Intern, "0.0", Admin, Mail, false, false),
	case  NewEater:save() of
		{ok, SavedEater} -> {redirect, [{'action', "index"}]};
		{error, Errors} -> {redirect, [{'action', "index"}]}
	end.
  
