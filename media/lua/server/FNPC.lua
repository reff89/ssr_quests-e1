-- Copyright (c) 2022-2023 Oneline/D.Borovsky
-- All rights reserved
require "BuildingObjects/ISBuildingObject"
require "BuildingObjects/ISDestroyCursor"

local ISDestroyCursor_canDestroy = ISDestroyCursor.canDestroy;
function ISDestroyCursor:canDestroy(object)
    if ISDestroyCursor_canDestroy(self, object) then
        local name = object:getName() or "";
        if string.starts_with(name, "NPC_") then
            return false;
        end
        return true;
    else
        return false;
    end
end

FNPC = ISBuildingObject:derive("FNPC");

local colorInfo = ColorInfo.new(1, 1, 1, 1);
function FNPC:setAnimation(sprite, frame_count, speed, offset_x, offset_y, loop, deleteWhenFinished)
    local index = sprite:lastIndexOf('_');
    local sprite_name, sprite_id = string.sub(sprite, 1, index), string.sub(sprite, index+2);
    self.animation = { sprite, sprite_name, sprite_id, frame_count, speed, offset_x, offset_y, loop, deleteWhenFinished };
    if self.javaObject then
        self.javaObject:setSprite("");
        self.javaObject:AttachAnim(sprite_name, sprite_id, frame_count, speed, offset_x, offset_y, loop, 0.7, deleteWhenFinished, 0.7, colorInfo);
    end
end

function FNPC:removeAnimation()
    self.animation = {};
    if self.javaObject then
        self.javaObject:setSprite(self:getSprite());
        self.javaObject:RemoveAttachedAnims();
    end
end

function FNPC:spawn()
    if self.javaObject then
        self:despawn();
    end

    self.sq = getWorld():getCell():getGridSquare(self.x, self.y, self.z);

    if self.sq then
        if self.animation[1] then
            self.javaObject = IsoObject.getNew(self.sq, nil, "NPC_"..self.name, true);
            if self.javaObject then
                self.javaObject:AttachAnim(self.animation[2], self.animation[3], self.animation[4], self.animation[5], self.animation[6], self.animation[7], self.animation[8], 0.7, self.animation[9], 0.7, colorInfo);
            end
        else
            self.javaObject = IsoObject.getNew(self.sq, self:getSprite(), "NPC_"..self.name, true);
        end

        --self.javaObject = IsoObject.new(self.sq, self:getSprite(), "NPC_"..self.name);
        --self.javaObject = IsoObject.getNew(self.sq, self:getSprite(), "NPC_"..self.name, true);
        if self.javaObject then
            self.sq:AddSpecialObject(self.javaObject);
            self.javaObject:setRenderYOffset(10);
            print("[QSystem] FurnitureFolks: Added character '"..tostring(self.name).."' to square "..tostring(self.sq:getX())..", "..tostring(self.sq:getY())..", "..tostring(self.sq:getZ()));
            FFDuplicateRemoval.addSquare(self.sq);
        else
            print("[QSystem] (Error) FurnitureFolks: Java Object is NULL. "..self.info);
        end
    else
        print("[QSystem] (Error) FurnitureFolks: Grid Square is NULL. "..self.info);
    end
end

function FNPC:despawn()
    if self.javaObject then
        if self.sq then
            self.javaObject:removeFromSquare();
            self.javaObject = nil;
            print("[QSystem] FurnitureFolks: Removed character '"..tostring(self.name).."' from square "..tostring(self.sq:getX())..", "..tostring(self.sq:getY())..", "..tostring(self.sq:getZ()));
            FFDuplicateRemoval.clearSquare(self.sq);
        else
            self.sq = getWorld():getCell():getGridSquare(self.x, self.y, self.z);
        end
    end
end

function FNPC:new(name, sprite, x, y, z)
    local o = {};
    setmetatable(o, self);
    self.__index = self;
    o:init();
    sprite = tostring(sprite);
    if sprite:ends_with(".png") and not sprite:starts_with("media/textures/") then
        sprite = "media/textures/"..sprite;
    end
    o:setSprite(sprite);
    o:setNorthSprite(sprite);
    o.animation = {};
    o.name = name or "none";
    o.x = x;
    o.y = y;
    o.z = z;
    o.info = string.format("name='%s', sprite='%s', x=%i, y=%i, z=%i", o.name, sprite, x, y, z);
    return o;
end

function FNPC:getHealth()
    return 100;
end

function FNPC:isValid(square)
    return true;
end

function FNPC:render(x, y, z, square)
    ISBuildingObject.render(self, x, y, z, square)
end
