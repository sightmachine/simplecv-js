application = require 'application'

module.exports = class Router extends Backbone.Router
  routes:
    '': 'home'
    

  home: ->
    if $("#content").length >0
      $('#content').html application.homeView.render().el
