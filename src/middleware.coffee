coffeeScript = require 'coffee-script'
{updateSyntaxError} = require 'coffee-script/lib/coffee-script/helpers'
fs = require 'fs'
path = require 'path'
url = require 'url'
mkdirp = require 'mkdirp'
debug = require('debug')('connect-coffee-script');

clone = (src) ->
  return unless typeof src is 'object'
  return src.slice() if Array.isArray src
  obj = {}
  for prop, val of src then obj[prop] = val
  obj

###

A simple connect middleware to serve CoffeeScript files.

@param {Object} options
@return {Function}
@api public
###

module.exports = (options = {}) ->
  # Accept src/dest dir
  if typeof options is 'string'
    options = src: options
  # Base directory
  baseDir = options.baseDir or process.cwd()
  # Source dir required
  src = options.src
  throw new Error 'Coffeescript middleware requires "src" directory' unless src
  src = path.resolve baseDir, src
  # Default dest dir to source
  dest = if options.dest then options.dest else src
  dest = path.resolve baseDir, dest
  # Default compile callback
  options.compile ?= (str, options) ->
    try
      coffeeScript.compile str, clone(options)
    catch err
      updateSyntaxError err, null, options.filename
      throw err
  # Middleware
  (req, res, next) ->
    return next() if 'GET' isnt req.method and 'HEAD' isnt req.method
    pathname = url.parse(req.url).pathname
    if /\.js$/.test pathname
      if options.prefix and 0 is pathname.indexOf options.prefix
        pathname = pathname.substring options.prefix.length
      jsPath = path.join dest, pathname
      coffeePath = path.join src, pathname.replace '.js', '.coffee'
      # Ignore ENOENT to fall through as 404
      error = (err) ->
        arg = if 'ENOENT' is err.code then null else err
        next arg
      # Compile to jsPath
      compile = ->
        debug 'read %s', jsPath
        fs.readFile coffeePath, 'utf8', (err, str) ->
          return error err if err
          # If `options` is passed to `coffeeScript.compile` (as it is in the
          # default `options.compile` function), `coffeeScript.compile` will
          # put `options.filename` in error messages. Set `options.filename`!
          options.filename = coffeePath
          options.generatedFile = path.basename(pathname)
          options.sourceFiles = [path.basename(pathname, '.js') + '.coffee']
          try
            result = options.compile str, options, coffeePath
            # when `options.sourceMap` presents, the compliation result is in
            # the following form:
            # {js: 'js code', v3SourceMap: 'map code', sourceMap: {...v4map object...}}
            map = result.v3SourceMap
            js = if map? then result.js else result
          catch err
            return next err
          debug('render %s', coffeePath);
          mkdirp path.dirname(jsPath), 0o0700, (err) ->
            return error err if err
            if map?
              mapFile = jsPath.replace /\.js$/, '.map'
              mapPath = 
                (options.sourceMapRoot ? '') + pathname.replace /\.js$/, '.map'
              mapFooter = """
                //# sourceMappingURL=#{mapPath}
                //@ sourceMappingURL=#{mapPath}
              """
              # Special comment at the end that is required to signify to WebKit dev tools
              # that a source map is available:
              js = "#{js}\n\n#{mapFooter}"
            fs.writeFile jsPath, js, 'utf8', ->
              return next() unless map?
              fs.writeFile mapFile, map, 'utf8', next
      # Force compilation
      return compile() if options.force
      # Compare mtimes
      fs.stat coffeePath, (err, coffeeStats) ->
        return error err if err
        fs.stat jsPath, (err, jsStats) ->
          if err
            if 'ENOENT' is err.code
              # JS has not been compiled, compile it!
              debug 'not found %s', jsPath
              compile()
            else
              next err
          else
            # Source has changed, compile it
            if coffeeStats.mtime > jsStats.mtime
              debug('modified %s', jsPath)
              compile()
            else
              next()
    else
      next()
