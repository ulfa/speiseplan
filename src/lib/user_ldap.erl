-module(user_ldap).
-include_lib("eldap/include/eldap.hrl").
-define(DEBUG(Var), io:format("DEBUG: ~p:~p - ~p~n ~p~n~n", [?MODULE, ?LINE, ??Var, Var])).
-compile(export_all).

start() ->
	ssl:start(),
	Handle = connect(),
	E = get_externals(Handle),
	?DEBUG(E),
	M = get_members(Handle),
	Members = [get_member(Handle, E, A)||A <- M],
	close(Handle),
	Members.
	
connect() ->
	{ok, Handle} = eldap:open(["testldap.innoq.com"], [{port, 636}, {ssl, true}]),
	Dn = "cn=ulfreader,dc=innoq,dc=com",
	Pw = [86,50,54,110,124,93,120,118,85,86,36,34,34,90,65,122,80,87,80,87,81,108,79,50,104,112],
	BaseDN = {base, "dc=innoq,dc=com"},
	ok = eldap:simple_bind(Handle, Dn, Pw),	
	Handle.

close(Handle) ->
	eldap:close(Handle).
	
get_members(Handle) ->
	M_group = "cn=Mitarbeiter,ou=Group,dc=innoq,dc=com",
	{ok, S} = eldap:search(Handle, [{base, M_group}, {filter, eldap:present("cn")}, {attributes, ["member"]}]),
	convert_members(extract_members(S)).
		
get_member(Handle, Externals, UID) ->	
	M_group = "uid=" ++ UID ++ ",ou=People,dc=innoq,dc=com",
	{ok, S}=eldap:search(Handle, [{base, M_group}, {filter, eldap:present("cn")}, {attributes, ["displayName", "mail"]}]),
	[{account, UID}, {mail, extract_mail(S)}, {display_name, extract_display_name(S)}, {intern, is_internal(UID, Externals)}, {admin, false}, {verified, true}, {confirmed, true}].

get_externals(Handle) ->
	M_group = "cn=Externe,ou=Group,dc=innoq,dc=com",
	{ok, S} = eldap:search(Handle, [{base, M_group}, {filter, eldap:present("cn")}, {attributes, ["member"]}]),
	convert_members(extract_members(S)).
	
convert_members(Members) ->
	lists:append([get_member(string:tokens(D,","))||D <- Members]).
	
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

extract_members(Eldap_search_result) when is_record(Eldap_search_result, eldap_search_result) ->
	Entry = extract_entry(Eldap_search_result),
	[{"member",Members}] = Entry#eldap_entry.attributes,
	Members.	

extract_mail(Eldap_search_result) when is_record(Eldap_search_result, eldap_search_result) ->
	Entry = extract_entry(Eldap_search_result),
	{"mail", [Mail]} = lists:keyfind("mail",1,Entry#eldap_entry.attributes),
	Mail.
	
extract_display_name(Eldap_search_result) when is_record(Eldap_search_result, eldap_search_result) ->
	Entry = extract_entry(Eldap_search_result),
	{"displayName", [DisplayName]} = lists:keyfind("displayName", 1, Entry#eldap_entry.attributes),
	?DEBUG(DisplayName),
	DisplayName.
	
extract_entry(Eldap_search_result) when is_record(Eldap_search_result, eldap_search_result)->
	lists:nth(1,Eldap_search_result#eldap_search_result.entries).

split_display_name(Display_name) ->
	ok.
-include_lib("eunit/include/eunit.hrl").
-ifdef(TEST).
	
is_internal_test() ->
	Externals = ["aa", "bb", "cc"],
	?assertEqual(true, is_internal("bb", Externals)),
	?assertEqual(false, is_internal("dd", Externals)).

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