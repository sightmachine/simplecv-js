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
  # getGrayArray:() =>
  #   matrix = @getArray();
  #   i = 0;
  #   while i < matrix.data.length
  #     avg = (matrix.data[i] + matrix.data[i+1] + matrix.data[i+2]) / 3
  #     matrix.data[i] = matrix.data[i+1] = matrix.data[i+2] = avg
  #     i += 4
  #   return matrix
       
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

  cloneWithBorder:(borderSz) =>
    #Add a border to the image for convoltuions etc
    # this should be private
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

  cloneGrayWithBorder:(borderSz) =>
    #Add a border to the image for convoltuions etc
    # this should be private
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

  cropBorderCopyGray:(img,borderSz) =>
    # take a border image, crop out the border
    # and return the image
    # this should be a private function.
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
        
  cropBorderCopy:(img,borderSz) =>
    # take a border image, crop out the border
    # and return the image
    # this should be a private function.
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

