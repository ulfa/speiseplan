-module(speiseplan_note_controller, [Req]).
-compile(export_all).

before_(_) ->
	user_lib:require_login(admin, Req).
	
index('GET', [], Admin) ->
	Menus = boss_db:find(note, [], [{aktiv, true}]),
	{ok, [{notes, Menus}, {eater, Admin}]}.
	
create('POST', [], Admin) ->
	CreatedDate = date_lib:create_actual_date(),
	Text = Req:post_param("text"),
	Aktiv = Req:post_param("aktiv"),
	FromDate = Req:post_param("fromdate"),
	ToDate = Req:post_param("todate"),
	NewNote = note:new(id, CreatedDate, elib:handle_checkbox(Aktiv), Text, FromDate, ToDate),	
	NewNote:save(),
	{redirect, [{'action', "index"}]}.
