App = require "./app"
{EventEmitter} = require "events"
Sinon = require "sinon-commonjs"
assert = require "assert"
portfinder = require "portfinder"
WebSocket = require "ws"
Socket = require "../socket"

describe "Stomp App", ->
  describe "accept", ->
    beforeEach ->
      @socket = new EventEmitter()
      @socket.send = Sinon.spy()
      @app = new App()
      @app.accept @socket

    it "should dispatch socket messages", ->
      @app.connect (client) ->
        client.connected()
      
      frame = 
        command: "CONNECT"
        headers: {}
      @socket.emit "message", frame
      
      assert @socket.send.called

    it "should fire disconnect at least once", (done) ->
      @app.disconnect ->
        done()
      @socket.emit "close"
  
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
    
      