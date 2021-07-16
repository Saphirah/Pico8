pico-8 cartridge // http://www.pico-8.com
version 32
__lua__

#include vector.p8
#include noise.p8

--Make BtnP only register the initial key delay
poke(0x5f5c,99999)
poke(0x5f5d,99999)

Game = {
    objects = {},
    pellets = {},
    players = {},
    flags = {},
    weaponTimer = 300
}

Map = {
    screens = vec2(4, 1),
    waterHeight = 90,
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
    setMapData = function(self, x, y, index, addToRedrawBuffer)
        addToRedrawBuffer = addToRedrawBuffer or true
        local dx = min(max(flr(x), 0), Map.screens.x*127)
        local dy = min(max(flr(y), 0), Map.screens.y*127)
        if(addToRedrawBuffer) then add(Map.redrawBuffer, { position = vec2(dx, dy) })
        Map.mapData[min(max(flr(dx/128), 0), 3)][dy * 128 + (dx % 128)] = index
    end,
    setMapDataByScreen = function(self, x, y, screen, index)
        local dx = min(max(flr(x), 0), 127)
        local dy = min(max(flr(y), 0), 127)
        add(Map.redrawBuffer, { position = vec2(dx + screen * 128, dy) })
        Map.mapData[screen][dy * 128 + (dx % 128)] = index
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
        position = vec2(16, 0),
        dimension = vec2(8, 8)
    },
    --LaserWeapon
    [11] = {
        position = vec2(24, 0),
        dimension = vec2(8, 8)
    },
    --LaserBall
    [12] = {
        position = vec2(32, 0),
        dimension = vec2(8, 8)
    },
    --AK
    [13] = {
        position = vec2(40, 0),
        dimension = vec2(8, 8),
        fissibubele = 42069
    },
    --Pistol
    [14] = {
        position = vec2(48, 0),
        dimension = vec2(8, 8)
    },
    --Sniper
    [15] = {
        position = vec2(56, 0),
        dimension = vec2(8, 8)
    },
    --WeaponDrops
    --Shotgun
    [20] = {
        position = vec2(16, 8),
        dimension = vec2(8, 8)
    },
    --LaserWeapon
    [21] = {
        position = vec2(24, 8),
        dimension = vec2(8, 8)
    },
    --LaserBall
    [22] = {
        position = vec2(32, 8),
        dimension = vec2(8, 8)
    },
    --AK
    [23] = {
        position = vec2(40, 8),
        dimension = vec2(8, 8)
    },
    --Pistol
    [24] = {
        position = vec2(48, 8),
        dimension = vec2(8, 8)
    },
    --Sniper
    [25] = {
        position = vec2(56, 8),
        dimension = vec2(8, 8)
    },
    --Blue Flag
    [30] = {
        position = vec2(64, 16),
        dimension = vec2(8, 16)
    },
    --Red Flag
    [31] = {
        position = vec2(72, 16),
        dimension = vec2(8, 16)
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
                    screen = flr((x + dx) / 128)
                    if(y + dy > Map.waterHeight) then
                        --Map:setMapDataByScreen(x + dx, y + dy, screen, -1)
                        Map.mapData[screen][max(1,min(128*128, (y + dy) * 128 + (x + dx) % 128))] = -1
                    else
                        --Map:setMapDataByScreen(x + dx, y + dy, screen, 0)
                        Map.mapData[screen][max(1,min(128*128, (y + dy) * 128 + (x + dx) % 128))] = 0
                    end
                end
            end
        end
        --add(Map.redrawBuffer, { position = vec2(x - radius - 1, y - radius - 1), dimension = vec2(radius * 2 + 2, radius * 2 + 2)})
    end
}

--Component that controls the sprite rendering
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
                    add(Map.redrawBuffer, { position = vec2(drawPos.x, drawPos.y), dimension = vec2(self.dim.x, self.dim.y)})
                end
            end
        }
    end
}

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

