pico-8 cartridge // http://www.pico-8.com
version 32
__lua__

#include vector.p8
#include noise.p8

--Make BtnP only register the initial key delay
poke(0x5f5c,99999)
poke(0x5f5d,99999)

Game = {
    objects = {}
    pellets = {}
}

Map = {
    screens = vec2(4, 1),
    waterHeight = 90,
    mapData = {},
    heightMap = {},
    getMapData = function(self, x, y)
        x = min(max(flr(x), 1), Map.screens.x*128)
        y = min(max(flr(y), 1), Map.screens.y*128)
        return Map.mapData[ceil(x/128)][y * 128 + (x % 128) + 1]
    end,
    getMapDataByScreen = function(self, x, y, screen)
        return Map.mapData[screen+1][flr(y) * 128 + flr(x) + 1]
    end,
    redrawBuffer = {}
}

Textures = {
    --Water, Negative Index with no collision
    [-1] = {
        position = vec2(88, 0),
        dimension = vec2(8, 8)
    },
    --Empty
    [0] = {
        position = vec2(0, 0),
        dimension = vec2(1, 1)
    },
    --Ground
    [1] = {
        position = vec2(96, 0),
        dimension = vec2(16, 16)
    },
    --Player
    [2] = {
        position = vec2(0, 0),
        dimension = vec2(8, 8)
    },
    --Grass
    [3] = {
        position = vec2(96, 16),
        dimension = vec2(16, 16)
    },
    --Weapons
    --Shotgun
    [10] = {
        position = vec2(16, 0),
        dimension = vec2(8, 8)
    }
}

debug = false

forceRedraw = true

Explosion = {
    new = function(self, x, y, radius)
        local screen = 0
        x = flr(x)
        y = flr(y)
        for dx = -radius, radius do
            for dy = -radius, radius do
                if(dx*dx + dy*dy <= radius * radius) then
                    screen = ceil((x + dx) / 128)
                    if(y + dy > Map.waterHeight) then
                        Map.mapData[screen][max(1,min(128*128, (y + dy) * 128 + (x + dx) % 128 + 1))] = -1
                    else
                        Map.mapData[screen][max(1,min(128*128, (y + dy) * 128 + (x + dx) % 128 + 1))] = 0
                    end
                end
            end
        end
        add(Map.redrawBuffer, { position = vec2(x - radius - 1, y - radius - 1), dimension = vec2(radius * 2 + 2, radius * 2 + 2)})
    end
}

--Component that controls the sprite rendering
C_SpriteRenderer = {
    new = function(self, spriteIndex)
        return {
            spriteIndex = spriteIndex,
            dim = Textures[spriteIndex].dimension,
            draw = function(self, owner)
                
                local drawPos = vec2(owner.transform.position.x - self.dim.x / 2, owner.transform.position.y - self.dim.y)
                local posX = drawPos.x - stat(3) * 128
                if((posX >= 0 and posX < 128) or (posX + self.dim.x >= 0 and posX + self.dim.x < 128)) then
                    cspr(self.spriteIndex, drawPos.x, drawPos.y, not owner.isFacingRight)
                end
                
                if(stat(3) == 3) then
                    add(Map.redrawBuffer, { position = vec2(drawPos.x, drawPos.y), dimension = vec2(self.dim.x, self.dim.y)})
                end
            end
        }
    end
}

C_VelocityController = {
    new = function(self, takeSteps)
        takeSteps = takeSteps or false
        return{
            update = function(self, owner)
                --Handle Y Velocity
                local velocityDir = vec2(owner.velocity.x / abs(owner.velocity.x), owner.velocity.y / abs(owner.velocity.y))
                local velocity = vec2(owner.velocity.x, owner.velocity.y)
                local hitGround = false
                if(abs(owner.velocity.y) > 0) then
                    while(velocity.y * velocityDir.y > 0) do
                        --Fall down
                        if(Map:getMapData(owner.transform.position.x, owner.transform.position.y - velocityDir.y) <= 0) then
                            owner.transform.position.y -= velocityDir.y * min(1, abs(velocity.y))
                            velocity.y -= velocityDir.y
                        --On Ground
                        else
                            owner.velocity.y = 0
                            hitGround = true
                            break
                        end
                    end
                end

                --Handle X Velocity
                if(abs(owner.velocity.x) > 0) then
                    while(velocity.x * velocityDir.x > 0) do
                        --Move left/right
                        if(Map:getMapData(owner.transform.position.x + velocityDir.x, owner.transform.position.y) <= 0) then
                            owner.transform.position.x += velocityDir.x * min(1, abs(velocity.x))
                            velocity.x -= velocityDir.x
                        --Take steps
                        elseif(takeSteps and (Map:getMapData(owner.transform.position.x + velocityDir.x, owner.transform.position.y-1) <= 0 or Map:getMapData(owner.transform.position.x + velocityDir.x, owner.transform.position.y-2) <= 0)) then
                            owner.transform.position.x += velocityDir.x * min(1, abs(velocity.x))
                            owner.transform.position.y -= 1
                            velocity.x -= velocityDir.x
                        --Hit Wall
                        else
                            owner.velocity.x = 0
                            hitGround = true
                            break
                        end
                    end
                end
                if(hitGround) then
                    owner:onHitGround()
                end
            end
        }
    end
}

