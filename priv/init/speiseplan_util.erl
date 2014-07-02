-module (speiseplan_util).
-compile (export_all).
-define (APPNAME, speiseplan). % is it possible to get it automatically somewhere in CB?

init() ->
  init_db (),
  create_admin(),
  create_guest_account(10),
  create_praktikant_account(10),
  init_erlcron(),
  ok.

init_db () ->
  init_db ([node ()]). % only for local node? what about nodes()++[node()]?
init_db (Nodes) ->
  mnesia:create_schema (Nodes),
  mnesia:change_table_copy_type (schema, node(), disc_copies), % only for local node?
  mnesia:start (),
  ModelList = [ list_to_atom (M) || M <- boss_files:model_list (?APPNAME) ],
  ExistingTables = mnesia:system_info(tables),
  Tables = (ModelList ++ ['_ids_']) -- ExistingTables,
  create_model_tables (Nodes, Tables).

% create all the tables
create_model_tables (_, []) -> ok;
create_model_tables (Nodes, [Model | Models]) ->
  [create_model_table (Nodes, Model)] ++
   create_model_tables (Nodes, Models).

% specific tables (not generated from model)
create_model_table (Nodes, '_ids_') ->
  create_table (Nodes, '_ids_', [type, id]);

% tables generated from model
create_model_table (Nodes, Model) ->
  Record = boss_record_lib:dummy_record (Model),
  { Model, create_table (Nodes, Model, Record:attribute_names ()) }.

% single table creator wrapper
create_table (Nodes, Table, Attribs) ->
  mnesia:create_table (Table,
    [ { disc_copies, Nodes   },
      { attributes,  Attribs } ]).

% here i will create the init admin 
create_admin() ->
	case boss_db:find(eater,[account,'equals',"ua"]) of
		[] -> NewAdmin = eater:new(id, "ua", user_lib:hash_for("ua", "123fuck456"), "Ulf", "Angermann", "Ulf Angermann", true, 3, true, "ua@innoq.com", true, true),
			  NewAdmin:save();
		_ -> []
	end.

  
create_praktikant_account(0) ->
  ok;
create_praktikant_account(Count) -> 
  create_praktikant("praktikant-" ++ integer_to_list(Count)),
  create_praktikant_account(Count - 1).
create_praktikant([H|T]=Account) ->
  case boss_db:find(eater,[account,'equals',Account]) of
    [] -> NewGuest = eater:new(id, Account, user_lib:hash_for(Account, "123fuck456"), "Praktikant", "Praktikant", lists:flatten([string:to_upper(H),T]), false, 5, false, "ua@innoq.com", true, true),
        NewGuest:save();
    _ -> []
  end.


create_guest_account(0) ->
  ok;
create_guest_account(Count) -> 
  create_guest("gast-" ++ integer_to_list(Count)),
  create_guest_account(Count - 1).

create_guest([H|T]=Account) ->
  case boss_db:find(eater,[account,'equals',Account]) of
    [] -> NewGuest = eater:new(id, Account, user_lib:hash_for(Account, "123fuck456"), "Gast", "Gast", lists:flatten([string:to_upper(H),T]), false, 5, false, "ua@innoq.com", true, true),
        NewGuest:save();
    _ -> []
  end.

init_erlcron() ->
	application:start(erlcron),
	erlcron:cron({{daily, {1, 00, am}}, {user_ldap, start, []}}), 
  erlcron:cron({{daily, {2, 00, am}}, {mnesia, backup, ["../backup/mnesia.backup"]}}).