C_VelocityController = {
    new = function(self, takeSteps, simulationSteps)
        return{
            takeSteps = takeSteps or false,
            simulationSteps = simulationSteps or 3,
            update = function(self, owner)
                --Handle Y Velocity
                local velocityDir = self.simulationSteps * vec2(owner.velocity.x / abs(owner.velocity.x), owner.velocity.y / abs(owner.velocity.y))
                local velocity = vec2(owner.velocity.x, owner.velocity.y)
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
            update = function(self, owner)
                owner.velocity.x *= 0.75
                owner.velocity.y -= 0.1
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
                if(btn(3, self.playerID)) then 
                    owner.velocity.y = -2
                    Explosion:new(owner.transform.position.x, owner.transform.position.y, 4)
                end

                --Jump
                if(btn(4, self.playerID)) then 
                    if(Map:getMapData(owner.transform.position.x, owner.transform.position.y + 1) > 0) then
                        owner.velocity.y = 2
                    end
                end

                --Build
                if(btnp(2, self.playerID)) then
                    self.stairDirection = owner.isFacingRight 
                    self.stairPosition = vec2(owner.transform.position.x, owner.transform.position.y)
                    self.stairDuration = 20
                    self.stairStartHeight = owner.transform.position.y
                end
                if(btn(2, self.playerID) and self.stairDuration > 0) then
                    for x = self.stairPosition.y, self.stairStartHeight do
                        Map:setMapData(self.stairPosition.x, self.stairPosition.y, 2, false)
                    end
                    add(Map.redrawBuffer, { position = vec2(dx, dy) })
                    self.stairPosition.x += self.stairDirection and 1 or -1
                    self.stairPosition.y -= 1
                    self.stairDuration -= 1
                end
            end
        }
    end
}

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
        return {
            health = maxHealth,
            maxHealth = maxHealth,
            owner = owner,
            applyDamage = function(self, amount)
                printh("Apply Damage")
                if(amount == 0) then return end
                
                self.health = min(max(self.health - amount, 0) ,maxHealth)

                if(self.owner.playerID == 1) then
                    if(amount < 0) then
                        for x = self.health - amount, self.health do
                            Map:setMapData(x, 0, 7)
                            Map:setMapData(x, 1, 7)
                        end
                    else
                        for x = self.health, self.health + amount do
                            Map:setMapData(x, 0, 0)
                            Map:setMapData(x, 1, 0)
                        end
                    end
                else
                    if(amount < 0) then
                        for x = self.health - amount, self.health do
                            Map:setMapData(512 - x, 0, 8)
                            Map:setMapData(512 - x, 1, 8)
                        end
                    else
                        for x = self.health, self.health + amount do
                            Map:setMapData(512 - x, 0, 0)
                            Map:setMapData(512 - x, 1, 0)
                        end
                    end
                end

                printh("Health: "..self.health..", PlayerID: "..owner.playerID)
            end,
            --Not optimal to check every frame but the easiest way
            update = function(self, owner)
                if(self.health <= 0) then
                    owner:destroy()
                end
            end
        }
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

C_FlagPickup = {
    new = function(self)
        return {
            pickUpDistance = 5,
            update = function(self, owner)
                local player = Game.players[owner.flagID == 30 and 2 else 1]
                if(player == nil) then return end
                if(player.flag ~= nil) then return end
                if(distance(player.transform.position, owner.transform.position) <= self.pickUpDistance) then
                    player.flag = owner
                    owner.playerFollow = {
                        player = player,
                        update = function(self, owner)
                            owner.transform.position = self.player.transform.position + (self.player.isFacingRight and 1 or -1) * vec2(-4, 0)
                            owner.isFacingRight = self.player.isFacingRight
                        end
                    }
                end
            end
        }
    end
}

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

Weapon = {
    new = function(self, parent, spriteID)
        local me = Entity:new(0, 0)
        me.parent = parent
        add(me.renderComponents, C_SpriteRenderer:new(spriteID))
        me.update = function(self)
            self.transform.position = self.parent.transform.position + (self.parent.isFacingRight and 1 or -1) * vec2(4, 0)
            self.isFacingRight = self.parent.isFacingRight
            self:isShooting()
        end
        me.isShooting = function(self)
            if(btnp(5, self.parent.playerID == 1 and 1 or 0)) then
                self:shoot()
            end
        end
        return me
    end
}

