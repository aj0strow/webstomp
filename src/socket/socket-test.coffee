Socket = require "./socket"
{EventEmitter} = require "events"
Sinon = require "sinon-commonjs"
assert = require "assert"

describe "Stomp Socket", ->
  beforeEach ->
    @ws = new EventEmitter()
    @ws.send = Sinon.spy()
    @ws.close = Sinon.spy()
    @socket = new Socket(@ws)
  
  describe "send", ->
    it "should break on bad command", ->
      assert.throws =>
        @socket.send
          command: "GARBAGE"
    
    it "should break on invalid command", ->
      assert.throws =>
        @socket.send
          command: "CONNECT"
          body: "This is not allowed."
    
    it "should send string packet", ->
      @socket.send command: "CONNECTED"
      packet = @ws.send.getCall(0).args[0]
      assert /CONNECTED/.test(packet)
    
    it "should pass send errors", (done) ->
      @ws.send = (data, f) ->
        f(new Error())
      @socket.send { command: "ERROR" }, (err) ->
        assert err
        done()
  
  describe "events", ->
    it "should parse and trigger message", (done) ->
      packet = [
        "DISCONNECT\n"
        "\n"
        "\0"
      ].join("")
      @socket.on "message", (message) ->
        assert.equal message.command, "DISCONNECT"
        done()
      @ws.emit "message", packet
  
    it "should relay errors", (done) ->
      @socket.on "error", (err) ->
        assert.equal err.message, "Guns"
        done()
      @ws.emit "error", new Error("Guns")
    
    it "should relay close events", (done) ->
      @socket.on "close", =>
        done()
      @ws.emit "close"
    
    it "should relay open events", (done) ->
      @socket.on "open", =>
        done()
      @ws.emit "open"

  describe "close", ->
    it "should close socket", ->
      @socket.close()
      assert @ws.close.called
