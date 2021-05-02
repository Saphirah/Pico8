pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
Game = { time=0, objects = {}, mousePositionX = 0 }

depth = {}

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
            local cameraDir = {x = sin((owner.transform.rotation+90)/360), y = cos((owner.transform.rotation+90)/360)}
            local distance
            local fov, cameraPlaneSite, textureResolution = 0.3, 5, 8
            local groundColor, ceilingColor = 3, 2
            local shakeStrength = 2
            if (owner.velocity.x != 0 | owner.velocity.y != 0) then shakeStrength += 3 end
            depth = {}
            
            local center =  64 + sin(Game.time/50) * 5
            rectfill(0,0, 128, center, ceilingColor)
            rectfill(0,center, 128, 128, groundColor)
            local rotation = owner.transform.rotation
            local forwardVector = owner:getForwardVector()
            owner.transform.rotation += 90
            local rightVector = owner:getForwardVector()
            owner.transform.rotation -= 90 + fov * 64
            local leftFOVVector = owner:getForwardVector()
            owner.transform.rotation += fov * 128
            local rightFOVVector = owner:getForwardVector()
            owner.transform.rotation = rotation
            for i = -64, 64 do
                local f = (i + 64) / 128
                local rayDir = { x = leftFOVVector.x + f * (rightFOVVector.x - leftFOVVector.x),  y = leftFOVVector.y + f * (rightFOVVector.y - leftFOVVector.y)}
                local ray = self:rayCast({ x = owner.transform.position.x + forwardVector.x + rightVector.x * i / 64, y = owner.transform.position.y + forwardVector.x + rightVector.y * i / 64}, rayDir)
                local lineheight = flr(128 / ray.distance)
                sspr(flr(textureResolution*ray.textureCoordinate), 32, 1, textureResolution, 64+i, center-lineheight, 1, lineheight*2)
                add(depth, ray.distance)
            end 
        end,
        rayCast = function(self, rayPos, rayDir)
            local mapCheck = convertToCell(rayPos.x, rayPos.y, true)
            local distance = 0.1
            rayPos = convertToCell(rayPos.x, rayPos.y, false)
            --Checks if camera plane is rendering in wall
            if(getMapLocal(mapCheck.x, mapCheck.y) == 0) then 
                local rayUnitStepSize = { x = sqrt(1 + (rayDir.y / rayDir.x)^2), y = sqrt(1 + (rayDir.x / rayDir.y)^2)}
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
                    
                    if(sget(mapCheck.x, mapCheck.y) != 0) then 
                        break 
                    end
                end
            end
            return {distance = distance, mapCoordinates = mapCheck, textureCoordinate = ((rayPos.x + rayDir.x * distance) + (rayPos.y + rayDir.y * distance)) % 1}
        end
    }
end

C_PlayerController = {}
C_PlayerController.new = function(self, speed, rotationSpeed)
    return {
        speed = speed or 1,
        rotationSpeed = rotationSpeed,
        update = function(self, owner)            
            owner.velocity = { x = 0, y = 0}
            local forward = owner:getForwardVector() 
            owner.transform.rotation += 90
            local right = owner:getForwardVector()
            owner.transform.rotation -= 90

            --Rotation
            if(btn(0,0)) then owner.transform.rotation-=self.rotationSpeed end
            if(btn(1,0)) then owner.transform.rotation+=self.rotationSpeed end
            --poke(0x5F2D, 1)
            --local mousePos = stat(32)
            --owner.transform.rotation += flr(mousePos - Game.mousePositionX)
            --Game.mousePositionX = mousePos


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
            position = { x = x, y = y}, 
            rotation = 1, 
            scale = 1
        },
        components = {C_PlayerController:new(1, 3.33)},
        renderComponents = {C_Renderer_Line:new(100)},
        draw = function(self)
            foreach(self.renderComponents, function(obj) obj:draw(self) end)
        end,
        update = function(self)
            foreach(self.components, function(obj) obj:update(self) end)
        end,
        getForwardVector = function(self)
            return {x = sin(self.transform.rotation/360), y = cos(self.transform.rotation/360)}
        end
    }
    add(Game.objects, me)
    return me
end

