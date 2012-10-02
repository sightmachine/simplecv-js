Image = require './Image'

module.exports = class Camera extends Backbone.Model
  stream: null
  video: null
  
  width: 480
  height: 360
  
  initialize:() =>
    @video = $("<video autoplay></video>").get(0)
    @video.width = @width
    @video.height = @height

  onLoad:() =>
    
  init:() =>
    navigator.webkitGetUserMedia({video: true, audio: true}, @onUserMediaSuccess)

  onUserMediaSuccess:(stream) =>
    @video.src = window.webkitURL.createObjectURL(stream)
    @onLoad();
    
  onUserMediaError:(error) =>
    console.log("Failed to initialize video stream. Error: #{error}");
    
  getImage:() =>
    canvas = document.createElement("canvas")
    canvas.width = @video.width
    canvas.height = @video.height
    ctx = canvas.getContext "2d"
    ctx.drawImage(@video, 0, 0)
    
    image = new Image(canvas)
    return image