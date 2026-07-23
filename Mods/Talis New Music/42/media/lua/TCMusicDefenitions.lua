-- Legacy True Music compatibility shim (historical misspelling kept intentionally).
-- Must never fail: legacy packs require this during bootstrap.
if type(GlobalMusic) ~= "table" then
    GlobalMusic = {}
end

