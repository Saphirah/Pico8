pico-8 cartridge // http://www.pico-8.com
version 32
__lua__

#include vector.p8
#include noise.p8

Game = {
    objects = {}
}

Map = {
    screens = vec2(4, 1),
    mapData = {},
    getMapData = function(x, y)
        return Map.mapData[ceil(x/128)][y * 128 + (x % 128) + 1]
    end,
    getMapDataByScreen = function(x, y, screen)
        return Map.mapData[screen+1][y * 128 + x + 1]
    end
}

Textures = {
    --Empty
    [0] = {
        position = vec2(0, 0),
        dimension = vec2(8, 16)
    },
    --Ground
    [1] = {
        position = vec2(8, 0),
        dimension = vec2(8, 8)
    },
    --Player
    [2] = {
        position = vec2(0, 0),
        dimension = vec2(8, 16)
    },
}

debug = false

forceRedraw = true

C_SpriteRenderer = {
    new = function(self, spriteIndex)
        return {
            spriteIndex = spriteIndex,
            lastPosition = vec2(0.1,0.1),
            draw = function(self, owner)
                redrawRegion(self.lastPosition.x, self.lastPosition.y, Textures[self.spriteIndex].dimension.x, Textures[self.spriteIndex].dimension.y)
                cspr(self.spriteIndex, owner.transform.position.x, owner.transform.position.y)
                self.lastPosition = owner.transform.position
            end
        }
    end
}

C_PlayerController = {
    new = function(self)
        return {
            update = function(self, owner)
                owner.velocity.x /= 1.5
                owner.velocity.y /= 1.5
                if(btn(1,1)) then
                    owner.velocity.x += 0.25
                end
                if(btn(0,1)) then 
                    owner.velocity.x -= 0.25
                end
                owner.transform.position.x += owner.velocity.x
                owner.transform.position.y += owner.velocity.y
            end
        }
    end
}

Entity = {
    new = function(self, x, y)
        local me = {
            transform = { 
                position = vec2(x, y), 
                rotation = 0, 
            },
            velocity = vec2(0, 0),
            components = {},
            renderComponents = {},
            health = 100,
            draw = function(self)
                foreach(self.renderComponents, function(obj) obj:draw(self) end)
            end,
            update = function(self)
                foreach(self.components, function(obj) obj:update(self) end)
            end,
            applyDamage = function(self, amount)
                self.health -= amount
                if(self.health<=0) then self:destroy() end
            end,
            destroy = function(self)
                del(Game.objects, self)
            end
        }
        add(Game.objects, me)
        return me
    end
}

Player = {
    new = function(self, x, y)
        local entity = Entity:new(x, y)
        entity.update = function(self)
            foreach(self.components, function(obj) obj:update(self) end)
        end
        add(entity.components, C_PlayerController:new())
        add(entity.renderComponents, C_SpriteRenderer:new(0))
        return entity
    end
}

function generateMap()
    local seed = rnd(100)
    Map.mapData = {}
    cls()
    for screenX = 1, Map.screens.x do
        add(Map.mapData, {})
        for y = 0, 127 do
            for x = 0, 127 do
                if y > 64 + Simplex2D((x + screenX * 128) / 200, seed) * 25 + Simplex2D((x + screenX * 128) / 50, seed) * 5 then
                    add(Map.mapData[screenX], 1)
                else
                    add(Map.mapData[screenX], 0)
                end
            end
        end
    end
    forceRedraw = true
end

function redrawRegion(posX, posY, width, height)
    local screen = stat(3)
    posX -= screen * 128
    if((posX >= 0 and posX < 128) or (posX + width >= 0 and posY + width < 128)) then
        palt(0, false)
        for x = max(posX,0), min(posX + width, 127) do
            for y = posY, posY + height do
                local pixel = Map.getMapDataByScreen(x, y, screen)
                local color = sget(mod(x, Textures[pixel].dimension.x), mod(y, Textures[pixel].dimension.y))
                pset(x, y, color)
            end
        end
        palt(0, true)
    end
end

function mod(x, m)
    while x < 0 do
        x += m
    end
    return x%m
end

function _init()
    generateMap()
    if(not debug) then
        Game.player = Player:new(20,50)
    end
end

function _update60()
    if(debug) then
        if(btnp(0, 1)) then
            generateMap()
        end
    end
    foreach(Game.objects, function(obj) obj:update(self) end)
end

poke(0x5f36,1)
function _draw()
    if(forceRedraw) then
        cls()
        local offset = to2D(stat(3), Map.screens.x)
        for x = 0, 15 do
            for y = 0, 15 do
                cspr(1, x * 8, y * 8)
            end
        end

        for x = 0, 127 do
            for y = 0, 127 do
                if Map.mapData[stat(3)+1][to1D(x, y, 128)] == 0 then
                    pset(x, y, 0)
                end
            end
        end

        forceRedraw = stat(3)<3
        return forceRedraw
    else
        foreach(Game.objects, function(obj) obj:draw(self) end)
        return stat(3)<3
    end
end

function to2D(index, width)
    return vec2(index % width, flr(index / width))
end

function to1D(indexX, indexY, width)
    return indexY * width + indexX + 1
end

function cspr(id, posX, posY)
    sspr(Textures[id].position.x, Textures[id].position.y, Textures[id].dimension.x, Textures[id].dimension.y, posX, posY)
end

_camera = camera -- save original camera function reference
function camera(x,y)
    x = x or 0
    y = y or 0
    local dx=flr(stat(3) % Map.screens.x)
    local dy=flr(stat(3) / Map.screens.x)
    _camera(x+128*dx, y+128*dy)
end

__gfx__
00999990884444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00ff5f00448884440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00fffff0444448840000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000ff000444484480000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0dddddd0884844440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fddddddf448484440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f0dddd0f448448840000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f0dddd0f884444480000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f0dddd0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f0dddd0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00dd0dd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
