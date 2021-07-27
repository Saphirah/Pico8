--__lua__
--Base abstract class for a weapon.
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

--A weapon pickup
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


Weapon_Shotgun = {
    new = function(self, parent)
        local me = Weapon:new(parent, 10)
        me.cooldown = 45
        me.shoot = function(self)
            sfx(8)
            ExplosionAnim:new (self.transform.position.x,self.transform.position.y,{50,51,52})
            self.parent.velocity.x = self.parent.isFacingRight and -10 or 10
            for i = 0, 4 do
                Projectile_Pellet:new(self.transform.position.x, self.transform.position.y, self.parent.isFacingRight and 3 or -3, rnd(1) - 0.5, self.parent.playerID, 10, 7, 10, 4)
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
            Projectile_Laser:new(self.transform.position.x, self.transform.position.y, self.parent.isFacingRight and 5 or -5, 0, self.parent.playerID, 20, 11, 5, 50, 0)
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
            Projectile_Launcher:new(self.transform.position.x, self.transform.position.y, self.parent.isFacingRight and 1 or -1, 0, self.parent.playerID, 25, 12, 6, 400, 8)
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
        me.short = false
        me.shoot = function(self)
            Projectile_Pellet:new(self.transform.position.x, self.transform.position.y, self.parent.isFacingRight and 2 or -2, rnd(0.1) - 0.05, self.parent.playerID, 5, 10, 40, 5)
            sfx(11)
        end
        
        me.isShooting = function(self)
            if(self.cooldown > 0) then
                self.cooldown -= 1
            else
                if(btn(5, self.parent.playerID == 1 and 1 or 0)) then
                    self:shoot()
                    self.cooldown = self.short and 3 or 15
                    self.short = not self.short
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
            Projectile_Sniper:new(self.transform.position.x, self.transform.position.y, self.parent.isFacingRight and 25 or -25, 0, self.parent.playerID, 15, 6, 30, 30, 4)
            Projectile_Sniper:new(self.transform.position.x, self.transform.position.y, self.parent.isFacingRight and 22 or -22, 0, self.parent.playerID, 15, 6, 30, 30, 4)
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