# The Color model provides easy access to an array
# of basic colors and methods for the conversion of
# representations of colors.

class Color extends Backbone.Model
  # A selection of colors in tuple (r, g, b) format.
  # Color list contains a reference to all of them
  # for sorting.
  BLACK = [0, 0, 0]; WHITE = [255, 255, 255]; BLUE = [0, 0, 255]; YELLOW = [255, 255, 0]; RED = [255, 0, 0]; LEGO_BLUE = [0,50,150]; LEGO_ORANGE = [255,150,40]; VIOLET = [181, 126, 220]; ORANGE = [255, 165, 0]; GREEN = [0, 128, 0]; GRAY = [128, 128, 128]; IVORY = [255, 255, 240]; BEIGE = [245, 245, 220]; WHEAT = [245, 222, 179]; TAN = [210, 180, 140]; KHAKI = [195, 176, 145]; SILVER = [192, 192, 192]; CHARCOAL = [70, 70, 70]; NAVYBLUE = [0, 0, 128]; ROYALBLUE = [8, 76, 158]; MEDIUMBLUE = [0, 0, 205]; AZURE = [0, 127, 255]; CYAN = [0, 255, 255]; AQUAMARINE = [127, 255, 212]; TEAL = [0, 128, 128]; FORESTGREEN = [34, 139, 34]; OLIVE = [128, 128, 0]; LIME = [191, 255, 0]; GOLD = [255, 215, 0]; SALMON = [250, 128, 114]; HOTPINK = [252, 15, 192]; FUCHSIA = [255, 119, 255]; PUCE = [204, 136, 153]; PLUM = [132, 49, 121]; INDIGO = [75, 0, 130]; MAROON = [128, 0, 0]; CRIMSON = [220, 20, 60]; DEFAULT = [0, 0, 0]
  colorlist = [BLACK,WHITE,BLUE,YELLOW,RED,VIOLET,ORANGE,GREEN,GRAY,IVORY,BEIGE,WHEAT,TAN,KHAKI,SILVER,CHARCOAL,NAVYBLUE,ROYALBLUE,MEDIUMBLUE,AZURE,CYAN,AQUAMARINE,TEAL,FORESTGREEN,OLIVE,LIME,GOLD,SALMON,HOTPINK,FUCHSIA,PUCE,PLUM,INDIGO,MAROON,CRIMSON,DEFAULT]
      
  # Returns a random color from the colorList
  # array.
  getRandom:() =>
    color = colorList[Math.floor(Math.random()*colorList.length)]
    return color
  
  # Takes a tuple set (r, g, b) and converts
  # it to a tuple (h, s, v)
  RGBtoHSV:(r, g, b) =>
    r = r/255; g = g/255; b = b/255;
    max = Math.max(r, g, b); min = Math.min(r, g, b);
    h = max; s = max; v = max;
    d = max - min; s = (if max == 0 then 0 else d / max);
    if max is min then h = 0
    else
      switch max
        when r
          h = (g - b) / d + (if g < b then 6 else 0)
        when g
          h = (b - r) / d + 2
        when b
          h = (r - g) / d + 4
      h /= 6
    return [h*360, s*100, v*255]
  
  # Takes a tuple set (h, s, v) and converts
  # it to a tuple (r, g, b)
  hsvToRgb:() ->
    h = @tuple[0]; s = @tuple[1]; v = @tuple[2];
    i = Math.floor(h * 6); f = h * 6 - i
    p = v * (1 - s); q = v * (1 - f * s); t = v * (1 - (1 - f) * s)
    switch i % 6
      when 0
        r = v;g = t;b = p;
      when 1
        r = q;g = v;b = p;
      when 2
        r = p;g = v;b = t;
      when 3
        r = p;g = q;b = v;
      when 4
        r = t;g = p;b = v;
      when 5
        r = v;g = p;b = q;
    return [r * 255, g * 255, b * 255]
  
module.exports = new Color()