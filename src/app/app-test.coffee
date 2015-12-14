App = require "./app"
{EventEmitter} = require "events"
Sinon = require "sinon-commonjs"
assert = require "assert"
portfinder = require "portfinder"
WebSocket = require "ws"
Socket = require "../socket"
http = require "http"

describe "Stomp App", ->
  describe "accept", ->
    beforeEach ->
      @socket = new EventEmitter()
      @socket.send = Sinon.spy()
      @app = new App()
      @app.accept @socket

    it "should dispatch socket messages", ->
      @app.connect (next) ->
        @connected()
      
      frame = 
        command: "CONNECT"
        headers: {}
      @socket.emit "message", frame
      
      assert @socket.send.called

    it "should fire disconnect at least once", (done) ->
      @app.disconnect ->
        done()
      @socket.emit "close"
    
    it "should proto inherit the session", (done) ->
      @app.use (next) ->
        @context.ok = true
        next()
      
      @app.use (next) ->
        assert @context.ok
        done()
      
      @socket.emit "message", {}
  
  describe "mount", ->
    it "should attach to params for wss", ->
      httpServer = http.createServer(-> null)
      app = new App()
      app.mount(server: httpServer)
  
  describe "listen", ->
    beforeEach (done) ->
      portfinder.getPort (err, port) =>
        if err
          return done(err)
        @port = port
        done()
    
    it "should accept connections", (done) ->
      @app = new App()
      server = @app.listen @port
      
      @app.connect ->
        server.close()
      
      ws = new WebSocket("ws://localhost:#{ @port }")
      
      socket = new Socket(ws)
      socket.on "open", ->
        socket.send
          command: "CONNECT"
      
      socket.on "close", ->
        done()
    
      