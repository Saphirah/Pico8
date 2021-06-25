local Perms = {
    151, 160, 137, 91, 90, 15, 131, 13, 201, 95, 96, 53, 194, 233, 7, 225,
    140, 36, 103, 30, 69, 142, 8, 99, 37, 240, 21, 10, 23, 190, 6, 148,
    247, 120, 234, 75, 0, 26, 197, 62, 94, 252, 219, 203, 117, 35, 11, 32,
    57, 177, 33, 88, 237, 149, 56, 87, 174, 20, 125, 136, 171, 168, 68,   175,
    74, 165, 71, 134, 139, 48, 27, 166, 77, 146, 158, 231, 83, 111,   229, 122,
    60, 211, 133, 230, 220, 105, 92, 41, 55, 46, 245, 40, 244, 102, 143, 54,
    65, 25, 63, 161, 1, 216, 80, 73, 209, 76, 132, 187, 208, 89, 18, 169,
    200, 196, 135, 130, 116, 188, 159, 86, 164, 100, 109, 198, 173, 186, 3, 64,
    52, 217, 226, 250, 124, 123, 5, 202, 38, 147, 118, 126, 255, 82, 85, 212,
    207, 206, 59, 227, 47, 16, 58, 17, 182, 189, 28, 42, 223, 183, 170, 213,
    119, 248, 152, 2, 44, 154, 163, 70, 221, 153, 101, 155, 167, 43, 172, 9,
    129, 22, 39, 253, 19, 98, 108, 110, 79, 113, 224, 232, 178, 185, 112, 104,
    218, 246, 97, 228, 251, 34, 242, 193, 238, 210, 144, 12, 191, 179, 162, 241,
    81,   51, 145, 235, 249, 14, 239,   107, 49, 192, 214, 31, 181, 199, 106, 157,
    184, 84, 204, 176, 115, 121, 50, 45, 127, 4, 150, 254, 138, 236, 205, 93,
    222, 114, 67, 29, 24, 72, 243, 141, 128, 195, 78, 66, 215, 61, 156, 180
 }

for i = 0, 255 do
   Perms[i]=Perms[i+1]
end

local Perms12 = {}

for i = 0, 255 do
   local x = Perms[i] % 12
   Perms[i + 256], Perms12[i], Perms12[i + 256] = Perms[i], x, x
end

local Grads3 = {
   { 1, 1, 0 }, { -1, 1, 0 }, { 1, -1, 0 }, { -1, -1, 0 },
   { 1, 0, 1 }, { -1, 0, 1 }, { 1, 0, -1 }, { -1, 0, -1 },
   { 0, 1, 1 }, { 0, -1, 1 }, { 0, 1, -1 }, { 0, -1, -1 }
}

for row in all(Grads3) do
   for i=0,2 do
      row[i]=row[i+1]
   end
end

for i=0,11 do
   Grads3[i]=Grads3[i+1]
end

function GetN2d (bx, by, x, y)
   local t = .5 - x * x - y * y
   local index = Perms12[bx + Perms[by]]
   return max(0, (t * t) * (t * t)) * (Grads3[index][0] * x + Grads3[index][1] * y)
end

function Simplex2D (x, y)
   local s = (x + y) * 0.366025403 -- F
   local ix, iy = flr(x + s), flr(y + s)
   local t = (ix + iy) * 0.211324865 -- G
   local x0 = x + t - ix
   local y0 = y + t - iy
   ix, iy = band(ix, 255), band(iy, 255)
   local n0 = GetN2d(ix, iy, x0, y0)
   local n2 = GetN2d(ix + 1, iy + 1, x0 - 0.577350270, y0 - 0.577350270) -- G2
   local xi = 0
   if x0 >= y0 then xi = 1 end
   local n1 = GetN2d(ix + xi, iy + (1 - xi), x0 + 0.211324865 - xi, y0 - 0.788675135 + xi) -- x0 + G - xi, y0 + G - (1 - xi)
   return 70 * (n0 + n1 + n2)
end

function GetN3d (ix, iy, iz, x, y, z)
   local t = .6 - x * x - y * y - z * z
   local index = Perms12[ix + Perms[iy + Perms[iz]]]
   return max(0, (t * t) * (t * t)) * (Grads3[index][0] * x + Grads3[index][1] * y + Grads3[index][2] * z)
end

function Simplex3D (x, y, z)
   local s = (x + y + z) * 0.333333333 -- F
   local ix, iy, iz = flr(x + s), flr(y + s), flr(z + s)
   local t = (ix + iy + iz) * 0.166666667 -- G
   local x0 = x + t - ix
   local y0 = y + t - iy
   local z0 = z + t - iz
   ix, iy, iz = band(ix, 255), band(iy, 255), band(iz, 255)
   local n0 = GetN3d(ix, iy, iz, x0, y0, z0)
   local n3 = GetN3d(ix + 1, iy + 1, iz + 1, x0 - 0.5, y0 - 0.5, z0 - 0.5) -- G3
   local i1
   local j1
   local k1
   local i2
   local j2
   local k2
   if x0 >= y0 then
      if y0 >= z0 then -- X Y Z
         i1, j1, k1, i2, j2, k2 = 1,0,0,1,1,0
      elseif x0 >= z0 then -- X Z Y
         i1, j1, k1, i2, j2, k2 = 1,0,0,1,0,1
      else -- Z X Y
         i1, j1, k1, i2, j2, k2 = 0,0,1,1,0,1
      end
   else
      if y0 < z0 then -- Z Y X
         i1, j1, k1, i2, j2, k2 = 0,0,1,0,1,1
      elseif x0 < z0 then -- Y Z X
         i1, j1, k1, i2, j2, k2 = 0,1,0,0,1,1
      else -- Y X Z
         i1, j1, k1, i2, j2, k2 = 0,1,0,1,1,0
      end
   end

   local n1 = GetN3d(ix + i1, iy + j1, iz + k1, x0 + 0.166666667 - i1, y0 + 0.166666667 - j1, z0 + 0.166666667 - k1) -- G
   local n2 = GetN3d(ix + i2, iy + j2, iz + k2, x0 + 0.333333333 - i2, y0 + 0.333333333 - j2, z0 + 0.333333333 - k2) -- G2
   return 32 * (n0 + n1 + n2 + n3)
end