assert = require "assert"
Transport = require "./transport"
EventEmitter = require "events"

describe "Transport", ->
  beforeEach ->
    @ws = new EventEmitter()
    @transport = new Transport(@ws)
  
  describe "events", ->
    it "should propagate open event", (done) ->
      @transport.on "open", ->
        done()
      @ws.emit "open"
    
    it "should propagate error event", (done) ->
      @transport.on "error", (err) ->
        assert.equal err.message, "ok"
        done()
      @ws.emit "error", new Error("ok")
    
    it "should propagate close event", (done) ->
      @transport.on "close", ->
        done()
      @ws.emit "close"
    
  describe "messages", ->
    it "should emit heartbeats", (done) ->
      @transport.on "heartbeat", ->
        done()
      @ws.emit "message", "\n"
    
    it "should emit frames", (done) ->
      @transport.on "frame", (frame) ->
        assert.equal frame.command, "CONNECTED"
        done()
      @ws.emit "message", "CONNECTED\n\0"
  
  describe "close", ->
    it "should close the websocket", (done) ->
      @ws.close = ->
        done()
      @transport.close()

  describe "send frame", ->
    it "should encode frames", ->
      @ws.send = (message, fn) ->
        assert.equal message, "CONNECT\naccept-version:1.2\n\n\0"
        fn(null)
      @transport.sendFrame
        command: "CONNECT"
        headers: { "accept-version": "1.2" }
    
    it "should fail on error", ->
      @ws.send = (message, fn) ->
        fn(new Error("websocket closed"))
      
      onSuccess = ->
        throw new Error("invalid code path")
      
      onError = (err) ->
        assert.equal err.message, "websocket closed"
      
      @transport.sendFrame(command: "CONNECTED")
        .then(onSuccess, onError)

  describe "send heartbeat", ->
    it "should send empty message", ->
      @ws.send = (message, fn) ->
        assert.equal message, "\n"
        fn()
      @transport.sendHeartbeat()
    
    it "should fail on error", ->
      @ws.send = (message, fn) ->
        fn(new Error("ok"))
      
      onSuccess = ->
        throw new Error("invalid code path")
      
      onError = (err) ->
        assert.equal err.message, "ok"
      
      @transport.sendHeartbeat()
        .then(onSuccess, onError)

  describe "auto heartbeat", ->
    it "should start timer", (done) ->
      outbox = []
      @ws.send = (message, fn) ->
        outbox.push message
        fn()
      intid = @transport.autoHeartbeat(5)
      onTimeout = ->
        clearInterval intid
        assert.equal outbox.length, 2
        done()
      setTimeout onTimeout, 14
