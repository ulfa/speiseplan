-module(speiseplan_apns_controller, [Req]).
-compile(export_all).


before_(_) ->
	lager:info("user agent: ~p for user: ~p", [Req:header('User-Agent'), Req:header("remote_user")]),
	user_lib:require_login(Req).

register('POST', [], Eater) ->
	Device_token = Req:post_param("device_token"),
	lager:info("Device Token : ~p for eater : ~p", [Device_token, Eater]),
	apns_devicetoken_mgr:add(Eater:account(), Device_token),
	{200, [], []}.
