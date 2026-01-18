return {
    default = 0x80ffffff,
    black = 0xff181819,
    white = 0xffffffff,
    red = 0xfffc5d7c,
    red_bright = 0xe0f38ba8,
    green = 0xff9ed072,
    blue = 0xff76cce0,
    blue_bright = 0xe089b4fa,
    yellow = 0xffe7c664,
    orange = 0xfff39660,
    magenta = 0xffb39df3,
    grey = 0xff7f8490,
    transparent = 0x00000000,

    bar = {
        bg = 0xf0181819,  -- Dark with slight transparency
        border = 0xff2c2e34,
    },

    popup = {
        bg = 0xFF1d1b2d,
        border = 0xff7f8490
    },

    bg1 = 0xFF1d1b2d,
    bg2 = 0xe0313436,

    accent = 0xFFb482c2,
    accent_bright = 0x33efc2fc,

    spotify_green = 0xe040a02b,

    with_alpha = function(color, alpha)
        if alpha > 1.0 or alpha < 0.0 then return color end
        return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
    end,
}
