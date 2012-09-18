nib = require 'nib'
stylus = require 'stylus'
sysPath = require 'path'

module.exports = class StylusCompiler
  brunchPlugin: yes
  type: 'stylesheet'
  extension: 'styl'
  generators:
    backbone:
      style: "@import 'nib'\n"
  _dependencyRegExp: /@import ['"](.*)['"]/g

  constructor: (@config) ->
    null

  compile: (data, path, callback) =>
    stylus(data)
      .set('compress', no)
      .set('firebug', !!@config.stylus?.firebug)
      .include(sysPath.join @config.paths.root)
      .include(sysPath.dirname path)
      .use(nib())
      .render(callback)

  getDependencies: (data, path, callback) =>
    paths = data.match(@_dependencyRegExp) or []
    parent = sysPath.dirname path
    dependencies = paths
      .map (path) =>
        res = @_dependencyRegExp.exec(path)
        @_dependencyRegExp.lastIndex = 0
        (res or [])[1]
      .filter((path) => !!path and path isnt 'nib')
      .map (path) =>
        if sysPath.extname(path) isnt ".#{@extension}"
          path + ".#{@extension}"
        else
          path
      .map(sysPath.join.bind(null, parent))
    process.nextTick =>
      callback null, dependencies
