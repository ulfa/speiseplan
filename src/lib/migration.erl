-module(migration).
-compile(export_all).

migrate_all_eaters_displayname_to_forename_and_name() ->
    lager:info("uc : eater migration; migrate displayName into forename and name; start"),
    Eaters = boss_db:find(eater, [], [{account, 'not_matches', "gast-*"}, {account, 'not_matches', "praktikant-*"}]),
    [migrate_one_eaters_displayname_to_forname_and_name(Eater) || Eater <- Eaters],
    lager:info("uc : eater migration; migrate displayName into forename and name; finished").

migrate_one_eaters_displayname_to_forname_and_name(Eater) ->
    Data = [{name, user_lib:get_lastname(Eater:display_name())}, {forename, user_lib:get_forename(Eater:display_name())}],
    NewEater = Eater:set(Data),
    {ok, SavedEater} = NewEater:save().

