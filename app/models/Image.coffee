Color = require './Color'
Model = require './model'
Display = require './Display'

# The Image model allows you to pass in a Canvas,
# HTMLImageElement, or an ImageData object and store
# that information in a universal format. The data
# is always passed in to a Canvas and the data can
# be retrieved by the methods show and getArray.
module.exports = class Image extends Model
  parent = null
  canvas = null
  ctx = null
  width = 0
  height = 0
  layers = null
  
  # Takes in a Canvas object, Array or Image.
  # In eitherx case, the data is stored in canvas
  # and array form. 
  initialize:(data) =>
    @canvas = document.createElement("canvas"); @layers = []
    if data instanceof HTMLCanvasElement
      @canvas = data
      @width = data.width
      @height = data.height
      @ctx = @canvas.getContext("2d")
    else if data instanceof ImageData
      @canvas.width = @width = data.width
      @canvas.height = @height = data.height
      @ctx = @canvas.getContext("2d")
      @ctx.putImageData(data, 0, 0)
    else if data instanceof HTMLImageElement
      @canvas.width = @width = data.width
      @canvas.height = @height = data.height
      @ctx = @canvas.getContext("2d")
      @ctx.drawImage(data, 0, 0)
    else
      throw new Error 'Cannot create Image with data type "'+data.constructor.name+'".'
  
  # Appends the canvas to parent element.
  # Defaults to appending it to the body.
  # If has been called before, ensure that
  # the canvas is visible.
  show:(container=$("body")) =>
    if container instanceof Display
      container = container.element
      
    view = $(container)
    view.html("").append(@canvas).width(@width).height(@height)
    for layer in @layers
      view.append(layer.canvas)
    @parent = container
    return
      
  # Creates a new canvas and processing.js
  # wrapper to be stored in the layers array.
  addDrawingLayer:() =>
    layer = document.createElement("canvas")
    layer.width = @width
    layer.height = @height
    pjs = new Processing(layer)
    pjs.background(0,0)
    pjs.size @width, @height
    pjs.scale 1    
    @layers.push {canvas: layer, processing: pjs}
    return pjs
    
  # Returns a drawing layer if any. Optional param
  # relating to which drawing layer is selected.
  getDrawingLayer:(layer=0) =>
    return @layers[layer].processing
  
  # Alias for getDrawingLayer
  dl:(layer) =>
    return @getDrawingLayer(layer)
  
  # Deletes a drawing layer from the image. Will
  # shift the indices of subsequent drawing layers
  # if they exist.
  removeDrawingLayer:(layer=@layers.length-1) =>
    delete @layers[layer]
    @layers.splice(layer, 1)
   
  # Returns the image in an image format that is
  # useful for grabbing the current state of the
  # canvas and applying native canvas transformations
  # on it.
  getImage:() =>
    image = document.createElement("image")
    image.src = @canvas.toDataURL()
    return image
   
  # Returns the image in a two dimensional array format
  # where each pixel is structured as [r, g, b].
  getMatrix:() =>
    result = []; x = [];
    matrix = @ctx.getImageData(0,0,@width,@height)
    i = 0; a = 1;
    while i < matrix.data.length
      x.push [matrix.data[i], matrix.data[i + 1], matrix.data[i + 2]]    
      i += 4
      if a is @width
        result.push x; x = []; a = 1
      else
        a++
    return result

  addBorder:(sz) =>
    newW = @width+(2*sz)
    newH = @height+(2*sz)
    newSz = newW*newH 

  # Returns the image in a single dimensional array format
  # where the pixels go in r, g, b, a order.
  getArray:() =>
    matrix = @ctx.getImageData(0,0,@width,@height)
    return matrix

  # Returns coordinates and value of the pixel with the highest
  # brightness following the format [x_pos, y_pos, value]
  getBrightestPixel:()=>
    points = @getGrayMatrix()
    x_pos = 0; y_pos = 0; brightness = 0
    for i in [0..@height-1]
      for j in [0..@width-1]
        if points[i][j][0] > brightness
          x_pos = i
          y_pos = j
          brightness = points[i][j][0]
    return [x_pos, y_pos, brightness]

  # Returns coordinates and value of the pixel with the smallest
  # brightness following the format [x_pos, y_pos, value]
  getDarkestPixel:()=>
    points = @getGrayMatrix()
    x_pos = 0; y_pos = 0; brightness = points[0][0][0]
    for i in [0..@height-1]
      for j in [0..@width-1]
        if points[i][j][0] < brightness
          x_pos = i
          y_pos = j
          brightness = points[i][j][0]
    return [x_pos, y_pos, brightness]

  # Returns the average brightness of the image.
  getAverageBrightness:()=>
    points = @getGrayMatrix()
    brightness_sum = 0
    for i in [0..@height-1]
      for j in [0..@width-1]
        brightness_sum += points[i][j][0]
    return brightness_sum / (@width * @height)

  
  # Simple image scale. Uses canvas to get this done
  # quickly. Returns a new image.
  scale:(factor) =>
    scaled = document.createElement("canvas")
    scaled.width = @width*factor
    scaled.height = @height*factor
    ctx = scaled.getContext("2d")
    ctx.drawImage(@canvas, 0, 0, @width*factor, @height*factor)
    return new Image(scaled)
  
  # Simple image resize. Also uses canvas to get this
  # done quickly. Returns a new image.
  resize:(width, height) =>
    scaled = document.createElement("canvas")
    scaled.width = width
    scaled.height = height
    ctx = scaled.getContext("2d")
    ctx.drawImage(@canvas, 0, 0, width, height)
    return new Image(scaled)   
    
  # Simple image crop. Uses canvas to get this done
  # quickly. Returns a new image.
  crop:(x, y, width, height) =>
    cropped = document.createElement("canvas")
    cropped.width = width
    cropped.height = height
    ctx = cropped.getContext("2d")
    ctx.drawImage(@canvas, x, y, width, height, 0, 0, width, height)
    return new Image(cropped)   
  
  # Simple subtract algorithm to find the difference
  # between two images.
  subtract:(image) =>
    matrixOne = @getArray(); matrixTwo = image.getArray(); i = 0;
    while i < matrixOne.data.length
      matrixTwo.data[i] = @clamp(matrixTwo[i]-matrixOne.data[i])
      matrixTwo.data[i+1] = @clamp(matrixTwo.data[i+1]-matrixOne.data[i+1])
      matrixTwo.data[i+2] = @clamp(matrixTwo.data[i+2]-matrixOne.data[i+2])
      i += 4
    return new Image(matrixTwo)

  # Simple subtract algorithm to find the difference
  # between two images.
  add:(image) =>
    matrixOne = @getArray(); matrixTwo = image.getArray(); i = 0;
    while i < matrixOne.data.length
      matrixTwo.data[i] = @clamp(matrixTwo[i]+matrixOne.data[i])
      matrixTwo.data[i+1] = @clamp(matrixTwo.data[i+1]+matrixOne.data[i+1])
      matrixTwo.data[i+2] = @clamp(matrixTwo.data[i+2]+matrixOne.data[i+2])
      i += 4
    return new Image(matrixTwo)

  mult:(image) =>
    matrixOne = @getArray(); matrixTwo = image.getArray(); i = 0;
    while i < matrixOne.data.length
      matrixTwo.data[i] = @clamp(matrixTwo[i]*matrixOne.data[i])
      matrixTwo.data[i+1] = @clamp(matrixTwo.data[i+1]*matrixOne.data[i+1])
      matrixTwo.data[i+2] = @clamp(matrixTwo.data[i+2]*matrixOne.data[i+2])
      i += 4
    return new Image(matrixTwo)

  lighten:(n=8) =>
    matrixOne = @getArray(); i = 0;
    while i < matrixOne.data.length
      matrixOne.data[i] = @clamp(matrixOne.data[i]+n)
      matrixOne.data[i+1] = @clamp(matrixOne.data[i+1]+n)
      matrixOne.data[i+2] = @clamp(matrixOne.data[i+2]+n)
      i += 4
    return new Image(matrixOne)

  darken:(n=8) =>
    matrixOne = @getArray(); i = 0;
    while i < matrixOne.data.length
      matrixOne.data[i] = @clamp(matrixOne.data[i]-n)
      matrixOne.data[i+1] = @clamp(matrixOne.data[i+1]-n)
      matrixOne.data[i+2] = @clamp(matrixOne.data[i+2]-n)
      i += 4
    return new Image(matrixOne)

