
APP = APP or {}
APP.Verbose = false
APP.fieldMap = {}

local getNumClassFields = getNumClassFields
local getClassField = getClassField
local getClassFieldVal = getClassFieldVal
local tostring = tostring
local strsub = string.sub
local strfind = string.find
local strlenPrivate = string.len("private")
local strlenProtected = string.len("protected")

function APP.getField(class, fieldName)
    for i=0, getNumClassFields(class)-1 do
        local field = getClassField(class,i)
        if not field then
            if APP.Verbose then print ('APP '..tostring(class)..'.'..fieldName..' '..i.." "..tostring("no more field.")); end
            return nil
        end
        
        --private field is not accessible out of debug mod and any access to it (even modifiers reading) will crash
        --that's why I use the dirty string analysis below.
        local stringField = tostring(field)
        local isPrivate = strsub(stringField,1,strlenPrivate)=="private"
        
        if not isPrivate then
            local isProtected = strsub(stringField,1,strlenProtected)=="protected"
            if not isProtected then
                local watchingFieldName = strsub(stringField,-#fieldName)
                local isRightName = fieldName == "" or watchingFieldName == fieldName
                if APP.Verbose then print ('APP '..tostring(class)..'.'..fieldName..' '..i..' '..tostring(isRightName)); end
                if isRightName then
                    return field
                end
                --if we reach here, it was not the right field (but public)
                if APP.Verbose then print ('APP '..tostring(class)..'.'..watchingFieldName..' '..i..' is public.'); end
            else
                if APP.Verbose then print ('APP '..tostring(class)..'.'..fieldName..' '..i..' is protected.'); end
            end
        else
            --if we reach here, it was not the right field (and private or protected)
            if APP.Verbose then print ('APP '..tostring(class)..'.'..fieldName..' '..i..' is private.'); end
        end
    end
    return nil
end


function getPublicFieldValue(classInstance,fieldName)
    local instanceId = APP.getKey(classInstance)
    if not APP.fieldMap[instanceId] then APP.fieldMap[instanceId] = {} end
    local fieldStruct = APP.fieldMap[instanceId][fieldName] --it should be fieldMap[classType][instanceId][fieldName] but instanceId includes also the type so let's save one stage
    if not fieldStruct then--parse the fields only the first time
        fieldStruct = {isValid = false, field=APP.getField(classInstance,fieldName)}
        if fieldStruct.field ~= nil then fieldStruct.isValid = true end
        
        if APP.Verbose then print ('APP Add memo '..tostring(instanceId)..' ['..tostring(fieldName)..'] = '..tostring(fieldStruct.field or 'nil')); end
        APP.fieldMap[instanceId][fieldName] = fieldStruct
    end
    if not fieldStruct.isValid then return nil end--nop
    return getClassFieldVal(classInstance, fieldStruct.field)--yep
end

function APP.getKey(classInstance)--stupidity encapsulation is key
    local strInstance = tostring(classInstance)
    local res = strfind(strInstance,'@')
    if res then
        i, j = res
        if i > 1 then
            local classStr = strsub(strInstance,1,i-1)
            return classStr
        end
    end
    return tostring(classInstance)
end

