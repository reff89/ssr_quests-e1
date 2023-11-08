-- Copyright (c) 2022-2023 Oneline/D.Borovsky
-- All rights reserved
require "Communications/QSystem"
if not QSystem.validate("ssr-quests-e1") then return end
FFDuplicateRemoval = {}
FFDuplicateRemoval.enabled = not isClient() and not isServer();

-- removes duplicates of IsoObjects left from FNPCs in singleplayer
local function removeDupesFromSquare(square)
    if not square then return end
    local objects = square:getObjects();
    if objects:size() > 0 then
        for i=objects:size()-1, 0, -1 do
            local object = objects:get(i);
            local name = object:getName() or "nil";
            if name:starts_with("NPC_") then
                local character = string.sub(name, 5);
                QuestLogger.print("[QSystem] FurnitureFolks: Removed duped NPC - "..tostring(character));
                object:removeFromSquare();
            end
        end
    end
end

function FFDuplicateRemoval.addSquare(square)
    if FFDuplicateRemoval.enabled then
        local m = getGameTime():getModData();
        if type(m.FNPC) ~= "table" then
            m.FNPC = {};
        end
        local x, y, z = square:getX(), square:getY(), square:getZ();
        table.insert(m.FNPC, {x=x, y=y, z=z});
    end
end

function FFDuplicateRemoval.clearSquare(square)
    if FFDuplicateRemoval.enabled then
        local m = getGameTime():getModData();
        local x, y, z = square:getX(), square:getY(), square:getZ();
        if type(m.FNPC) == 'table' then
            for i=#m.FNPC, 1, -1 do
                if x == m.FNPC[i].x and y == m.FNPC[i].y and z == m.FNPC[i].z then
                    removeDupesFromSquare(square);
                    table.remove(m.FNPC, i);
                end
            end
        end
    end
end

function FFDuplicateRemoval.onGameStart()
    local m = getGameTime():getModData();
    if type(m.FNPC) == 'table' then
        for i=#m.FNPC, 1, -1 do
            local square = getCell():getGridSquare(m.FNPC[i].x, m.FNPC[i].y, m.FNPC[i].z);
            if square then
                removeDupesFromSquare(square);
                table.remove(m.FNPC, i);
            end
        end
    end
end

if FFDuplicateRemoval.enabled then
Events.OnGameStart.Add(FFDuplicateRemoval.onGameStart);
end