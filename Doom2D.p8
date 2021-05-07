pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
Game = { 
    time=0, 
    objects = {}, 
    mousePositionX = 0 ,
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
    rotation = {}
}

Cache = {
    rayUnitStepSize = {},
    forwardVector = {}
}

depth = {}


Textures = {
    [1] = {
        position = { x = 0, y = 0 },
        dimension = { w = 8, h = 8 }
    }, 
    [2] = {
        position = { x = 8, y = 0 },
        dimension = { w = 8, h = 8 }
    }
}

Map = {
    width = 38,
    height = 10,
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
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    },
    height = texture
}


--Old renderer to display the player on the 2d Map
C_Renderer_Dot = {}
function C_Renderer_Dot.new(self,dotSize)
    return {
        dotSize = dotSize,
        draw = function(self, owner)
            circfill(owner.transform.position.x,owner.transform.position.y, dotSize * owner.transform.scale)
        end
    }
end

C_Renderer_Line = {}
function C_Renderer_Line.new(self, renderDistance)
    return{
        renderDistance = renderDistance or 100,
        draw = function(self,owner)
            local groundColor, ceilingColor = 3, 2
            local shakeStrength = 5

            depth = {}
            
            local center =  64 + sin(Game.time/50) * shakeStrength
            rectfill(0,0, 128, center, ceilingColor)
            rectfill(0,center, 128, 128, groundColor)
            for i = -64, 64 do
                local ray = self:rayCast(owner.transform.position, mod(owner.transform.rotation + i * 0.3, 360))
                if(ray.texture != 0) then
                    local lineheight = flr(128 / ray.distance)
                    --Print to Screen
                    sspr(Textures[ray.texture].position.x + flr(ray.textureCoordinate * Textures[ray.texture].dimension.w), Textures[ray.texture].position.y, 1, Textures[ray.texture].dimension.h, 64+i, center-lineheight, 1, lineheight*2)
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
C_PlayerController.new = function(self, speed, rotationSpeed)
    --Activate Mouse Lock
    poke(0x5f2d,0x5)
    return {
        speed = speed or 1,
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

            if(btn(1,1)) then
                owner.velocity.x += right.x * self.speed
                owner.velocity.y += right.y * self.speed
            end
            if(btn(0,1)) then 
                owner.velocity.x -= right.x * self.speed
                owner.velocity.y -= right.y * self.speed
            end

            --Movement with collision checks
            if(btn(2,1)) then 
                owner.velocity.x += forward.x * self.speed
                owner.velocity.y += forward.y * self.speed
            end
            if(btn(3,1)) then 
                owner.velocity.x -= forward.x * self.speed
                owner.velocity.y -= forward.y * self.speed
            end

            if(getMap( owner.transform.position.x + owner.velocity.x, owner.transform.position.y ) == 0) then 
                owner.transform.position.x += owner.velocity.x
            end
            if(getMap( owner.transform.position.x, owner.transform.position.y + owner.velocity.y ) == 0) then 
                owner.transform.position.y += owner.velocity.y
            end
            
        end
    }
end

Entity = {}
Entity.new = function (self, x, y)
    local me = {
        transform = { 
            position = { x = x, y = y }, 
            rotation = 1, 
            scale = 1
        },
        velocity = {
            x = 0,
            y = 0
        },
        angularVelocity = 0,
        components = {C_PlayerController:new(0.1, 3)},
        renderComponents = {C_Renderer_Line:new(100)},
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
	ent = Entity:new(20, 20)
    --Create direction cache
    for x = 0, 360/Game.fov do
        local rayDir = {x = sin(x*Game.fov/360), y = cos(x*Game.fov/360)}
        add(Cache.forwardVector, {x = sin(x*Game.fov/360), y = cos(x*Game.fov/360)})
        add(Cache.rayUnitStepSize, { x = sqrt(1 + (rayDir.y / rayDir.x)^2), y = sqrt(1 + (rayDir.x / rayDir.y)^2)})
    end
end

function _update60()
	Game.time += 1
    foreach(Game.objects, function(obj) obj:update(self) end)
end

--poke(0x5f36,1) -- to enable. **secret!**
function _draw()
--	di = stat(3)
	cls()
	foreach(Game.objects, function(obj) obj:draw(self) end)
    print("Memory: " .. stat(0))
    print("CPU: " .. stat(1))
    print("FPS: " .. stat(7))
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
11111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
14444441188dd8810000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1455554118dddd810000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
155dd55118dffd810000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
155dd55118dffd810000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1455554118dddd810000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
14444441188dd8810000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
