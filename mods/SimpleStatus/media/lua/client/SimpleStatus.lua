local utils = require("ss.utils")
local stats = require("ss.stats")

SimpleStatus = {
    VERSION = "1.230503.1",
    
    isNewer = function(self, ver)
        if ver == self.VERSION then return true end
        if not string.match(ver, "^%d+%.%d+%.%d+$") then
            return false
        end
        local v = {}
        local v1 = {}
        for i in string.gmatch(self.VERSION, "([^.]+)") do
            table.insert(v, tonumber(i))
        end
        for i in string.gmatch(ver, "([^.]+)") do
            table.insert(v1, tonumber(i))
        end
        for i = 1, 3 do
            if v1[i] > v[i] then return true end
            if v1[i] < v[i] then return false end
        end
        return true
    end,

    addStat = function(self, name, stat, reverse_stat)
        if stats[name] then return end
        table.insert(stats._values, name)
        stats[name] = stat
        if reverse_stat then
            stats._reverse[name] = reverse_stat
        end
    end
}
