
--Credits where it is due, this comes from
--https://steamcommunity.com/sharedfiles/filedetails/?id=2960089295
--By Deon and Poltergeist

Override = Override or {}
Override.Verbose = false

Override.patchClassMetaMethod = function(class, methodName, createPatch)
    local metatable = __classmetatables[class]
    if not metatable then
        error("Unable to find metatable for class "..tostring(class))
    end
    local metatable__index = metatable.__index
    if not metatable__index then
        error("Unable to find __index in metatable for class "..tostring(class))
    end
    local originalMethod = metatable__index[methodName]
    metatable__index[methodName] = createPatch(originalMethod)
    if Override.Verbose then print('Override.patchClassMetaMethod override '..tostring(class)..' '..methodName) end
end
