View = require './view'
Camera = require '../models/Camera'
CVImage = require '../models/Image'
Color = require '../models/Color'
template = require './templates/home'

module.exports = class HomeView extends View
  id: 'home-view'
  template: template
  
  initialize: =>
    $(=>
        body = $("body")
        one = $('<div class="cvImage"></div>').appendTo(body)
        two = $('<div class="cvImage"></div>').appendTo(body)
        three = $('<div class="cvImage"></div>').appendTo(body)
        four = $('<div class="cvImage"></div>').appendTo(body)
        
        imageFile = $("<img/>").attr("src", "https://encrypted-tbn1.gstatic.com/images?q=tbn:ANd9GcSZIGwNZEDfyuO3VzbpaDb71l8nVgqsUTGkt_h4QcItRgP_GpkUYg").get(0)
        imageFile.onload = =>
          i = new CVImage(imageFile)
          i.binarize()
          i.show(one)
          
        
        c = new Camera();
        c.init(=>
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
            e = e.binarize(240)
            e.show(three)
          , 1000/60)
        )
        
    )
