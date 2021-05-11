pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
Game = { 
    time = 0,
    deltaTime = 0,
    player = nil,
    objects = {}, 
    sprites = {},
    mousePositionX = 0,
    --You need to start Pico8 with the following parameters: -display_x 2 -displays_y 2
    screens = {
        x = 1,
        y = 1
    },
    dimension = function()
        return {
            w = x * 128,
            h = y * 128
        }
    end,
    fov = 0.1,
    rotation = {},
    center = 64
}

Cache = {
    rayUnitStepSize = {},
    forwardVector = {}
}

depth = {}


Textures = {
    [1] = {
        name = "Wall1",
        position = { x = 0, y = 0 },
        dimension = { w = 8, h = 8 }
    }, 
    [2] = {
        name = "Wall2",
        position = { x = 8, y = 0 },
        dimension = { w = 8, h = 8 }
    },
    [3] = {
        name = "Wizard",
        position = { x = 16, y = 0},
        dimension = { w = 64, h = 64},
        worldSize = { w = 400, h = 400 },
    }
}

Map = {
    width = 38,
    height = 12,
    --TODO: Use for different heights
    texture = {
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2,
        1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 2, 0, 2, 0, 1, 0, 0, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 2,
        1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 2,
        1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 2,
        1, 0, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 2,
        1, 0, 0, 0, 1, 2, 2, 0, 0, 1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1,
        1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1,
        1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1,
        1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1,
        1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1,
        1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1,
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    },
    height = texture
}


--Old renderer to display the player on the 2d Map
--C_Renderer_Dot = {}
--function C_Renderer_Dot.new(self,dotSize)
--    return {
--        dotSize = dotSize,
--        draw = function(self, owner)
--            circfill(owner.transform.position.x,owner.transform.position.y, dotSize * owner.transform.scale)
--        end
--    }
--end

Ray = {}
Ray.new = function(rayPos, rotation)
    local mapCheck = convertToCell(rayPos.x, rayPos.y, true)
    local distance = 0
    local texture = getMapLocal(mapCheck.x, mapCheck.y)
    local rayDir = getForwardVector(rotation)
    rayPos = convertToCell(rayPos.x, rayPos.y, false)
    
    --Checks if camera plane is rendering in wall
    if(texture == 0) then 

        --Precalculation
        --local rayUnitStepSize = { x = sqrt(1 + (rayDir.y / rayDir.x)^2), y = sqrt(1 + (rayDir.x / rayDir.y)^2)}
        local rayUnitStepSize = Cache.rayUnitStepSize[flr(mod(rotation,360)/Game.fov)+1]
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
            
            texture = getMapLocal(mapCheck.x, mapCheck.y)
            if(texture != 0) then break end
        end
    end
    return {
        distance = distance, 
        mapCoordinates = mapCheck,
        texture = texture or 1,
        textureCoordinate = ((rayPos.x + rayDir.x * distance) + (rayPos.y + rayDir.y * distance)) % 1, 
        rayPos = {x = rayPos.x + rayDir.x * distance, y = rayPos.y + rayDir.y * distance}
    }
end


