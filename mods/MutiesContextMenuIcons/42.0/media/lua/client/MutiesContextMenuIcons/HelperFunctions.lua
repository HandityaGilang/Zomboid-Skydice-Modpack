MutiesContextMenuIcons = {};

-- Simply add context menu option names here along with their texture path
MutiesContextMenuIcons.Options = {};

local function ApplyOptionIconsToInventoryContextMenu(
        player, context, items, item)
    if not context then return end

    for optionName in pairs(MutiesContextMenuIcons.Options) do
        local optionDetails = MutiesContextMenuIcons.Options[optionName];
        local option = context:getOptionFromName(getText(optionName));
        if option and type(optionDetails) == "string" then
            local texturePath = optionDetails;
            option.iconTexture = getTexture(texturePath);
        elseif option and type(optionDetails) == "table" then
            local texturePath = optionDetails.TexturePath;
            option.iconTexture = getTexture(texturePath);
            local subContext = context:getSubMenu(option.subOption);
            if not subContext then return end
            for subOptionName in pairs(optionDetails.SubOptions) do
                local subOption = subContext:getOptionFromName(getText(subOptionName));
                if subOption then
                    texturePath = optionDetails.SubOptions[subOptionName];
                    subOption.iconTexture = getTexture(texturePath);
                end
            end
        end
    end
end

function ApplyOptionIconsToWorldContextMenu(player, context, worldobjects, test)
    if test and ISWorldObjectContextMenu.Test then return true end
    if not context then return end

    for optionName in pairs(MutiesContextMenuIcons.Options) do
        local optionDetails = MutiesContextMenuIcons.Options[optionName];
        local option = context:getOptionFromName(getText(optionName));
        if option and type(optionDetails) == "string" then
            local texturePath = optionDetails;
            option.iconTexture = getTexture(texturePath);
        elseif option and type(optionDetails) == "table" then
            local texturePath = optionDetails.TexturePath;
            option.iconTexture = getTexture(texturePath);
            local subContext = context:getSubMenu(option.subOption);
            if not subContext then return end
            for subOptionName in pairs(optionDetails.SubOptions) do
                local subOption = subContext:getOptionFromName(getText(subOptionName));
                if subOption then
                    texturePath = optionDetails.SubOptions[subOptionName];
                    subOption.iconTexture = getTexture(texturePath);
                end
            end
        end
    end
end

Events.OnFillInventoryObjectContextMenu.Add(ApplyOptionIconsToInventoryContextMenu);
Events.OnFillWorldObjectContextMenu.Add(ApplyOptionIconsToWorldContextMenu);