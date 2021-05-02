pico-8 cartridge // http://www.pico-8.com
version 32
__lua__

function _init()

end

function _update()
    cls()
    varrrr = 20
    local timer = stat(1)
    returnValue = varrrr >= 20 and 1 or 0
    print(stat(1) - timer)
    timer = stat(1)
    if(varrrr >= 20) then
        returnValue = 1
    else
        returnValue = 0
    end
    print(stat(1) - timer)

end

function _draw()

end