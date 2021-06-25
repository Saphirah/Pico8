pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
Game = { 
    time = 0,
    deltaTime = 0,
    player = nil,
    objects = {}, 
    sprites = {},
    enemyCount = 0
}

Screen = {
    --You need to start Pico8 with the following parameters to support multiple screens: -display_x 2 -displays_y 2
    count = {
        x = 1,
        y = 0
    },
    resolution = function()
        return {
            w = x * 128,
            h = y * 128
        }
    end,
    fov = 0.15,
    center = 64,
    ceilingColor = 6,
    floorColor = 13
}

Cache = {
    resolution = 0.1,
    rayUnitStepSize = {},
    forwardVector = {}
}

depth = {}


Textures = {
    [1] = {
        name = "Wall1",
        position = { x = 64, y = 64 },
        dimension = { w = 64, h = 64 }
    }, 
    [2] = {
        name = "Wall2",
        position = { x = 64, y = 0 },
        dimension = { w = 64, h = 64 }
    },
    [3] = {
        name = "Enemy",
        position = { x = 0, y = 0 },
        dimension = { w = 32, h = 32 },
        worldSize = { w = 50, h = 50 },
        worldOffset = { x = 0, y = -10 }
    },
    [4] = {
        name = "EnemyExplosion",
        position = { x = 32, y = 0 },
        dimension = { w = 32, h = 32 },
        worldSize = { w = 50, h = 50 },
        worldOffset = { x = 0, y = -10 }
    },
    [5] = {
        name = "EnemyPuddle",
        position = { x = 0, y = 32 },
        dimension = { w = 32, h = 8 },
        worldSize = { w = 50, h = 12.5 },
        worldOffset = { x = 0, y = 20 }
    },
    [6] = {
        name = "Projectile",
        position = { x = 0, y = 40 },
        dimension = { w = 28, h = 20 },
        worldSize = { w = 50, h = 40 },
        worldOffset = { x = 0, y = 0 }
    },
    [7] = {
        name = "Crosshair",
        position = { x = 0, y = 64 },
        dimension = { x = 16, y = 16 }
    },
    [8] = {
        name = "Heart",
        position = { x = 16, y = 64},
        dimension = { x = 16, y = 16 }
    }
}

Map = {
    width = 38,
    height = 12,
    texture = {
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2,
        1, 0, 0, 0, 1, 0, 0, 2, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 2,
        1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 2,
        1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 2,
        1, 0, 0, 0, 1, 0, 0, 2, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 2, 0, 0, 0, 0, 0, 1, 0, 0, 2,
        1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 2,
        1, 0, 0, 0, 1, 0, 0, 1, 1, 0, 0, 0, 1, 0, 2, 1, 1, 1, 1, 0, 0, 0, 0, 0, 2, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2,
        1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 2, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 2,
        1, 0, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 2, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 2, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 2,
        1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 2,
        1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 2,
        1, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1,


    }
}


C_Renderer_Line = {}
C_Renderer_Line.new = function(self, renderDistance)
    return{
        renderDistance = renderDistance or 100,
        draw = function(self,owner)
            local shakeStrength = 3
            depth = {}
            Screen.center =  64 + sin(time()) * shakeStrength + owner.transform.position.z + owner.cameraTilt.y
            rectfill(0,0, 128, Screen.center, Screen.ceilingColor)
            rectfill(0, Screen.center, 128, 128, Screen.floorColor)
            for i = -64, 64 do
                local rotation = mod(owner.transform.rotation + (i * Screen.fov * 3), 360)
                local rayPos = owner.transform.position
                local mapCheck = {x = flr(rayPos.x), y = flr(rayPos.y)}
                local distance = 0
                local texture = getMap(mapCheck.x, mapCheck.y)
                local rayDir = getForwardVector(rotation)
                
                --Checks if camera plane is rendering in wall
                if(texture == 0) then 
            
                    --Precalculation
                    --local rayUnitStepSize = { x = sqrt(1 + (rayDir.y / rayDir.x)^2), y = sqrt(1 + (rayDir.x / rayDir.y)^2)}
                    local rayUnitStepSize = Cache.rayUnitStepSize[ceil(mod(rotation,360)/Cache.resolution)]
                    local rayLength = {}
                    local step = {}
            
                    if(rayDir.x < 0) then
                        step.x = -1
                        rayLength.x = (rayPos.x - mapCheck.x) * rayUnitStepSize.x
                    else
                        step.x = 1
                        rayLength.x = (mapCheck.x + 1 - rayPos.x) * rayUnitStepSize.x
                    end
            
                    if(rayDir.y < 0) then
                        step.y = -1
                        rayLength.y = (rayPos.y - mapCheck.y) * rayUnitStepSize.y
                    else
                        step.y = 1
                        rayLength.y = (mapCheck.y + 1 - rayPos.y) * rayUnitStepSize.y
                    end
                    
                    --Raycasting steps
                    for i = 0, 25 do
                        if(rayLength.x < rayLength.y) then
                            mapCheck.x += step.x
                            distance = rayLength.x
                            rayLength.x += rayUnitStepSize.x
                        else
                            mapCheck.y += step.y
                            distance = rayLength.y
                            rayLength.y += rayUnitStepSize.y
                        end
                        
                        texture = Map.texture[mapCheck.y * Map.width + mapCheck.x]
                        if(texture != 0) then break end
                    end
                end
                local ray = {
                    distance = distance, 
                    mapCoordinates = mapCheck,
                    texture = texture or 1,
                    textureCoordinate = ((rayPos.x + rayDir.x * distance) + (rayPos.y + rayDir.y * distance)) % 1, 
                    rayPos = {x = rayPos.x + rayDir.x * distance, y = rayPos.y + rayDir.y * distance}
                }
                if(ray.texture != 0) then
                    local lineheight = flr(128 / ray.distance)
                    --Print to Screen
                    sspr(Textures[ray.texture].position.x + flr(ray.textureCoordinate * Textures[ray.texture].dimension.w), Textures[ray.texture].position.y, 1, Textures[ray.texture].dimension.h, 64+i, Screen.center-lineheight + i * owner.cameraTilt.x, 1, lineheight*2)
                end
                --Store depth data for sprite rendering
                add(depth, ray.distance)
            end 
            
        end
    }
