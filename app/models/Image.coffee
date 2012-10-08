Color = require './Color'
Model = require './model'

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
  # In either case, the data is stored in canvas
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
  removeDrawingLayer:(layer=@layers.lenth-1) =>
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
  getMatrix: =>
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
  
  # Returns the image in a single dimensional array format
  # where the pixels go in r, g, b, a order.
  getArray:() =>
    matrix = @ctx.getImageData(0,0,@width,@height)
    return matrix
  
  # Simple image scale. Uses canvas to get this done
  # quickly. Returns a new image.
  scale:(factor) =>
    scaled = document.createElement("canvas")
    scaled.width = @width*factor
    scaled.height = @height*factor
    ctx = scaled.getContext("2d")
    ctx.drawImage(@canvas, 0, 0, @width*factor, @height*factor)
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