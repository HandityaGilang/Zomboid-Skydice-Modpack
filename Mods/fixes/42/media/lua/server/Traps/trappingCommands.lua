require "Traps/STrapSystem"

if isClient() then return end

local Commands = {}

local function noise(message) 
    if STrapSystem.instance then
        STrapSystem.instance:noise(message) 
    end
end

local function getTrapAt(x, y, z)
    if not STrapSystem.instance then return nil end
    return STrapSystem.instance:getLuaObjectAt(x, y, z)
end

function Commands.add(player, args)
    if not args then return end
    
    local trap = getTrapAt(args.x, args.y, args.z)
    if trap then
        noise('client placed > 1 trap at '..args.x..','..args.y..','..args.z)
    else
        local cell = getCell()
        if not cell then return end
        
        local square = cell:getGridSquare(args.x, args.y, args.z)
        if square then
            local object = STrapSystem.findTrapObject(square)
            if object then
                STrapSystem.loadObject(object)
            end
        end
    end
end

function Commands.remove(player, args)
    if not player or not args then return end
    
    local trap = getTrapAt(args.x, args.y, args.z)
    if trap then
        local item = instanceItem(trap.trapType)
        if item then
            player:getInventory():AddItem(item);
            sendAddItemToContainer(player:getInventory(), item);
        end
        trap:removeBait(player)
        trap:removeIsoObject()
    else
        noise('no trap found at '..args.x..','..args.y..','..args.z)
    end
end

function Commands.removeAnimal(player, args)
    if not player or not args then return end
    
    local trap = getTrapAt(args.x, args.y, args.z)
    if trap then
        if trap.animal and trap.animal.type then
            trap:removeAnimal(player)
        else
            noise('no animal in trap at '..args.x..','..args.y..','..args.z)
        end
    else
        noise('no trap found at '..args.x..','..args.y..','..args.z)
    end
end

function Commands.addBait(player, args)
    if not player or not args then return end
    
    local trap = getTrapAt(args.x, args.y, args.z)
    if trap then
        trap:addBait(args.bait, args.age, args.baitAmountMulti, player)
    else
        noise('no trap found at '..args.x..','..args.y..','..args.z)
    end
end

function Commands.addAnimalDebug(player, args)
    if not args then return end
    
    local trap = getTrapAt(args.x, args.y, args.z)
    if trap then
        trap:setAnimal(args.animal)
    else
        noise('no trap found at '..args.x..','..args.y..','..args.z)
    end
end

function Commands.checkTrap(player, args)
    if not player or not args then return end
    
    local trap = getTrapAt(args.x, args.y, args.z)
    if trap then
        -- NO SERVIDOR: Executar verificacao diretamente, sem usar funcoes de cliente
        -- ISTrapMenu.onCheckTrap usa luautils.walkAdj que e uma funcao de CLIENTE
        -- Entao no servidor, processamos diretamente
        
        local world = getWorld()
        if not world then return end
        local cell = world:getCell()
        if not cell then return end
        
        local square = cell:getGridSquare(args.x, args.y, args.z)
        if not square then return end
        
        -- Verificar se tem animal na armadilha
        if trap.animal and trap.animal.type then
            -- Notificar cliente que tem animal
            sendServerCommand(player, "trap", "hasAnimal", {
                x = args.x,
                y = args.y,
                z = args.z,
                animal = trap.animal
            })
        else
            -- Notificar cliente que armadilha esta vazia
            sendServerCommand(player, "trap", "isEmpty", {
                x = args.x,
                y = args.y,
                z = args.z
            })
        end
        
        -- Atualizar objeto da armadilha
        local isoObject = trap:getIsoObject()
        if isoObject then
            trap:toObject(isoObject, true)
        end
    else
        noise('no trap found at '..args.x..','..args.y..','..args.z)
    end
end

function Commands.removeBait(player, args)
    if not player or not args then return end
    
    local trap = getTrapAt(args.x, args.y, args.z)
    if trap then
        trap:removeBait(player)
    else
        noise('no trap found at '..args.x..','..args.y..','..args.z)
    end
end

function Commands.destroy(player, args)
    if not args then return end
    
    local trap = getTrapAt(args.x, args.y, args.z)
    if trap then
        local world = getWorld()
        if not world then return end
        local cell = world:getCell()
        if not cell then return end
        
        local square = cell:getGridSquare(args.x, args.y, args.z)
        if square then
            local isoObject = trap:getIsoObject()
            trap:spawnDestroyItems(square, isoObject)
            trap:removeIsoObject()
        else
            trap.destroyed = true
        end
    else
        noise('no trap found at '..args.x..','..args.y..','..args.z)
    end
end

STrapSystemCommands = Commands
