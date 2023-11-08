-- Copyright (c) 2022-2023 Oneline/D.Borovsky
-- All rights reserved
require "Scripting/Commands/CommandList_a"
require "Communications/QSystem"

if not QSystem.validate("ssr-quests-e1") then return end

local type_ff = "FurnitureFolk";
local type_dialogue = "DialoguePanel";

-- allow execution of existing commands
for i=1, #CommandList_a do
    if CommandList_a[i].command == "is_flag" or CommandList_a[i].command == "set_flag" or CommandList_a[i].command == "jump" or CommandList_a[i].command == "is_quest" or CommandList_a[i].command == "is_task" or CommandList_a[i].command == "is_event" or CommandList_a[i].command == "is_stat" or CommandList_a[i].command == "is_time" or CommandList_a[i].command == "is_alive" or CommandList_a[i].command == "exit" then
        CommandList_a[i].supported[#CommandList_a[i].supported+1] = type_ff;
    end
end

-- npc_create name|texture|x,y,z
-- npc_create name|texture|x,y,z|forced
local npc_create = Command:derive("npc_create")
function npc_create:execute(sender)
    self:debug();
    local coord = self.args[3]:ssplit(',');
    if #coord == 3 then
        for i=1, #coord do
            local status;
            status, coord[i] = pcall(tonumber, coord[i]);
            if not status or not coord[i] then
                return "Argument is not number";
            end
        end
    else
        return "Invalid argument";
    end
    if FFManager.instance:exists(self.args[1]) then
        local status, sprite = pcall(getSprite, self.args[2])
        if status and sprite then
            if #self.args == 4 then
                if self.args[4] == "true" or self.args[4] == 1 then
                    self.args[4] = true;
                else
                    self.args[4] = false;
                end
                FFManager.instance:create(self.args[1], self.args[2], coord[1], coord[2], coord[3], self.args[4]);
            else
                FFManager.instance:create(self.args[1], self.args[2], coord[1], coord[2], coord[3]);
            end
        else
            return "Sprite '"..tostring(self.args[2]).."' not found";
        end
    else
        return "Character with name '"..tostring(self.args[1]).."' doesn't exist";
    end
end

-- npc_remove
-- npc_remove name
local npc_remove = Command:derive("npc_remove")
function npc_remove:execute(sender)
    self:debug();
    if #self.args == 0 then
        FFManager.instance:removeAll(true);
    elseif #self.args == 1 then
        FFManager.instance:remove(self.args[1], true);
    else
        return "Unexpected amount of arguments";
    end
end

-- npc_update name
local npc_update = Command:derive("npc_update")
function npc_update:execute(sender)
    self:debug();
    if not FFManager.instance.updateSpawnPoints(self.args[1], true) then
        return "Invalid npc name specified";
    end
end

-- is_sprite character_name|sprite
local is_sprite = Command:derive("is_sprite")
function is_sprite:execute(sender)
    self:debug();
    local path = tostring(self.args[2]);
    if not path:starts_with("media/textures/") then
        path = "media/textures/"..path;
    end
    if not FFManager.instance:isSprite(self.args[1], path) then
        QuestLogger.print("[QSystem*] #is_sprite: Skipping block due to sprite being not equal \""..tostring(path))
        sender.script.skip = sender.script.layer+1;
    end
end

-- npc_animate name|sprite|frame_count|speed|offset_x|offset_y
-- npc_animate name|sprite|frame_count|speed|offset_x|offset_y|loop
local npc_animate = Command:derive("npc_animate")
function npc_animate:execute(sender)
    self:debug();
    for i=3, 6 do
        local status;
        status, self.args[i] = pcall(tonumber, self.args[i]);
        if not status or not self.args[i] then
            return "Argument is not number";
        end
    end
    if FFManager.instance:exists(self.args[1]) then
        local status, sprite = pcall(getSprite, self.args[2]..'_'..'0')
        if status and sprite then
            if #self.args == 7 then
                FFManager.instance:animate(self.args[1], self.args[2], self.args[3], self.args[4], self.args[5], self.args[6], self.args[7] == 'true');
            else
                FFManager.instance:animate(self.args[1], self.args[2], self.args[3], self.args[4], self.args[5], self.args[6], false);
            end
        else
            return "Sprite '"..tostring(self.args[2]).."_0' not found";
        end
    else
        return "Character with name '"..tostring(self.args[1]).."' doesn't exist";
    end
end

CommandList_a[#CommandList_a+1] = npc_create:new("npc_create", 3, 4, {type_ff, type_dialogue});
CommandList_a[#CommandList_a+1] = npc_remove:new("npc_remove", 0, 1, {type_dialogue});
CommandList_a[#CommandList_a+1] = npc_update:new("npc_update", 1, nil, {type_dialogue});

CommandList_a[#CommandList_a+1] = is_sprite:new("is_sprite", 2, nil, {type_ff, type_dialogue});

CommandList_a[#CommandList_a+1] = npc_animate:new("npc_animate", 6, 7, {type_ff, type_dialogue});