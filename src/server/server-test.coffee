Server = require "./server"
WebSocket = require "ws"
ClientTransport = require "../client-transport"
assert = require "assert"
portfinder = require "portfinder"

bluebird = require "bluebird"
findOpenPort = bluebird.promisify(portfinder.getPort)

describe "Server", ->
  beforeEach ->
    findOpenPort().then (port) =>
      @port = port
  
  it "should emit listening event", (done) ->
    server = new Server(port: @port)
    server.on "listening", =>
      server.close()
      done()
  
  it "should emit errors", (done) ->
    server1 = new Server(port: @port)
    server2 = new Server(port: @port)
    server2.on "error", (err) =>
      assert.equal err.code, "EADDRINUSE"
      server1.close()
      done()
  
  it "should emit transports", (done) ->
    server = new Server(port: @port)
    
    server.on "connection", (transport) ->
      transport.on "frame", (frame) ->
        assert.equal frame.command, "CONNECT"
        response =
          command: "CONNECTED"
          headers: { "version": "1.2" }
        transport.sendFrame response
          .catch done
    
    ws = new WebSocket("ws://localhost:#{ @port }")
    transport = new ClientTransport(ws)
    
    transport.on "open", ->      
      request =
        command: "CONNECT"
        headers: { "server": "test", "accept-version": "1.2" }
      transport.sendFrame request
        .catch done
    
    transport.on "frame", (frame) ->
      assert.equal frame.command, "CONNECTED"
      server.close()
    
    transport.on "error", done
    
    transport.on "close", ->
      done()
