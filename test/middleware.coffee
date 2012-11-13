
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
      middleware(options) req, res, () ->
        fs.exists "#{__dirname}/../sample/public/test.js", (exists) ->
          exists.should.be.ok
          next()

  it 'should honor the base directory', (next) ->
    rimraf "#{__dirname}/../sample/public", (err) ->
      options =
        baseDir: "#{__dirname}/../sample"
        src: './view'
        dest: './public'
      req =
        url: 'http://localhost/test.js'
        method: 'GET'
      res = {}
      middleware(options) req, res, () ->
        fs.exists "#{__dirname}/../sample/public/test.js", (exists) ->
          exists.should.be.ok
          next()