C_Renderer_Line = {}
C_Renderer_Line.new = function(self, renderDistance)
    return{
        renderDistance = renderDistance or 100,
        draw = function(self,owner)
            local groundColor, ceilingColor = 3, 2
            local shakeStrength = 3

            depth = {}
            Game.center =  64 + sin(time()) * shakeStrength + owner.transform.position.z
            rectfill(0,0, 128, Game.center, ceilingColor)
            rectfill(0, Game.center, 128, 128, groundColor)
            for i = -64, 64 do
                local ray = Ray.new(owner.transform.position, mod(owner.transform.rotation + i * 0.3, 360))
                if(ray.texture != 0) then
                    local lineheight = flr(128 / ray.distance)
                    --Print to Screen
                    sspr(Textures[ray.texture].position.x + flr(ray.textureCoordinate * Textures[ray.texture].dimension.w), Textures[ray.texture].position.y, 1, Textures[ray.texture].dimension.h, 64+i, Game.center-lineheight, 1, lineheight*2)
                end
                --Store depth data for sprite rendering
                add(depth, ray.distance)
            end 
            
        end,
        rayCast = function(self, rayPos, rotation)
            local mapCheck = convertToCell(rayPos.x, rayPos.y, true)
            local distance = 0
            local texture = getMapLocal(mapCheck.x, mapCheck.y)
            local rayDir = getForwardVector(rotation)
            rayPos = convertToCell(rayPos.x, rayPos.y, false)
            
            --Checks if camera plane is rendering in wall
            if(texture == 0) then 

                --Precalculation
                --local rayUnitStepSize = { x = sqrt(1 + (rayDir.y / rayDir.x)^2), y = sqrt(1 + (rayDir.x / rayDir.y)^2)}
                local rayUnitStepSize = Cache.rayUnitStepSize[flr(mod(rotation,360)/Game.fov)+1]
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
                    
                    texture = getMapLocal(mapCheck.x, mapCheck.y)
                    if(texture != 0) then break end
                end
            end
            return {
                distance = distance, 
                mapCoordinates = mapCheck,
                texture = texture or 1,
                textureCoordinate = ((rayPos.x + rayDir.x * distance) + (rayPos.y + rayDir.y * distance)) % 1, 
                rayPos = {x = rayPos.x + rayDir.x * distance, y = rayPos.y + rayDir.y * distance}
            }
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
            owner.velocity.x /= 1.1
            owner.velocity.y /= 1.1
            owner.angularVelocity /= 1.2
            local forward = getForwardVector(owner.transform.rotation)
            local right = getForwardVector(owner.transform.rotation + 90 )

            --Rotation
            --OLD: Rotation using arrow keys
            --if(btn(0,0)) then owner.transform.rotation-=self.rotationSpeed end
            --if(btn(1,0)) then owner.transform.rotation+=self.rotationSpeed end
            owner.angularVelocity += stat(38) / 50
            owner.transform.rotation = mod(owner.transform.rotation + owner.angularVelocity,360)
            if(owner.transform.position.z > 0) then 
                owner.velocity.z -= 0.1
            elseif(owner.velocity.z != 0) then
                owner.velocity.z = 0
            end

            if(btn(1,1)) then
                owner.velocity.x += right.x * owner.movementSpeed * Game.deltaTime
                owner.velocity.y += right.y * owner.movementSpeed * Game.deltaTime
            end
            if(btn(0,1)) then 
                owner.velocity.x -= right.x * owner.movementSpeed * Game.deltaTime
                owner.velocity.y -= right.y * owner.movementSpeed * Game.deltaTime
            end

            if(btn(4,1) and owner.transform.position.z == 0) then
                owner.velocity.z = 2
            end

            --Movement with collision checks
            if(btn(2,1)) then 
                owner.velocity.x += forward.x * owner.movementSpeed * Game.deltaTime
                owner.velocity.y += forward.y * owner.movementSpeed * Game.deltaTime
            end
            if(btn(3,1)) then 
                owner.velocity.x -= forward.x * owner.movementSpeed * Game.deltaTime
                owner.velocity.y -= forward.y * owner.movementSpeed * Game.deltaTime
            end

            if(getMap( owner.transform.position.x + owner.velocity.x, owner.transform.position.y ) == 0) then 
                owner.transform.position.x += owner.velocity.x
            end
            if(getMap( owner.transform.position.x, owner.transform.position.y + owner.velocity.y ) == 0) then 
                owner.transform.position.y += owner.velocity.y
            end

            owner.transform.position.z = max(owner.transform.position.z + owner.velocity.z, 0)
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
            local relativePos = { x = owner.transform.position.x - Game.player.transform.position.x, y = owner.transform.position.y - Game.player.transform.position.y }
            --Cheap average distance
            self.distance = abs(relativePos.x) + abs(relativePos.y)
            --OLD: self.distance = sqrt(relativePos.x * relativePos.x + relativePos.y * relativePos.y)
            self.spriteAngle = mod(atan2(relativePos.y, relativePos.x) * 360 - Game.player.transform.rotation,360)
            --Align to center of the screen
            if self.spriteAngle > 180 then self.spriteAngle -= 360 end
            --DEBUG Log
            --Calculate Sprite Scale
            local size = 5 / self.distance;
            --Render Sprite when in View
            if(self.spriteAngle <= 40 and self.spriteAngle >=-40) then
                local halfSize = flr(size * Textures[spriteIndex].worldSize.w / 2)
                local screenPosY = Game.center + (Textures[spriteIndex].worldSize.h -2000) * 0.25 / self.distance + Game.player.transform.position.z

                --Occlusion Check
                local isOccluded = false
                local screenPosXLeft = flr(64 + self.spriteAngle * 3.6 -halfSize)
                local screenPosXRight = flr(64 + self.spriteAngle * 3.6 + halfSize)
                for x = max(screenPosXLeft,1), min(screenPosXRight, 128) do
                    if(self.distance > depth[x] * 16) then
                        isOccluded = true
                        break
                    end
                end

                --Slow Method: Render Sprite Stripes
                if isOccluded then
                    for x = -halfSize, halfSize do 
                        local screenPosX = flr(64 + self.spriteAngle * 3.6 + x)
                        if(screenPosX >= 0 and screenPosX <= 128) then
                            if(self.distance < depth[screenPosX+1] * 16) then
                                sspr(
                                    Textures[spriteIndex].position.x + Textures[spriteIndex].dimension.w * (x + halfSize) / (halfSize * 2), Textures[spriteIndex].position.y, 
                                    1, Textures[spriteIndex].dimension.h, 
                                    screenPosX, screenPosY, 
                                    1, size *  Textures[spriteIndex].worldSize.h
                                )
                                
                            end
                        end
                    end
                
                --Fast Method: Render whole Sprite
                else
                    sspr(
                                    Textures[spriteIndex].position.x, Textures[spriteIndex].position.y, 
                                    Textures[spriteIndex].dimension.w, Textures[spriteIndex].dimension.h, 
                                    screenPosXLeft, screenPosY, 
                                    screenPosXRight - screenPosXLeft, size *  Textures[spriteIndex].worldSize.h
                    )
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
        components = {},
        renderComponents = {},
        draw = function(self)
            foreach(self.renderComponents, function(obj) obj:draw(self) end)
        end,
        update = function(self)
            foreach(self.components, function(obj) obj:update(self) end)
        end
    }
    add(Game.objects, me)
    return me
