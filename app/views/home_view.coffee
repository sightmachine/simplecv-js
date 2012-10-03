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
        four = $('<div class="cvImage"></div>').appendTo(body)
        
        """
        imageFile = $("<img/>").attr("src", "https://encrypted-tbn1.gstatic.com/images?q=tbn:ANd9GcSZIGwNZEDfyuO3VzbpaDb71l8nVgqsUTGkt_h4QcItRgP_GpkUYg").get(0)
        imageFile.onload = =>
          i = new CVImage(imageFile)
          i.binarize()
          i.show(one)
        """
        
        h = null

        c = new Camera();
        c.init(=>
          setInterval(=>
            i = c.getImage()
            i = i.scale(.5)
            i = i.saturate()
            i.show(one)
            
            # Drawing is not recommended on a
            # huge frame rate. It takes a toll
            # on the CPU with all the garbage
            # collection and dom creation.
            # i.addDl(d)
            # must be done before i is drawn
            
            #d = i.addDrawingLayer()
            #d.fill(204, 102, 0)
            #d.rect(10,10,30,30)
              
            g = i.grayscale()
            g = g.flipHorizontal()
            g.show(two)
            
            b = g.binarize(60)
            b.show(three)
            
            # If there is a previous frame
            # we can show the difference.
            if h
              f = h.subtract(i)
              f = f.grayscale()
              f = f.binarize(40)
              f.show(four)
            
            h = i
          , 1000/30)
        )
        
    )
