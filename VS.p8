pico-8 cartridge // http://www.pico-8.com
version 32
__lua__

#include vector.p8
#include noise.p8
#include math.p8
#include projectiles.p8
#include weapons.p8

--Make BtnP only register the initial key delay
--This is so that BtnP does not repeat the input, 
--but only trigger once when it's pressed down
poke(0x5f5c,99999)
poke(0x5f5d,99999)

Game = {
    objects = {},
    pellets = {},
    players = {},
    flags = {},
    flagPads = {},
    weaponTimer = 300
}

Map = {
    screens = vec2(4, 1),
    groundHeight = 90,
    waterHeight = 100,
    mapData = {},
    heightMap = {},
    getMapData = function(self, x, y)
        local dx = min(max(flr(x), 0), Map.screens.x*127)
        local dy = min(max(flr(y), 0), Map.screens.y*127)
        return Map.mapData[min(max(flr(dx/128), 0), 3)][dy * 128 + (dx % 128)]
    end,
    getMapDataByScreen = function(self, x, y, screen)
        local dx = min(max(flr(x), 0), Map.screens.x*127)
        local dy = min(max(flr(y), 0), Map.screens.y*127)
        return Map.mapData[screen][flr(dy) * 128 + flr(dx)]
    end,
    setMapData = function(self, x, y, index)
        local dx = min(max(flr(x), 0), Map.screens.x*127)
        local dy = min(max(flr(y), 0), Map.screens.y*127)
        Map.mapData[min(max(flr(dx/128), 0), 3)][dy * 128 + (dx % 128)] = index
    end,
    setMapDataByScreen = function(self, x, y, screen, index)
        local dx = min(max(flr(x), 0), 127)
        local dy = min(max(flr(y), 0), 127)
        Map.mapData[screen][dy * 128 + (dx % 128)] = index
    end,
    redrawBuffer = {}
}

AvgPerformance = 0
Time = 0

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
    --Stone
    [2] = {
        position = vec2(112, 0),
        dimension = vec2(16, 16)
    },
    --Grass
    [3] = {
        position = vec2(96, 16),
        dimension = vec2(16, 16)
    },
    --Wood
    [4] = {
        position = vec2(112, 16),
        dimension = vec2(16, 16)
    },
    --Player 1
    [5] = {
        position = vec2(0, 0),
        dimension = vec2(8, 8)
    },
    --Player 2
    [6] = {
        position = vec2(8, 0),
        dimension = vec2(8, 8)
    },
    --Health Bar Player 1
    [7] = {
        position = vec2(80, 10),
        dimension = vec2(8, 2)
    },
    --Health Bar Player 2
    [8] = {
        position = vec2(80, 8),
        dimension = vec2(8, 2)
    },
    --Weapons
    --Shotgun
    [10] = {
        position = vec2(16, 2),
        dimension = vec2(8, 4)
    },
    --LaserWeapon
    [11] = {
        position = vec2(24, 3),
        dimension = vec2(8, 4)
    },
    --LaserBall
    [12] = {
        position = vec2(32, 1),
        dimension = vec2(8, 6)
    },
    --AK
    [13] = {
        position = vec2(40, 3),
        dimension = vec2(8, 4)
    },
    --Pistol
    [14] = {
        position = vec2(48, 1),
        dimension = vec2(8, 6)
    },
    --Sniper
    [15] = {
        position = vec2(56, 3),
        dimension = vec2(8, 4)
    },
    --WeaponDrops
    --Shotgun
    [20] = {
        position = vec2(18, 10),
        dimension = vec2(4, 6)
    },
    --LaserWeapon
    [21] = {
        position = vec2(25, 9),
        dimension = vec2(7, 7)
    },
    --LaserBall
    [22] = {
        position = vec2(33, 8),
        dimension = vec2(7, 8)
    },
    --AK
    [23] = {
        position = vec2(41, 9),
        dimension = vec2(6, 7)
    },
    --Pistol
    [24] = {
        position = vec2(49, 5),
        dimension = vec2(6, 4)
    },
    --Sniper
    [25] = {
        position = vec2(57, 9),
        dimension = vec2(6, 7)
    },
    --Blue Flag
    [30] = {
        position = vec2(64, 16),
        dimension = vec2(6, 10)
    },
    --Red Flag
    [31] = {
        position = vec2(72, 16),
        dimension = vec2(6, 10)
    },
    --Blue Flag Post
    [32] = {
        position = vec2(80, 28),
        dimension = vec2(8, 4)
    },
    --Red Flag Post
    [33] = {
        position = vec2(88, 28),
        dimension = vec2(8, 4)
    },
    --Leafs
    [40] = {
        position = vec2(80, 0),
        dimension = vec2(8, 8)
    },
    --Hitmarker
    [42] = {
        position = vec2(80, 12),
        dimension = vec2(3, 3)
    },
--Shotgun
    --ShotgunBlast01
    [50] = {
        position = vec2(16, 16),
        dimension = vec2(4, 4)
    },
    --ShotgunBlast02
    [51] = {
        position = vec2(16, 24),
        dimension = vec2(8, 8)
    },
    --ShotgunBlast03
    [52] = {
        position = vec2(20, 16),
        dimension = vec2(4, 8)
    },

