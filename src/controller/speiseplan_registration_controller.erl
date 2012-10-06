-module(speiseplan_registration_controller, [Req]).
-compile(export_all).

index('GET', []) ->
  {ok, []}.

confirm('GET', [EaterId]) ->
	case boss_db:find(EaterId) of
		{error, Reason} -> {ok, [{errors, Reason}]};
		Eater -> UpdatedEater = Eater:set([{'verified', true}]),
				{ok, SavedEater} = UpdatedEater:save(),
				{ok, [{eater, SavedEater}]}
	end.

create('POST', []) ->
	Account = Req:post_param("account"),
	Name = Req:post_param("name"),
  	Mail = Req:post_param("mail"),
  	Forename = Req:post_param("forename"),
  	Password = Req:post_param("password"),
  	Intern = Req:post_param("intern"),
	Host = Req:header(host),
	NewEater = eater:new(id, Account, user_lib:hash_for(Account, Password), Forename, Name, Intern, "0.0", "false", Mail, true),	
	case boss_db:find(eater, [{account, 'eq', Account}]) of
		[] -> case NewEater:save() of
	  			{ok, SavedEater} -> send_mail(SavedEater, Host), {redirect, "/login/index"};
	    		{error, Errors} -> {ok, [{errors, Errors}, {eater, NewEater}]}
			end;	  				 
		_ -> {ok, [{errors, ["Account already exists!"]}, {eater, NewEater}]}
	end.
	
send_mail(Eater, Host) ->
	boss_mail:send("kuechenbulle@kiezkantine.de", Eater:mail(), "Registration", create_confirm_link(Eater, Host)).

create_confirm_link(Eater, Host) ->
	io_lib:format("Bitte bestätige deine Registrierung durch klicken auf den Link: http://~s/registration/confirm/~s", [Host, Eater:id()]).
	

	
	

