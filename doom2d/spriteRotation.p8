function rspr(sx,sy,x,y,r,w)
    local ca,sa=cos(r),sin(r)
    local srcx,srcy,addr,pixel_pair
    local ddx0,ddy0=ca,sa
    local mask=shl(0xfff8,(w-1))
    w*=4
    ca*=w-0.5
    sa*=w-0.5
    local dx0,dy0=sa-ca+w,-ca-sa+w
    w=2*w-1
    for ix=0,w do
        srcx,srcy=dx0,dy0
        for iy=0,w do
            if band(bor(srcx,srcy),mask)==0 then
                local c= sget(sx+srcx,sy+srcy)
                sset(x+ix,y+iy,c)
            else
                sset(x+ix,y+iy,rspr_clear_col)
            end
            srcx-=ddy0
            srcy+=ddx0
        end
        dx0+=ddx0
        dy0+=ddy0
    end
end