--Laser
    --LaserBlast01
    [53] = {
        position = vec2(24, 16),
        dimension = vec2(4, 3)
    },
    --LaserBlast02
    [54] = {
        position = vec2(28, 16),
        dimension = vec2(4, 3)
    },
    --LaserBlast03
    [55] = {
        position = vec2(24, 19),
        dimension = vec2(5, 5)
    },
    --LaserBlast04
    [56] = {
        position = vec2(28, 20),
        dimension = vec2(4, 4)
    },

--Launcher
    --LauncherBlast01
    [57] = {
        position = vec2(32, 16),
        dimension = vec2(6, 6)
    },
    --LauncherBlast02
    [58] = {
        position = vec2(32, 24),
        dimension = vec2(6, 6)
    },
    --LauncherExplo01
    [60] = {
        position = vec2(40, 24),
        dimension = vec2(8, 8)
    },
    --LauncherExplo02
    [61] = {
        position = vec2(40, 32),
        dimension = vec2(8, 8)
    },

--Sniper
    --SniperHit01
    [62] = {
        position = vec2(56, 16),
        dimension = vec2(8, 3)
    },
    --SniperHit02
    [63] = {
        position = vec2(56, 19),
        dimension = vec2(8, 5)
    },
    --SniperHit03
    [64] = {
        position = vec2(83, 12),
        dimension = vec2(5, 4)
    },

--Pellet
    --PelletHit01
    [65] = {
        position = vec2(80, 12),
        dimension = vec2(3, 3)
    },
    --PelletHit02
    [66] = {
        position = vec2(80, 16),
        dimension = vec2(4, 4)
    },
    --PelletHit03
    [67] = {
        position = vec2(88, 16),
        dimension = vec2(4, 4)
    },
    --PelletHit04
    [68] = {
        position = vec2(83, 12),
        dimension = vec2(4, 4)
    },
}

debug = false

forceRedraw = true

--Spawns an explosion and destroys the environment
Explosion = {
    new = function(self, x, y, radius)
        local screen = 0
        x = flr(x)
        y = flr(y)
        for dx = -radius, radius do
            for dy = -radius, radius do
                if(dx*dx + dy*dy <= radius * radius) then
                    local ex = min(max(flr(dx + x), 0), Map.screens.x*127)
                    local ey = min(max(flr(dy + y), 0), Map.screens.y*127)
                    if(y + dy > Map.waterHeight) then
                        Map.mapData[min(max(flr(ex/128), 0), 3)][ey * 128 + (ex % 128)] = -1
                    else
                        Map.mapData[min(max(flr(ex/128), 0), 3)][ey * 128 + (ex % 128)] = 0
                    end
                end
            end
        end
        add(Map.redrawBuffer, { position = vec2(x - radius, y - radius), dimension = vec2(radius * 2, radius * 2)})
    end
}

--RenderComponent that draws a Sprite
C_SpriteRenderer = {
    new = function(self, spriteIndex)
        return {
            spriteIndex = spriteIndex,
            dim = Textures[spriteIndex].dimension,
            draw = function(self, owner)
                if(owner.transform.position.x == nil) then return end
                local drawPos = vec2(owner.transform.position.x - self.dim.x / 2, owner.transform.position.y - self.dim.y)
                local posX = drawPos.x - stat(3) * 128
                if((posX >= 0 and posX < 128) or (posX + self.dim.x >= 0 and posX + self.dim.x < 128)) then
                    cspr(self.spriteIndex, drawPos.x, drawPos.y, not owner.isFacingRight)
                end
                if(stat(3) == 3) then
                    add(Map.redrawBuffer, { position = vec2(drawPos.x, drawPos.y), spriteIndex = self.spriteIndex, flipped = not owner.isFacingRight })
                end
            end
        }
    end
}

C_AnimatedSpriteRenderer = {
    new = function(self, sprites, animationTime, cycles)
        return {
            sprites = sprites,
            cycles = cycles,
            spriteIndex = 1,
            animationTimeMax = animationTime,
            animationTime = animationTime,
            draw = function(self, owner)
                dim = Textures[self.sprites[self.spriteIndex]].dimension
                if(owner.transform.position.x == nil) then return end
                local drawPos = vec2(owner.transform.position.x - dim.x / 2, owner.transform.position.y - dim.y)
                local posX = drawPos.x - stat(3) * 128
                if((posX >= 0 and posX < 128) or (posX + dim.x >= 0 and posX + dim.x < 128)) then
                    cspr(self.sprites[self.spriteIndex], drawPos.x, drawPos.y, not owner.isFacingRight)
                end
                if(stat(3) == 3) then
                    add(Map.redrawBuffer, { position = vec2(drawPos.x, drawPos.y), spriteIndex = self.sprites[self.spriteIndex], flipped = not owner.isFacingRight })
                    if self.animationTime >= 0 then
                        self.animationTime -= 1
                    else                        
                        if self.cycles and self.spriteIndex == #self.sprites then
                            self.spriteIndex = 0
                        end 
                        if self.spriteIndex < #self.sprites then
                            self.spriteIndex += 1
                        end
                        self.animationTime = self.animationTimeMax
                    end                    
                end
            end
        }
    end
}

