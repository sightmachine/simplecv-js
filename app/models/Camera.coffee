Image = require './Image'

module.exports = class Camera extends Backbone.Model
  load: null
  stream: null
  video: null
  
  # TODO: Figure out how to get this to scale
  # with the actual video stream.
  width: 640
  height: 480
  
  # Creates a video object that we can point
  # to the camera stream for image capture.
  # It seems we have to defi
  initialize:() =>
    @video = $("<video autoplay></video>").get(0)
    @video.width = @width
    @video.height = @height
    
  init:(callback) =>
    @load = callback
    navigator.webkitGetUserMedia({video: true, audio: true}, @onUserMediaSuccess)

  onUserMediaSuccess:(stream) =>
    @video.src = window.webkitURL.createObjectURL(stream)
    setTimeout(@load, 700)
    
  onUserMediaError:(error) =>
    console.log("Failed to initialize video stream. Error: #{error}");
    
  getImage:() =>
    canvas = document.createElement("canvas")
    canvas.width = @video.width
    canvas.height = @video.height
    ctx = canvas.getContext("2d")
    ctx.drawImage(@video, @width, 0, -@width, @height)
    return new Image(canvas)