end

Sprite = {}
Sprite.new = function(self, x, y, spriteIndex)
    local me = Entity:new(x,y)
    add(me.renderComponents, C_SpriteRenderer:new(spriteIndex))
end

Player = {}
Player.new = function (self, x, y)
    local me = Entity:new(x, y)
    me.velocity = {
        x = 0,
        y = 0,
        z = 0
    }
    me.transform.position.z = 0
    me.angularVelocity = 0
    me.movementSpeed = 2
    add(me.components, C_PlayerController:new(3))
    add(me.renderComponents, C_Renderer_Line:new(100))
    return me
end

function convertToCell(x, y, round)
    if(round) then
        return {
            x = flr(x / 128 * 16), 
            y = flr(y / 128 * 16)
        }
    else
        return {
            x = x / 128 * 16, 
            y = y / 128 * 16
        }
    end
end

function getForwardVector(rotation)
    return Cache.forwardVector[flr(mod(rotation,360)/Game.fov)+1]
end

--Gets a point on the map in local coordinates
function getMapLocal(x,y)
    --Old method using sprites
    --return sget(x, y)
    return Map.texture[y * Map.width + x]
end

--Gets a point on the map in global coordinates
function getMap(x,y)
    cord = convertToCell(x,y,true)
    return getMapLocal(cord.x, cord.y)
end

function mod(x, m)
    while x < 0 do
        x += m
    end
    return x%m
end

