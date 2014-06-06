-module (speiseplan_util).
-compile (export_all).
-define (APPNAME, speiseplan). % is it possible to get it automatically somewhere in CB?

init() ->
  init_db (),
  create_admin(),
  create_guest(),
  init_erlcron(),
  sue_start(),
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
	case boss_db:find(eater,[account,'equals',"admin"]) of
		[] -> NewAdmin = eater:new(id, "admin", user_lib:hash_for("admin", "123fuck456"), "Admin", "Admin", "Administrator", true, 3, true, "ua@innoq.com", true, true),
			  NewAdmin:save();
		_ -> []
	end.
create_guest() ->
  case boss_db:find(eater,[account,'equals',"guest"]) of
    [] -> NewGuest = eater:new(id, "guest", user_lib:hash_for("guest", "123fuck456"), "Guest", "Guest", "The guest", false, 5, false, "ua@innoq.com", true, true),
        NewGuest:save();
    _ -> []
  end.

sue_start() ->
  sue:start().
init_erlcron() ->
	application:start(erlcron),
	erlcron:cron({{daily, {1, 00, am}}, {user_ldap, start, []}}).