Weapon_Shotgun = {
    new = function(self, parent)
        local me = Weapon:new(parent, 10)
        me.cooldown = 45
        me.shoot = function(self)
            sfx(8)
            self.parent.velocity.x = self.parent.isFacingRight and -10 or 10
            for i = -2, 2 do
                Projectile_Pellet:new(self.transform.position.x, self.transform.position.y, self.parent.isFacingRight and 3 or -3, i / 5, self.parent.playerID, 10, 7, 10, 4)
            end
            
        me.isShooting = function(self)
            if(self.cooldown > 0) then
                self.cooldown -= 1
            else
                if(btn(5, self.parent.playerID == 1 and 1 or 0)) then
                    self:shoot()
                    self.cooldown = 45
                end
            end
        end
    end
        return me
    end
}

Weapon_LaserWeapon = {
    new = function(self, parent)
        local me = Weapon:new(parent, 11)
        me.shoot = function(self)
            Projectile_Laser:new(self.transform.position.x, self.transform.position.y, self.parent.isFacingRight and 5 or -5, 0, self.parent.playerID, 10, 11, 5, 50, 0)
            sfx(9)
        end
        return me
    end
}

Weapon_LaunchWeapon = {
    new = function(self, parent)
        local me = Weapon:new(parent, 12)
        me.cooldown = 60
        me.shoot = function(self)
            Projectile_Laser:new(self.transform.position.x, self.transform.position.y, self.parent.isFacingRight and 1 or -1, 0, self.parent.playerID, 10, 12, 6, 400, 8)
            Projectile_Laser:new(self.transform.position.x, self.transform.position.y-1, self.parent.isFacingRight and 1 or -1, 0, self.parent.playerID, 5, 14, 6, 400, 3)
            Projectile_Laser:new(self.transform.position.x, self.transform.position.y+1, self.parent.isFacingRight and 1 or -1, 0, self.parent.playerID, 5, 14, 6, 400, 3)
            sfx(10)
        end
        
        me.isShooting = function(self)
            if(self.cooldown > 0) then
                self.cooldown -= 1
            else
                if(btn(5, self.parent.playerID == 1 and 1 or 0)) then
                    self:shoot()
                    self.cooldown = 60
                end
            end
        end
        return me
    end
}

Weapon_PistolWeapon = {
    new = function(self, parent)
        local me = Weapon:new(parent, 14)
        me.cooldown = 15
        me.shoot = function(self)
            Projectile_Pellet:new(self.transform.position.x, self.transform.position.y, self.parent.isFacingRight and 2 or -2, 0, self.parent.playerID, 5, 10, 40, 5)
            sfx(11)
        end
        
        me.isShooting = function(self)
            if(self.cooldown > 0) then
                self.cooldown -= 1
            else
                if(btn(5, self.parent.playerID == 1 and 1 or 0)) then
                    self:shoot()
                    self.cooldown = 15
                end
            end
        end
        return me
    end
}

Weapon_AK = {
    new = function(self, parent)
        local me = Weapon:new(parent, 13)
        me.cooldown = 3
        me.shoot = function(self)
            sfx(11)
            self.parent.velocity.x = self.parent.isFacingRight and -1 or 1
            Projectile_Pellet:new(self.transform.position.x, self.transform.position.y, self.parent.isFacingRight and 3 or -3, rnd(0.5) - 0.25, self.parent.playerID, 3, 7, 50, 3)
        end
        me.isShooting = function(self)
            if(self.cooldown > 0) then
                self.cooldown -= 1
            else
                if(btn(5, self.parent.playerID == 1 and 1 or 0)) then
                    self:shoot()
                    self.cooldown = 3
                end
            end
        end
        return me
    end
}

Weapon_SniperWeapon = {
    new = function(self, parent)
        local me = Weapon:new(parent, 15)
        me.cooldown = 50
        me.shoot = function(self)
            Projectile_Sniper:new(self.transform.position.x, self.transform.position.y, self.parent.isFacingRight and 25 or -25, 0, self.parent.playerID, 20, 6, 30, 30, 4)
            Projectile_Sniper:new(self.transform.position.x, self.transform.position.y, self.parent.isFacingRight and 22 or -22, 0, self.parent.playerID, 5, 6, 30, 30, 4)
        end
        me.isShooting = function(self)
            if(self.cooldown > 0) then
                self.cooldown -= 1
            else
                if(btn(5, self.parent.playerID == 1 and 1 or 0)) then
                    self:shoot()
                    self.cooldown = 50
                    sfx(12)
                end
            end
        end
        return me
    end
}