function _init()
    --Spawn Player
    Game.player = Player:new(20, 20)
    Sprite:new(22,22, 3)
    Sprite:new(24,22, 3)
    Sprite:new(28,22, 3)
    
    --Create direction cache
    for x = 0, 360/Game.fov do
        local rayDir = {x = sin(x*Game.fov/360), y = cos(x*Game.fov/360)}
        add(Cache.forwardVector, {x = sin(x*Game.fov/360), y = cos(x*Game.fov/360)})
        --add(Cache.rayUnitStepSize, { x = sqrt(1 + (rayDir.y / rayDir.x)^2), y = sqrt(1 + (rayDir.x / rayDir.y)^2)})
        add(Cache.rayUnitStepSize, { x = abs(1/rayDir.x), y = abs(1/rayDir.y)})
    end
end

function _update60()
    Game.deltaTime = time() - Game.time
    Game.time = time()
    foreach(Game.objects, function(obj) obj:update(self) end)
end

--poke(0x5f36,1) -- to enable. **secret!**
function _draw()
--	di = stat(3)
	cls()
	foreach(Game.objects, function(obj) obj:draw(self) end)
    --print("Memory: " .. stat(0))
    --print("CPU: " .. stat(1))
    --print("FPS: " .. stat(7))
    print(Game.player.velocity.z)
--	return di<2 --true means "give me another display to draw to
end


--_camera = camera --save original camera function reference
--function camera(x,y)
--	x = x or 0
--	y = y or 0
--	local dx = flr(stat(3) % Game.screens.x)
--	local dy = flr(stat(3) / Game.screens.x)
--	_camera(x+128*dx, y+128*dy)
--end




__gfx__
11111111111111110000000000000000000000000222222222222200000000000000000000000000000000000000000000000000000000000000000000000000
14444441188dd8810000000000000000000000000000002222222200000000000000000000000000000000000000000000000000000000000000000000000000
1455554118dddd810000000000000000000000000022222222222220000000000000000000000000000000000000000000000000000000000000000000000000
155dd55118dffd810000000000000000000002222222222222222222222000000000000000000000000000000000000000000000000000000000000000000000
155dd55118dffd810000000000000000000000000222222222222200000000000000000000000000000000000000000000000000000000000000000000000000
1455554118dddd810000000000000000000000000022222222000000000000000000000000000000000000000000000000000000000000000000000000000000
14444441188dd8810000000000000000000000000002222222222222222000000000000000000000000000000000000000000000000000000000000000000000
11111111111111110000000000000000000000000222222222222222222000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000222222222222220000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000002222222222222000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000022222222222222000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000002222222222222222000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000222222222222222222222222002222222000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000222222222222222222222222222222222000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000002222222222222222222222222222222222000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000022222222222222222222222222222222220000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000999999999999900000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000009999999999999990000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000009999999999999999000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000099999cc9999cc999900000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000009999ccc999ccc999900000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000009999cc9999ccc999900000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000009999999999999999990000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000009999999999999999990000000000000000000005000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000009999999999999999990000000000000000000055000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000999999999999999990000000000000000000050000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000999999999999999990000000000000000000550050000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000999999999999999990000000000000000005505555000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000099999999999999990000000000000000055555050000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000999999999999900000000000000000555000500000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000099999999000000000000000555500555000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000009999999999900000000000555555005000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000099999999999990000000000505050550000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000009999999999999999000000000055555000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000099999909990999999900000005555000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000009999999009990099999900000055550000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000099999999009900009999990005555500000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000009999999990009990009999990555555000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000099999999900009990000999995555550000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000999999999000009990000999999555550000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000009999999900000009990000009995555500000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000009999999000000009990000000995555000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000099999000000000009990000000095550000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000099990000000000009990000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000990000000000099990000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000099990000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000999999000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000099999999900000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000999999999990000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000009999999999999000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000999999999999999900000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000009999999999999099990000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000099999999900099999990000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000999999999000000099999000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000009999999990000000009999900000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000999999999900000000000999990000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000099999999999000000000000099999000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000009999999999990000000000000009999000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000999999999999000000000000000000999990000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000009999999999900000000000000000000099999000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000099999999990000000000000000000000009999900000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000099999999000000000000000000000000000999990000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000099990000000000000000000000000000000099990000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000999000000000000000000000000000000000000999000000000000000000000000000000000000000000000000000000000000000
