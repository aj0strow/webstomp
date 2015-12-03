Server = require "./server"
WebSocket = require "ws"
Socket = require "../socket"
assert = require "assert"
portfinder = require "portfinder"

describe.only "Stomp Server", ->
  beforeEach (done) ->
    portfinder.getPort (err, port) =>
      if err
        return done(err)
      @port = port
      done()
  
  it "should emit sockets", (done) ->
    server = new Server(port: @port)
    server.on "connection", (socket) ->      
      socket.on "message", ->
        frame = 
          command: "CONNECTED"
          headers: { "version": "1.2" }
        
        socket.send frame, (err) ->
          done(new Error("server send error")) if err
          
    
    ws = new WebSocket("ws://localhost:#{ @port }")
    socket = new Socket(ws)
    
    socket.on "open", ->      
      socket.on "message", (frame) ->
        assert.equal frame.command, "CONNECTED"
        server.close()
        done()
      
      frame =
        command: "CONNECT"
        headers: { "accept-version": "1.2" }
      socket.send frame, (err) ->
        done(new Error("client send error")) if err        


