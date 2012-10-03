View = require './view'
Camera = require '../models/Camera'
CVImage = require '../models/Image'
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
        
        """
        imageFile = $("<img/>").attr("src", "https://encrypted-tbn1.gstatic.com/images?q=tbn:ANd9GcSZIGwNZEDfyuO3VzbpaDb71l8nVgqsUTGkt_h4QcItRgP_GpkUYg").get(0)
        imageFile.onload = =>
          i = new CVImage(imageFile)
          i.binarize()
          i.show(one)
        """

        c = new Camera();
        c.init(=>
          setInterval(=>
            i = c.getImage().saturate()
            
            # Drawing is not recommended on a
            # huge frame rate. It takes a toll
            # on the CPU with all the garbage
            # collection and dom creation.
            
            
            # i.addDl(d)
            
            #d = i.addDrawingLayer()
            #d.fill(204, 102, 0)
            #d.rect(10,10,30,30)
              
            i.show(one)
            
            g = i.grayscale()
            g.show(two)
            
            b = g.binarize()
            b.show(three)
          , 1000/30)
        )
        
    )
