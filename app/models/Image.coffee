module.exports = class Image extends Backbone.Model
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
    @canvas = document.createElement("canvas")
    @ctx = @canvas.getContext("2d")
    @layers = []
    
    if data instanceof HTMLCanvasElement
        @canvas = data
        @width = data.width
        @height = data.height
        @matrix = @getMatrix()
        
    else if data instanceof HTMLImageElement
        @matrix = data
        @height = data.length
        @width = data[0].length
        @canvas.putImageData(data, 0, 0)
        
    else if data instanceof Array
        @canvas.width = @width = data.width
        @canvas.height = @height = data.height
        @ctx.drawImage(data, 0, 0)
        @matrix = @getMatrix()
  
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
  getMatrix:() =>
    return @ctx.createImageData(@width, @height);
  
  # Alias call to cv.js' threshold function which converts
  # the image into black and white based upon the specified
  # threshold that defaults to a middle value.
  binarize:(threshold=128) =>
    image = new Image(CV.threshold(@getMatrix(), threshold))
    return image