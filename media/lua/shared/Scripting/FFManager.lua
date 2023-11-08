-- Copyright (c) 2022-2023 Oneline/D.Borovsky
-- All rights reserved
require "Scripting/ScriptManagerNeo"
require "Communications/QSystem"

FFManager = ScriptManagerNeo:derive("FFManager");
FFManager.initialized = false;
FFManager.instance = nil;

local function playScript(id)
    FFManager.instance.items[id].script:reset();
    QuestLogger.print("[QSystem*] FurnitureFolks: "..FFManager.instance.items[id].script.file);
    while true do
        local result = FFManager.instance.items[id].script:play(FFManager.instance.items[id]);
        if result then
            if result ~= -1 then
                print(result);
            end
            break;
        end
    end
end

function FFManager.updateSpawnPoints(name, forced)
    if not forced then QuestLogger.mute = true; end
    local success = false;
    for i=1, FFManager.instance.items_size do
        if name == FFManager.instance.items[i].name or not name then
            if FFManager.instance.items[i].instance then
                if (not FFManager.instance.items[i].instance.javaObject and not FFManager.instance.items[i].forced) or forced then -- when object is out of range and pos isn't set by action/dialogue command
                    playScript(i);
                end
            else -- create instance if null
                playScript(i);
            end
            success = true;
            if name then break end
        end
    end
    QuestLogger.mute = false;

    return success;
end

local function getDistance(x1, y1, x2, y2)
    local absX = math.abs(x2 - x1);
    local absY = math.abs(y2 - y1);
    return math.sqrt(absX^2 + absY^2);
end

function FFManager.render()
    if FFManager.instance then
        for a=1, FFManager.instance.items_size do
            if FFManager.instance.items[a].instance then
                if FFManager.instance.items[a].instance.javaObject then
                    local attached = FFManager.instance.items[a].instance.javaObject:getAttachedAnimSprite();
                    if attached then
                        for i=0, attached:size()-1 do
                            local anim = attached:get(i);
                            local s = anim:getParentSprite();
                            s:update();
                        end
                    end
                end
            end
        end
    end
end

function FFManager.update()
    local square = getPlayer():getSquare();
    if square then
        for i=1, FFManager.instance.items_size do
            if FFManager.instance.items[i].instance then
                local distance = getDistance(square:getX(), square:getY(), FFManager.instance.items[i].instance.x, FFManager.instance.items[i].instance.y);
                if distance > 35 and FFManager.instance.items[i].instance.javaObject then
                    FFManager.instance.items[i].instance:despawn();
                elseif distance <= 30 and not FFManager.instance.items[i].instance.javaObject then
                    FFManager.instance.items[i].instance:spawn();
                end
            end
        end
    end
    FFManager.render();
end

function FFManager:animate(name, sprite, frame_count, speed, offset_x, offset_y, loop)
    for i=1, self.items_size do
        if name == self.items[i].name then
            if self.items[i].instance then
                if self.items[i].instance.animation[1] ~= sprite then
                    self.items[i].instance:setAnimation(sprite, frame_count, speed, offset_x, offset_y, loop, not loop);
                end
            end
            return;
        end
    end
end

function FFManager:create(name, sprite, x, y, z, forced) -- FIXME: сейчас невозможно переписать анимацию спрайтом (если ранее он уже был назначен)
    for i=1, self.items_size do
        if name == self.items[i].name then
            if self.items[i].instance then
                if self.items[i].instance.x ~= x or self.items[i].instance.y ~= y or self.items[i].instance.z ~= z or self.items[i].instance.sprite ~= sprite then
                    self.items[i].instance:despawn();
                    self.items[i].instance = FNPC:new(name, sprite, x, y, z);
                end
            else
                self.items[i].instance = FNPC:new(name, sprite, x, y, z);
            end
            self.items[i].forced = forced;
            return;
        end
    end
end

function FFManager:remove(name, destroy)
    for i=1, self.items_size do
        if name == self.items[i].name and self.items[i].instance then
            self.items[i].instance:despawn();
            if destroy then
                self.items[i].instance = nil;
            end
            return;
        end
    end
end

function FFManager:removeAll(destroy)
    for i=1, self.items_size do
        if self.items[i].instance then
            self.items[i].instance:despawn();
            if destroy then
                self.items[i].instance = nil;
            end
        end
    end
end

function FFManager:exists(name)
    for i=1, self.items_size do
        if name == self.items[i].name then
            return true;
        end
    end
end

function FFManager:isSprite(character, sprite)
    for i=1, self.items_size do
        if character == self.items[i].name then
            if self.items[i].instance.sprite == sprite then
                return true;
            else
                return false;
            end
        end
    end
end

function FFManager:new()
    local o = ScriptManagerNeo:new("characters");
    setmetatable(o, self);
    self.__index = self;
    return o;
end

function FFManager.reset()
    if FFManager.instance then
        FFManager.instance:removeAll(true);
        FFManager.instance.items_size = 0;
        FFManager.instance.items = {};
    end
end

function FFManager.start()
    if not FFManager.initialized then
        SSRTimer.add_ms(FFManager.update, 100, true);
        SSRTimer.add_s(FFManager.updateSpawnPoints, 15, true);
        FFManager.initialized = true;
    end
end

function FFManager.load()
    if FFManager.instance then
        FFManager.instance.items = {};
        for i=1, CharacterManager.instance.items_size do
            local file = CharacterManager.instance.items[i].file;
            local mod = CharacterManager.instance.items[i].mod;
            local language = CharacterManager.instance.items[i].language;
            if file:ends_with(".txt") then
                local index = string.lastIndexOf(file, ".txt");
                file = string.sub(file, 1, index).."_pos.txt";
            end
            local npc = {};
            npc.name = tostring(CharacterManager.instance.items[i].name);
            npc.position = nil;
            npc.instance = nil;
            npc.character_id = i;
            npc.script = FFManager.instance:load_script(file, mod, true, language);
            npc.forced = false;
            npc.Type = "FurnitureFolk";
            if npc.script then
                FFManager.instance.items_size = FFManager.instance.items_size + 1; FFManager.instance.items[FFManager.instance.items_size] = npc;
            end
        end
        FFManager.updateSpawnPoints();
    end
end

function FFManager.init()
    if not FFManager.instance then FFManager.instance = FFManager:new() end
    FFManager.load();
    if not isServer() then
        Events.OnQSystemStart.Add(FFManager.start);
    end
end

function FFManager.preinit()
    FFManager.instance = FFManager:new();
    for entry_id=1, #QImport.scripts do
        print(string.format("[QSystem] FurnitureFolks: Loading data for plugin 'ssr-plugin-e1' from mod '%s'", tostring(QImport.scripts[entry_id].mod)));
        for i=1, #QImport.scripts[entry_id].char_data do
            local file = QImport.scripts[entry_id].char_data[i];
            if file:ends_with(".txt") then
                local index = string.lastIndexOf(file, ".txt");
                file = string.sub(file, 1, index).."_pos.txt";
            end
            FFManager.instance:load_script(file, QImport.scripts[entry_id].mod, true, QImport.scripts[entry_id].language)
        end
    end
end

if QSystem.validate("ssr-quests-e1") then
    Events.OnQSystemInit.Add(FFManager.init);
    Events.OnQSystemRestart.Add(FFManager.load); -- FIXME: probably need to update pos on OnQSystemUpdate event as well
    Events.OnQSystemReset.Add(FFManager.reset);

    if not isServer() then
        Events.OnQSystemPreInit.Add(FFManager.preinit);
    end
end