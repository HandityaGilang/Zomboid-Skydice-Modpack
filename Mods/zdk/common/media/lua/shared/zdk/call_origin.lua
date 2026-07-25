zdk = zdk or {}

local MODS_SPLIT_STR = "/Contents/mods/"
local GAME_SPLIT_STR = "/ProjectZomboid/Project Zomboid.app/Contents/Java/media/lua/"

-- arguments: mod ids to ignore
function zdk.get_call_origin(...)
    if not getCurrentCoroutine or not getCoroutineCallframeStack or not getFilenameOfCallframe or not getLineNumber then return end

    local skip_dirs = {...}
    table.insert(skip_dirs, "zdk") -- always ignore zdk itself

    local ok, result = pcall(function()
        local coro = getCurrentCoroutine()
        if not coro then return end

        for i = 0, 20 do
            local frame = getCoroutineCallframeStack(coro, i)
            if not frame then break end

            -- both getFilenameOfCallframe() and getLineNumber() could return nil
            local fname = getFilenameOfCallframe(frame)
            if fname then
                local skip = false
                for _, skip_dir in ipairs(skip_dirs) do
                    if fname:contains("/mods/" .. skip_dir .. "/") then
                        skip = true
                        break
                    end
                end
                if not skip then
                    local mod       = zdk.fname2mod(fname)
                    local a         = fname:split("/workshop/content/108600/")
                    local b         = a[2] and a[2]:split("/") or {}
                    local steam_id  = b[1]
                    local short_str = a[#a] or fname
                    local line      = getLineNumber(frame)

                    if line then
                        if type(line) == "number" and line > 1 then 
                            line = line - 1    -- points to the next line?
                        end
                        if #b > 2 and mod and mod.getId then
                            table.remove(b, 1) -- steam_id
                            table.remove(b, 1) -- "mods"
                            table.remove(b, 1) -- mod's dir
                            short_str = tostring(mod:getId()) .. "." .. tostring(steam_id) .. "/" .. table.concat(b, "/") .. ":" .. tostring(line)
                        elseif short_str:contains(MODS_SPLIT_STR) then
                            -- ~/Zomboid/Workshop/ZScienceSkill/Contents/mods/ZScienceSkill/common/media/lua/shared/ZScienceSkill/data/glasses.lua:19
                            local a = short_str:split(MODS_SPLIT_STR)
                            short_str = a[#a] .. ":" .. tostring(line)
                        elseif short_str:contains(GAME_SPLIT_STR) then
                            -- ~/Library/Application Support/Steam/steamapps/common/ProjectZomboid/Project Zomboid.app/Contents/Java/media/lua/client/OptionScreens/MainScreen.lua:1822
                            local a = short_str:split(GAME_SPLIT_STR)
                            short_str = a[#a] .. ":" .. tostring(line)
                        else
                            short_str = short_str .. ":" .. tostring(line)
                        end
                    end

                    return {
                        fname     = fname,
                        line      = line,
                        mod       = mod,
                        steam_id  = steam_id,
                        short_str = short_str, -- XXX format is a subject to change, don't rely on it
                    }
                end
            end
        end
    end)

    return ok and result or nil
end

function zdk.get_call_origin_str(...)
    local origin = zdk.get_call_origin(...)
    return origin and origin.short_str or "unknown"
end

function zdk.get_call_origin_mod_id(...)
    local origin = zdk.get_call_origin(...)
    return origin and origin.mod and origin.mod.getId and origin.mod:getId() or nil
end
