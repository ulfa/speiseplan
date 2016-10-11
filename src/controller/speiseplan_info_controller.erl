-module(speiseplan_info_controller, [Req]).
-compile(export_all).

health('GET', []) ->
    {json, [{version, boss_env:get_env(speiseplan, version, "undefined")}]}.