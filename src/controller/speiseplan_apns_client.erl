-module(speiseplan_apns_client).

-include("deps/apns/include/apns.hrl").

-export([connect_apn/0, send/2, send/5, send_all/1, send_apn/2]).
-export([log_error/2, log_feedback/1]).
-export([create_message/5]).
-export([send_test/0, send_all_test/0, send_apn_test/0]).

connect_apn() ->
	  apns:connect(
        %% your connection identifier:
        'icook',
        %% called in case of a "hard" error:
        fun ?MODULE:log_error/2,
        %% called if the device uninstalled the application:
        fun ?MODULE:log_feedback/1
      ).

send_apn(Eater, Menu) ->
  Account = boss_env:get_env(speiseplan, admin_apn, ""),
  Device_token = apns_devicetoken_mgr:get(Account), 
  Message = ["Anfrage für den ", date_lib:create_date_german_string(Menu:date()), "\nvon ", Eater:display_name()],
  lager:info("uc: request : ~p ~p ~p", [Account, Device_token, Message]),
  speiseplan_apns_client:send(anfrage, lists:flatten(Message), Eater:id(), Menu:id(), Device_token). 

send(Alert, notfound) ->
	ok;
send(Alert, Device_token) ->
  create_message(message,Alert, Device_token).

send(anfrage, Alert, Eater_id, Menu_id, Device_token) ->
  create_message(anfrage, Alert, Eater_id, Menu_id, Device_token).

create_message(anfrage, Alert, Eater_id, Menu_id, Device_token) ->
  apns:send_message('icook', #apns_msg{
        alert  = Alert ,
        badge  = 1,
        sound  = "default" ,
        category = "ICOOK_ANFRAGE",
        expiry = 1348000749,        
        extra = [{eater_id, erlang:list_to_binary(Eater_id)}, {menu_id, erlang:list_to_binary(Menu_id)}],
        device_token = Device_token
      }).
create_message(message, Alert, Device_token) ->
  apns:send_message('icook', #apns_msg{
        alert  = Alert ,
        badge  = 1,
        sound  = "default" ,
        category = "ICOOK",
        expiry = 1348000749,        
        device_token = Device_token
      }).

send_all(Alert) ->
	[send(Alert, Device_token:device_token())||Device_token <- apns_devicetoken_mgr:get()].

-spec log_error(string(), string()) -> ok.
log_error(MsgId, Status) ->
  lager:error("Error on msg ~p: ~p", [MsgId, Status]).

-spec log_feedback(string()) -> ok.
log_feedback(Token) ->
  lager:warning("Device with token ~p removed the app~n", [Token]).

send_test() ->
	apns_devicetoken_mgr:add("ua","63c0d784cb0ccb0d1f93b6271b956afdbdd8371451a6c6f91dc6e7fad85a60e9"),
	send("Mahlzeit", apns_devicetoken_mgr:get("ua")).

send_all_test() ->
	apns_devicetoken_mgr:add("ua","63c0d784cb0ccb0d1f93b6271b956afdbdd8371451a6c6f91dc6e7fad85a60e9"),
	send_all("Mahlzeit").

send_apn_test() ->
  Menu = boss_db:find("menu-1"),
  Eater = boss_db:find("eater-1"),
  send_apn(Eater, Menu).