--Component that controls the player movement
C_PlayerController = {
    new = function(self)
        return {
            stairDirection = 1,
            stairPosition = {},
            update = function(self, owner)
                owner.velocity.x *= 0.75
                owner.velocity.y -= 0.1

                --Go Right
                if(btn(1,1)) then
                    owner.velocity.x += 0.4
                    owner.isFacingRight = true
                end

                --Go Left
                if(btn(0,1)) then 
                    owner.velocity.x += -0.4
                    owner.isFacingRight = false
                end

                --Jump
                if(btn(4,1)) then 
                    if(Map:getMapData(owner.transform.position.x, owner.transform.position.y + 1) > 0) then
                        owner.velocity.y = 2
                    end
                end

                --Shoot, now controlled by weapons due to different behaviours
                --if(btn(5,1)) then 
                    --owner.weapon:shoot()
                --end

                --Build
                if(btn(5,1) and btn(4,1)) then 
                    if(stairDirection == 0) then
                        stairDirection = owner.isFacingRight
                    end
                else
                    if(not stairDirection == 0) then
                        stairDirection = 0
                        stairPosition = {}
                    end
                end
            end
        }
    end
}

Weapon_GrenadeLauncher = {
    new = function(self, parent)
        local me = Entity:new()
        me.parent = parent
        add(me.renderComponents, C_SpriteRenderer:new(10))
        me.update = function(self)
            self.transform.position = self.parent.transform.position + (self.parent.isFacingRight and 1 or -1) * vec2(4, 0)
            self.isFacingRight = self.parent.isFacingRight
            if(btnp(5,1)) then
                self:shoot()
            end
        end
        me.shoot = function(self)
            self.parent.velocity.x = self.parent.isFacingRight and -10 or 10
            for i = -5, 5 do
                add(Game.pellets, { 
                    position = vec2(self.transform.position.x, self.transform.position.x), 
                    velocity = vec2(self.parent.isFacingRight and 5 or -5, i / 5),
                    lifetime = 0
                })
            end
        end
        return me
    end
}

