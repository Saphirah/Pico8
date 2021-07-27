--__lua__

--Abstract Projectile Class
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
        me.destroy = function(self)
            explosion = ceil(rnd(2))
            if explosion == 1 then                    
                ExplosionAnim:new (self.transform.position.x,self.transform.position.y,{65,66,67,68})
            end
            if explosion == 2 then                    
                ExplosionAnim:new (self.transform.position.x,self.transform.position.y,{65,66,67,68})
            end
            del(Game.objects, self)
        end
        return me
    end
}

Projectile_Laser = {
    new = function(self, x, y, velocityX, velocityY, playerID, damage, color, width, lifetime, explosionRadius)
        local me = Projectile:new(x, y, velocityX, velocityY, playerID, damage, color, lifetime, explosionRadius)
        add(me.renderComponents, C_LineRenderer:new(color, width))
        me.destroy = function(self)            
            ExplosionAnim:new (self.transform.position.x,self.transform.position.y,{53,54,55,56})
            del(Game.objects, self)
        end
        return me
    end
}

Projectile_Launcher = {
    new = function(self, x, y, velocityX, velocityY, playerID, damage, color, width, lifetime, explosionRadius)
        local me = Projectile:new(x, y, velocityX, velocityY, playerID, damage, color, lifetime, explosionRadius)
        add(me.renderComponents, C_AnimatedSpriteRenderer:new({57,58}, 2, true))
        me.destroy = function(self)            
            ExplosionAnim:new (self.transform.position.x,self.transform.position.y,{60,61})
            del(Game.objects, self)
        end
        return me
    end
}

Projectile_Sniper = {
    new = function(self, x, y, velocityX, velocityY, playerID, damage, color, width, lifetime, explosionRadius)
        local me = Projectile:new(x, y, velocityX, velocityY, playerID, damage, color, lifetime, explosionRadius)
        add(me.renderComponents, C_LineRenderer:new(color, width))
        me.destroy = function(self)            
            ExplosionAnim:new (self.transform.position.x,self.transform.position.y,{62,63,64})
            del(Game.objects, self)
        end
        return me
    end
}