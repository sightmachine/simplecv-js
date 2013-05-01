# SimpleCV.js - a port of the SimpleCV Framework to Javascript

Currently a Skeleton

[**CHECK OUT THE LIVE DEMO (Chrome only!)**](http://demo.simplecv.org/)

## Requirements

[Coffee Script](http://coffeescript.org/)
[Node.js](http://nodejs.org) ~ v0.6.10
[Node Package Manager](https://npmjs.org/)

## Quick Start Guide

_Note that this quickstart guide is tested and works for Ubuntu 12.04 LTS_

* Install [brunch](http://brunch.io/).
* Install [coffe-script-brunch](https://github.com/brunch/coffee-script-brunch) which adds support for Coffee Script.
* Install a [coffee script](http://coffeescript.org/) build environment.
* _Optional_ Install [SimpleCV](https://github.com/sightmachine/simplecv#installation) and its dependencies.
* Run `npm install` to install missing dependencies
* Add the following command to your .bashrc file and source the file:
  alias http "python -m SimpleHTTPServer"
* Run the following commands in the shell
    * > cd simplecv-js 
    * > brunch build
    * > brunch watch &  
    * > http
* Using Chrome go to locahost:8000/public/ and check out the results.
* Most of the action happens in /simplecv-js/app/models/Image.coffee
* Enjoy!

To test the javascript to python functionality do the following:

* cd ./simplecv-js/webrtc-2-python 
* python server.py
* Using Chrome go to localhost:8080
* Allow the camera.
* Enjoy!

Wraps the following:

* ccv.js & face.js: https://github.com/liuliu/ccv
* cv.js (partial OpenCV port): http://code.google.com/p/js-aruco/
* processing.js: http://processingjs.org/
* caman.js: https://github.com/meltingice/CamanJS
* depth.js: https://github.com/doug/depthjs
* psx.js: https://github.com/zhijie/psx
* paintbrush.js: https://github.com/mezzoblue/PaintbrushJS
* filter.js: https://github.com/foo123/FILTER.js
* pixastic: https://github.com/jseidelin/pixastic
* seam carving.js: https://github.com/axemclion/seamcarving
* three.js: https://github.com/mrdoob/three.js/
* d3.js: https://github.com/mbostock/d3
* hogdescriptor.js: https://github.com/harthur/hog-descriptor
* brain.js: https://github.com/harthur/brain
* jsqrcode: https://github.com/LazarSoft/jsqrcode