end

C_PlayerController = {}
C_PlayerController.new = function(self, rotationSpeed)
    --Activate Mouse Lock
    poke(0x5f2d,0x5)
    return {
        rotationSpeed = rotationSpeed,
        update = function(self, owner)            
            owner.velocity.x /= 1.5
            owner.velocity.y /= 1.5
            owner.angularVelocity /= 1.2
            local forward = getForwardVector(owner.transform.rotation)
            local right = getForwardVector(owner.transform.rotation + 90 )
            --Rotation
            --OLD: Rotation using arrow keys
            if(btn(0,0)) then owner.transform.rotation-=self.rotationSpeed end
            if(btn(1,0)) then owner.transform.rotation+=self.rotationSpeed end
            owner.angularVelocity += stat(38) * (rotationSpeed / 50)
            owner.transform.rotation = mod(owner.transform.rotation + owner.angularVelocity,360)
            owner.cameraTilt.x = lerp(owner.cameraTilt.x, 0, Game.deltaTime * 4)
            owner.cameraTilt.y = lerp(owner.cameraTilt.y, 0, Game.deltaTime * 4)

            if(owner.transform.position.z > 0) then 
                owner.velocity.z -= 0.1
            elseif(owner.velocity.z != 0) then
                owner.velocity.z = 0
            end

            if(btn(1,1)) then
                owner.velocity.x += right.x * owner.movementSpeed * Game.deltaTime
                owner.velocity.y += right.y * owner.movementSpeed * Game.deltaTime
                owner.cameraTilt.x = lerp(owner.cameraTilt.x, -0.05 * owner.movementSpeed, Game.deltaTime * 4)
            end
            if(btn(0,1)) then 
                owner.velocity.x -= right.x * owner.movementSpeed * Game.deltaTime
                owner.velocity.y -= right.y * owner.movementSpeed * Game.deltaTime
                owner.cameraTilt.x = lerp(owner.cameraTilt.x, 0.05 * owner.movementSpeed, Game.deltaTime * 4)
            end

            if(btn(4,1) and owner.transform.position.z == 0) then
                owner.velocity.z = 2
            end

            --Movement with collision checks
            if(btn(2,1)) then 
                owner.velocity.x += forward.x * owner.movementSpeed * Game.deltaTime
                owner.velocity.y += forward.y * owner.movementSpeed * Game.deltaTime
                owner.cameraTilt.y = lerp(owner.cameraTilt.y, -10 * owner.movementSpeed, Game.deltaTime * 4)
            end
            if(btn(3,1)) then 
                owner.velocity.x -= forward.x * owner.movementSpeed * Game.deltaTime
                owner.velocity.y -= forward.y * owner.movementSpeed * Game.deltaTime
                owner.cameraTilt.y = lerp(owner.cameraTilt.y, 10 * owner.movementSpeed, Game.deltaTime * 4)
            end

            if(getMap( owner.transform.position.x + owner.velocity.x, owner.transform.position.y ) == 0) then 
                owner.transform.position.x += owner.velocity.x
            end
            if(getMap( owner.transform.position.x, owner.transform.position.y + owner.velocity.y ) == 0) then 
                owner.transform.position.y += owner.velocity.y
            end

            owner.transform.position.z = max(owner.transform.position.z + owner.velocity.z, 0)
            Screen.fov = 0.1 + sqrt(owner.velocity.x * owner.velocity.x + owner.velocity.y * owner.velocity.y) / 20
        end
    }
end

