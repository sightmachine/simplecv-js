Model = require "./model"

# The Display model provides a simple way to
# display an Image in a container.
module.exports = class Display extends Model
  element: null
  width: null
  height: null
  
  initialize:(selector) =>
    @element = $(selector)
    @width = @element.width()
    @height = @element.height()
    
  resolution:() =>
    return [@element.width(), @element.height()] 