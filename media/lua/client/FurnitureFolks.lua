-- Copyright (c) 2022-2023 Oneline/D.Borovsky
-- All rights reserved
require "Communications/QSystem"

if not QSystem.validate("ssr-quests-e1") then return end

FurnitureFolks = {}
FurnitureFolks.instances = {}

FurnitureFolks.createOption = function(context, character_id) -- modders might want to override this function to add different options like "Inspect corpse" or something
    if CharacterManager.instance.items[character_id]:isAlive() then
        --context:addOptionOnTop((getTextOrNull("UI_QSystem_TalkTo") or "Talk to ")..CharacterManager.instance.items[character_id].displayName, CharacterManager.instance.items[character_id].file, DialoguePanel.create);
        context:addOptionOnTop((getTextOrNull("UI_QSystem_Talk") or "Talk"), CharacterManager.instance.items[character_id].file, DialoguePanel.create);
    end
end

FurnitureFolks.createMenu = function(player, context, worldobjects)
    local playerObj = getPlayer();
    local z = math.floor(playerObj:getZ());
    local x = math.floor(screenToIsoX(player, context.x, context.y, z));
	local y = math.floor(screenToIsoY(player, context.x, context.y, z));

    local occupied = false;
    local function validate(square)
        if not square then return end
        local objects = square:getObjects();
        if objects:size() > 0 then
            for i=objects:size()-1, 0, -1 do
                local object = objects:get(i);
                local name = object:getName() or "nil";
                if name:starts_with("NPC_") then
                    local character = string.sub(name, 5);
                    local char_id = CharacterManager.instance:indexOf(character);
                    local distance = square:DistToProper(playerObj);
                    if char_id and distance <= 3 then
                        FurnitureFolks.createOption(context, char_id);
                        occupied = true;
                    end
                end
            end
        end
    end

    validate(getCell():getGridSquare(x, y, z));
    if not occupied then
        validate(getCell():getGridSquare(x+1, y+1, z));
    end

    if isClient() then
        local accessLevel = getAccessLevel();
        if accessLevel == "" or accessLevel == "None" then return end
    elseif not isDebugEnabled() then
        return;
    end

    local option = context:addOption("[DEBUG] Furniture Folks", worldobjects, nil);
    local subMenu = ISContextMenu:getNew(context);
    context:addSubMenu(option, subMenu);

    subMenu:addOption("Respawn", 4, FurnitureFolks.respawn);
    subMenu:addOption("Despawn all", nil, FurnitureFolks.despawnAll);
end

FurnitureFolks.despawnAll = function ()
    FFManager.instance:removeAll(true);
end

Events.OnFillWorldObjectContextMenu.Add(FurnitureFolks.createMenu);

FurnitureFolks.respawn = function(code)
    if code == 4 then
        if FFManager.instance then
            FFManager.instance:removeAll(true);
        end
        FFManager.updateSpawnPoints(nil, true);
    end
end

Events.OnQSystemUpdate.Add(FurnitureFolks.respawn);