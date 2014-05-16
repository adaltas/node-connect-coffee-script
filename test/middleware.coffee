
fs = require 'fs'
rimraf = require 'rimraf'
should = require 'should'
middleware = if process.env.COFFEE_COV then require '../lib-cov/middleware' else require '../lib/middleware'

describe 'middleware', ->

  it 'should compile a coffee file', (next) ->
    rimraf "#{__dirname}/../sample/public", (err) ->
      options =
        src: "#{__dirname}/../sample/view"
        dest: "#{__dirname}/../sample/public"
      req =
        url: 'http://localhost/test.js'
        method: 'GET'
      res = {}
      middleware(options) req, res, (err) ->
        return next err if err
        fs.readFile "#{__dirname}/../sample/public/test.js", 'utf8', (err, content) ->
          should.not.exist err
          content.should.eql "(function() {\n  alert(\'welcome\');\n\n}).call(this);\n"
          next()

  it 'should compile with force option', (next) ->
    rimraf "#{__dirname}/../sample/public", (err) ->
      options =
        src: "#{__dirname}/../sample/view"
        dest: "#{__dirname}/../sample/public"
        force: true
      req =
        url: 'http://localhost/test.js'
        method: 'GET'
      res = {}
      middleware(options) req, res, (err) ->
        return next err if err
        fs.stat "#{__dirname}/../sample/public/test.js", (err, stat) ->
          mtime = stat.mtime
          setTimeout ->
            middleware(options) req, res, (err) ->
              return next err if err
              fs.stat "#{__dirname}/../sample/public/test.js", (err, stat) ->
                # File should be modified
                mtime.should.be.below stat.mtime
                fs.readFile "#{__dirname}/../sample/public/test.js", 'utf8', (err, content) ->
                  should.not.exist err
                  content.should.eql "(function() {\n  alert(\'welcome\');\n\n}).call(this);\n"
                  next()
          , 1000

  it 'creates subdirectories', (next) ->
    rimraf "#{__dirname}/../sample/public", (err) ->
      options =
        src: "#{__dirname}/mkdir/view"
        dest: "#{__dirname}/mkdir/public"
      req =
        url: 'http://localhost/js/test.js'
        method: 'GET'
      res = {}
      middleware(options) req, res, (err) ->
        return next err if err
        fs.readFile "#{__dirname}/mkdir/public/js/test.js", 'utf8', (err, content) ->
          should.not.exist err
          content.should.eql "(function() {\n  alert(\'welcome\');\n\n}).call(this);\n"
          fs.unlink "#{__dirname}/mkdir/public/js/test.js"
          next()

  it 'should honor the base directory and bare option', (next) ->
    rimraf "#{__dirname}/../sample/public", (err) ->
      options =
        baseDir: "#{__dirname}/../sample"
        src: './view'
        dest: './public'
        bare: true
      req =
        url: 'http://localhost/test.js'
        method: 'GET'
      res = {}
      middleware(options) req, res, (err) ->
        return next err if err
        fs.readFile "#{__dirname}/../sample/public/test.js", 'utf8', (err, content) ->
          should.not.exist err
          content.should.eql "alert(\'welcome\');\n"
          next()

  it 'prepend the sourcemap location with the sourceMapRoot', (next) ->
    rimraf "#{__dirname}/../sample/public", (err) ->
      options =
        src: "#{__dirname}/../sample/view",
        dest: "#{__dirname}/../sample/public",
        sourceMap: true,
        sourceMapRoot: '/static'
      req =
        url: 'http://localhost/test.js'
        method: 'GET'
      res = {}
      middleware(options) req, res, (err) ->
        return next err if err
        fs.readFile "#{__dirname}/../sample/public/test.js", 'utf8', (err, content) ->
          should.not.exist err
          content.should.eql "(function() {\n  alert(\'welcome\');\n\n}).call(this);\n\n\n//# sourceMappingURL=/static/test.map\n//@ sourceMappingURL=/static/test.map"
          next()

  it 'should strip path', (next) ->
    rimraf "#{__dirname}/../sample/public", (err) ->
      options =
        baseDir: "#{__dirname}/prefix"
        src: './view/coffee'
        dest: './public/js'
        prefix: '/js'
      req =
        url: 'http://localhost/js/test.js'
        method: 'GET'
      res = {}
      middleware(options) req, res, (err) ->
        return next err if err
        fs.readFile "#{__dirname}/prefix/public/js/test.js", 'utf8', (err, content) ->
          should.not.exist err
          content.should.eql "(function() {\n  alert(\'welcome\');\n\n}).call(this);\n"
          fs.unlink "#{__dirname}/prefix/public/js/test.js"
          next()

  it 'should show filename on error', (next) ->
    rimraf "#{__dirname}/../sample/public", (err) ->
      options =
        src: "#{__dirname}/error/view"
        dest: "#{__dirname}/error/public"
      req =
        url: 'http://localhost/test.js'
        method: 'GET'
      res = {}
      middleware(options) req, res, (err) ->
        err.message.should.eql 'missing ", starting'
        err.toString().should.eql """
        #{__dirname}/error/view/test.coffee:2:9: error: missing \", starting
        alert \"\"\u001b[1;31m\"\u001b[0mwelcome
        \u001b[1;31m        ^\u001b[0m
        """
        next()
