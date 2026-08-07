
Id = Id or {}
Id.Verbose = false

function Id.getFromWorldObjects(worldobjects,idFunc)
    for iter,isoObj in ipairs(worldobjects) do
        if Id.Verbose then print('Id.getFromWorldObject '..o2str(isoObj)..' '..tostring(isoObj)) end
        if idFunc(isoObj) then
            return isoObj
        end
    end
    return nil
end

function Id.isDeadBody(isoObject)
    return instanceof(isoObject,'IsoDeadBody')
end
