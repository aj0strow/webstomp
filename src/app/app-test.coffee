App = require "./app"
{EventEmitter} = require "events"
sinon = require "sinon-commonjs"
assert = require "assert"
WebSocket = require "ws"
http = require "http"
ClientTransport = require "../client-transport"
ServerTransport = require "../server-transport"

portfinder = require "portfinder"
bluebird = require "bluebird"
findOpenPort = bluebird.promisify(portfinder.getPort)

describe "App", ->
  describe "accept", ->
    beforeEach ->
      @app = new App()
      
      @socket = new EventEmitter()
      @transport = new ServerTransport(@socket)
      @transport.sendFrame = sinon.spy()
      @transport.emit = (name, data) ->
        @signals[name].emit(data)
      
      @app.accept @transport

    it "should dispatch socket messages", ->
      @app.connect (next) ->
        @connected
          "version": "1.2"
          "heart-beat": "0,0"
      
      connect =
        command: "CONNECT"
        headers: {}
      
      @transport.emit "frame", connect
      assert @transport.sendFrame.called

    it "should fire disconnect at least once", (done) ->
      @app.disconnect ->
        done()
      @transport.emit "close"

    it "should proto inherit the session", (done) ->
      @app.use (next) ->
        @state.ok = true
        next()
      
      @app.use (next) ->
        assert @state.ok
        done()
      
      @transport.emit "frame", {}
  
  describe "mount", ->
    it "should attach to params for wss", ->
      httpServer = http.createServer(-> null)
      app = new App()
      app.mount(server: httpServer)
  
  describe "listen", ->
    beforeEach ->
      findOpenPort().then (port) =>
        @port = port
    
    it "should accept connections", (done) ->
      @app = new App()
      server = @app.listen @port
      
      @app.connect ->
        server.close()
      
      ws = new WebSocket("ws://localhost:#{ @port }")
      transport = new ClientTransport(ws)
      
      transport.on "open", ->
        transport.connect { "accept-version": "1.2", "host": "test" }
      
      transport.on "close", ->
        done()