C_SpriteRenderer = {}
C_SpriteRenderer.new = function(self, spriteIndex)
    return {
        spriteIndex = spriteIndex,
        spriteAngle = 0,
        distance = 0,
        draw = function(self, owner)
            --Calculate angle and distance
            if(owner.distanceToPlayer<15) then
                local relativePos = { x = owner.transform.position.x - Game.player.transform.position.x, y = owner.transform.position.y - Game.player.transform.position.y }
                self.spriteAngle = mod(atan2(relativePos.y, relativePos.x) * 360 - Game.player.transform.rotation,360)
                --Align to center of the screen
                if self.spriteAngle > 180 then self.spriteAngle -= 360 end
                --Render Sprite when in View
                if(self.spriteAngle <= 400*Screen.fov and self.spriteAngle >=-400*Screen.fov) then
                    --Calculate Sprite Scale
                    
                    --Cheap average distance
                    local size = 5 / owner.distanceToPlayer
                    local halfSize = flr(size * Textures[self.spriteIndex].worldSize.w / 2)
                    --Occlusion Check
                    local screenPosXLeft = flr(64 + self.spriteAngle * 3.6 * (0.1 / Screen.fov) -halfSize)
                    local screenPosXRight = flr(64 + self.spriteAngle * 3.6 * (0.1 / Screen.fov) + halfSize)
                    local leftIndex = min(max(screenPosXLeft,1),128)
                    local rightIndex = max(min(screenPosXRight, 128),1)
                    if(owner.distanceToPlayer > depth[leftIndex] and owner.distanceToPlayer > depth[rightIndex] and owner.distanceToPlayer > depth[flr((rightIndex + leftIndex) / 2)]) then
                        --print("Don't render")
                    elseif(owner.distanceToPlayer > depth[leftIndex] or owner.distanceToPlayer > depth[rightIndex]) then
                        --print("Occluded render")
                        local screenPosY = Screen.center - Textures[self.spriteIndex].worldSize.h * 0.25 + Textures[self.spriteIndex].worldOffset.y * size + Game.player.transform.position.z / 20 + Game.player.cameraTilt.y/20 + ((screenPosXLeft + screenPosXRight) / 2 -64) * Game.player.cameraTilt.x
                        for x = -halfSize, halfSize do 
                            local screenPosX = flr(64 + self.spriteAngle * 3.6 + x)
                            if(screenPosX >= 0 and screenPosX <= 128) then
                                if(owner.distanceToPlayer < depth[screenPosX+1]) then
                                    sspr(
                                        Textures[self.spriteIndex].position.x + Textures[self.spriteIndex].dimension.w * (x + halfSize) / (halfSize * 2), Textures[self.spriteIndex].position.y, 
                                        1, Textures[self.spriteIndex].dimension.h, 
                                        screenPosX, screenPosY, 
                                        1, size *  Textures[self.spriteIndex].worldSize.h
                                    )
                                end
                            end
                        end
                    else
                        --print("Fast render")
                        local screenPosY = Screen.center - Textures[self.spriteIndex].worldSize.h * 0.25 + Textures[self.spriteIndex].worldOffset.y * size + Game.player.transform.position.z / 20 + Game.player.cameraTilt.y/20 + ((screenPosXLeft + screenPosXRight) / 2 -64) * Game.player.cameraTilt.x
                        sspr(
                            Textures[self.spriteIndex].position.x, Textures[self.spriteIndex].position.y, 
                            Textures[self.spriteIndex].dimension.w, Textures[self.spriteIndex].dimension.h, 
                            screenPosXLeft, screenPosY, 
                            screenPosXRight - screenPosXLeft, size *  Textures[self.spriteIndex].worldSize.h
                        )
                    end
                end
            end
        end
    }
end 

C_Ability_Dash = {}
C_Ability_Dash.new = function(self, movementSpeed)
    
    return{
        lastExecution = -4,
        cooldown = 0.5,
        maxSpeed = movementSpeed,
        holdButton = false,
        update = function(self, owner)
            
            if not self.holdButton and btn(5,1) and time() - self.lastExecution >= self.cooldown then
                owner.movementSpeed = self.maxSpeed * 5
                self.lastExecution = time()
                sfx(7)
            end
            self.holdButton = btn(5,1)
            owner.movementSpeed = lerp(owner.movementSpeed, self.maxSpeed, Game.deltaTime * 5)
        end
    }
end

C_PlayerDead = {}
C_PlayerDead.new = function(self)
    Game.objects = {}
    return {
        deadTimer = 1,
        update = function(self, owner)
            owner.cameraTilt.x += (1 - self.deadTimer)/100
            Screen.fov -= 0.001
            self.deadTimer -= Game.deltaTime
            if(self.deadTimer <= 0) then Game.player.renderComponents = {} end
            if(self.deadTimer <= -2) then run() end
        end
    }
end

C_EnemyDead = {}
C_EnemyDead.new = function(self)
    return {
        deadTimer = 1,
        update = function(self, owner)
            self.deadTimer -= Game.deltaTime
            if(self.deadTimer <= 0) then 
                owner.renderComponents[1].spriteIndex = 5 
                owner.components = {}
            end
        end
    }
end

C_Bouncer = {}
C_Bouncer.new = function(self)
    return{
        enemyShot = true,
        update = function(self, owner)
            if(owner.distanceToPlayer<=1) then
                if(sqrt(Game.player.velocity.x*Game.player.velocity.x+Game.player.velocity.y*Game.player.velocity.y)>=0.1) then
                    owner.velocity.x = Game.player.velocity.x * 1.5
                    owner.velocity.y = Game.player.velocity.y * 1.5
                    self.enemyShot = false
                    sfx(8)
                elseif(self.enemyShot) then
                    Game.player:applyDamage(1)
                    owner:destroy()
                end
            end
            if(not self.enemyShot) then
                foreach(Game.objects, function(obj) 
                    if(obj != owner and obj.health != nil) then
                        local relativePos = { x = obj.transform.position.x - owner.transform.position.x, y = obj.transform.position.y - owner.transform.position.y }
                        if(sqrt(relativePos.x * relativePos.x + relativePos.y * relativePos.y) <= 0.3) then
                            obj:applyDamage(1)
                            owner:destroy()
                        end
                    end
                end)
            end

            owner.velocity.x *= 0.99
            owner.velocity.y *= 0.99

            if(Map.texture[flr(owner.transform.position.y) * Map.width + flr((owner.transform.position.x + owner.velocity.x))]>0) then
                owner.velocity.x *= -1
                sfx(9)
            end

            if(Map.texture[flr((owner.transform.position.y + owner.velocity.y)) * Map.width + flr(owner.transform.position.x)]>0) then
                owner.velocity.y *= -1
                sfx(9)
            end

            if(abs(owner.velocity.x)+abs(owner.velocity.y) < 0.005) then
                owner:destroy()
            end

            owner.transform.position.x += owner.velocity.x
            owner.transform.position.y += owner.velocity.y
            
        end
    }
end

C_HeartRenderer = {}
C_HeartRenderer.new = function(self)
    return {
        draw = function(self, owner)
            for x = 1, owner.health do
                sspr(
                    Textures[8].position.x, Textures[8].position.y,
                    Textures[8].dimension.x, Textures[8].dimension.y,
                    Textures[8].dimension.x * (x-1) + 3, 3,
                    10, 10
                )
            end
        end
    }
