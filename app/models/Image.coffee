module.exports = class Image extends Backbone.Model
  parent = null
  canvas = null
  ctx = null
  imgdata = null
  
  width = 0
  height = 0
  layers = null
  
  # Takes in a Canvas object, Array or Image.
  # In either case, the data is stored in canvas
  # and array form. 
  initialize:(data) =>
    @canvas = document.createElement("canvas")
    @layers = []
    
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
      @imgdata = data

    else if data instanceof HTMLImageElement
      @canvas.width = @width = data.width
      @canvas.height = @height = data.height
      @ctx = @canvas.getContext("2d")
      @ctx.drawImage(data, 0, 0)
      
    else
      #throw new Error "Unknown Image format \""+data.constructor+", try again"
  
  # Appends the canvas to parent element.
  # Defaults to appending it to the body.
  # If has been called before, ensure that
  # the canvas is visible.
  show:(container=$("body")) =>
    if parent is null
      $(container).html(@canvas)
      @parent = container
    else
      $(@canvas).show()
    return
      
  # Creates a new canvas and processing.js
  # wrapper to be stored in the layers array.
  addDrawingLayer:() =>
    canvas = document.createElement("canvas")
    canvas.width = @width
    canvas.height = @height
    
    pjs = new Processing(@$el.find("canvas").get 0)
    pjs.background(0,0)
    pjs.size @$el.width(), @model.get("height") * scale
    pjs.scale 1    
    
    @layers.push {canvas: canvas, processing: pjs}
    return canvas
    
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
   
  # Returns the image in a two dimensional array format
  # where each pixel is structured as [r, g, b, a].
  getMatrix:(safe=true) =>
    result = []; x = [];
    pixels = @ctx.getImageData(0,0,@width,@height)
    
    if(safe == false) then return pixels
     
    i = 0; a = 1
    while i < pixels.data.length
      x.push [pixels.data[i], pixels.data[i + 1], pixels.data[i + 2]]    
      i += 4

      if a is @width
        result.push x
        x = []
        a = 1
      else
        a++

    return result
  
  # Simple subtract algorithm to find the difference
  # between two images.
  subtract:(image) =>
    matrixOne = @getMatrix(false)
    matrixTwo = image.getMatrix(false)
    
    i = 0;
    while i < matrix.data.length
      matrixTwo.data[i] -= matrixOne.data[i];
      matrixTwo.data[i+1] -= matrixOne.data[i+1];
      matrixTwo.data[i+2] -= matrixOne.data[i+2];
      i += 4
      
    image = new Image(matrixTwo)
    return image    
  
  # Simple multiply algorithm to increase saturation
  # in the image. First subtracts a grey level and
  # then multiplies by a factor.
  saturate:(factor=250/170) =>
    matrix = @getMatrix(false)
    
    i = 0;
    while i < matrix.data.length
      matrix.data[i] -= 75; matrix.data[i] *= factor
      matrix.data[i+1] -= 75; matrix.data[i+1] *= factor
      matrix.data[i+2] -= 75; matrix.data[i+2] *= factor
      i += 4
      
    image = new Image(matrix)
    return image
  
  # Simple grayscale algorithm. Had to create our
  # own because the cv.js library actually down-
  # samples the image by 4x.
  grayscale:(threshold=128) =>
    matrix = @getMatrix(false)
    
    i = 0;
    while i < matrix.data.length
      avg = (matrix.data[i] + matrix.data[i+1] + matrix.data[i+2]) / 3
      matrix.data[i] = matrix.data[i+1] = matrix.data[i+2] = avg
      i += 4
      
    image = new Image(matrix)
    return image


  # Alias to the cv.js library's binarize function.
  # We pass in our image and give it a threshold.
  binarize:(threshold=128, otsu=false) =>
    matrix = @getMatrix(false)
    if otsu is true then threshold = CV.otsu(matrix); console.log(otsu)
    return new Image(CV.threshold(matrix, matrix, threshold))