Projectile = {
    new = function(self, x, y, velocityX, velocityY, playerID, damage, color, lifetime, explosionRadius)
        local me = Entity:new(x, y-4)
        add(me.components, C_VelocityController:new(false))
        add(me.components, C_Lifetime:new(lifetime))
        add(me.components, C_Damage:new(damage))
        me.velocity = vec2(velocityX, velocityY)
        me.playerID = playerID
        if(explosionRadius > 0) then
            me.explosionRadius = explosionRadius
            me.onHitGround = function(self)
                Explosion:new(self.transform.position.x, self.transform.position.y, self.explosionRadius)
                me:destroy()
            end
        else
            me.onHitGround = function(self)
                me:destroy()
            end
        end
        me.destroy = function(self)
            del(Game.objects, self)
        end
        return me
    end
}

Projectile_Pellet = {
    new = function(self, x, y, velocityX, velocityY, playerID, damage, color, lifetime, explosionRadius)
        local me = Projectile:new(x, y, velocityX, velocityY, playerID, damage, color, lifetime, explosionRadius)
        add(me.renderComponents, C_PixelRenderer:new(10))
        return me
    end
}

Projectile_Laser = {
    new = function(self, x, y, velocityX, velocityY, playerID, damage, color, width, lifetime, explosionRadius)
        local me = Projectile:new(x, y, velocityX, velocityY, playerID, damage, color, lifetime, explosionRadius)
        add(me.renderComponents, C_LineRenderer:new(color, width))
        return me
    end
}

Projectile_Sniper = {
    new = function(self, x, y, velocityX, velocityY, playerID, damage, color, width, lifetime, explosionRadius)
        local me = Projectile:new(x, y, velocityX, velocityY, playerID, damage, color, lifetime, explosionRadius)
        add(me.renderComponents, C_LineRenderer:new(color, width))
        return me
    end
}

WeaponDrop = {
    new = function(self, weaponID)
        local me = Entity:new(flr(rnd(516)), 0)
        me.weaponID = weaponID
        me.lastDownVelocity = 0
        me.onHitGround = function(self)
            self.velocity.y = 0.3
        end
        add(me.components, C_Lifetime:new(900))
        add(me.components, C_WeaponPickup:new(weaponID))
        add(me.components, {
            update = function(self, owner)
                owner.velocity.y -= 0.01
                self.lastDownVelocity = owner.velocity.y
            end
        })
        add(me.components, C_VelocityController:new(true))
        add(me.renderComponents, C_SpriteRenderer:new(weaponID))
        return me
    end
}

FlagPickup = {
    new = function(self, flagID)
        local me = Entity:new(flagID == 30 and 20 or 490, 0)
        me.flagID = flagID
        me.playerFollow = nil
        me.onHitGround = function(self)
            self.velocity.y = 0.3
        end
        add(me.components, C_FlagPickup:new(flagID))
        add(me.components, {
            update = function(self, owner)
                owner.velocity.y -= 0.01
            end
        })
        add(me.components, C_VelocityController:new(true))
        add(me.renderComponents, C_SpriteRenderer:new(flagID))
        add(Game.flags, me)
        return me
    end
}

Flag

Blood = {
    new = function(self, x, y)
        local me = Entity:new(x, y)
        add(me.renderComponents, C_PixelRenderer:new(8))
        me.velocity = vec2(rnd(2)-1, rnd(3))
        me.lifetime = 120
        me.update = function(self)
            self.velocity -= vec2(0, 0.1)
            self.transform.position += vec2(self.velocity.x, -self.velocity.y)
            self.lifetime -= 1
            if(self.lifetime <= 0) then
                self:destroy()
            end
        end
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

            --Blood Splatter
            for x = 0, 30 do
                Blood:new(self.transform.position.x, self.transform.position.y)
            end
            --Respawn Player
            PlayerRespawner:new(self.spawnPoint.x, self.spawnPoint.y, self.playerID)

            --Remove Player from lists
            del(Game.players, self)
            del(Game.objects, self)
        end

        if(playerID == nil) then
            self.playerID += 1
            entity.playerID = self.playerID
        else
            entity.playerID = playerID
        end

        entity.spawnPoint = vec2(x,y)
        entity.weapon = nil
        entity.flag = nil
        entity.healthSystem = C_HealthSystem:new(entity, 50)

        add(entity.components, C_PlayerController:new(entity.playerID))
        add(entity.components, C_VelocityController:new(true, 1))
        add(entity.components, entity.healthSystem)
        add(entity.renderComponents, C_SpriteRenderer:new(entity.playerID == 1 and 5 or 6))
        add(Game.players, entity)
        return entity
    end
}