end

C_ProjectileShooter = {}
C_ProjectileShooter.new = function(self)
    return{
        timer = rnd(5)+2,
        update = function(self, owner)
            self.timer -= Game.deltaTime
            if(self.timer <= 0) then
                self.timer = 1 + rnd(2)
                local rayPos = owner.transform.position
                local mapCheck = {x = flr(rayPos.x), y = flr(rayPos.y)}
                local distance = 0
                local texture = getMap(mapCheck.x, mapCheck.y)
                local rayDir = { x = Game.player.transform.position.x - owner.transform.position.x, y = Game.player.transform.position.y - owner.transform.position.y }
                local rotation = acos(rayDir.y / sqrt(rayDir.x * rayDir.x + rayDir.y * rayDir.y)) * 360
                self.rotation = rotation                
                --Checks if camera plane is rendering in wall
                if(texture == 0) then 
            
                    --Precalculation
                    --local rayUnitStepSize = { x = sqrt(1 + (rayDir.y / rayDir.x)^2), y = sqrt(1 + (rayDir.x / rayDir.y)^2)}
                    local rayUnitStepSize = Cache.rayUnitStepSize[ceil(mod(rotation,360)/Cache.resolution)]
                    local rayLength = {}
                    local step = {}
            
                    if(rayDir.x < 0) then
                        step.x = -1
                        rayLength.x = (rayPos.x - mapCheck.x) * rayUnitStepSize.x
                    else
                        step.x = 1
                        rayLength.x = (mapCheck.x + 1 - rayPos.x) * rayUnitStepSize.x
                    end
            
                    if(rayDir.y < 0) then
                        step.y = -1
                        rayLength.y = (rayPos.y - mapCheck.y) * rayUnitStepSize.y
                    else
                        step.y = 1
                        rayLength.y = (mapCheck.y + 1 - rayPos.y) * rayUnitStepSize.y
                    end
                    
                    --Raycasting steps
                    for i = 0, 25 do
                        if(rayLength.x < rayLength.y) then
                            mapCheck.x += step.x
                            distance = rayLength.x
                            rayLength.x += rayUnitStepSize.x
                        else
                            mapCheck.y += step.y
                            distance = rayLength.y
                            rayLength.y += rayUnitStepSize.y
                        end
                        
                        texture = Map.texture[mapCheck.y * Map.width + mapCheck.x]
                        if(texture != 0) then break end
                    end
                end

                if(distance > owner.distanceToPlayer) then
                    local e = Ball:new(owner.transform.position.x, owner.transform.position.y)
                    local rand = 1 + rnd(2)
                    e.velocity = { x = rayDir.x / 100 * rand, y = rayDir.y / 100 * rand }
                end
            end
        end
    }
end

Entity = {}
Entity.new = function(self, x, y)
    local me = {
        transform = { 
            position = { x = x, y = y }, 
            rotation = 1, 
            scale = 1
        },
        velocity = { x = 0, y = 0, z = 0},
        components = {},
        renderComponents = {},
        distanceToPlayer = 9999,
        health = 1,
        draw = function(self)
            foreach(self.renderComponents, function(obj) obj:draw(self) end)
        end,
        update = function(self)
            foreach(self.components, function(obj) obj:update(self) end)
            local relativePos = { x = self.transform.position.x - Game.player.transform.position.x, y = self.transform.position.y - Game.player.transform.position.y }
            self.distanceToPlayer = sqrt(relativePos.x * relativePos.x + relativePos.y * relativePos.y)
        end,
        applyDamage = function(self, amount)
            self.health -= amount
            if(self.health<=0) then self:destroy() end
        end,
        destroy = function(self)
            del(Game.objects, self)
        end
    }
    return me
end

Sprite = {}
Sprite.new = function(self, x, y, spriteIndex)
    local me = Entity:new(x,y)

    add(me.renderComponents, C_SpriteRenderer:new(spriteIndex))

    printh("Created Sprite at G:(" .. x .. "/" .. y .. "), I:" .. getMapIndex(x,y))
    add(Game.objects, me)
    return me
end

Ball = {}
Ball.new = function(self, x, y)
    local me = Sprite:new(x, y, 6)
    add(me.components, C_Bouncer:new())
    sfx(8)
    return me
end

Enemy = {}
Enemy.new = function(self, x, y)
    local me = Sprite:new(x, y, 3)
    add(me.components, C_ProjectileShooter:new())
    Game.enemyCount += 1
    me.destroy = function(self)
        self.health = nil
        self.renderComponents[1].spriteIndex = 4
        self.components = {}
        add(me.components, C_EnemyDead:new())
        Game.enemyCount -= 1
        if(Game.enemyCount <= 0) then
            load("Credits")
            run()
        end
    end
    return me
end

Player = {}
Player.new = function (self, x, y)
    local me = Entity:new(x, y)
    me.transform.position.z = 0
    me.angularVelocity = 0
    me.movementSpeed = 1
    me.cameraTilt = { x = 0, y = 0 }
    me.health = 3
    me.destroy = function(self)
        self.components = {}
        add(self.components, C_PlayerDead:new())
    end
    add(me.components, C_PlayerController:new(2))
    add(me.components, C_Ability_Dash:new(me.movementSpeed))
    add(me.renderComponents, C_Renderer_Line:new(100))
    add(me.renderComponents, C_HeartRenderer:new())
    return me
end

function lerp(a, b, f)
    return a + f * (b-a)
end

function getForwardVector(rotation)
    return Cache.forwardVector[ceil(mod(rotation,360)/0.1)]
