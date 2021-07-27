--Convert a 1D Index to 2D
function to2D(index, width)
    return vec2(index % width, flr(index / width))
end

--Convert 2D Index to 1D
function to1D(indexX, indexY, width)
    return indexY * width + indexX + 1
end

--Custom modulo function for negative values
function mod(x, m)
    while x < 0 do
        x += m
    end
    return x%m
end

--Round function with 0.5-based rounding
function round(x)
    if(x%1 >= 0.5) then
        return ceil(x)
    else
        return flr(x)
    end
end