# Simple subtract algorithm to find the difference
  # between two images.
  subtract:(image) =>
    matrixOne = @getArray(); matrixTwo = image.getArray(); i = 0;
    while i < matrixOne.data.length
      matrixTwo.data[i] -= matrixOne.data[i];
      matrixTwo.data[i+1] -= matrixOne.data[i+1];
      matrixTwo.data[i+2] -= matrixOne.data[i+2];
      i += 4
    return new Image(matrixTwo)

  
  
  # Simple multiply algorithm to increase saturation
  # in the image. First subtracts a grey level and
  # then multiplies by a factor.
  saturate:(factor=250/200) =>
    matrix = @getArray(); i = 0;
    while i < matrix.data.length
      matrix.data[i] -= 50; matrix.data[i] *= factor
      matrix.data[i+1] -= 50; matrix.data[i+1] *= factor
      matrix.data[i+2] -= 50; matrix.data[i+2] *= factor
      i += 4
    return new Image(matrix)
  
  # Simple grayscale algorithm. Had to create our
  # own because the cv.js library actually down-
  # samples the image by 4x.
  grayscale:() =>
    matrix = @getArray(); i = 0;
    while i < matrix.data.length
      avg = (matrix.data[i] + matrix.data[i+1] + matrix.data[i+2]) / 3
      matrix.data[i] = matrix.data[i+1] = matrix.data[i+2] = avg
      i += 4
    return new Image(matrix)

  # Return a gray matrix suitable for grayscale cv operations.
  getGrayArray:() =>
    matrix = @getArray(); out = []
    i = 0;
    while i < matrix.data.length
      avg = (matrix.data[i] + matrix.data[i+1] + matrix.data[i+2]) / 3
      out.push avg
      i += 4
    return out
       
  getGrayMatrix:() =>
    result = []; x = [];
    matrix = @ctx.getImageData(0,0,@width,@height)
    i = 0; a = 1;
    while i < matrix.data.length
      avg = (matrix.data[i] + matrix.data[i+1] + matrix.data[i+2]) / 3
      x.push [avg]    
      i += 4
      if a is @width
        result.push x; x = []; a = 1
      else
        a++
    return result

  # Alias to the cv.js library's binarize function.
  # We pass in our image and give it a threshold.
  binarize:(threshold=-1) =>
    matrix = @getArray()
    if threshold is -1 then threshold = CV.otsu(matrix);
    return new Image(CV.threshold(matrix, matrix, threshold))

  # Simple function to invert the pixels in an image.
  invert:() =>
    matrix = @getArray(); i = 0;
    while i < matrix.data.length
      matrix.data[i] = 255 - matrix.data[i]
      matrix.data[i+1] = 255 - matrix.data[i+1]
      matrix.data[i+2] = 255 - matrix.data[i+2]
      i += 4
    return new Image(matrix)   
 
  # Returns a greyscale image where black represents
  # exact color match and white represents an opposite
  # hue.
  hueDistance:(matchHue) =>
    matrix = @getArray(); i = 0;
    while i < matrix.data.length
      hsv = Color.RGBtoHSV(matrix.data[i], matrix.data[i+1], matrix.data[i+2])
      if hsv[2]<40
        matrix.data[i] = matrix.data[i+1] = matrix.data[i+2] = 255
      else
        pixelHue = hsv[0]
        lowerHue = (if pixelHue > matchHue then matchHue else pixelHue)
        higherHue = (if pixelHue > matchHue then pixelHue else matchHue)
        d1 = higherHue - lowerHue
        d2 = lowerHue + 361 - higherHue
        distance = (if d1 > d2 then d2 else d1)
        matrix.data[i] = matrix.data[i+1] = matrix.data[i+2] = 255 * (distance / 360)
      i += 4
    return new Image(matrix)

  cvGray2RGB:(input) =>
    # CV.js does some crazy stuff to make a grayscale image
    # Instead of making an array that is the same size as the
    # image but only has one channel, it takes a three channel
    # image and shoves the grayscale values into the first third
    # of the array. So for example, if you have a 10x10pixel image
    # the grayscale image is 300bytes long, but only the first
    # 100 bytes are used for the gray image. This method 
    # unpacks the first hundred bytes and adds sets each 
    # channel of the image to the gray value. If you neglect
    # to do this you get a gray image where there are four smaller
    # images along the top 1/3 of the image.
    #
    out = @getArray()
    a = 0
    b = 0
    while a < out.data.length
      out.data[a] = input.data[b]
      out.data[a+1] = input.data[b]
      out.data[a+2] = input.data[b]
      a = a + 4
      b = b + 1
    return new Image(out)
    
  getRChannel:() =>
    # Get the red channel as a grayscale rgb image.
    retVal = @getArray()
    a = 0
    b = 0
    while a < retVal.data.length
      val = retVal.data[a]
      retVal.data[a+1] = val
      retVal.data[a+2] = val
      a = a + 4
    return new Image(retVal)

  getGChannel:() =>
    # Get the green channel as a grayscale rgb image.
    retVal = @getArray()
    a = 0
    b = 0
    while a < retVal.data.length
      val = retVal.data[a+1]
      retVal.data[a] = val
      retVal.data[a+2] = val
      a = a + 4
    return new Image(retVal)

  getBChannel:() =>
    # Get the blue channel as a grayscale rgb image.
    retVal = @getArray()
    a = 0
    while a < retVal.data.length
      val = retVal.data[a+2]
      retVal.data[a] = val
      retVal.data[a+1] = val
      a = a + 4
    return new Image(retVal)

  split:() =>
    # Split the image into each of its three channels return a list
    return [@getRChannel(),@getGChannel(),@getBChannel()]

  merge:(r,g,b) =>
    # Merge rgb images of the channels into one image
    if( r.width isnt @width or r.height isnt @height or \
        g.width isnt @width or g.height isnt @height or \
        b.width isnt @width or b.height isnt @height )
      throw 'Sorry - I can\'t merge images of different sizes' 

    retVal = @getArray()
    rp = r.getArray()
    gp = g.getArray()
    bp = b.getArray()
    i = 0
    while i < retVal.data.length
      retVal.data[i] = rp.data[i]
      retVal.data[i+1] = gp.data[i+1]
      retVal.data[i+2] = bp.data[i+2]
      i = i + 4
    return new Image(retVal)

  mergeCVGray:(r,g,b) =>
    #merge r,g,b cvGray Images into an rgb image. 
    out = @getArray()
    i = 0
    j = 0
    while i < out.data.length
      out.data[i] = r.data[j]
      out.data[i+1] = g.data[j]
      out.data[i+2] = b.data[j]
      i = i + 4
      j = j + 1
    return new Image(out)

  dilate:(iterations=1,grayscale=false)=>
    if( iterations < 1 )
      iterations = 1
    border = 1
    w = @width+(2*border)
    h = @height+(2*border) 
    istart = border
    istop = border+@width-1
    jstart = border
    jstop = border+@height-1

    if( grayscale )
      out = @cloneGrayWithBorder(border)
      temp = @cloneGrayWithBorder(border)
      #istart = istart + 1    
      for k in [1..iterations]
        for j in [jstart..jstop] #Y
          for i in [istart..istop] #X
            a = temp[((j-1)*w)+((i+1))]
            b = temp[((j-1)*w)+((i  ))]
            c = temp[((j-1)*w)+((i-1))]
            d = temp[((j)*w)+  ((i+1))]
            e = temp[((j)*w)+  ((i  ))]
            f = temp[((j)*w)+  ((i-1))]
            g = temp[((j+1)*w)+((i+1))]
            h = temp[((j+1)*w)+((i  ))]
            l = temp[((j+1)*w)+((i-1))]
            r = Math.max(a,b,c,d,e,f,g,h,l)
            out[(j*w)+(i)] = r
        if( iterations > 1 )
          for m in [0..temp.length]
            temp[m]=out[m]
      return  @cropBorderCopyGray(out,border)
    else
      out = @cloneWithBorder(border)
      temp = @cloneWithBorder(border)
      bpp = 4
      for k in [1..iterations]
        for j in [jstart..jstop] #Y
          for i in [istart..istop] #X
            for offset in [0..2]
              a = temp[offset+(bpp*(j-1)*w)+(bpp*(i+1))]
              b = temp[offset+(bpp*(j-1)*w)+(bpp*(i  ))]
              c = temp[offset+(bpp*(j-1)*w)+(bpp*(i-1))]
              d = temp[offset+(bpp*(j)*w)+  (bpp*(i+1))]
              e = temp[offset+(bpp*(j)*w)+  (bpp*(i  ))]
              f = temp[offset+(bpp*(j)*w)+  (bpp*(i-1))]
              g = temp[offset+(bpp*(j+1)*w)+(bpp*(i+1))]
              h = temp[offset+(bpp*(j+1)*w)+(bpp*(i  ))]
              l = temp[offset+(bpp*(j+1)*w)+(bpp*(i-1))]
              r = Math.max(a,b,c,d,e,f,g,h,l)
              out[offset+(bpp*j*w)+(bpp*i)] = r
        if( iterations > 1 )
          for m in [0..temp.length]
            temp[m]=out[m]
      return @cropBorderCopy(out,border)


  erode:(iterations=1,grayscale=false)=>
    if( iterations < 1 )
      iterations = 1
    border = 1
    w = @width+(2*border)
    h = @height+(2*border) 
    istart = border
    istop = border+@width-1
    jstart = border
    jstop = border+@height-1

    if( grayscale )
      out = @cloneGrayWithBorder(border)
      temp = @cloneGrayWithBorder(border)
      #istart = istart + 1    
      for k in [1..iterations]
        for j in [jstart..jstop] #Y
          for i in [istart..istop] #X
            a = temp[((j-1)*w)+((i+1))]
            b = temp[((j-1)*w)+((i  ))]
            c = temp[((j-1)*w)+((i-1))]
            d = temp[((j)*w)+  ((i+1))]
            e = temp[((j)*w)+  ((i  ))]
            f = temp[((j)*w)+  ((i-1))]
            g = temp[((j+1)*w)+((i+1))]
            h = temp[((j+1)*w)+((i  ))]
            l = temp[((j+1)*w)+((i-1))]
            r = Math.min(a,b,c,d,e,f,g,h,l)
            out[(j*w)+(i)] = r
        if( iterations > 1 )
          for m in [0..temp.length]
            temp[m]=out[m]
      return  @cropBorderCopyGray(out,border)
    else
      out = @cloneWithBorder(border)
      temp = @cloneWithBorder(border)
      bpp = 4
      for k in [1..iterations]
        for j in [jstart..jstop] #Y
          for i in [istart..istop] #X
            for offset in [0..2]
              a = temp[offset+(bpp*(j-1)*w)+(bpp*(i+1))]
              b = temp[offset+(bpp*(j-1)*w)+(bpp*(i  ))]
              c = temp[offset+(bpp*(j-1)*w)+(bpp*(i-1))]
              d = temp[offset+(bpp*(j)*w)+  (bpp*(i+1))]
              e = temp[offset+(bpp*(j)*w)+  (bpp*(i  ))]
              f = temp[offset+(bpp*(j)*w)+  (bpp*(i-1))]
              g = temp[offset+(bpp*(j+1)*w)+(bpp*(i+1))]
              h = temp[offset+(bpp*(j+1)*w)+(bpp*(i  ))]
              l = temp[offset+(bpp*(j+1)*w)+(bpp*(i-1))]
              r = Math.min(a,b,c,d,e,f,g,h,l)
              out[offset+(bpp*j*w)+(bpp*i)] = r
        if( iterations > 1 )
          for m in [0..temp.length]
            temp[m]=out[m]
      return @cropBorderCopy(out,border)

  #Does an erosion of the dilation of the image (see: http://en.wikipedia.org/wiki/Closing_(morphology))
  closing:(iterations=1,grayscale=false)=>
    dilation = @dilate(iterations, grayscale)
    return dilation.erode(iterations, grayscale)

  #Does an dilation of the erosion of the image (see: http://en.wikipedia.org/wiki/Opening_(morphology))
  opening:(iterations=1,grayscale=false)=>
    erosion = @erode(iterations, grayscale)
    return erosion.dilate(iterations, grayscale)
      
  edges:()=>
    # so this is just the sobel magnitude. if we were really
    # cool we would do it in floating point and scale it to
    # the maximum. 
    ximg = @sobelX()
    yimg = @sobelY()
    out = @getArray()
    xv = ximg.getArray()
    yv = yimg.getArray()
    for i in [0..xv.data.length]
      d = Math.sqrt((xv.data[i]*xv.data[i])+(yv.data[i]*yv.data[i]))
      out.data[i] = @clamp(d) # we reall should scale versus clamp
    return new Image(out)

  # Returns an object with both magnitudes and directions of its edges.
  # More info at http://en.wikipedia.org/wiki/Sobel_operator#Formulation
  getEdgesInfo:()=>
    x = @sobelX().getArray()
    y = @sobelY().getArray()
    result = {}
    result.magnitudes = []
    result.directions = []
    for i in [0..x.data.length]
      result.magnitudes.push(Math.sqrt(Math.pow(x.data[i],2)+Math.pow(y.data[i],2)))
      result.directions.push(Math.atan(y.data[i]/x.data[i]))
    return result  
     
  sobelY:(grayscale=false)=>
    kernel = [[-1.0,0.0,1.0],[-2.0,0.0,2.0],[-1.0,0.0,1.0]]
    return @kernel3x3(kernel,grayscale)

  sobelX:(grayscale=false)=>
    kernel = [[-1.0,-2.0,-1.0],[0.0,0.0,0.0],[1.0,2.0,1.0]]
    return @kernel3x3(kernel,grayscale)
    
  kernel3x3:(kernel,grayscale)=>
    border = 1
    w = @width+(2*border)
    h = @height+(2*border) 
    istart = border
    istop = border+@width-1
    jstart = border
    jstop = border+@height-1

    if( grayscale )
      out = @cloneGrayWithBorder(border)
      temp = @cloneGrayWithBorder(border)
      #istart = istart + 1  
      for j in [jstart..jstop] #Y
        for i in [istart..istop] #X
          vals = []
          vals.push(temp[((j-1)*w)+((i+1))]*kernel[0][0])
          vals.push(temp[((j-1)*w)+((i  ))]*kernel[0][1])
          vals.push(temp[((j-1)*w)+((i-1))]*kernel[0][2])
          vals.push(temp[((j)*w)+  ((i+1))]*kernel[1][0])
          vals.push(temp[((j)*w)+  ((i  ))]*kernel[1][1])
          vals.push(temp[((j)*w)+  ((i-1))]*kernel[1][2])
          vals.push(temp[((j+1)*w)+((i+1))]*kernel[2][0])
          vals.push(temp[((j+1)*w)+((i  ))]*kernel[2][1])
          vals.push(temp[((j+1)*w)+((i-1))]*kernel[2][2])
          acc = 0
          for v in vals
            acc += v          
          out[(j*w)+(i)] = @clamp(Math.abs(acc))
      return  @cropBorderCopyGray(out,border)
    else
      out = @cloneWithBorder(border)
      temp = @cloneWithBorder(border)
      bpp = 4
      for j in [jstart..jstop] #Y
        for i in [istart..istop] #X
          for offset in [0..2]
            vals = []
            vals.push(temp[offset+(bpp*(j-1)*w)+(bpp*(i+1))]*kernel[0][0])
            vals.push(temp[offset+(bpp*(j-1)*w)+(bpp*(i  ))]*kernel[0][1])
            vals.push(temp[offset+(bpp*(j-1)*w)+(bpp*(i-1))]*kernel[0][2])
            vals.push(temp[offset+(bpp*(j)*w)+  (bpp*(i+1))]*kernel[1][0])
            vals.push(temp[offset+(bpp*(j)*w)+  (bpp*(i  ))]*kernel[1][1])
            vals.push(temp[offset+(bpp*(j)*w)+  (bpp*(i-1))]*kernel[1][2])
            vals.push(temp[offset+(bpp*(j+1)*w)+(bpp*(i+1))]*kernel[2][0])
            vals.push(temp[offset+(bpp*(j+1)*w)+(bpp*(i  ))]*kernel[2][1])
            vals.push(temp[offset+(bpp*(j+1)*w)+(bpp*(i-1))]*kernel[2][2])
            acc = 0
            for v in vals
              acc += v          
            out[offset+(bpp*j*w)+(bpp*i)] = @clamp(Math.abs(acc))
      return @cropBorderCopy(out,border)

              
  clamp:(x,max=255,min=0) =>
    return Math.max(min, Math.min(max, x))    

  # Adds a border to the image for convolutions, etc
  cloneWithBorder:(borderSz) ->
    bpp = 4 
    oldSz = @width*@height*bpp
    rgbBorderSz = bpp*borderSz
    top = borderSz*((@width*bpp)+(borderSz*2*bpp))
    bottom = borderSz*((@width*bpp)+(borderSz*2*bpp))
    sides = 2*bpp*borderSz*@height
    newSize = oldSz+top+bottom+sides
    temp = new Uint8Array(newSize)
    idx = 0
    start = top+rgbBorderSz-1
    stop = top+sides+oldSz-1
    old = @getArray()
    rowStop = start+(@width*bpp)
    update = (@width*bpp)+(2*rgbBorderSz)
    i = start
    while i < stop
      temp[++i] = old.data[idx++]
      temp[++i] = old.data[idx++]
      temp[++i] = old.data[idx++]
      temp[++i] = old.data[idx++]
      if i == rowStop 
        i = i + (2*rgbBorderSz)
        rowStop = rowStop+update
    return temp

  # Adds a border to the image for convolutions, etc (grayscale)
  cloneGrayWithBorder:(borderSz) ->
    bpp = 4
    oldSz = @width*@height*bpp
    rgbBorderSz = bpp*borderSz
    top = borderSz*(@width+(borderSz*2))
    bottom = borderSz*(@width+(borderSz*2))
    sides = 2*borderSz*@height
    newSize = oldSz+top+bottom+sides
    temp = new Uint8Array(newSize)
    idx = 0
    start = top
    stop = top+sides+oldSz
    old = @getArray()
    rowStop = start+(@width)
    update = (@width)+(2*borderSz)
    i = start
    while i < stop
      temp[++i] = (old.data[idx] + old.data[idx+1] + old.data[idx+2]) / 3
      idx += 4
      if i == rowStop 
        i = i + (2*borderSz)
        rowStop = rowStop+update
    return temp

  # Takes a border image, crops out the border and returns the image (grayscale)
  cropBorderCopyGray:(img,borderSz) ->
    bpp = 4
    oldSz = @width*@height*bpp
    rgbBorderSz = bpp*borderSz
    top = borderSz*((@width)+(borderSz*2))
    bottom = borderSz*(@width+(borderSz*2))
    sides = 2*borderSz*@height
    newSize = oldSz+top+bottom+sides

    start = top+1
    stop = top+sides+oldSz
    output = @getArray()
    rowStop = start+(@width)
    update = (@width)+(2*borderSz)
    i = start
    idx = 0
    while i < stop
      output.data[idx++] = img[i]
      output.data[idx++] = img[i]
      output.data[idx++] = img[i]
      output.data[idx++] = 255
      i = i + 1
      if i >= rowStop 
        i = i + (2*borderSz)
        rowStop = rowStop+update
    return new Image(output)
  
  # Takes a border image, crops out the border and returns the image      
  cropBorderCopy:(img,borderSz) =>
    bpp = 4
    oldSz = @height*@width*bpp
    rgbBorderSz = bpp*borderSz
    top = borderSz*((@width*bpp)+(borderSz*2*bpp))
    bottom = borderSz*((@width*bpp)+(borderSz*2*bpp))
    sides = 2*bpp*borderSz*@height
    oldSz = bpp*@width*@height
    idx = 0
    start = top+rgbBorderSz
    stop = top+sides+oldSz
    output = @getArray()
    rowStop = start+(@width*bpp)
    update = @width*bpp+(2*rgbBorderSz)
    i = start
    while i < stop
      output.data[idx++] = img[i++]
      output.data[idx++] = img[i++]
      output.data[idx++] = img[i++]
      output.data[idx++] = img[i++]
      if i >= rowStop 
        i = i + (2*rgbBorderSz)
        rowStop = rowStop+update
    return new Image( output)
      
  blur:(kernel_sz, gray=true) =>
    # Do a gaussian blur, 
    # the kernel must be odd
    if( kernel_sz <= 0)
      kernel_sz = 1
    if( kernel_sz%2== 0)
      kernel_sz += 1 # only odd values
    if( gray )
      gray1 = @getArray()
      gray1 = CV.grayscale(gray1,gray1);
      out = CV.gaussianBlur(gray1,gray1,gray1,kernel_sz)
      return @cvGray2RGB(out)
    else
      chans = @split()
      r = chans[0].getArray()
      r = CV.grayscale(r,r)
      r = CV.gaussianBlur(r,r,r,kernel_sz)
      g = chans[1].getArray()
      g = CV.grayscale(g,g)
      g = CV.gaussianBlur(g,g,g,kernel_sz)
      b = chans[2].getArray()
      b = CV.grayscale(b,b)
      b = CV.gaussianBlur(b,b,b,kernel_sz)
      return @mergeCVGray(r,g,b)

  crop:(x,y,w,h)=>
    # we'll try and do what the user wants, not what they say
    if( x < 0 )
      alert("Crop: your crop x position is negative.")
      w = w+x
      x = 0
    if( y < 0 )
      alert("Crop: your crop y position is negative.")
      h = h+y
      y = 0
    if( x+w > @width )
      alert("Crop: your crop width exceeds the image dimensions.")
      w = @width-x
    if( y+h > @height )
      alert("Crop: your crop height exceeds the image dimensions.")
      h = @height-y
    return new Image( @ctx.getImageData(x,y,w,h) )

  blit:(img,x=0,y=0,alpha=255,mask=undefined) =>
    retVal = undefined
    if( x+img.width >= @width or y+img.height >= @height )
      alert("blit - your image is too big to blit directly - crop it down please.")
    if( x < 0 or y < 0 )
      alert("blit - can't blit image at a negative position.")      
    bpp = 4
    if( alpha >= 255 and !mask)
      retVal = new Image(@ctx.getImageData(0,0,@width,@height))
      retVal.ctx.putImageData(img.getArray(),x,y)
    else
      start = ((y*@width)+x)*bpp
      stop = (((y+img.height)*@width)-(@width-x-img.width))*bpp
      rowStop = start + ((img.width)*bpp) # when to stop the row
      rowSkip = ((@width-x-img.width)+x)*bpp # where to start the new row
      rowUpdate = img.width*bpp
      src = img.getArray()
      i = 0
      idx = start
      dst = @getArray()
      if( alpha < 255 and !mask)
      # so canvas alpha channels are totally for stacking
      # and completely useless for this kind of stuff
        a = alpha / 255.0
        b = (255-alpha) / 255.0
        while( idx < stop )
          dst.data[idx] = b*dst.data[idx]+a*src.data[i]
          dst.data[idx+1] = b*dst.data[idx+1]+a*src.data[i+1]
          dst.data[idx+2] = b*dst.data[idx+2]+a*src.data[i+2]
          if(idx>=rowStop)
            idx+=rowSkip
            rowStop=rowStop+rowSkip+rowUpdate
          else
            idx += 4
            i += 4        
        retVal = new Image(dst)
      else if( alpha >= 255 and mask)
        maskArray = mask.getArray()
        while( idx < stop )
          if( maskArray.data[i] > 0 )
            dst.data[idx] = src.data[i]
            dst.data[idx+1] = src.data[i+1]
            dst.data[idx+2] = src.data[i+2]
          if(idx>=rowStop)
            idx+=rowSkip
            rowStop=rowStop+rowSkip+rowUpdate
          else
            idx += 4
            i += 4        
        retVal = new Image(dst)
      else if( alpha < 255 and mask )
        a = alpha / 255.0
        b = (255-alpha) / 255.0
        maskArray = mask.getArray()
        while( idx < stop )
          if(maskArray.data[i])
            dst.data[idx] = b*dst.data[idx]+a*src.data[i]
            dst.data[idx+1] = b*dst.data[idx+1]+a*src.data[i+1]
            dst.data[idx+2] = b*dst.data[idx+2]+a*src.data[i+2]
          if(idx>=rowStop)
            idx+=rowSkip
            rowStop=rowStop+rowSkip+rowUpdate
          else
            idx += 4
            i += 4        
        retVal = new Image(dst)
    return retVal

  canny:(highThreshold = 60, lowThreshold = 30, kernel_size = 5)=>
    ######################################################################################################################################
    #The Canny edge detector is an edge detection operator that uses a multi-stage algorithm to detect a wide range of edges in images. 
    #The Algorithm is as follows  
    #1. Smooth the image with gaussian blur  
    #2. Obtain gradients in x and y directions by convoluting with sobel kernels   
    #3. Obtain edgestrengths  G = ((G(x)^2+G(y)^2))^1/2  and edge directions  theta = arctan(G(y)/G(x))
    #4. After the above step we do something called non maximum suppression . i.e looking for peaks by comparing the edge strengths
    #   of  the corresponding pixels in the 8-pixel neighbourhood. 
    #5. Now we have possible edge points and we also have false edge points that we dont really need. so as to obtain true edges
    #   we do double thresholding. we choose two threshold values highThreshold and lowThreshold. the peaks which are true and  
    #   have corresponding edge strengths greater than highThreshold . they are marked true in the final edge matrix. the peaks which have 
    #   edge strengths lower than lowThreshold are marked false and they are not included in the final edge matrix. 
    #6. The remaining peaks whose edge strengths are in betweeen highThreshold and lowThreshold we check the 8-pixel neighbourhood and if it has 
    #   a true edge point in that area then we make it true. this is also known as edge linking.
    #7. Finally we printout black pixel where final edge points dont exist (or false) and white pixel if they are true
    #
    #The arguments to this method are given below:
    #
    # highThreshold = the higher threshold value for high thresholding
    #
    # lowThreshold  = the low threshold value for low thresholding
    #
    # kernel_size   = the specified size for gaussian smoothing kernel , it must be odd.
    ######################################################################################################################################

    blurIm = @blur(kernel_size,false)#smoothing the image to reduce noise
    gradientX = blurIm.getGrayArray()#initializing gradient matrices for both x and y directions and temp matrices for convolution 
    tempX = blurIm.getGrayArray()
    gradientY = blurIm.getGrayArray()
    tempY = blurIm.getGrayArray()
    kernelX = [[-1.0,0.0,1.0],[-2.0,0.0,2.0],[-1.0,0.0,1.0]]#the sobel kernels
    kernelY = [[1.0,2.0,1.0],[0.0,0.0,0.0],[-1.0,-2.0,-1.0]]
    for j in [1..@width-2] # convolution to obtain the gradients
      for i in [1..@width-2] #
        valsX = []
        valsX.push(tempX[((j-1)*(@width))+((i+1))]*kernelX[2][0])
        valsX.push(tempX[((j-1)*(@width))+((i  ))]*kernelX[1][0])
        valsX.push(tempX[((j-1)*(@width))+((i-1))]*kernelX[0][0])
        valsX.push(tempX[((j)*(@width ))+  ((i+1))]*kernelX[2][1])
        valsX.push(tempX[((j)*(@width ))+  ((i  ))]*kernelX[1][1])
        valsX.push(tempX[((j)*(@width ))+  ((i-1))]*kernelX[0][1])
        valsX.push(tempX[((j+1)*(@width))+((i+1))]*kernelX[2][2])
        valsX.push(tempX[((j+1)*(@width))+((i  ))]*kernelX[1][2])
        valsX.push(tempX[((j+1)*(@width))+((i-1))]*kernelX[0][2])
        accX = 0
        for v in valsX
          accX += v          
        gradientX[(j*(@width))+(i)] = accX
        
        valsY = []
        valsY.push(tempY[((j-1)*(@width))+((i+1))]*kernelY[2][0])
        valsY.push(tempY[((j-1)*(@width))+((i  ))]*kernelY[1][0])
        valsY.push(tempY[((j-1)*(@width))+((i-1))]*kernelY[0][0])
        valsY.push(tempY[((j)*(@width ))+  ((i+1))]*kernelY[2][1])
        valsY.push(tempY[((j)*(@width ))+  ((i  ))]*kernelY[1][1])
        valsY.push(tempY[((j)*(@width ))+  ((i-1))]*kernelY[0][1])
        valsY.push(tempY[((j+1)*(@width ))+((i+1))]*kernelY[2][2])
        valsY.push(tempY[((j+1)*(@width ))+((i  ))]*kernelY[1][2])
        valsY.push(tempY[((j+1)*(@width ))+((i-1))]*kernelY[0][2])
        accY = 0
        for v in valsY
          accY += v          
        gradientY[(j*(@width))+(i)] = accY
    edge_strength = []# initializing local matrices for use in the algorithm , edge_strength for calculationg edgestrengths
    peaks = []# peaks for calculating the local maxima(possible edge points)
    angle = []# angle for calculating the edge directions
    x = []    #temporary arrays
    inter = []
    inter1 = []
    for i in [0..@height-1]#pushing zeroes into peaks
      for j in [0..@width-1]
        x.push 0
      peaks.push x
      x = []
    out = @getArray()#the original image characteistic array used for output
    b = 0
    for i in [0..@height-1]# calculation of edge strengths and pushing them into a temporary array and then pushing temp to edge_strength
      for j in [0..@width-1]# calculation of edge directions and pushing them into a temp array and then pushing temp to angle 
        d = Math.sqrt((gradientX[b]*gradientX[b] + gradientY[b]*gradientY[b]))
        s = Math.round(d)
        inter.push s
        if (gradientX[b] == 0)
          if (gradientY[b] >= 0)
            inter1.push 90
          else
            inter1.push -90
        else
          k = Math.atan((gradientY[b])/(gradientX[b]))*57.295
          inter1.push k
        b+= 1
      edge_strength.push inter
      angle.push inter1
      inter = []
      inter1 = []
    for i in [1..@height-2]# non maximum suppression , we basically look for the pixels in the edge direction and compare with them 
      for j in [1..@width-2]#to obtain peaks
        if(angle[i][j] < 22.5 and angle[i][j] >= -22.5)
          if(edge_strength[i][j] > Math.max(edge_strength[i][j-1],edge_strength[i][j+1]))
            peaks[i][j] = 1
          else
            peaks[i][j] = 0
        if(angle[i][j] < 67.5 and angle[i][j] >= 22.5)
          if(edge_strength[i][j] > Math.max(edge_strength[i+1][j-1],edge_strength[i-1][j+1]))
            peaks[i][j] = 1
          else
            peaks[i][j] = 0
        if(angle[i][j] < -22.5 and angle[i][j] >= -67.5)
          if(edge_strength[i][j] > Math.max(edge_strength[i-1][j-1],edge_strength[i+1][j+1]))
            peaks[i][j] = 1
          else
            peaks[i][j] = 0
        else
          if(edge_strength[i][j] > Math.max(edge_strength[i-1][j],edge_strength[i+1][j]))
            peaks[i][j] = 1
          else
            peaks[i][j] = 0
    y = []
    final = [] #final array , used for final peaks after hysterisis thresholding
    for i in [0..@height-1]
      for j in [0..@width-1]
        y.push 0
      final.push y
      y = []
    for i in [1..@height-2]# high thresholding , marking all existing peaks in final false if they are lower than highThreshold 
      for j in [1..@width-2]# and true if they are higher than it
        if(peaks[i][j] == 1 and edge_strength[i][j] > highThreshold)
          peaks[i][j] = 0
          final[i][j] = 1
        if(peaks[i][j] == 0 and edge_strength[i][j] < lowThreshold)
          peaks[i][j] = 0
          final[i][j] = 0
    flag = 1
    while(flag == 1)# a simple way of low thresholding i.e for the values less than high threshold and greater than low threshold 
      flag = 0      # also known as edge linking
      for i in [1..@height-2]
        for j in [1..@width-2]
          if (peaks[i][j] == 1)
            for p in [-1..1]
              for q in [-1..1]
                if(final[i+p][j+q] == 1)
                  final[i][j] = 1
                  peaks[i][j] = 0
                  flag = 1
    a = 0
    for i in [0..@height-1]# if in final , it is true print white pixel there 
      for j in [0..@width-1]# and if its not true print black pixel
        if (final[i][j] == 1)
          out.data[a] = 255
          out.data[a+1] = 255
          out.data[a+2] = 255
        else
          out.data[a] = 0
          out.data[a+1] = 0
          out.data[a+2] = 0
        a+= 4
    return new Image(out)     

  #posterize effect(cartooning effect) http://en.wikipedia.org/wiki/Posterization
  posterize:(adjust = 5)=>
    numOfAreas = 256 / adjust
    numOfValues = 255 / (adjust - 1)
    out = @getArray()
    posterize_LUT = @posterizeLUT(numOfAreas,numOfValues)
    i = 0
    while i < out.data.length
      r = out.data[i]
      g = out.data[i+1]
      b = out.data[i+2]
      out.data[i] = posterize_LUT[r]
      out.data[i+1] = posterize_LUT[g]
      out.data[i+2] = posterize_LUT[b]
      i+=4
    return new Image(out)

  #look up table for posterize
  posterizeLUT:(numOfAreas,numOfValues)=>
    result = []
    for i in [0..255]
      k = Math.floor Math.floor(i / numOfAreas) * numOfValues
      result.push k
    return result
  #a gamma filter ,http://en.wikipedia.org/wiki/Gamma_correction
  gamma:(gammanew = 2)=>
    out = @getArray()
    i = 0
    gamma_LUT = @gammaLUT(gammanew)
    while i < out.data.length
      r = out.data[i]
      g = out.data[i+1]
      b = out.data[i+2]
      out.data[i] = gamma_LUT[r]
      out.data[i+1] = gamma_LUT[g]
      out.data[i+2] = gamma_LUT[b]
      i+=4
    return new Image(out)
    
  #gamma look up table for increasing performance
  gammaLUT:(gammatemp)=>
    result = []
    for i in [0..255]
      b = i/255
      k = Math.round(255*(Math.pow(b,gammatemp)))
      result.push k
    return result

  # A sepia filter.
  sepia:(sepiaIntensity = 30)=>
    sepiaDepth = 20
    out = @getArray()
    i = 0
    while i < out.data.length
      r = out.data[i]
      g = out.data[i+1]
      b = out.data[i+2]
      a = out.data[i+3]
      avg = (r+g+b)/3
      r = @clamp(avg + (sepiaDepth*2))
      g = @clamp(avg + sepiaDepth)
      b = @clamp(avg - sepiaIntensity)
      out.data[i] = r
      out.data[i+1] = g
      out.data[i+2] = b
      i+=4
    return new Image(out)
    
  #This method changes an Image into an oilpainting.More info at http://supercomputingblog.com/graphics/oil-painting-algorithm/
  #Don't keep the radius more than 4. As you increase the radius the cost will increase
  #This Algorithm is slow , so lookout a little longer than usual for the result 
  oilpaint:(radius = 2,intensityLevels = 20)=>
    red = []; green = []; blue = []
    finalRed = []; finalGreen = []; finalBlue = []
    out = @getArray()
    x = []; y = []; z = []; f = [];g = []; h =[]
    a = 0;
    for i in [0..@height-1]
      for j in [0..@width-1]
        x.push out.data[a]
        f.push out.data[a]
        y.push out.data[a+1]
        g.push out.data[a+1]
        z.push out.data[a+2]
        h.push out.data[a+2]
        a+=4
      red.push x
      finalRed.push f
      green.push y
      finalGreen.push g
      blue.push z
      finalBlue.push h
      x = []; y = []; z = []; f = [];g = []; h =[]
    for i in [radius..@height-radius-1]
      for j in [radius..@width-radius-1]
        intensityCount = []; averageR = []; averageG = []; averageB = []
        for k in [0..intensityLevels]
          intensityCount.push 0
          averageR.push 0 
          averageG.push 0
          averageB.push 0
        for p in [(-radius)..radius]
          for q in [(-radius)..radius]
            d = (red[i+p][j+q]+green[i+p][j+q]+blue[i+p][j+q])/3
            curIntensity = Math.round ((d/255.0)*intensityLevels) 
            intensityCount[curIntensity]++
            averageR[curIntensity]+= red[i+p][j+q]
            averageG[curIntensity]+= green[i+p][j+q]
            averageB[curIntensity]+= blue[i+p][j+q]
        curMax = intensityCount[0]
        for r in [0..intensityLevels]
          if(intensityCount[r] > curMax)
            curMax = intensityCount[r]
            maxIndex = r
        finalRed[i][j] = averageR[maxIndex] / curMax
        finalGreen[i][j] = averageG[maxIndex] / curMax
        finalBlue[i][j] = averageB[maxIndex] / curMax
    b = 0
    for i in [0..@height-1]
      for j in [0..@width-1]
        out.data[b] = finalRed[i][j]
        out.data[b+1] = finalGreen[i][j]
        out.data[b+2] = finalBlue[i][j]
        b+=4
    return new Image(out)    

  #flips the image horizontally
  flipHorizontal:()=>
    flipped = document.createElement("canvas")
    flipped.width = @width
    flipped.height = @height
    ct = flipped.getContext("2d")
    ct.translate(@width,0)
    ct.scale(-1,1)
    ct.drawImage(@canvas, 0, 0)
    return new Image(flipped)    

  #flips image vertically
  flipVertical:()=>
    flipped = document.createElement("canvas")
    flipped.width = @width
    flipped.height = @height
    ct = flipped.getContext("2d")
    ct.scale(1,-1)
    ct.drawImage(@canvas, 0, -@height)
    return new Image(flipped)
    
  #this is a basic face detection method which when used with image like this
  #faces  = i.getFaces()
  #gives a set of faces 
  getFaces:()=>
    comp = ccv.detect_objects({"canvas" : (@canvas),"cascade" : cascade,"interval" : 5,"min_neighbors" : 1})
    return comp
  
  #simple stretch function , takes in two thresholds and sets all the values between 0 and lowthreshold to 0 and
  #sets all the values between high and 255 into 255 
  #returns a grayscale image
  #i.stretch(low,high) .. low shoul be less than high to get the desired effect
  stretch:(low=50,high=100)=>
    gray = @getGrayArray()
    out  = @getArray()
    i    = 0
    a    = 0
    while(i < gray.length)
      if(gray[i] < low)
        out.data[a] = 0; out.data[a+1] =0; out.data[a+2] = 0
      if(gray[i] > high)
        out.data[a] = 255; out.data[a+1] = 255; out.data[a+2] = 255
      else
        out.data[a] = out.data[a+1] = out.data[a+2] = gray[i]
      i+=1
      a+=4
    return new Image(out)
  
  #Draws a rectangular box in the image . the default drawing mode being from the corner.
  drawRect:(x,y,width,height)=>
    dl = @addDrawingLayer()
    dl.noFill()
    dl.rect(x,y,width,height)
    return @
    
  #Draws a line from (x1,y1) to (x2,y2) 
  drawLine:(x1,y1,x2,y2)=>
    dl = @addDrawingLayer()
    dl.line(x1,y1,x2,y2)
    return @
  
  #Draws an ellipse centered at (x,y) with a height and width
  drawEllipse:(x,y,width,height)=>
    dl = @addDrawingLayer()
    dl.noFill()
    dl.ellipse(x,y,width,height)
    return @
    
  #Draws a circle with (x,y) as center with radius
  drawCircle:(x,y,radius)=>
    return @drawEllipse(x,y,radius,radius)
    
  #Draw a triangle with vertices (x1,y1) (x2,y2) (x3,y3)
  drawTriangle:(x1,y1,x2,y2,x3,y3)=>
    dl = @addDrawingLayer()
    dl.noFill()
    dl.triangle(x1, y1, x2, y2, x3, y3)
    return @
    
  #Introduces a noise by a random value in [min,max]
  noise:(min=1,max=100)=>
    rand = Math.round(Math.random() * (max-min)) + min
    im   = @getArray()    
    out  = @getArray()
    i = 0
    while i<im.data.length
      out.data[i] = @clamp(im.data[i]+rand)
      out.data[i+1]=@clamp(im.data[i+1]+rand)
      out.data[i+2]=@clamp(im.data[i+2]+rand)
      i+=4
    return new Image(out)
    
    
    
        
    
      
    