PlayerRespawner = {
    new = function(self, x, y, playerID)
        local me = Entity:new(x, y)
        me.playerID = playerID
        me.respawnTimer = 300
        me.update = function(self)
            self.respawnTimer -= 1
            if(self.respawnTimer <= 0) then
                Player:new(x, y, playerID)
                foreach(Game.players, function(obj) obj.healthSystem.health = obj.healthSystem.maxHealth end)
                createHealthBar()
                self:destroy()
            end
        end
    end
}


function spawnWeapon()
    Game.weaponTimer -= 1
    if(Game.weaponTimer <= 0) then
        Game.weaponTimer = 300
        local weaponID = 20 + flr(rnd(6))
        WeaponDrop:new(weaponID)
    end
end

function generateMap()
    local seed = rnd(100)
    Map.mapData = {}    
    cls()
    for screenX = 0, Map.screens.x-1 do
        Map.mapData[screenX] = {}
        for y = 0, 127 do
            for x = 0, 127 do
                local distance = 64 + Simplex2D((x + screenX * 128) / 200, seed) * 25 + Simplex2D((x + screenX * 128) / 50, seed) * 5 - y
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
    forceRedraw = true
end

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

function redrawPixel(posX, posY)
    local x = posX - stat(3) * 128
    if(x < 0 or x >= 128) then return false end

    local pixel = Map:getMapData(posX, posY)
    local color = sget(posX % Textures[pixel].dimension.x + Textures[pixel].position.x, posY % Textures[pixel].dimension.y + Textures[pixel].position.y)
    pset(x, posY, color)
    return true
end

function drawPixel(posX, posY, index)
    local x = posX - stat(3) * 128
    if(x < 0 or x >= 128) then return false end

    local color = sget(posX % Textures[index].dimension.x + Textures[index].position.x, posY % Textures[index].dimension.y + Textures[index].position.y)
    pset(x, posY, color)
    return true
end

function setAndDrawPixel(posX, posY, index)
    Map:setMapData(posX, posY, index)
    redrawPixel(posX, posY)
end

function mod(x, m)
    while x < 0 do
        x += m
    end
    return x%m
end

function round(x)
    if(x%1 >= 0.5) then
        return ceil(x)
    else
        return flr(x)
    end
end