World = {}
World.new = function (self)
    local me = {
        width = 16,
        height = 16,
        tilemap = {},
        generate = function(self)
            for x = 0, width do
                for y = 0, height do
                    --TODO Implement World Generation
                end
            end
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

--Gets a point on the map in local coordinates
function getMapLocal(x,y)
    return sget(x, y)
end

--Gets a point on the map in global coordinates
function getMap(x,y)
    cord = convertToCell(x,y)
    return sget(cord.x, cord.y)
end

function _init()
    --Spawn Player
	ent = Entity:new(20, 20)
end

function _update60()
	Game.time += 1
	for index, value in ipairs(Game.objects) do
        value:update()
	end
end

function _draw()
	cls()
	for index, value in ipairs(Game.objects) do
        value:draw()
	end
    --sspr(24, 0, 16, 37, 0, 0, 16, 37)
end




__gfx__
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd000000000000000000000000000000000000000000000000
d00000000000000d0000000000000000d00000000000000000000000000000000000dd00000000dd000000000000000000000000000000000000000000000000
d00000400000000d0000000000000000d0000000000000000000000000000000000dd000000000d0000000000000000000000000000000000000000000000000
d00000400000000d0000000000000000d000000000000000000000000000000000dd0000000000d0000000000000000000000000000000000000000000000000
d99999400005000d0000000000000000d000000000000000000000000000000000d0000000000dd0000000000000000000000000000000000000000000000000
d00000000005000d0000000000000000d000000000000000000000000000000000d0000000000d00000000000000000000000000000000000000000000000000
d00000000005000d0000000000000000d000000000000000000000000000000000d0000000000d00000000000000000000000000000000000000000000000000
d00000000005000d0000000000000000d000000000000000000000000000000000dd000000000d00000000000000000000000000000000000000000000000000
d00000000005000d0000000000000000d0000000000000000000000000000000000d000000000d00000000000000000000000000000000000000000000000000
d00000000005000d0000000000000000d0000000000000000000000000000000000d000000000d00000000000000000000000000000000000000000000000000
d000ccccccc5000d0000000000000000d00000000000000000000000000000000000d00000000d00000000000000000000000000000000000000000000000000
d00000000000000d0000000000000000d00000000000ddddddd00000000000000000dd0000000d00000000000000000000000000000000000000000000000000
d00000000000000d0000000000000000d0000000000dd00000dd00000000000000000dd000000dd0000000000000000000000000000000000000000000000000
d00000000000000d0000000000000000d000000000dd00000000d00000000000000000d000000dd0000000000000000000000000000000000000000000000000
d00000000000000dddddddd000000000d000000000d000000000dd0000000000000000d000000d00000000000000000000000000000000000000000000000000
d000000000000000000000d000000000d000000000d000000000000000000000000000d000000d00000000000000000000000000000000000000000000000000
d000660000600000000000d000000000d000000000d0000000000000000000000000ddd000000d00000000000000000000000000000000000000000000000000
d000660000660000000000d000000000d000000000d0000000000000ddd00dddddddd0000000dd00000000000000000000000000000000000000000000000000
d000660006660000000000d000000000d000000000dd00000000000000dddd00000000000000d000000000000000000000000000000000000000000000000000
d000600000000000000000d000000000d0000000000d0000000000000000000000000000000dd000000000000000000000000000000000000000000000000000
d000000000000000000000d000000000d0000000000dd00000000000000000000000000000dd0000000000000000000000000000000000000000000000000000
d000000000000000000000d000000000d00000000000dd0000000000000000000000000000d00000000000000000000000000000000000000000000000000000
d000006600000666666000d000000000d0000000000000dd0000000000000000000000000dd00000000000000000000000000000000000000000000000000000
d0006666000000066660000000000000d000000000000000dd00000000000000000000000d000000000000000000000000000000000000000000000000000000
d0000000000000006660000000000000d0000000000000000dd0000000000000000000000d000000000000000000000000000000000000000000000000000000
d0000000000000000660000000000000d00000000000000000dd000000000000000000000d000000000000000000000000000000000000000000000000000000
d0006000006600000060000000000000d000000000000000000ddddddddd0000000000000d000000000000000000000000000000000000000000000000000000
d000600000666600006000d000000000d0000000000000000000dd00000dddd0000000000d000000000000000000000000000000000000000000000000000000
d000600000666600000000d000000000d00000000000000000000d000000000ddddddddddd000000000000000000000000000000000000000000000000000000
d000600000666000000000d000000000d00000000000000000000dd0000000000000000000000000000000000000000000000000000000000000000000000000
d0006000000000000000dddddd000000d000000000000000000000d0000000000000000000000000000000000000000000000000000000000000000000000000
dddddddddddddddddddddddddd0000000000000000000000000000d0000000000000000000000000000000000000000000000000000000000000000000000000
11111111000000000000dddddd000000000000000000000000000dd0000000000000000000000000000000000000000000000000000000000000000000000000
14444441000000000000dddddd0000000000000000000000000ddd00000000000000000000000000000000000000000000000000000000000000000000000000
14555541000000000000dddddddddddddddddddd0000dddddddd0000000000000000000000000000000000000000000000000000000000000000000000000000
155dd5510000000000000000000000000000000dddddd00000000000000000000000000000000000000000000000000000000000000000000000000000000000
155dd551000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
14555541000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
14444441000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
