-module(speiseplan_db). 
-export([init/0, reinit/0, reinstall/1]). 

-define(APPNAME, speiseplan). 
-define(MODELS, [list_to_atom(M) || M <- boss_files:model_list(?APPNAME)]). 
-define(NODES, [node()]). 

init() -> 
    mnesia:stop(), 
    mnesia:create_schema(?NODES), 
    mnesia:change_table_copy_type(schema, node(), disc_copies), 
    mnesia:start(), 
    ExistingTables = mnesia:system_info(tables), 
    TablesToCreate = (?MODELS ++ ['_ids_']) -- ExistingTables, 
    io:format("To create: ~p~n",[TablesToCreate]), 
    [install(T) || T <- TablesToCreate], 
    {ok, []}. 


install('_ids_') -> 
    create_table(?NODES, '_ids_', [type, id, count]); 
install(Model) -> 
    io:format("Installing Table ~p~n",[Model]), 
    DummyRecord = boss_record_lib:dummy_record(Model), 
    Attributes = DummyRecord:attribute_names(), 
    create_table(?NODES, Model, Attributes). 

create_table(Nodes, Table, Attributes) -> 
    mnesia:create_table(Table, [{attributes, Attributes}, 
                               {disc_copies, Nodes}]). 


reinit() -> 
    mnesia:stop(), 
    mnesia:delete_schema(?NODES), 
    init(). 

reinstall(Model) -> 
    mnesia:delete_table(Model), 
    install(Model). 
