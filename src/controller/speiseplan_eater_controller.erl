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
	handle_eater_return_value(NewEater:save()).
						
	
create('POST', []) ->
	Id = Req:post_param("id"),
	Account = Req:post_param("account"),
	Name = Req:post_param("name"),
	Mail = Req:post_param("mail"),
	Forename = Req:post_param("forename"),
	Password = Req:post_param("password"),
	Intern = elib:convert_to_boolean(Req:post_param("intern")),
	Admin = elib:convert_to_boolean(Req:post_param("admin")),	
	PriceToPay = Req:post_param("priceToPay"),
	Verified = elib:convert_to_boolean(Req:post_param("verified")),
	Comfirmed = elib:convert_to_boolean(Req:post_param("comfirmed")),
	save(Id, [{'account', Account}, {'forename', Forename}, {'name', Name}, {'price_to_pay', PriceToPay}, {'intern', Intern}, {'admin', Admin}, {'mail', Mail}, {'verified', Verified}, {password, Password},{comfirmed, Comfirmed}]).
%%	NewEater = eater:new(id, Account, user_lib:hash_for(Account, Password), Forename, Name, Intern, "0.0", Admin, Mail, false, false),
%%	handle_eater_return_value(NewEater:save()).
  		
save("undefined", [{'account', Account}, {'forename', Forename}, {'name', Name}, {'price_to_pay', PriceToPay}, {'intern', Intern}, {'admin', Admin}, {'mail', Mail}, {'verified', Verified}, {password, Password}, {comfirmed, Comfirmed}]) ->
		NewEater = eater:new(id, Account, user_lib:hash_for(Account, Password), Forename, Name, Intern, "0.0", Admin, Mail, false, false),	
		handle_eater_return_value(NewEater:save());
	
save(Id, Data) ->
	Eater = boss_db:find(Id),
	NewEater = Eater:set(Data),
	handle_eater_return_value(NewEater:save()).
    
handle_eater_return_value({ok, SavedEater}) ->
	{redirect, [{'action', "index"}]};
handle_eater_return_value({error, Errors}) ->
	{redirect, [{'action', "index"}, {errors, Errors}]}.

