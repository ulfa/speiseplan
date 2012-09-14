-module(speiseplan_registration_controller, [Req]).
-compile(export_all).

index('GET', []) ->
  {ok, []}.

create('POST', []) ->
	Account = Req:post_param("account"),
	Name = Req:post_param("name"),
  	Mail = Req:post_param("mail"),
  	Forename = Req:post_param("forename"),
  	Password = Req:post_param("password"),
  	Intern = Req:post_param("intern"),
  	NewEater = eater:new(id, Account, user_lib:hash_for(Account, Password), Forename, Name, Intern, "0.0", "false", Mail, false),
	case NewEater:save() of
  		{ok, SavedEater} -> {redirect, "/login/index"};
    	{error, Errors} -> {ok, [{errors, Errors}, {eater,NewEater}]}
	end.
	
send_mail(Eater) ->
	boss_mail:send("noreply@kiezkantine.de", Eater:mail(), "Registration", "Bitte bestätige deine Registrierung"),
	

	
	

