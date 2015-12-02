
should = require('should')
http = require('http')
express = require('express')
bodyParser = require('body-parser')
fs = require('fs')
horaa = require 'horaa'

port = process.env.PORT || 3333
baseurl = "http://localhost:#{port}"
process.env.NODE_ENV = 'devel'
process.env.SERVER_SECRET = 'jfdlksjflaf'
process.env.DATABASE_URL = process.env.DATABASE_URL || 'sqlite:'

g =
  user:
    email: '112'
    groups: []
  lang: 'cs'
  checkStatus: (res, desiredStatus)->
    console.log res.body
    res.statusCode.should.eql desiredStatus
  port: port

Sequelize = require('sequelize')

url = process.env.DATABASE_URL || 'sqlite:'
opts = {}
if url.indexOf('sqlite:') >= 0
  opts.dialect = 'sqlite'
  if url.length > 8
    opts.storage = url.slice(9)
console.log("## DB: #{url}")

sequelize = new Sequelize(url, opts)

# entry ...
describe "app", ->

  before (done) ->

    require('./models') sequelize, Sequelize

    sequelize.sync({ logging: console.log })
    .then () ->
      g.db = sequelize
      g.app = express()
      g.app.use(bodyParser.json())

      CRUD = require('../index')
      personsCRUD = CRUD sequelize.models.person, [
        name: 'name'
        model: sequelize.models.translats
        fk: 'entity_id'
        defaults: entity_type: 0
      ,
        name: 'descr'
        model: sequelize.models.translats
        fk: 'entity_id'
        defaults: entity_type: 1
      ]
      personsCRUD.initApp(g.app)

      g.server = g.app.listen port, (err) ->
        return done(err) if err
        done()
    .catch (err) ->
      done(err)

  after (done) ->
    g.server.close()
    done()

  it "should exist", (done) ->
    should.exist g.app
    done()

  # run the rest of tests
  g.baseurl = "http://localhost:#{port}"

  g.data = require('./data')

  T = require('./suites/basic')
  T(g, g.baseurl)