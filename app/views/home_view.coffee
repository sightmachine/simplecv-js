View = require './view'
Camera = require '../models/Camera'
template = require './templates/home'

module.exports = class HomeView extends View
  id: 'home-view'
  template: template
  
  initialize: =>
    $(=>
        $('<div id="one"></div>').appendTo($("body"));
        $('<div id="onehalf"></div>').appendTo($("body"));
        $('<div id="two"></div>').appendTo($("body"));
        $('<div id="three"></div>').appendTo($("body"));
        $("#one, #onehalf, #two, #three").css("display", "inline-block")
        
        c = new Camera();
        c.init(=>
          setInterval(=>
            i = c.getImage();
            i.show($("#one"));
            
            s = i.saturate();
            s.show($("#onehalf"));
            
            g = s.grayscale();
            g.show($("#two"));
            
            b = g.binarize();
            b.show($("#three"));
          , 1000/60)
        )
    )
