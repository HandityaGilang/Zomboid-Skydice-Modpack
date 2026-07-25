-- stop copying on first match
local COPY_DISTR = {
    ["MyComputer.FloppyDiskElectricalPublisher"]   = "ZScienceSkill.FloppyDiskSciencePublisher",
    ["SupportCorps.FloppyDiskElectricalPublisher"] = "ZScienceSkill.FloppyDiskSciencePublisher",
}

local logger = zdk.Logger.new("ZScienceSkill")

local function updateDistributions()
    local t0 = os.time()
    if ProceduralDistributions then
        for src, dst in pairs(COPY_DISTR) do
            if zdk.copy_distr(ProceduralDistributions.list, src, dst, logger) > 0 then
                break -- stop copying on first match
            end
        end
    else
        logger:error("ProceduralDistributions not found, skipping distribution updates.")
    end
    local t1 = os.time()
    logger:info("distribution updates completed in %.3fs", t1 - t0)
end

Events.OnPreDistributionMerge.Add(updateDistributions)
