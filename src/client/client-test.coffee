assert = require "assert"
EventEmitter = require "events"
Client = require "./client"
{noop} = require "lodash"
{resolve, reject} = require "bluebird"

describe "Client", ->
  beforeEach ->
    @transport = new EventEmitter()
    @client = new Client(@transport)

  describe "send frame", ->
    it "should send to transport", ->
      @transport.sendFrame = (frame) ->
        assert frame
        resolve()
      @client.sendFrame {}
    
    it "should not send when disconnected", ->
      @client.disconnected = true
      @client.sendFrame()
        .catch (err) ->
          /disconnected/.test err.message

  describe "auto heartbeat", ->
    it "should not send if zero", ->
      @transport.autoHeartbeat = ->
        throw new Error("invalid code path")
      @client.autoHeartbeat "5000,0"

    it "should send heartbeat max", ->
      @transport.autoHeartbeat = (ms) ->
        assert.equal ms, 60000
      @client.autoHeartbeat "5000,60000"

  describe "send frame with receipt", ->
    it "should generate unique id", ->
      receipts = []
      @transport.sendFrame = (frame) =>
        receipts.push frame.headers["receipt"]
        resolve()
      
      @client.sendFrameWithReceipt(headers: {})
      @client.sendFrameWithReceipt(headers: {})
      
      assert.notEqual receipts[0], receipts[1]

    it "should resolve when received", ->
      @transport.sendFrame = (frame) =>
        setImmediate =>
          receipt = 
            command: "RECEIPT"
            headers: { "receipt-id": frame.headers["receipt"] }
          @transport.emit "frame", receipt
        resolve()
      @client.sendFrameWithReceipt(headers: {})

    it "should fail on server error", ->
      @transport.sendFrame = (frame) =>
        setImmediate =>
          error = 
            command: "ERROR"
            headers: { "receipt-id": frame.headers["receipt"] }
          @transport.emit "frame", error
        resolve()
      onSuccess = ->
        throw new Error("invalid code path")
      @client.sendFrameWithReceipt(headers: {})
        .then onSuccess, noop

  describe "connect", ->
    it "should require headers", ->
      assert.throws (=> @client.connect()), /headers/
    
    it "should require accept version", ->
      assert.throws (=> @client.connect({})), /accept-version/
    
    it "should require host", ->
      headers = { "accept-version": "1.2" }
      assert.throws (=> @client.connect headers), /host/
  
    it "should send connect command", ->
      @transport.sendFrame = (frame) ->
        assert.equal frame.command, "CONNECT"
        resolve()
      @client.connect("accept-version": "1.2", host: "localhost")
      null
    
    it "should add default heart-beat", ->
      @transport.sendFrame = (frame) ->
        assert.equal frame.headers["heart-beat"], "10000,0"
        resolve()
      @client.connect("accept-version": "1.2", host: "localhost")
      null
    
    it "should resolve when connected", ->
      @transport.sendFrame = =>
        setImmediate =>
          connected = 
            command: "CONNECTED"
            headers: {}
          @transport.emit "frame", connected
        resolve()
      @client.connect("accept-version": "1.2", host: "localhost")

  describe "send", ->
    it "should require headers", ->      
      assert.throws (=> @client.send()), /headers/
    
    it "should require destination", ->
      assert.throws (=> @client.send {}), /destination/
    
    it "should map to send command", ->
      @transport.sendFrame = (frame) ->
        assert.equal frame.command, "SEND"
        resolve()
      @client.send(destination: "/ottawa")
      null
  
  describe "subscribe", ->
    it "should require headers", ->
      assert.throws (=> @client.subscribe()), /headers/
    
    it "should require destination", ->
      assert.throws (=> @client.subscribe({})), /destination/
    
    it "should map to subscribe command", ->
      @transport.sendFrame = (frame) ->
        assert.equal frame.command, "SUBSCRIBE"
        resolve()
      @client.subscribe({ id: "1", destination: "/toronto" })
      null
    
    it "should generate unique ids", ->
      ids = []
      @transport.sendFrame = (frame) ->
        ids.push frame.headers.id
        resolve()
      @client.subscribe({ destination: "/peru" })
      @client.subscribe({ destination: "/iceland" })
      assert.notEqual ids[0], ids[1]
  
  describe "unsubscribe", ->
    it "should require headers", ->
      assert.throws (=> @client.unsubscribe()), /headers/
    
    it "should require id", ->
      assert.throws (=> @client.unsubscribe {}), /id/
    
    it "should map to unsubscribe command", ->
      @transport.sendFrame = (frame) ->
        assert.equal frame.command, "UNSUBSCRIBE"
        resolve()
      @client.unsubscribe(id: "sub-1")
      null

  describe "source", ->
    it "should subscribe and unsubscribe", (done) ->
      commands = []
      @transport.sendFrame = (frame) =>
        commands.push frame.command
        receipt = 
          command: "RECEIPT"
          headers: { "receipt-id": frame.headers["receipt"] }
        @transport.emit "frame", receipt
        resolve()
      source = @client.source(destination: "/paris")
      
      complete = ->
        assert.equal commands[0], "SUBSCRIBE"
        assert.equal commands[1], "UNSUBSCRIBE"
        done()
      
      sub = source.subscribe(next: noop, error: noop, complete: complete)
      setTimeout (-> sub.unsubscribe()), 5
      setTimeout complete, 5
    
    it "should push frame body message", (done) ->
      @transport.sendFrame = (frame) =>
        receipt = 
          command: "RECEIPT"
          headers: { "receipt-id": frame.headers["receipt"] }
        @transport.emit "frame", receipt
        resolve()
      source = @client.source(destination: "/moscow", id: "S1")
      sub = source.subscribe
        next: (message) ->
          assert.equal message, "ok"
          sub.unsubscribe()
          done()
      onMessage = =>
        message = 
          command: "MESSAGE"
          headers:
            subscription: "S1"
          body: "ok"
        @transport.emit "frame", message
      setTimeout onMessage, 5
  
  describe "disconnect", ->
    it "should close transport on receipt", (done) ->
      @transport.sendFrame = (frame) =>
        receipt = 
          command: "RECEIPT"
          headers: { "receipt-id": frame.headers["receipt"] }
        @transport.emit "frame", receipt
        resolve()
      @transport.close = done
      @client.disconnect()
    
    it "should close transport on error", (done) ->
      @transport.sendFrame = (frame) =>
        error = 
          command: "ERROR"
          headers: { "receipt-id": frame.headers["receipt"] }
        @transport.emit "frame", error
        resolve()
      @transport.close = done
      @client.disconnect()
        .catch noop
      null
