zdk = zdk or {}

zdk.get_callable_info = function(func)
    if ZombieBuddy and ZombieBuddy.getCallableInfo then
        return ZombieBuddy.getCallableInfo(func)
    end
end
