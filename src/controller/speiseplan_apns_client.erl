-module(speiseplan_apns_client).

-include("deps/apns/include/apns.hrl").

-export([connect_apn/0, send/2, send_all/1, send_test/0, send_all_test/0]).
-export([log_error/2, log_feedback/1]).


connect_apn() ->
	  apns:connect(
        %% your connection identifier:
        'icook',
        %% called in case of a "hard" error:
        fun ?MODULE:log_error/2,
        %% called if the device uninstalled the application:
        fun ?MODULE:log_feedback/1
      ).

send(Alert, notfound) ->
	ok;
send(Alert, Device_token) ->
  apns:send_message('icook', #apns_msg{
        alert  = Alert ,
        badge  = 1,
        sound  = "default" ,
        category = "INVITE_CATEGORY",
        expiry = 1348000749,
        device_token = Device_token
      }).

send_all(Alert) ->
	[send(Alert, Device_token)||{_Account, Device_token} <- apns_devicetoken_mgr:get()].

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
	apns_devicetoken_mgr:add("aa","63c0d784cb0ccb0d1f93b6271b956afdbdd8371451a6c6f91dc6e7fad85a60e9"),
	send_all("Mahlzeit").