--RenderComponent that draws a pixel
C_PixelRenderer = {
    new = function(self, color)
        return {
            color = color,
            draw = function(self, owner)
                local posX = owner.transform.position.x - stat(3) * 128
                if(posX >= 0 and posX < 128) then
                    pset(posX, owner.transform.position.y, color)
                end
                if(stat(3) == 3) then
                    add(Map.redrawBuffer, { position = vec2(owner.transform.position.x, owner.transform.position.y) })
                end
            end
        }
    end
}

--RenderComponent that draws a line
C_LineRenderer = {
    new = function(self, color, width)
        return {
            color = color,
            width = width,
            draw = function(self, owner)
                local posX = owner.transform.position.x - stat(3) * 128
                if((posX >= 0 and posX < 128) or (posX + width >= 0 and posX + width < 128)) then
                    line(posX, owner.transform.position.y, posX + self.width, owner.transform.position.y, self.color)
                end
                if(stat(3) == 3) then
                    add(Map.redrawBuffer, { position = vec2(owner.transform.position.x, owner.transform.position.y), dimension = vec2(self.width, 0) })
                end 
            end
        }
    end
}

--Component that simulates velocity and collision
C_VelocityController = {
    --This is a really inefficient implementation of a velocity controller,
    --Because it basically needs to do a pixel by pixel simulation of the projectile in both directions.
    --I tried using a raycast here, but this is even worse.
    new = function(self, takeSteps, simulationSteps)
        return{
            takeSteps = takeSteps or false,
            simulationSteps = simulationSteps or 3,
            update = function(self, owner)
                --Handle Y Velocity
                local velocityDir = self.simulationSteps * vec2(owner.velocity.x / abs(owner.velocity.x), owner.velocity.y / abs(owner.velocity.y))
                local velocity = vec2(owner.velocity.x, owner.velocity.y)

                --Screen Bounds
                if(velocity.x + owner.transform.position.x < 0) then 
                    velocity.x = -owner.transform.position.x
                elseif(velocity.x + owner.transform.position.x > Map.screens.x * 128) then
                    velocity.x = Map.screens.x * 128 - owner.transform.position.x
                end

                if(owner.transform.position.y - velocity.y < 0) then 
                    velocity.y = owner.transform.position.y
                elseif(owner.transform.position.y - velocity.y > Map.screens.y * 128) then
                    velocity.y = owner.transform.position.y - Map.screens.y * 128
                end

                --Handle Y Velocity
                local hitGround = false
                if(owner.velocity.y ~= 0) then
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
                if(owner.velocity.x ~= 0) then
                    while(velocity.x * velocityDir.x > 0) do
                        --Move left/right
                        if(Map:getMapData(owner.transform.position.x + velocityDir.x, owner.transform.position.y) <= 0) then
                            owner.transform.position.x += velocityDir.x * min(1, abs(velocity.x))
                            velocity.x -= velocityDir.x
                        --Take steps
                        elseif(takeSteps) then
                            if((Map:getMapData(owner.transform.position.x + velocityDir.x, owner.transform.position.y-1) <= 0 or Map:getMapData(owner.transform.position.x + velocityDir.x, owner.transform.position.y-2) <= 0)) then
                                owner.transform.position.x += velocityDir.x * min(1, abs(velocity.x))
                                owner.transform.position.y -= 1
                                velocity.x -= velocityDir.x
                            else
                                owner.velocity.x = 0
                                hitGround = true
                                break
                            end
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

--Component that adds velocity, but no collision
C_VelocityController_NoCollision = {
    new = function(self)
        return{
            update = function(self, owner)
                owner.transform.position += vec2(owner.velocity.x, -owner.velocity.y)
            end
        }
    end
}

--Component that controls the player movement
C_PlayerController = {
    new = function(self, playerID)
        return {
            stairDirection = 0,
            stairPosition = {},
            stairStartHeight = 0,
            stairDuration = 20,
            playerID = playerID == 1 and 1 or 0,
            digTimer = 0,
            update = function(self, owner)
                owner.velocity.x *= 0.75
                owner.velocity.y -= 0.1
                if(Map:getMapData(owner.transform.position.x, owner.transform.position.y) == -1) then
                    owner.velocity.y = max(owner.velocity.y, -0.3)
                end
                --Go Right
                if(btn(1, self.playerID)) then
                    owner.velocity.x += 0.4
                    owner.isFacingRight = true
                end

                --Go Left
                if(btn(0, self.playerID)) then 
                    owner.velocity.x += -0.4
                    owner.isFacingRight = false
                end

                --Dig
                if(btn(3, self.playerID) and self.digTimer <= 0 and not damagedPlayer) then 
                    owner.velocity.y = -3
                    sfx(15)
                    Explosion:new(owner.transform.position.x, owner.transform.position.y, 7)
                    self.digTimer = 30
                end
                if(self.digTimer > 0 and not damagedPlayer) then self.digTimer -= 1 end

                --Jump
                if(btn(4, self.playerID)) then                                  
                    if(Map:getMapData(owner.transform.position.x, owner.transform.position.y + 1) ~= 0 or Map:getMapData(owner.transform.position.x, owner.transform.position.y + 2) ~= 0) then
                        owner.velocity.y = 2 
                        sfx(19)          
                    end
                end

                --Build
                if(btnp(2, self.playerID)) then
                    self.stairDirection = owner.isFacingRight 
                    self.stairPosition = vec2(owner.transform.position.x + (owner.isFacingRight and 3 or -3), owner.transform.position.y+2)
                    self.stairDuration = 30
                    self.stairStartHeight = owner.transform.position.y+2
                end
                if(btn(2, self.playerID) and self.stairDuration > 0) then
                    for y = self.stairPosition.y, self.stairPosition.y + 3 do
                        if(Map:getMapData(self.stairPosition.x, y)<=0) then 
                            Map:setMapData(self.stairPosition.x, y, 2)
                        end
                    local otherPlayer = Game.players[playerID == 1 and 2 or 1]
                        if(otherPlayer ~= nil) then
                            if(distance(self.stairPosition, otherPlayer.transform.position) <= 5) then
                                otherPlayer.healthSystem:applyDamage(30)
                            end
                        end
                    end
                    add(Map.redrawBuffer, { position = vec2(self.stairPosition.x, self.stairPosition.y), dimension = vec2(1, self.stairStartHeight - self.stairPosition.y) })
                    self.stairPosition.x += self.stairDirection and 1 or -1
                    self.stairPosition.y -= 0.7
                    self.stairDuration -= 1
                end

                --Damage Player on Stomp
                if(owner.velocity.y <= -3) then
                    local otherPlayer = Game.players[playerID == 1 and 2 or 1]
                    if(otherPlayer ~= nil) then
                        if(distance(owner.transform.position, otherPlayer.transform.position) <= 6) then
                            otherPlayer.healthSystem:applyDamage(20)
                        end
                    end
                end
            end
        }
    end
}

--Component that destroys the entity after a certain amount of frames
C_Lifetime = {
    new = function(self, lifetime)
        return {
            lifetime = lifetime,
            update = function(self, owner)
                lifetime -= 1
                if(lifetime <= 0) then
                    owner:destroy()
                end
            end
        }
    end
}

--Component that controls a health value
C_HealthSystem = {
    new = function(self, owner, maxHealth)
        local me = {
            health = maxHealth,
            maxHealth = maxHealth,
            owner = owner,
            applyDamage = function(self, amount)
                printh("Apply Damage")
                if(amount == 0) then return end
                sfx(14)
                
                self.health = min(max(self.health - amount, 0) ,maxHealth)

                --Terrible way to implement this, but the health bar needs to be redrawn on different locations using different formulas
                if(self.owner.playerID == 1) then
                    if(amount < 0) then
                        for x = self.health - amount, self.health do
                            Map:setMapData(x, 0, 7)
                            Map:setMapData(x, 1, 7)
                        end
                        add(Map.redrawBuffer, { position = vec2(self.health + amount, 0), dimension = vec2(-amount, 2) })
                        sfx(14)
                    else
                        for x = self.health, self.health + amount do
                            Map:setMapData(x, 0, 0)
                            Map:setMapData(x, 1, 0)
                        end
                        add(Map.redrawBuffer, { position = vec2(self.health, 0), dimension = vec2(amount, 2) })
                        sfx(14)
                    end
                else
                    if(amount < 0) then
                        for x = self.health - amount, self.health do
                            Map:setMapData(512 - x, 0, 8)
                            Map:setMapData(512 - x, 1, 8)
                        end
                        add(Map.redrawBuffer, { position = vec2(512 + amount - self.health, 0), dimension = vec2(-amount, 2) })
                        sfx(14)
                    else
                        for x = self.health, self.health + amount do
                            Map:setMapData(512 - x, 0, 0)
                            Map:setMapData(512 - x, 1, 0)
                        end
                        add(Map.redrawBuffer, { position = vec2(512 - amount - self.health, 0), dimension = vec2(amount, 2) })
                        sfx(14)
                    end
                end

                --Spawn BloodParticle
                if(amount > 0) then
                    for x = 0, flr(amount / 5) do
                        BloodParticle:new(self.owner.transform.position.x, self.owner.transform.position.y)
                    end
                end
            end,
            --Not optimal to check every frame but the easiest way
            --You can not check it in the applyDamage function, because then the foreach in the update function might get screwed
            update = function(self, owner)
                if(self.health <= 0) then
                    owner:destroy()
                    sfx(17)
                end
            end
        }
        owner.healthSystem = me
        return me
    end
}

--Component grants the player a weapon when coming close to the entity
C_WeaponPickup = {
    new = function(self, weaponID)
        return {
            pickUpDistance = 5,
            weaponID = weaponID,
            update = function(self, owner)
                for player in all(Game.players) do
                    if(distance(player.transform.position, owner.transform.position) <= self.pickUpDistance) then
                        if(not (player.weapon == nil)) then player.weapon:destroy() end
                        owner:destroy()
                        sfx(16)
                        --Lua is lacking switch case so we are doing if's
                        if(self.weaponID == 20) then
                            player.weapon = Weapon_Shotgun:new(player)
                        elseif(self.weaponID == 21) then
                            player.weapon = Weapon_LaserWeapon:new(player)
                        elseif(self.weaponID == 22) then
                            player.weapon = Weapon_LaunchWeapon:new(player)
                        elseif(self.weaponID == 24) then
                            player.weapon = Weapon_PistolWeapon:new(player)                                    
                        elseif(self.weaponID == 25) then
                            player.weapon = Weapon_SniperWeapon:new(player)
                        else
                            player.weapon = Weapon_AK:new(player)
                        end
                        return
                    end
                end
            end
        }
    end
}

--Component let's the player pick up a flag when coming close to the entity
C_FlagPickup = {
    new = function(self)
        return {
            pickUpDistance = 5,
            pickedUpPlayer = nil,
            update = function(self, owner)
                local player = Game.players[owner.flagID == 30 and 2 or 1]
                if(player == nil) then 
                    pickedUpPlayer = nil
                    return
                end
                if(pickedUpPlayer == nil) then
                    if(distance(player.transform.position, owner.transform.position) <= self.pickUpDistance) then
                        pickedUpPlayer = player
                    end
                end
                if(pickedUpPlayer ~= nil) then
                    owner.transform.position = pickedUpPlayer.transform.position + vec2(pickedUpPlayer.isFacingRight and 1 or 3, -3)
                end
            end
        }
    end
}

--Component that damages nearby players.
C_Damage = {
    new = function(self, damageAmount)
        return {
            damageAmount = damageAmount,
            update = function(self, owner)
                local enemyPlayer = Game.players[owner.playerID == 1 and 2 or 1]
                if(enemyPlayer ~= nil) then
                    --printh(distance(enemyPlayer.transform.position + vec2(0, -4), owner.transform.position))
                    if(distance(enemyPlayer.transform.position + vec2(0, -4), owner.transform.position) < 5) then
                        enemyPlayer.healthSystem:applyDamage(self.damageAmount)
                        owner:destroy()
                    end
                end
            end
        }
    end
}

FlagPickup = {
    new = function(self, flagID)
        local me = Entity:new(flagID == 30 and 20 or 490, 4)
        me.flagID = flagID
        add(me.components, C_FlagPickup:new(flagID))
        add(me.components, {
            update = function(self, owner)
                if(Map:getMapData(owner.transform.position.x, owner.transform.position.y+1) == 0) then
                    owner.transform.position.y += 0.2
                end
            end
        })
        add(me.renderComponents, C_SpriteRenderer:new(flagID))
        add(Game.flags, me)
        return me
    end
}

FlagPad = {
    new = function(self, padID)
        local x = padID == 32 and 490 or 20
        local me = Entity:new(x, getHeightOfMap(x))
        me.padID = padID
        add(me.renderComponents, C_SpriteRenderer:new(padID))
        add(Game.flagPads, me)
        return me
    end
}

--Abstract Particle Class
Particle = {
    new = function(self, x, y, color)
        local me = Entity:new(x, y)
        add(me.renderComponents, C_PixelRenderer:new(color))
        me.lifetime = 60
        me.update = function(self)
            self.transform.position += vec2(self.velocity.x, -self.velocity.y)
            self.lifetime -= 1
            if(self.lifetime <= 0 or self.transform.position.y > Map.screens.y * 128) then
                self:destroy()
            end
        end
        return me
    end
}

BloodParticle = {
    new = function(self, x, y)
        local me = Particle:new(x, y, 8)
        me.velocity = vec2(rnd(2)-1, rnd(3))
        me.oldUpdate = me.update
        me.update = function(self)
            self.velocity -= vec2(0, 0.1)
            self:oldUpdate()
        end
    end
}

ExplosionAnim = {
    new = function(self, x, y, sprites)
        local me = Entity:new(x, y)
        add(me.renderComponents, C_AnimatedSpriteRenderer:new(sprites,3, false))
        add(me.components,C_Lifetime:new (15))
    end
}


FlagPadParticle = {
    new = function(self, x, y, color)
        local me = Particle:new(x, y, color)
        me.velocity = vec2(rnd(1)-0.5, rnd(2)+1)
        me.lifetime = 30
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
            isFacingRight = true,
            draw = function(self)
                foreach(self.renderComponents, function(obj) obj:draw(self) end)
            end,
            update = function(self)
                foreach(self.components, function(obj) obj:update(self) end)
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
    playerID = 0,
    new = function(self, x, y, playerID)

        local entity = Entity:new(x, y)
        entity.update = function(self)
            foreach(self.components, function(obj) obj:update(self) end)
        end
        entity.destroy = function(self)
            --Destroy Weapon
            if(self.weapon ~= nil) then
                self.weapon:destroy()
            end

            --BloodParticle Splatter
            for x = 0, 30 do
                BloodParticle:new(self.transform.position.x, self.transform.position.y)
            end

            --Respawn Player
            PlayerRespawner:new(self.spawnPoint.x, self.spawnPoint.y, self.playerID)

            --Remove Player from lists
            Game.players[self.playerID] = nil
            del(Game.objects, self)
        end

        if(playerID == nil) then
            self.playerID += 1
            entity.playerID = self.playerID
            add(Game.players, entity)
        else
            entity.playerID = playerID
            Game.players[playerID] = entity
        end

        entity.spawnPoint = vec2(x,y)
        entity.weapon = Weapon_PistolWeapon:new(entity)
        entity.flag = nil

        add(entity.components, C_PlayerController:new(entity.playerID))
        add(entity.components, C_VelocityController:new(true, 1))
        add(entity.components, C_HealthSystem:new(entity, 50))
        add(entity.renderComponents, C_SpriteRenderer:new(entity.playerID == 1 and 5 or 6))
        return entity
    end
}

--Respawns the player after a few seconds
PlayerRespawner = {
    new = function(self, x, y, playerID)
        local me = Entity:new(x, y)
        me.playerID = playerID
        me.respawnTimer = 300
        me.update = function(self)
            self.respawnTimer -= 1
            if(self.respawnTimer <= 0) then
                Player:new(x, y, playerID)
                foreach(Game.players, function(obj) 
                    obj.healthSystem.health = obj.healthSystem.maxHealth 
                    obj.flag = nil
                end)
                foreach(Game.flags, function(obj) 
                    obj:destroy()
                end)
                Game.flags = {}
                createHealthBar()
                FlagPickup:new(30)
                FlagPickup:new(31)
                self:destroy()
            end
        end
    end
}

--Spawns a tree at the x coordinate
Tree = {
    new = function(self, x)
        local position = vec2(x, 0)

        --Find Tree Position Height
        position.y = getHeightOfMap(position.x)
        position.y += 2

        local iters = 30
        for iteration = 0, iters do
            position.y -= 1
            position.x += Simplex2D(position.x, position.y) * 2
            local width = (sin(iteration / iters) + 1) * 3 + 1
            for x = -width, width do
                Map:setMapData(position.x + x, position.y, (iteration <= iters/5*2) and 4 or 40)
            end
        end
    end
}

--Returns the grass height at a position of the map
function getHeightOfMap(x)
    local height = 0
    while(Map:getMapData(x, height) ~= 3) do
        height += 1
    end
    return height
end

--Spawn weapon loop
function spawnWeapon()
    Game.weaponTimer -= 1
    if(Game.weaponTimer <= 0) then
        Game.weaponTimer = 400
        local weaponID = 20 + flr(rnd(6))
        WeaponDrop:new(weaponID)
    end
end

--Recreates the map from scratch
function generateMap()
    local seed = rnd(100)
    Map.mapData = {}    
    cls()
    for screenX = 0, Map.screens.x-1 do
        Map.mapData[screenX] = {}
        for y = 0, 127 do
            for x = 0, 127 do
                local distance = Map.groundHeight + Simplex2D((x + screenX * 128) / 200, seed) * 25 + Simplex2D((x + screenX * 128) / 50, seed) * 5 - y
                if distance < 0 then
                    --Create Grass
                    if(distance > -8 + Simplex2D((x + screenX * 128), 99) * 5) then
                        Map.mapData[screenX][x + y * 128] = 3
                    --Create Dirt
                    else
                        Map.mapData[screenX][x + y * 128] = 1
                    end
                --Above Ground
                else
                    --Create Water
                    if(y > Map.waterHeight) then
                        Map.mapData[screenX][x + y * 128] = -1
                    --Create Air
                    else
                        Map.mapData[screenX][x + y * 128] = 0
                    end
                end
            end
        end
    end

    for i = 0, 3 do
        Tree:new(rnd(512))
    end
    forceRedraw = true
end

--Redraws a region of the screen
function redrawRegion(posX, posY, width, height)
    local screen = stat(3)
    posX = flr(posX) - screen * 128
    posY = flr(posY)
    if((posX >= 0 and posX < 128) or (posX + width >= 0 and posX + width < 128)) then
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
    end
end

--Redraws a pixel of the screen
function redrawPixel(posX, posY)
    local x = posX - stat(3) * 128
    if(x < 0 or x >= 128) then return false end

    local pixel = Map:getMapData(posX, posY)
    local color = sget(posX % Textures[pixel].dimension.x + Textures[pixel].position.x, posY % Textures[pixel].dimension.y + Textures[pixel].position.y)
    pset(x, posY, color)
    return true
end

--Redraws a region of the screen defined by the sprite mask
function redrawSprite(posX, posY, spriteIndex, isFlipped)
    local screen = stat(3)
    posX = flr(posX) - screen * 128
    posY = flr(posY)
    local width = Textures[spriteIndex].dimension.x
    local height = Textures[spriteIndex].dimension.y
    if((posX >= 0 and posX < 128) or (posX + width >= 0 and posX + width < 128)) then
        for x = max(posX,0), min(posX + width, 127) do
            for y = max(posY, 0), min(posY + height, 127) do
                if(isFlipped) then
                    if(sget(Textures[spriteIndex].position.x + width - (x - posX + 1), Textures[spriteIndex].position.y + y - posY) ~= 0) then
                        local pixel = Map:getMapDataByScreen(x, y, screen)
                        local color = sget(x % Textures[pixel].dimension.x + Textures[pixel].position.x, y % Textures[pixel].dimension.y + Textures[pixel].position.y)
                        pset(x, y, color)
                    end
                else
                    if(sget(x - posX + Textures[spriteIndex].position.x, y - posY + Textures[spriteIndex].position.y) ~= 0) then
                        local pixel = Map:getMapDataByScreen(x, y, screen)
                        local color = sget(x % Textures[pixel].dimension.x + Textures[pixel].position.x, y % Textures[pixel].dimension.y + Textures[pixel].position.y)
                        pset(x, y, color)
                    end
                end
            end
        end
    end
end

--Draws a pixel of a specific id at a specific pixel
--Respects tiling of texture
function drawPixel(posX, posY, index)
    local x = posX - stat(3) * 128
    if(x < 0 or x >= 128) then return false end

    local color = sget(posX % Textures[index].dimension.x + Textures[index].position.x, posY % Textures[index].dimension.y + Textures[index].position.y)
    pset(x, posY, color)
    return true
end

--Draws the health bar for both players
function createHealthBar()
    for x = 0, 50 do
        Map:setMapData(x, 0, 7)
        Map:setMapData(x, 1, 7)
        Map:setMapData(512-x, 0, 8)
        Map:setMapData(512-x, 1, 8)
    end
    add(Map.redrawBuffer, { position = vec2(0, 0), dimension = vec2(50, 2)})
    add(Map.redrawBuffer, { position = vec2(462, 0), dimension = vec2(50, 2)})
end

--Redraws the entire screen
function redrawScreen()
    cls()
    redrawRegion(128 * stat(3), 0, 127, 127)
    line(0,128,128,128, 5)
    forceRedraw = stat(3)<3
    return forceRedraw
end

--Redraw the buffer (pixels/areas that need to be redrawn)
function redrawBuffer()
    palt(0, false)
    for i in all(Map.redrawBuffer) do
        if(i.spriteIndex ~= nil) then
            redrawSprite(i.position.x, i.position.y, i.spriteIndex, i.flipped)
        elseif(i.dimension == nil) then
            redrawPixel(i.position.x, i.position.y)
        else
            redrawRegion(i.position.x, i.position.y, i.dimension.x, i.dimension.y)
        end
    end
    palt(0, true)
    if(stat(3)==3) then
        Map.redrawBuffer = {}
    end
end

--Custom Sprite draw function supporting the ID's defined under Textures
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

function _init()
    generateMap()
    Player:new(20,20)
    Player:new(490,20)
    FlagPickup:new(30)
    FlagPickup:new(31)
    FlagPad:new(32)
    FlagPad:new(33)
    createHealthBar()
end

function _update60()
    foreach(Game.objects, function(obj) obj:update(self) end)
    spawnWeapon()
end

--Activate Multiscreen Feature
poke(0x5f36,1)
function _draw()
    printh(#Game.objects)
    if(forceRedraw) then
        --Redraw the whole map
        return redrawScreen()
    else
        --Redraw parts of the screen
        if #Map.redrawBuffer > 0 then
            redrawBuffer()
        end
        --Draw entities
        foreach(Game.objects, function(obj) obj:draw(self) end)
        --if(stat(3) == 3) then 
            --AvgPerformance += stat(1)
            --Time += 1
            --printh("Performance: "..stat(1)..", Frame: "..Time..", Average: "..(AvgPerformance / Time))
        --end
        return stat(3)<3
    end
end

-- save original camera function reference
_camera = camera 
--Custom camera function for multiscreen
function camera(x,y)
    x = x or 0
    y = y or 0
    local dx=flr(stat(3) % Map.screens.x)
    local dy=flr(stat(3) / Map.screens.x)
    _camera(x+128*dx, y+128*dy)
end

__gfx__
00e000000030000000000000000000000000000000000000000000000000000044f44444444ff44433b3366311cd111144445444444544445555555d55555555
0e0cc60003088e00000000000000000000000dd000000000000000000000000044f444444444f4443b3353361111111d4445454444445444555555d5d555ddd5
000dcc000002880000000000000000000ee0d0dd00000000aa9900000000000044f444444444f444363db5461111c11144444494444444545555555555dd5555
0a911dc00a9112e00065d55503bbb0b0ee7e50000011155540055a900266c00044ff4444444ff44456b5b3b3c11d111154444f4444f4644455d5555ddd555555
091cc61909188e1906544400bb333b5b2ee2d0dd01d9d5550004000000977966444ff444444f444443b33b351111111c4f44444f444544455d55d55555555d55
091ccc1009188810650000000dbbb000d2250dd01510c00000000000079559004444ff44444f444445b636b311111111445444444444459455555d555555d555
00dc1c000028180000000000d000000055500000d0000c00000000004440000044444fff444fffff353b36351c11cd11444444444444444f555555d555555d55
000c010000080100000000000000000000000000000000000000000000000000ff44444ff4ff44446b3b5d33d1111111444444444444f4445555d55d55555555
0000000000000000000000000000000000000dd00000000000000000000000004f444444fff44444e882e882000000004444444444544544555d5555555d555d
000000000000000000000000000000bb0000d0000000055000000000000000604ff4444ffff4444482e882e8000000004444544444444444d555d5555dd555d5
000040000000f000000005000000bb500000d00d00005550000000000000060044fffff44ff44444cdd1cdd10000000044464f4444454454d555555dd5555555
0a911dc00a9112e000005000000b3b0000ee5dd00001550000000000000c60004444f4444f444444d1cdd1cd0000000044f444f444444544d55555d555555555
091cc61909188e19000d400000b3b0000ee7e0000019dc000009009000d790004444f4444f44444460600900000000004544494454444444555d5555555d5555
091ccc100918881000640000003b000002ee200001dd00c000900a0002755000444ff4444f444444090900000000000044545444444444f45555d55555d55555
00dc1c0000281800005000000bd000000022500001d1000009a590000094000044ff44444fff44446060009000000000444444454444f444555d555d55555d55
000c0100000801000050000000d0000000d5000000d00000004040000040000044f4444444ff444400009000000000004444445444444544555555d5555555dd
0000000000000000000909000b03b6b000200d00001cc1000000000000a900005110000052200000004000000a0a0000d33333333333333b5555415141554555
00000000000000000a900004b73b793b20ee60000ce27ec0000000006a7aa9605dd110005ee2200009a900000499a00033b3333b3b33b3335555115445555155
00000000000000007f990a090b03b3b0087ae0001870608c0000000000a000005ccdd110588ee2200a7f00000f7a0000bb3333b3b33bd3335555155455554155
00000000000000000a900000035000502ea78200c200000c0000000000009a095ccccdd158888ee204a0900009a400003533a3333333333a1555555555554155
000000000000000000000009b60b350306ee0000766000670000a00a009a94005ccdd110588ee2200000000000000000333333d3335333335555455555555155
00000000000000000000000039b30060d00200001c000021000000005489a5965dd110005ee220000000000000000000333b3b33333393335455455555555555
00000000000000000000009003303800000000000e2060c000000000009aa9005110000052200000000000000000000033bdb3333333333b5415455515555555
000000000000000000009400b00b00300000000000cc710000000000000090a950000000500000000000000000000000533333b3b3b333b35455455414551555
0000006c000000e800909a00000000006002000000000000000000000000000f5000000050000000000000000000000039333b3b3b5333355455555414555145
00000cc10000088200084890000000000ce8d0000000600000000000000000f0500000005000000000000000000000003333b533333333335555545454551145
00006c100000e8200005009a000006002ea7820000c070c00000000000000900d0000000e000000000000000000000003333d335333d33335455545555551145
0006c100000e8200055008990000b0000879e000000070000000000000000000d0000000e000000000000000000000003b333333335333331455541555551155
00cc100000882000600040a9000300000d8e0200067707760000000000070000d0000000e00000008000000810000001b3333b3b33333b335555545455451555
06c100000e8200000000089a0000000000200600000c70000000000000600000d0000000e000000055000055550000553a33b3b33933b3bb1554551555451555
cc10000088200000000890a00300000000000000001070c00000000000000000d0000000e0000000e5eeee5ec5cccc5c33333533b3b333335555155551551555
c1000000820000000090a9000000000000000000000060000000000060000000d0000000e00000005555555555555555b333333b3b3333d35555155551551555
__map__
0000000000000000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
c20d0020155201552018030180301a0301a0301c010200102101021010230102303021020210302001020010210102101018510195101a5101a5101e0501e0401c0201c02019020190201a0201a0201752014520
300d0000042200b4001c1000b400196001a100267001960025700186002870026700196000c4001530015300267000c4000b2100b210092100921026700186001b100002000423004210042001f1002670026700
c10d00002472024720247202471024710257102571010000287302872028720287100a0000c40015300297001d7301d7201d7201d720217202172023730237202372023720227202272022720227102171021710
b60d00003040030400242503040023210232302342023410152202d400152402d4002c4002c400202202c4002d4002d4001522015230152101523015240152402d4002d400152201523017210172301524017240
b10d00000c650376001b6000c6000c6502f6001b600326000c6500c600076000b6000c65032600316000c6000c650376001b6001b6000c6502f6001b600326000c6503260007600016000c650006002b6000c620
800d0000174001740017400174002d630144001440014400134002d61013400296002d6301240012400124000b4000b4002d6000b4002d6300b4000b4000b4000b4002d6100b4000b4002d6300e4001140013400
000d00001013010130101300411010130101301013004110131301310010110101100b50014100141101412014120141201412014110141101411002500025000250001500191101911019100191001911019110
000d00001013010130101300711010120101101011008110131301010010110101101010010100141101412014120141201412014110141102610019600000000d60010110121201212012110121001211012110
00030000000401466004550106500d6400a64008640066300463003620036100161000510005100051000600006000b6000a6000960000600006000f02019620146100d600076100000000000256101161010100
00010000056202f140200501a0401523013030117300f7300e730132300c0300c730182500b730182500b740172400b730172300a720162201621014210132101321011210102100e2200c210092100721000210
000400000d31009660043200b3100a640043100b6100f1301312018110036100004001040010400204002040030400404005030070300a0200b1200b2200b0300b2300b0300b0300b0300b0200b2100b0100b410
00030000146500e630086200111000610000100870002700001000010000000004000040000000001000010000000001000010000100001000010000000000000000000000000000000000000000000000000000
0003000001440186600a420176501664015630146301363012620116200f6200c6200b62008620076200662005620036200362002620016200162000620006200062000620006200062000620006200061000610
0001000006660074100a6200e13011110131201512016130171401814019130191201912019110191101911019110191101911019110181101910019100191001910019100191001910018100181001810018100
00020000306102b620042600162006310016200061000610196000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200001c610136200665001310086000244000620002100060000600006200064008650096200c6101e600000000d6000000000000000000000000000000000000000000000000000000000000000000000000
00040000131401a140000002e0500000000000000000000007620012100000013600116301a6200d6100020000000000000000000000000000000000000000000000000000000000000000000000000000000000
00050000160201e0402304026050270502704026040240301f0301b1201612013120101200e1100c1100911007110051100411003110011100111000110000000900004000000000000000000000000000000000
000700001d1601d10000100001001d1501d1001d150000001d15000000000000010018150000000000000000000001d1601d1501d1501d1501d1401d1401d1301d1301d1201d1201d11000010000000000000000
0002000004040091500c1400e1301012012120151101a110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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