function printList(list)
    returnStr = "{"
    for key, obj in pairs(list) do
        returnStr = returnStr .. " " .. key .. " = "
        --if(type(obj) == "table") then
        --    returnStr = returnStr .. printList(obj) .. ", "
        --else
            returnStr = returnStr .. tostr(obj) .. ", "
        --end
    end
    if(#returnStr > 1) then returnStr = sub(returnStr, 1, #returnStr - 2) .. " " end
    return returnStr .. "}"
end

function _init()
    generateMap()
    Player:new(20,20)
    Player:new(490,20)
    createHealthBar()
end

function _update60()
    foreach(Game.objects, function(obj) obj:update(self) end)
    spawnWeapon()
end

--Draws the health bar for both players
function createHealthBar()
    for x = 0, 50 do
        Map:setMapData(x, 0, 7)
        Map:setMapData(x, 1, 7)
        Map:setMapData(512-x, 0, 8)
        Map:setMapData(512-x, 1, 8)
    end
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
        if(i.dimension == nil) then
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

poke(0x5f36,1)
function _draw()
    --Redraw the whole map
    if(forceRedraw) then
        return redrawScreen()
    --Redraw parts of the screen
    else
        if #Map.redrawBuffer > 0 then
            redrawBuffer()
        end
        --Draw entities
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
00e000000030000000000000000000000000000000000000000000000000000044f44444444ff44433533dd3dcdcccdc44445444444544445555555d55555555
0e0cc60003088e00000000000000000000000dd000000000000000000000000044f444444444f4443533533ddcccdcdc4445454444445444555555d5d555ddd5
000dcc000002880000000000000000000ee0d0dd00000000000000000000000044f444444444f4443d3db55dccdcdcdc44444494444444545555555555dd5555
0a911dc00a9112e00000000003bbb0b0ee7e5000001110100000000002ddc00044ff4444444ff4445db5b3b3dcdcdccc54444f4444f4644455d5555ddd555555
091cc61909188e190065d555bb333b5b2ee2d0dd01d9d5550000000000977966444ff444444f444453b33bb5dcdcccdc4f44444f444544455d55d55555555d55
091ccc1009188810065444000dbbb000d2250dd00d10c000a99a5900079559004444ff44444f444455bd3db5dcccdcdc445444444444459455555d555555d555
00dc1c000028180065000000d000000055500000d5000c00405000004440000044444fff444fffff353b3d35ccdcdcdc444444444444444f555555d555555d55
000c010000080100000000000000000000000000000000000000000000000000ff44444ff4ff4444db3b5d33dcdcdccc444444444444f4445555d55d55555555
0000000000000000000000000000000000000dd00000000000000000000000004f444444fff44444e882e882000000004444444444544544555d5555555d555d
000000000000000000000000000000bb0000d0000000015000000000000000604ff4444ffff4444482e882e8000000004444544444444444d555d5555dd555d5
000040000000f000000005000000bb500000d00d00000500000000000000060044fffff44ff44444cdd1cdd10000000044464f4444454454d555555dd5555555
0a911dc00a9112e000005000000b3b0000ee5dd00001500000000000000c60004444f4444f444444d1cdd1cd0000000044f444f444444544d55555d555555555
091cc61909188e19000d400000b3b0000ee7e0000019dc000009009000d790004444f4444f44444400000000000000004544494454444444555d5555555d5555
091ccc100918881000640000003b000002ee200001dd00c000900a0002755000444ff4444f444444000000000000000044545444444444f45555d55555d55555
00dc1c0000281800005000000bd000000022500001d1000009a590000094000044ff44444fff44440000000000000000444444454444f444555d555d55555d55
000c0100000801000050000000d0000000d5000000d00000004040000040000044f4444444ff444400000000000000004444445444444544555555d5555555dd
afafafaf6566556500000000000000000000000000000000000000000000000051100000522000000000000000000000d33333333333333b0000000000000000
94949494d55d55d50000000000000000000200d00000000000000000000000005dd110005ee22000000000000000000033b3333b3b33b3330000000000000000
4f4f4f4f556555550009000000000000020ee6000000000000000000000000005ccdd110588ee2200000000000000000bb3333b3b33bd3330000000000000000
f464f464165551650a900000000000000087ae000000000000000000000000005ccccdd158888ee200000000000000003533a3333333333a0000000000000000
545454545d5555d57f990000303bb60002ea78200000001c0000a00a606709ff5ccdd110588ee2200000000000000000333333d3335333330000000000000000
464f464fd55455550a90000000000000006ee0000000000000000000000000005dd110005ee220000000000000000000333b3b33333393330000000000000000
454545455451d54d00000000000000000d0020000000000000000000000000005110000052200000000000000000000033bdb3333333333b0000000000000000
141414145555555500000000000000000000000000000000000000000000000050000000500000000000000000000000533333b3b3b333b30000000000000000
0000006c000000e800909a00000000000000000200000000000000000000000f5000000050000000000000000000000039333b3b3b5333350000000000000000
00000cc1000008820000489000000000060020000000000000000000000000f0500000005000000000000000000000003333b533333333330000000000000000
00006c100000e8200008009a0000060000ce8d00000000000000000000000900d0000000e000000000000000000000003333d335333d33330000000000000000
0006c100000e8200000008990000b00002ea7820000000000000000000000000d0000000e000000000000000000000003b333333335333330000000000000000
00cc100000882000000040a90003000000879e00000000000000000000070000d0000000e00000000000000000000000b3333b3b33333b330000000000000000
06c100000e8200000000089a0000000000d8e020000000000000000000600000d0000000e000000000000000000000003a33b3b33933b3bb0000000000000000
cc10000088200000000890a00300000000020060000000000000000000000000d0000000e0000000000000000000000033333533b3b333330000000000000000
c1000000820000000090a90000000000d0000000000000000000000060000000d0000000e00000000000000000000000b333333b3b3333d30000000000000000
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