Projectile_Pellet = {
    new = function(self, x, y, velocityX, velocityY)
        local me = Entity:new(x, y)
        add(me.components, C_VelocityController:new(false))
        me.velocity = vec2(velocityX, velocityY)
        me.onHitGround = function(self)
            
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
            isFacingRight = true,
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
            end,
            onHitGround = function(self)
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
        entity.weapon = Weapon_GrenadeLauncher:new(entity)
        add(entity.components, C_PlayerController:new())
        add(entity.components, C_VelocityController:new(true))
        add(entity.renderComponents, C_SpriteRenderer:new(2))
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
                local distance = 64 + Simplex2D((x + screenX * 128) / 200, seed) * 25 + Simplex2D((x + screenX * 128) / 50, seed) * 5 - y
                if distance < 0 then
                    --Create Grass
                    if(distance > -8 + Simplex2D((x + screenX * 128), 99) * 5) then
                        add(Map.mapData[screenX], 3)
                    --Create Dirt
                    else
                        add(Map.mapData[screenX], 1)
                    end
                --Above Ground
                else
                    --Create Water
                    if(y > Map.waterHeight) then
                        add(Map.mapData[screenX], -1)
                    --Create Air
                    else
                        add(Map.mapData[screenX], 0)
                    end
                end
            end
        end
    end
    forceRedraw = true
end

function redrawRegion(posX, posY, width, height)
    local screen = stat(3)
    posX = flr(posX) - screen * 128
    posY = flr(posY)
    if((posX >= 0 and posX < 128) or (posX + width >= 0 and posX + width < 128)) then
        palt(0, false)
        for x = max(posX,0), min(posX + width, 127) do
            for y = max(posY, 0), min(posY + height, 127) do
                local pixel = Map:getMapDataByScreen(x, y, screen)
                local color = sget(x % Textures[pixel].dimension.x + Textures[pixel].position.x, y % Textures[pixel].dimension.y + Textures[pixel].position.y)
                if(forceRedraw) then
                    pset(x, y, color)
                else
                    pset(x, y, color)
                end
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
    Game.player = Player:new(20,10)
end

function _update60()
    foreach(Game.objects, function(obj) obj:update(self) end)
end

poke(0x5f36,1)
function _draw()
    if(forceRedraw) then
        cls()
        redrawRegion(128 * stat(3), 0, 127, 127)
        line(0,128,128,128, 5)
        forceRedraw = stat(3)<3
        return forceRedraw
    else
        if #Map.redrawBuffer > 0 then
            for i in all(Map.redrawBuffer) do
                redrawRegion(i.position.x, i.position.y, i.dimension.x, i.dimension.y)
            end
            if(stat(3)==3) then
                Map.redrawBuffer = {}
            end
        end
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

function cspr(id, posX, posY, flipX, flipY)
    flipX = flipX or false
    flipY = flipY or false
    local dim = Textures[id].dimension
    local screen = stat(3)
    posX -= screen * 128
    if((posX >= 0 and posX < 128) or (posX + dim.x >= 0 and posX + dim.x < 128)) then
        sspr(Textures[id].position.x, Textures[id].position.y, dim.x, dim.y, posX, posY, dim.x, dim.y, flipX, flipY)
    end
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
00e000000030000000000000000000000000000000000000000000000000000044f44444444ff44433533dd3dcdcccdc44445444444544440000000000000000
0e0cc60003088e00000000000000000000000dd000000000000000000000000044f444444444f4443533533ddcccdcdc44454544444454440000000000000000
000dcc000002880000000000000000000ee0d0dd00000000000000000000000044f444444444f4443d3db55dccdcdcdc44444494444444540000000000000000
0a911dc00a9112e00000000003bbb0b0ee7e5000001110100000000002ddc00044ff4444444ff4445db5b3b3dcdcdccc54444f4444f464440000000000000000
091cc61909188e190065d555bb333b5b2ee2d0dd01d9d5550000000000977966444ff444444f444453b33bb5dcdcccdc4f44444f444544450000000000000000
091ccc1009188810065444000dbbb000d2250dd00d10c000a99a5900079559004444ff44444f444455bd3db5dcccdcdc44544444444445940000000000000000
00dc1c000028180065000000d000000055500000d5000c00405000004440000044444fff444fffff353b3d35ccdcdcdc444444444444444f0000000000000000
000c010000080100000000000000000000000000000000000000000000000000ff44444ff4ff4444db3b5d33dcdcdccc444444444444f4440000000000000000
0000000000000000000000000000000000000dd00000000000000000000000004f444444fff44444000000000000000044444444445445440000000000000000
000000000000000000000000000000bb0000d0000000015000000000000000604ff4444ffff44444000000000000000044445444444444440000000000000000
000040000000f000000005000000bb500000d00d00000500000000000000060044fffff44ff44444000000000000000044464f44444544540000000000000000
0a911dc00a9112e000005000000b3b0000ee5dd00001500000000000000c60004444f4444f444444000000000000000044f444f4444445440000000000000000
091cc61909188e19000d400000b3b0000ee7e0000019dc000009009000d790004444f4444f444444000000000000000045444944544444440000000000000000
091ccc100918881000640000003b000002ee200001dd00c000900a0002755000444ff4444f444444000000000000000044545444444444f40000000000000000
00dc1c0000281800005000000bd000000022500001d1000009a590000094000044ff44444fff44440000000000000000444444454444f4440000000000000000
000c0100000801000050000000d0000000d5000000d00000004040000040000044f4444444ff4444000000000000000044444454444445440000000000000000
afafafaf6566556500000000000000000000000000000000000000000000000000000000000000000000000000000000d33333333333333b0000000000000000
94949494d55d55d50000000000000000000200d00000000000000000000000000000000000000000000000000000000033b3333b3b33b3330000000000000000
4f4f4f4f556555550009000000000000020ee60000000000000000000000000000000000000000000000000000000000bb3333b3b33bd3330000000000000000
f464f464165551650a900000000000000087ae00000000000000000000000000000000000000000000000000000000003533a3333333333a0000000000000000
545454545d5555d57f990000303bb60002ea78200000001c0000a00a606709ff00000000000000000000000000000000333333d3335333330000000000000000
464f464fd55455550a90000000000000006ee00000000000000000000000000000000000000000000000000000000000333b3b33333393330000000000000000
454545455451d54d00000000000000000d0020000000000000000000000000000000000000000000000000000000000033bdb3333333333b0000000000000000
141414145555555500000000000000000000000000000000000000000000000000000000000000000000000000000000533333b3b3b333b30000000000000000
0000006c000000e800909a00000000000000000200000000000000000000000f0000000000000000000000000000000039333b3b3b5333350000000000000000
00000cc1000008820000489000000000060020000000000000000000000000f0000000000000000000000000000000003333b533333333330000000000000000
00006c100000e8200008009a0000060000ce8d00000000000000000000000900000000000000000000000000000000003333d335333d33330000000000000000
0006c100000e8200000008990000b00002ea7820000000000000000000000000000000000000000000000000000000003b333333335333330000000000000000
00cc100000882000000040a90003000000879e0000000000000000000007000000000000000000000000000000000000b3333b3b33333b330000000000000000
06c100000e8200000000089a0000000000d8e020000000000000000000600000000000000000000000000000000000003a33b3b33933b3bb0000000000000000
cc10000088200000000890a003000000000200600000000000000000000000000000000000000000000000000000000033333533b3b333330000000000000000
c1000000820000000090a90000000000d000000000000000000000006000000000000000000000000000000000000000b333333b3b3333d30000000000000000

__sfx__
c20d0020155201552018030180301a0301a0301c010200102101021010230102303021020210302001020010210102101018510195101a5101a5101e0501e0401c0201c02019020190201a0201a0201752014520
300d0000042200b4001c1000b400196001a100267001960025700186002870026700196000c4001530015300267000c4000b2100b210092100921026700186001b100002000423004210042001f1002670026700
c10d00002472024720247202471024710257102571010000287302872028720287100a0000c40015300297001d7301d7201d7201d720217202172023730237202372023720227202272022720227102171021710
b60d00003040030400242503040023210232302342023410152202d400152402d4002c4002c400202202c4002d4002d4001522015230152101523015240152402d4002d400152201523017210172301524017240
b10d00000c650376001b6000c6000c6502f6001b600326000c6500c600076000b6000c65032600316000c6000c650376001b6001b6000c6502f6001b600326000c6503260007600016000c650006002b6000c620
800d0000174001740017400174002d630144001440014400134002d61013400296002d6301240012400124000b4000b4002d6000b4002d6300b4000b4000b4000b4002d6100b4000b4002d6300e4001140013400
000d00001013010130101300411010130101301013004110131301310010110101100b50014100141101412014120141201412014110141101411002500025000250001500191101911019100191001911019110
010d00001013010130101300711010120101101011008110131301010010110101101010010100141101412014120141201412014110141102610019600000000d60010110121201212012110121001211012110
000300000007004670046700303002670016700064000620006101e50006600056000460004600036000060000600006000060000600006000060000000000000000000000000000000000000000000000000000
00020000121701a560220500002000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0003000000450014501861011450004500d630004500005000050000500f6500004001040010400204002040030400404005030070300a0200b1200b2200b0300b2300b0300b0300b0300b0200b2100b0100b410
001000002f2102e7402d4202b130247501a7500874002730001200012000020004100041000010001100011000010001100011000110001300014000000000000000000000000000000000000000000000000000
__music__
00 01074345
00 01020345
00 01024105
00 01024005
00 01040205
00 01040205
00 02040305
00 02420345
00 00044305
00 00044305
00 00040305
00 00040305
00 00030104
00 00030104
00 00010304
00 00410344
00 01020504
00 01020504
00 02070504
00 02060504
00 01070504
00 01060504
00 00074344
02 00064344

