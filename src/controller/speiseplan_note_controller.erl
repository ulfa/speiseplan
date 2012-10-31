-module(speiseplan_note_controller, [Req]).
-compile(export_all).

before_(_) ->
	user_lib:require_login(admin, Req).
	
index('GET', [], Admin) ->
	Notes = boss_db:find(note, []),
	{ok, [{notes, Notes}, {eater, Admin}]}.
	
create('POST', [], Admin) ->
	Id = Req:post_param("id"),
	CreatedDate = date_lib:create_actual_date(),
	Text = Req:post_param("text"),
	Aktiv = Req:post_param("aktiv"),
	FromDate = Req:post_param("fromdate"),
	ToDate = Req:post_param("todate"),
	save(Id, [{create_date, CreatedDate}, {text, Text}, {ativ, elib:handle_checkbox(Aktiv)}, {from_date,FromDate}, {to_date, ToDate}]),
	{redirect, [{'action', "index"}]}.

edit('GET' ,[Id], Admin) ->
	Note = boss_db:find(Id),
	Notes = boss_db:find(note, []),
	{ok, [{note, Note}, {notes, Notes}, {eater, Admin}]}.
	
save("undefined", [{create_date, CreatedDate}, {text, Text}, {ativ, Aktiv}, {from_date,FromDate}, {to_date, ToDate}]) ->
	NewNote = note:new(id, CreatedDate, Aktiv, Text, FromDate, ToDate),	
	NewNote:save();
	
save(Id, Data) ->
	Note = boss_db:find(Id),
	NewNote = Note:set(Data),
	NewNote:save().