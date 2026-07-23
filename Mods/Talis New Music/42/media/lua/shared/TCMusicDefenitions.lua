-- Legacy True Music compatibility shim in shared namespace.
-- Some legacy packs resolve require() against shared paths at bootstrap.
if type(GlobalMusic) ~= "table" then
    GlobalMusic = {}
end
