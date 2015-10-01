-module(convert).
-export([change_node_name/4, restore/1]).
-export([migrate/2]).

migrate(From, To) ->
	change_node_name(From, To, "./backup/latest/mnesia.backup", "./backup/latest/migration.backup"),
	restore("./backup/latest/migration.backup"),
	mnesia:stop(),
	mnesia:start(),
	io:format("~n migration finished! ~n").

change_node_name(From, To, Source, Target) ->
	Switch =
		fun
			(Node) when Node == From -> 
				io:format("     - Replacing nodename: '~p' with: '~p'~n", [From, To]),
				To;
			(Node) when Node == To -> throw({error, already_exists});
			(Node) -> 
				io:format("     - Node: '~p' will not be modified (it is not '~p')~n", [Node, From]),
				Node
		end,
	Convert =
		fun
			({schema, db_nodes, Nodes}, Acc) ->
				io:format(" +++ db_nodes ~p~n", [Nodes]),
				{[{schema, db_nodes, lists:map(Switch,Nodes)}], Acc};
			({schema, version, Version}, Acc) ->
				io:format(" +++ version: ~p~n", [Version]),
				{[{schema, version, Version}], Acc};
			({schema, cookie, Cookie}, Acc) ->
				io:format(" +++ cookie: ~p~n", [Cookie]),
				{[{schema, cookie, Cookie}], Acc};
			({schema, Tab, CreateList}, Acc) ->
				io:format("~n * Checking table: '~p'~n", [Tab]),
				%io:format("  . Initial content: ~p~n", [CreateList]),
				Keys = [ram_copies, disc_copies, disc_only_copies],
				OptSwitch =
					fun({Key, Val}) ->
						case lists:member(Key, Keys) of
							true -> 
								io:format("   + Checking key: '~p'~n", [Key]),
								{Key, lists:map(Switch, Val)};
							false-> {Key, Val}
						end
					end,
				Res = {[{schema, Tab, lists:map(OptSwitch, CreateList)}], Acc},
				%io:format("  . Resulting content: ~p~n", [Res]),
				Res;
			(Other, Acc) ->
				%io:format(" --- ~p~n", [Other]),
				{[Other], Acc}
		end,
	{ok, _LastAcc} = mnesia:traverse_backup(Source, Target, Convert, switched).

restore(Backup) ->
	{atomic, _RestoredTabs} = mnesia:restore(Backup, [{default_op, recreate_tables}]).