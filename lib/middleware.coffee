coffeeScript = require 'coffee-script'
fs = require 'fs'
path = require 'path'
url = require 'url'
mkdirp = require 'mkdirp'
debug = require('debug')('connect-coffee-script');

clone = (src) ->
    if src is Object(src)
        if toString.call(src) is '[object Array]'
            src.slice()
        else
            obj = {}
            obj[prop] = src[prop] for prop, val in src

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

    # Source dir required
    src = options.src
    throw new Error 'Coffeescript middleware requires "src" directory' unless src

    # Default dest dir to source
    dest = if options.dest then options.dest else src

    # Default compile callback
    options.compile ?= (str, options) ->
        coffeeScript.compile str, clone(options)

    # Middleware
    (req, res, next) ->
        return next() if 'GET' isnt req.method and 'HEAD' isnt req.method
        pathname = url.parse(req.url).pathname
        if /\.js$/.test pathname
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
                    try
                        js = options.compile str, options
                    catch err
                        return next err
                    debug('render %s', coffeePath);
                    mkdirp path.dirname(jsPath), 0o0700, (err) ->
                        return error err if err
                        fs.writeFile jsPath, js, 'utf8', next

            # Force compilation
            return compile() if options.force

            # Compare mtimes
            fs.stat coffeePath, (err, coffeeStats) ->
                return error err if err
                fs.stat jsPath, (err, jsStats) ->
                    # JS has not been compiled, compile it!
                    if err
                        if 'ENOENT' is err.code
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
