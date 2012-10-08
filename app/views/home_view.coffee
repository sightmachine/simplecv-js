View = require './view'
Camera = require '../models/Camera'
CVImage = require '../models/Image'
Color = require '../models/Color'
template = require './templates/home'

module.exports = class HomeView extends View
  id: 'home-view'
  template: template
  demoOne: null
  demoTwo: null
  demoThree: null
  editors: null
  
  initialize: =>
    @editors = []
    $(=>
        @demoOne = $("#demoOne .preview")
        @demoTwo = $("#demoTwo .preview")
        @demoThree = $("#demoThree .preview")
        @highlight()
        @kittyDemo()
        @cameraDemo()
        #@realTimeCamera()
    )
    return
  
  highlight: =>
    elements = $(".demo .code form textarea")
    for i in elements
      editor = CodeMirror.fromTextArea(i, {
        lineNumbers: true,
        readOnly: true,
        lineWrapping: true
      });
      editor.setOption("theme", "ambiance")
      @editors[_i] = editor
  
  # Displays a picture of a cat, the grey
  # version of it, and the binarized
  # version of it.
  kittyDemo:() =>
    one = $('<div class="cvImage"></div>').appendTo(@demoOne)
    two = $('<div class="cvImage"></div>').appendTo(@demoTwo)
    three = $('<div class="cvImage"></div>').appendTo(@demoThree)
    kitty = $("<img/>").attr("src", "images/kitty.jpg").get(0)
    kitty.onload = =>
      k = new CVImage(kitty)
      k1 = k.grayscale()
      k2 = k1.binarize()
      k.show(one)
      k1.show(two)
      k2.show(three)
    return

  # Displays a camera, 
  cameraDemo: =>
    c = new Camera();
    c.init(=>
      one = $('<div class="cvImage"></div>'); @demoOne.html(one)
      two = $('<div class="cvImage"></div>'); @demoTwo.html(two)
      three = $('<div class="cvImage"></div>'); @demoThree.html(three)
      
      @editors[0].setValue("""
Camera = require '../models/Camera'
container = $("body")
c = new Camera();
c.init =>
  setInterval(=>
    # Scaled Camera Shot
    me = c.getImage()
    me = me.scale(.5)
    me = me.saturate()
    me.show(container)
  , 1000/60)
""")
      
      @editors[1].setValue("""
me = c.getImage()
me = me.scale(.5)
me = me.saturate()
me = me.grayscale()  
""")
      
      @editors[2].setValue("""
me = c.getImage()
me = me.scale(.5)                                                      
me = me.hueDistance(357)
me = me.invert()
me = me.binarize(241)
me.show(three)
""")      
      
      setInterval(=>
        # Scaled Camera Shot
        a = c.getImage()
        a = a.scale(.5)
        a = a.saturate()
        a.show(one)
        
        # Greyscale Camera
        b = a.grayscale()
        b.show(two)            
        
        # Color Distance
        e = a.hueDistance(357)
        e = e.invert()
        e = e.binarize(241)
        e.show(three)
      , 1000/60)
    )
    return