end

function getMapIndex(x,y)
    return y * Map.width + x
end

--Gets a point on the map in local coordinates
function getMap(x,y)
    return Map.texture[flr(y) * Map.width + flr(x)]
end

--The % operator behaves weirdly in negative area. This function is like a regular modulo
function mod(x, m)
    while x < 0 do
        x += m
    end
    return x%m
end

function acos(x)
    return atan2(x,-sqrt(1-x*x))
end

function printList(list)
    returnStr = "{"
    for key, obj in pairs(list) do
        returnStr = returnStr .. " " .. key .. " = "
        if(type(obj) == "table") then
            returnStr = returnStr .. printList(obj) .. ", "
        else
            returnStr = returnStr .. tostr(obj) .. ", "
        end
    end
    if(#returnStr > 1) then returnStr = sub(returnStr, 1, #returnStr - 2) .. " " end
    return returnStr .. "}"
end

function quickSort(array, p, r)
    p = p or 1
    r = r or #array
    if p < r then
        q = partition(array, p, r)
        quickSort(array, p, q - 1)
        quickSort(array, q + 1, r)
    end
end

function partition(array, p, r)
    local x = array[r]
    local i = p - 1
    for j = p, r - 1 do
        if array[j].distanceToPlayer > x.distanceToPlayer then
            i = i + 1
            local temp = array[i]
            array[i] = array[j]
            array[j] = temp
        end
    end
    local temp = array[i + 1]
    array[i + 1] = array[r]
    array[r] = temp
    return i + 1
end


function _init()
    --Spawn Player
    Game.player = Player:new(3, 3)
    Enemy:new(3,10)
    Enemy:new(6.5,3)
    Enemy:new(11,3)
    Enemy:new(11.5,9)
    Enemy:new(14.5,8.5)
    Enemy:new(17.5,10)
    Enemy:new(14.5,3)
    Enemy:new(22,10)
    Enemy:new(22,2.5)
    Enemy:new(23,6)
    Enemy:new(27,9.5)
    Enemy:new(31,3)
    Enemy:new(36,3)
    Enemy:new(35,9)
    Enemy:new(32,10.5)


    music(0)
    --Create direction cache
    for x = 0, 360/Cache.resolution do
        local rayDir = {x = sin(x*Cache.resolution/360), y = cos(x*Cache.resolution/360)}
        add(Cache.forwardVector, {x = sin(x*Cache.resolution/360), y = cos(x*Cache.resolution/360)})
        add(Cache.rayUnitStepSize, { x = abs(1/rayDir.x), y = abs(1/rayDir.y)})
    end
end

function _update60()
    cls()
    Game.deltaTime = time() - Game.time
    Game.time = time()
    if(Game.player != nil) then Game.player:update(Game.player) end
    foreach(Game.objects, function(obj) obj:update(self) end)
end

--poke(0x5f36,1) -- to enable. **secret!**
function _draw()
    --di = stat(3)
    if(Game.player != nil) then Game.player:draw(Game.player) end
    quickSort(Game.objects, 1, #Game.objects)
	foreach(Game.objects, function(obj) obj:draw(self) end)
    --print("Memory: " .. stat(0))
    --print("CPU: " .. stat(1))
    --print("FPS: " .. stat(7))
    --print("PlayerSpeed: "..sqrt(Game.player.velocity.x*Game.player.velocity.x+Game.player.velocity.y*Game.player.velocity.y))
    --return di<2 --true means "give me another display to draw to
    sspr(Textures[7].position.x, Textures[7].position.y, Textures[7].dimension.x, Textures[7].dimension.y, 56, 56, 16, 16)
end


--_camera = camera --save original camera function reference
--function camera(x,y)
--	x = x or 0
--	y = y or 0
--	local dx = flr(stat(3) % Screen.count.x)
--	local dy = flr(stat(3) / Screen.count.x)
--	_camera(x+128*dx, y+128*dy)
--end




__gfx__
00000000000009b33b4492200000000000000200000000000000000020000000c6c6c898989998997999999999999999999799999999999799998999898cc66c
0000000002a9853bbb7bb3998000000000000000050000020000000200000000cccfc7a77aaa7aaaaaa7aaaaaa7aaa7aaaaaaaa7aaa77aaaaa7a7aaaa77cccc6
0000000083bbbbbbb7bb7bbb39200000000000200007000200b0002000000200cccdcfaaaaaaaaaaaaa7aaaaaaaaaaaaaaaaaa7aaaaaaaaaaaaaaaaaafacdccc
00000023bbbbb7ba76c77777bbb30000b00000020000000e0000002000002000cdcdcaaaaafaaaaaaa7aaaaaaaaaaaaaaaaa77aaaaaaaaaaa7aaafaaaaacddcc
000009bbb0bb2b7b37b55cc67bbb200000000002700b00200000020000e20000ccccc899989999997999999999999999997999999999999799999989989ccccc
00022bb0bb23320503c335abb7bbb2000000a00e2000002000000b070e200002da9f9111111111111111111111111111111111111111111111111111111f45ad
00092bbb0003303030000335c67bb30000000000200000e00000000000000220c967d111111111111111111111111111111111111111111111111111111a94cd
0029bb3300000000000330035bb7bb20000e0300bb73b0000000000000302e00dd6a9111111111111111111111111111111111111111111111111111111955dd
0092bb3120b000c0000000003cabbb50020000b07b030000030e0b300b000000dc97a111111111111111111111111111111111111111111111111111111d95dd
029bcb00000000000000b000335b7be000208000000300003300b07bb700b000dd97c111111111111111111111111111111111111111111111111111111d45cd
022bb0b0000000000002000073cbbbb200000300000300000000000000000000d9679111111111111111111111111111111111111111111111111111111955dd
09ebb770b088000000b007003b35b7b200000000300000000000000000000000dd67d111111111111111111111111111111111111111111111111111111d95d9
29bb0700002e800000000000033bbbb5050b0700000000000000000330e00050d9676111111111111111111111111111111111111111111111111111111955dd
23bb77000008e0000c0000000030bbb300003330700000000e00003300830000dd676111111111111111111111111111111111111111111111111111111645dd
2eb9760000002000000000002030b7ae0b0000e30e00000000000030e0000000dd6791111111111111111111111111111111111111111111111111111119d5dd
233b70000000000000000b000070cbb300000000000000000000a000b0000000dd67d111111111111111111111111111111111111111111111111111111d556d
53bb000000000a000070000288000bb3002e373ba00000000000002222220202dd676111111111111111111111111111111111111111111111111111111d55d6
233bb000000000000000002e8200b0b50000e080b00000000000000000e00b00dd679111111111111111111111111111111111111111111111111111111d95dd
e34b300900000000000008e8a000bbbe0b00000b0000000300000000000000006d676111111111111111111111111111111111111111111111111111111d55dd
5333222000b00000000002a000000bb50000a000000000000000000030e00000d667d111111111111111111111111111111111111111111111111111111d45dd
233928e200000000e00b0000070bbbb200000003000000000000000000b00070d5779111111111111111111111111111111111111111111111111111111955dd
2343328240000000000000c00002bbe00000e000000030000000000000000000ddd76111111111111111111111111111111111111111111111111111111d55dd
2539b320b000100000000000033bbb20000be000000000000003e00003000000dd67d111111111111111111111111111111111111111111111111111111d55dd
0e333b490000000000000010b33bb2c00220000e030000000000000a00070000dd676111111111111111111111111111111111111111111111111111111955dd
0253933b2b009000000000000bbbec000000300000000000e0000b00bb223000dd676111111111111111111111111111111111111111111111111111111655dd
01e33943b1900000007000b0b0bb2c00000030500000300000000000b0002000dd67d111111111111111111111111111111111111111111111111111111555dd
0025339b33bb02090000000bbbbbc000000000e0e0000000000ee2003e000200dd679111111111111111111111111111111111111111111111111111111d55dd
000c23393b3bb0b0000000b0bbb21000b0000203000000000000002000000000dd676111111111111111111111111111111111111111111111111111111d556d
0000c25334933b33b3b03bbbbb3c0000000320000bb00300bb00070000805000dd67611111111111111111111111111111111111111111111111111111165556
00000c253333433b333bbbbbb2c0000000002000bb0003200b00000320000000dd676111111111111111111111111111111111111111111111111111111d55dd
00000012e333339349334bb2c00000000000b000000703200070000000000000dd67d111111111111111111111111111111111111111111111111111111d55dd
000000001225e2e233323e200000000000000000000003000000000000200000dd676111111111111111111111111111111111111111111111111111111d55dd
0000000000000000000000000000000050000000000000000000000000000000dd67d111111111111111111111111111111111111111111111111111111d55dd
000000000009b000009bb0000000000000000000000000000000000000000000dd676111111111111111111111111111111111111111111111111111111955dd
0000000000a33b0000333b000000000000000000000000000000000000000100dd676111111111111111111111111111111111111111111111111111111655dd
0000020009333b0b03b63b000000000000020000000000000000000000000000dd676111111111111111111111111111111111111111111111111111111d55dd
00024323b3322b3342334b39b200000000000000000000000000000000010000dd676111111111111111111111111111111111111111111111111111111d65dd
0004bbb332bbb23cb723bbb43b34b00000000000000000000000000000d00000dd676111111111111111111111111111111111111111111111111111111d55dd
002b6bbb4bbb532bbbb43b4356233b0000000020000000000000000006000000dd676111111111111111111111111111111111111111111111111111111d5ddd
336533555566353336335336335b333500000000000000000000000000000000dd676111111111111111111111111111111111111111111111111111111d556d
0000000000000000000000000000000000000000e00000000000000000000000dd676111111111111111111111111111111111111111111111111111111d55d6
00000000000000000000000000000000000000000600000000000060000000006d676111111111111111111111111111111111111111111111111111111655dd
0000000000000000000000000000000000000000000000000000000000000000d6676111111111111111111111111111111111111111111111111111111655dd
0000000000000000000000000000000000000000000800000000d00000000000dd67d111111111111111111111111111111111111111111111111111111655dd
00000000000000000000000000000000000000000000e000000c000000000000dd56d111111111111111111111111111111111111111111111111111111d55dd
00000000000000000000000000000000000000000000060000c0000000000000dd67d111111111111111111111111111111111111111111111111111111d55dd
0000000000000018100000000000000000000000000000700700000000000000dd676111111111111111111111111111111111111111111111111111111d55dd
000000000000128c18e000000000000000000000000000000000000000000000dd675111111111111111111111111111111111111111111111111111111655dd
0000000000088ece2e7200000000000000000000000000000000000000000000dd676111111111111111111111111111111111111111111111111111111655dd
000000000082e8ece6e220000000000000000000000000700700000000000000dd676111111111111111111111111111111111111111111111111111111dd5dd
00000008002e8cd6ee2b2100800000000000000000000c000060000000000000dd67d111111111111111111111111111111111111111111111111111111d5dcd
00080e000782ed776787e10e00008000000000000000c000000e000000000000dd676111111111111111111111111111111111111111111111111111111d55dc
0000000008ebe677dc8e21000000000000000000000d000000000000000000006d676111111111111111111111111111111111111111111111111111111655dd
00000000028caeede82e80000000000000000000006000000000080000000000dd67d111111111111111111111111111111111111111111111111111111d55dd
00000000008e6e2eb2e810000000000000000000000000000000007000000000dd676111111111111111111111111111111111111111111111111111111d55d6
00000000000ce8c2282100000000000000000000d00000000000000e00000000cd67c1111111111111111111111111111111111111111111111111111116c5dd
00000000000088282210000000000000000000000000000000000000000000006c67d111111111111111111111111111111111111111111111111111111d55dd
00000000000002211100000000000000000000d0000000000000000002000000dd67c111111111111111111111111111111111111111111111111111111c5cdc
0000000000000000000000000000000000000000000000000000000000000000cd67d111111111111111111111111111111111111111111111111111111d55dd
00000000000000000000000000000000000000000000000000000000000200006cccc111111111111111111111111111111111111111111111111111111c666c
0000000000000000000000000000000000000000000000000000000000000000ccccc111111111111111111111111111111111111111111111111111111ccccc
0000000000000000000000000000000000d00000000000000000000000000000cccdc111111111111111111111111111111111111111111111111111111cdccc
0000000000000000000000000000000001000000000000000000000000000050ccdcc111111111111111111111111111111111111111111111111111111cddcc
0000000000000000000000000000000000000000000000000000000000000000ccccc111111111111111111111111111111111111111111111111111111ccccc
0000000000000000000000000000000000000000000000000000000000000000c6c6c999999999997999999999999999999799999999999799999999999cc66c
0000000000000000001111100111110000000000000000000000000000000000cccfc747744474444447444444744474444444474447744444747444477cccc6
0000000000000000011dc51111dc511000000000000000000000000000000000cccdcf444444444444474444444444444444447444444444444444444f4cdccc
0000000000000000116ccc5116ccc51100000000000000000000000000000000cdcdc44444f444444474444444444444444477444444444447444f44444cddcc
00000000000000001dccccc5dccccc5100000000000000000000000000000000ccccc899989999997999999999999999997999999999999799999989989ccccc
00000200006000001cccccccccccccc100000000000000000000000000000000dd66d111111111111111111111111111111111111111111111111111111d55dd
000000e00c0000001cccccccccccccc100000000000000000000000000000000cd67d111111111111111111111111111111111111111111111111111111c55cd
00000000000000001cccccccccccccc100000000000000000000000000000000dd66d111111111111111111111111111111111111111111111111111111d55dd
000000000000000016cccccccccccc6100000000000000000000000000000000dc67d111111111111111111111111111111111111111111111111111111dc5dd
000000c00e0000001d6ccccccccccc5100000000000000000000000000000000dd67c111111111111111111111111111111111111111111111111111111d55cd
000006000020000011d6ccccccccc51100000000000000000000000000000000dd67d111111111111111111111111111111111111111111111111111111d55dd
0000000000000000011d7ccccccc511000000000000000000000000000000000dd67d111111111111111111111111111111111111111111111111111111d55dd
00000000000000000011d7ccccc5110000000000000000000000000000000000dd676111111111111111111111111111111111111111111111111111111d55dd
000000000000000000011d6ccc51100000000000000000000000000000000000dd676111111111111111111111111111111111111111111111111111111d55dd
0000000000000000000011dcc511000000000000000000000000000000000000dd67d111111111111111111111111111111111111111111111111111111d55dd
0000000000000000000001111110000000000000000000000000000000000000dd67d111111111111111111111111111111111111111111111111111111d556d
0000000000000000000000000000000000000000000000000000000000000000dd676111111111111111111111111111111111111111111111111111111d55d6
0000000000000000000000000000000000000000000000000000000000000000dd67d111111111111111111111111111111111111111111111111111111d55dd
00000000000000000000000000000000000000000000000000000000000000006d676111111111111111111111111111111111111111111111111111111d55dd
0000000000000000000000000000000000000000000000000000000000000000d667d111111111111111111111111111111111111111111111111111111d55dd
0000000000000000000000000000000000000000000000000000000000000000d577d111111111111111111111111111111111111111111111111111111d55dd
0000000000000000000000000000000000000000000000000000000000000000ddd76111111111111111111111111111111111111111111111111111111d55dd
0000000000000000000000000000000000000000000000000000000000000000dd67d111111111111111111111111111111111111111111111111111111d55dd
0000000000000000000000000000000000000000000000000000000000000000dd676111111111111111111111111111111111111111111111111111111d55dd
0000000000000000000000000000000000000000000000000000000000000000dd676111111111111111111111111111111111111111111111111111111655dd
0000000000000000000000000000000000000000000000000000000000000000dd67d111111111111111111111111111111111111111111111111111111555dd
0000000000000000000000000000000000000000000000000000000000000000dd67d111111111111111111111111111111111111111111111111111111d55dd
0000000000000000000000000000000000000000000000000000000000000000dd676111111111111111111111111111111111111111111111111111111d556d
0000000000000000000000000000000000000000000000000000000000000000dd67611111111111111111111111111111111111111111111111111111165556
0000000000000000000000000000000000000000000000000000000000000000dd676111111111111111111111111111111111111111111111111111111d55dd
0000000000000000000000000000000000000000000000000000000000000000dd67d111111111111111111111111111111111111111111111111111111d55dd
0000000000000000000000000000000000000000000000000000000000000000dd676111111111111111111111111111111111111111111111111111111d55dd
0000000000000000000000000000000000000000000000000000000000000000dd67d111111111111111111111111111111111111111111111111111111d55dd
0000000000000000000000000000000000000000000000000000000000000000dd676111111111111111111111111111111111111111111111111111111d55dd
0000000000000000000000000000000000000000000000000000000000000000dd676111111111111111111111111111111111111111111111111111111655dd
0000000000000000000000000000000000000000000000000000000000000000dd676111111111111111111111111111111111111111111111111111111d55dd
0000000000000000000000000000000000000000000000000000000000000000dd676111111111111111111111111111111111111111111111111111111d65dd
0000000000000000000000000000000000000000000000000000000000000000dd676111111111111111111111111111111111111111111111111111111d55dd
0000000000000000000000000000000000000000000000000000000000000000dd676111111111111111111111111111111111111111111111111111111d5ddd
0000000000000000000000000000000000000000000000000000000000000000dd676111111111111111111111111111111111111111111111111111111d556d
0000000000000000000000000000000000000000000000000000000000000000dd676111111111111111111111111111111111111111111111111111111d55d6
00000000000000000000000000000000000000000000000000000000000000006d676111111111111111111111111111111111111111111111111111111655dd
0000000000000000000000000000000000000000000000000000000000000000d6676111111111111111111111111111111111111111111111111111111655dd
0000000000000000000000000000000000000000000000000000000000000000dd67d111111111111111111111111111111111111111111111111111111655dd
0000000000000000000000000000000000000000000000000000000000000000dd56d111111111111111111111111111111111111111111111111111111d55dd
0000000000000000000000000000000000000000000000000000000000000000dd67d111111111111111111111111111111111111111111111111111111d55dd
0000000000000000000000000000000000000000000000000000000000000000dd676111111111111111111111111111111111111111111111111111111d55dd
0000000000000000000000000000000000000000000000000000000000000000dd675111111111111111111111111111111111111111111111111111111655dd
0000000000000000000000000000000000000000000000000000000000000000dd676111111111111111111111111111111111111111111111111111111655dd
0000000000000000000000000000000000000000000000000000000000000000dd676111111111111111111111111111111111111111111111111111111dd5dd
0000000000000000000000000000000000000000000000000000000000000000dd67d111111111111111111111111111111111111111111111111111111d5dcd
0000000000000000000000000000000000000000000000000000000000000000dd676111111111111111111111111111111111111111111111111111111d55dc
00000000000000000000000000000000000000000000000000000000000000006d676111111111111111111111111111111111111111111111111111111655dd
0000000000000000000000000000000000000000000000000000000000000000dd67d111111111111111111111111111111111111111111111111111111d55dd
0000000000000000000000000000000000000000000000000000000000000000dd676111111111111111111111111111111111111111111111111111111d55d6
0000000000000000000000000000000000000000000000000000000000000000cd67c1111111111111111111111111111111111111111111111111111116c5dd
00000000000000000000000000000000000000000000000000000000000000006c67d111111111111111111111111111111111111111111111111111111d55dd
0000000000000000000000000000000000000000000000000000000000000000dd67c111111111111111111111111111111111111111111111111111111c5cdc
0000000000000000000000000000000000000000000000000000000000000000cd67d111111111111111111111111111111111111111111111111111111d55dd
00000000000000000000000000000000000000000000000000000000000000006cccc111111111111111111111111111111111111111111111111111111c666c
0000000000000000000000000000000000000000000000000000000000000000ccccc111111111111111111111111111111111111111111111111111111ccccc
0000000000000000000000000000000000000000000000000000000000000000cccdc111111111111111111111111111111111111111111111111111111cdccc
0000000000000000000000000000000000000000000000000000000000000000ccdcc111111111111111111111111111111111111111111111111111111cddcc
0000000000000000000000000000000000000000000000000000000000000000ccccc111111111111111111111111111111111111111111111111111111ccccc
__sfx__
301000200b4300b410006000b450006001a100267001960025700186001441014410104100e4100e4101f100004200c4101a1000c420186001b100267001860002420024100b43021700176000c4302050017500
301000000b4300b4101c1100b450196001a140267201960025750186002872026750196000c4101533015320267400c4101a1100c420186001b12026720186001b130186000b43026710176001f1202674026730
301000000b4300b4101c1100b450131101a1401001010010104101a12007010070200a0200c4101533015320090100c4100c3300c420090100c320090100901018120181100b4100701017110171200701007020
b61000002313023110231202311000000000000000000000000000000000000000002313023110231202311024130241202413024110128001580017800000001f1301f1101f1201f1100c310113201533018340
8e1000003c610376001b6201b610326502f6101b60032640396103263007620016203265032610316003060037610376001b6201b610326502f6101b600326403961032630076200162032650326202b61036620
96100000174101742017440174401441014420144301443013410134201344013430124101242012430124400b4000b4100b4200b4100b4000b4100b4200b4100b4000b4100b4200b4100b4100e4301144013450
0001000009070060600133000070000700006005540055300553007520095200a5200b5200c5300f53010530105200250002500025000250002500025000250002500015000150000500005000e0000e0000d000
000200000f6102d620376303a6203c6203961034610306102b61034330236101e6101a61016610126100d6101d3200361000610276001b5002610019600000000d60000600056000000000000000000000000000
000300000007004670046700303002670016700064000620006101e50006600056000460004600036000060000600006000060000600006000060000000000000000000000000000000000000000000000000000
00020000121701a560220500002000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0003000000450014501861011450004500d630004500005000050000500f6500004001040010400204002040030400404005030070300a0200b1200b2200b0300b2300b0300b0300b0300b0200b2100b0100b410
001000002f2102e7402d4202b130247501a7500874002730001200012000020004100041000010001100011000010001100011000110001300014000000000000000000000000000000000000000000000000000
__music__
00 01434441
00 02034344
00 02040144
00 01040045
00 01044305
00 02400405
00 00424305
02 00420405

