# Write your [mocha](http://visionmedia.github.com/mocha/) specs here.
require 'app/models/Image'

describe "models/Image", ->
  i = new Image [640, 480]
  describe '#width', ->
    it 'should be 640', ->
      i.width.should.equal 640
      