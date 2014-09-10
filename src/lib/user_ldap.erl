-module(user_ldap).
-include_lib("eldap/include/eldap.hrl").
-define(DEBUG(Var), io:format("DEBUG: ~p:~p - ~p~n ~p~n~n", [?MODULE, ?LINE, ??Var, Var])).
-define(INTERNAL, "cn=Mitarbeiter,ou=Group,dc=innoq,dc=com").
-define(EXTERNAL, "cn=Externe,ou=Group,dc=innoq,dc=com").

-compile(export_all).

start() ->
	error_logger:info_msg("uc: ldap_import; start"),
	ssl:start(),
	Handle = connect(),
	E = get_account_list(Handle, ?EXTERNAL),
	M = get_account_list(Handle, ?INTERNAL),	
	Members = [get_member(Handle, E, A)||A <- lists:append(M, E)],
	iterate_eaters(Members),
	close(Handle),
	error_logger:info_msg("uc: ldap_import; finished").
		
connect() ->
	Ldap_server = get_env(speiseplan, ldap_server, "testldap.innoq.com"),
	Ldap_port = get_env(speiseplan, ldap_port, 636),
	Ldap_user = get_env(speiseplan, ldap_user, "cn=ulfreader,dc=innoq,dc=com"),
	Ldap_pass = get_env(speiseplan, ldap_pass, [86,50,54,110,124,93,120,118,85,86,36,34,34,90,65,122,80,87,80,87,81,108,79,50,104,112]),
	{ok, Handle} = eldap:open([Ldap_server], [{port, Ldap_port}, {ssl, true}]),
	ok = eldap:simple_bind(Handle, Ldap_user, Ldap_pass),	
	Handle.

close(Handle) ->
	eldap:close(Handle).
	
get_account_list(Handle, Filter) ->
	{ok, S} = eldap:search(Handle, [{base, Filter}, {filter, eldap:present("cn")}, {attributes, ["member"]}]),
	convert_members(extract_members(S, Filter)).
	
get_member(Handle, Externals, UID) ->	
	M_group = "uid=" ++ UID ++ ",ou=People,dc=innoq,dc=com",
	case eldap:search(Handle, [{base, M_group}, {filter, eldap:present("cn")}, {attributes, ["displayName", "mail"]}]) of 		
		{error, Reason} -> lager:error("uc : ldap_import; Error : ~p for uid : ~p ", [Reason, UID]),
							[];
		{ok, S} ->[{account, UID}, {password, user_lib:hash_for(UID, "secret")}, {display_name, extract_display_name(S, M_group)}, {mail, extract_mail(S,M_group)},  {intern, is_internal(UID, Externals)},  {admin, false}, {verified, true}, {comfirmed, true}]
	end.		
	
convert_members(Members) ->
	lists:append([get_member(string:tokens(D,","))||D <- Members]).
	
extract_members(Eldap_search_result, M_group) when is_record(Eldap_search_result, eldap_search_result) ->
	Entry = extract_entry(Eldap_search_result, M_group),
	[{"member", Members}] = Entry#eldap_entry.attributes,
	Members.	

get_member(Member) ->
	[get_uid(A)||A<-Member, is_uid(A)].

get_uid(Uid_string) ->
	[A, B] = string:tokens(Uid_string, "="),
	B.
	
is_internal(UID, Externals) ->
	is_internal([A||A<-Externals, A=:=UID]).
is_internal([]) ->
	true;
is_internal(L) ->
	false.

is_uid(Test) ->
	[A, B] = string:tokens(Test, "="),
	is_uid(A, B).	
is_uid("uid", UID) ->
	true;
is_uid(_A, _B) ->
	false.

extract_mail(Eldap_search_result, M_group) when is_record(Eldap_search_result, eldap_search_result) ->	
	Entry = extract_entry(Eldap_search_result, M_group),	
	{"mail", [Mail]} = lists:keyfind("mail",1,Entry#eldap_entry.attributes),
	Mail.
	
extract_display_name(Eldap_search_result, M_group) when is_record(Eldap_search_result, eldap_search_result) ->
	Entry = extract_entry(Eldap_search_result, M_group),	
	{"displayName", [DisplayName]} = lists:keyfind("displayName", 1, Entry#eldap_entry.attributes),
	DisplayName.
	
extract_entry(Eldap_search_result, M_group) when is_record(Eldap_search_result, eldap_search_result)->
	lists:keyfind(M_group, 2, Eldap_search_result#eldap_search_result.entries).

iterate_eaters([]) ->
	ok;
iterate_eaters([[]|T]) ->
	iterate_eaters(T);
iterate_eaters([H|T]) ->
	{account, UID} = lists:keyfind(account, 1, H),
	?DEBUG(UID),
	save_eater(boss_db:find(eater,[account,'equals',UID]), H),
	iterate_eaters(T).

save_eater([], [{account, Account}, {password, Password}, {display_name, DisplayName},  {mail, Mail}, {intern, Intern}, {admin, Admin}, {verified, Verified},  {comfirmed, Comfirmed}]) ->
	?DEBUG("save new eater"),
	NewEater = eater:new(id, Account, Password, "not set", "not set", DisplayName, Intern, "", Admin, Mail, Verified, Comfirmed),
	Return = NewEater:save(),
	?DEBUG(Return);
save_eater(_A, H) ->
	?DEBUG("allready in DB:"),
	ok.
	
get_env(App, Key, Default) ->
	boss_env:get_env(App, Key, Default).

-include_lib("eunit/include/eunit.hrl").
-ifdef(TEST).

get_env_test() ->
	?assertEqual(636, get_env(speiseplan, ldap_port, fehler)).
	
is_internal_test() ->
	Externals = ["aa", "bb", "cc"],
	?assertEqual(false, is_internal("bb", Externals)),
	?assertEqual(true, is_internal("dd", Externals)).

get_member_test() ->
	?assertEqual(["ua"], get_member(["uid=ua","ou=People","dc=innoq","dc=com"])).
	
convert_members_test() ->
	?assertEqual(["ak", "akl"], convert_members(["uid=ak,ou=People,dc=innoq,dc=com","uid=akl,ou=People,dc=innoq,dc=com"])).
	
is_uid_test() ->
	?assertEqual(true, is_uid("uid=ua")),
	?assertEqual(false, is_uid("cn=ua")).
	
get_uid_test() ->
	?assertEqual("ua", get_uid("uid=ua")).

-endif.