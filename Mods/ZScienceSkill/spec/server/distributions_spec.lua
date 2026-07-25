-- Test for ZScienceSkill_Distributions.lua
-- Verifies Science skill books are added to loot distributions

describe("Science book items", function()
    it("BookScience1 is registered with ScriptManager", function()
        local item = ScriptManager.instance:getItem("ZScienceSkill.BookScience1")
        assert.is_not_nil(item, "BookScience1 should be registered")
    end)
    
    it("all 5 volumes are registered", function()
        for i = 1, 5 do
            local item = ScriptManager.instance:getItem("ZScienceSkill.BookScience" .. i)
            assert.is_not_nil(item, "BookScience" .. i .. " should be registered")
        end
    end)
    
    it("BookScience1 can be instantiated", function()
        local item = create_item("ZScienceSkill.BookScience1")
        assert.is_not_nil(item, "Should be able to create BookScience1 instance")
    end)
end)

describe("Science book distributions", function()
    it("ProceduralDistributions exists after game init", function()
        assert.is_not_nil(ProceduralDistributions)
        assert.is_table(ProceduralDistributions.list)
    end)
    
    it("LibraryBooks distribution contains Science books", function()
        local dist = ProceduralDistributions.list.LibraryBooks
        if not dist then
            ZBSpec.skip("LibraryBooks distribution not found")
            return
        end
        
        -- Check if BookScience1 is in the items list
        local found = false
        for i = 1, #dist.items, 2 do
            if dist.items[i] == "ZScienceSkill.BookScience1" then
                found = true
                break
            end
        end
        assert.is_true(found, "BookScience1 should be in LibraryBooks distribution")
    end)
    
    it("BookstoreBooks distribution contains Science books", function()
        local dist = ProceduralDistributions.list.BookstoreBooks
        if not dist then
            ZBSpec.skip("BookstoreBooks distribution not found")
            return
        end
        
        local foundBooks = {}
        for i = 1, #dist.items, 2 do
            local item = dist.items[i]
            if item and item:match("^ZScienceSkill%.BookScience") then
                foundBooks[item] = dist.items[i + 1]  -- weight
            end
        end
        
        -- Should have all 5 volumes
        assert(foundBooks["ZScienceSkill.BookScience1"])
        assert(foundBooks["ZScienceSkill.BookScience2"])
        assert(foundBooks["ZScienceSkill.BookScience3"])
        assert(foundBooks["ZScienceSkill.BookScience4"])
        assert(foundBooks["ZScienceSkill.BookScience5"])
    end)
    
    it("higher volume books have lower spawn weights", function()
        local dist = ProceduralDistributions.list.LibraryBooks
        if not dist then
            ZBSpec.skip("LibraryBooks distribution not found")
            return
        end
        
        local weights = {}
        for i = 1, #dist.items, 2 do
            local item = dist.items[i]
            if item and item:match("^ZScienceSkill%.BookScience") then
                weights[item] = dist.items[i + 1]
            end
        end
        
        local w1 = weights["ZScienceSkill.BookScience1"]
        local w5 = weights["ZScienceSkill.BookScience5"]
        
        assert.gt(w1, w5, "Vol 1 should have higher weight than Vol 5")
    end)
end)

describe("Science book spawning", function()
    it("books can spawn from distribution roll", function()
        local dist = ProceduralDistributions.list.LibraryBooks
        if not dist or not dist.items then
            ZBSpec.skip("LibraryBooks distribution not available")
            return
        end
        
        -- Simulate the roll logic: items array is [item1, weight1, item2, weight2, ...]
        -- Build a weighted list and check our books have non-zero weights
        local scienceBooks = {}
        local totalWeight = 0
        
        for i = 1, #dist.items, 2 do
            local itemType = dist.items[i]
            local weight = dist.items[i + 1] or 0
            
            if type(itemType) == "string" and itemType:match("^ZScienceSkill%.BookScience") then
                scienceBooks[itemType] = weight
            end
            
            if type(weight) == "number" then
                totalWeight = totalWeight + weight
            end
        end
        
        -- Verify books are present with positive weights
        assert.gt(scienceBooks["ZScienceSkill.BookScience1"] or 0, 0, "BookScience1 should have weight > 0")
        
        -- Calculate spawn probability
        local book1Weight = scienceBooks["ZScienceSkill.BookScience1"] or 0
        local spawnChance = book1Weight / totalWeight * 100
        assert.gt(spawnChance, 0, "BookScience1 should have spawn chance > 0%")
    end)
end)

return ZBSpec.runAsync()
