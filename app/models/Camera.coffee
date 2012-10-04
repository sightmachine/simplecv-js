CVImage = require './Image'

# The Camera model contains code to initialize
# a connection to the camera via WebRTC and
# provides one public method to capture a single
# frame from the camera in Imgae format.
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
    
  # Provides a hook for the asynchronous
  # user media call. 
  init:(callback) =>
    @load = callback
    navigator.webkitGetUserMedia({video: true, audio: true}, @onUserMediaSuccess)

  # The camera takes almost a second to
  # initialize and spit back real data.
  # Call the callback hook. 
  onUserMediaSuccess:(stream) =>
    @video.src = window.webkitURL.createObjectURL(stream)
    setTimeout(@load, 700)
    
  # :(
  onUserMediaError:(error) =>
    console.log("Failed to initialize video stream. Error: #{error}");
    
  # Captures a frame from the video element
  # and push the captured canvas to a new
  # Image and returns it.
  getImage:() =>
    canvas = document.createElement("canvas")
    canvas.width = @video.width
    canvas.height = @video.height
    ctx = canvas.getContext("2d")
    ctx.drawImage(@video, @width, 0, -@width, @height)
    return new CVImage(canvas)