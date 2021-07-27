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