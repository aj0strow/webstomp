assert = require "assert"
EventEmitter = require "events"
Client = require "./client"
{noop} = require "lodash"

describe "Client", ->
  beforeEach ->
    @transport = new EventEmitter()
    @client = new Client(@transport)
  
  describe "connect", ->
    it "should require headers", ->
      assert.throws (=> @client.connect()), /headers/
    
    it "should require accept version", ->
      assert.throws (=> @client.connect({})), /accept-version/
    
    it "should require host", ->
      headers = { "accept-version": "1.2" }
      assert.throws (=> @client.connect headers), /host/
    
    it "should map to connect command", ->
      @transport.sendFrame = (frame) ->
        assert.equal frame.command, "CONNECT"
      @client.connect("accept-version": "1.2", host: "localhost")
    
    it "should add default heart-beat", ->
      @transport.sendFrame = (frame) ->
        assert.equal frame.headers["heart-beat"], "10000,0"
      @client.connect("accept-version": "1.2", host: "localhost")
  
  describe "send", ->
    it "should require headers", ->      
      assert.throws (=> @client.send()), /headers/
    
    it "should require destination", ->
      assert.throws (=> @client.send {}), /destination/
    
    it "should map to send command", ->
      @transport.sendFrame = (frame) ->
        assert.equal frame.command, "SEND"
        assert.equal frame.headers.destination, "/dest"
      @client.send(destination: "/dest")
    
    it "should encode json", ->
      @transport.sendFrame = (frame) ->
        assert.equal frame.headers["content-type"], "application/json"
        assert.equal frame.body, '{"ok":true}'
      @client.send({ destination: "/" }, { ok: true })
  
  describe "subscribe", ->
    it "should require headers", ->
      assert.throws (=> @client.subscribe()), /headers/
    
    it "should require destination", ->
      assert.throws (=> @client.subscribe({})), /destination/
    
    it "should map to subscribe command", ->
      @transport.sendFrame = (frame) ->
        assert.equal frame.command, "SUBSCRIBE"
        assert.equal frame.headers.id, "1"
        assert.equal frame.headers.destination, "/tea"
      @client.subscribe({ id: "1", destination: "/tea" })
    
    it "should generate unique id", ->
      ids = []
      @transport.sendFrame = (frame) ->
        ids.push frame.headers.id
      @client.subscribe({ destination: "/one" })
      @client.subscribe({ destination: "/two" })
      assert.notEqual ids[0], ids[1]
    
  describe "unsubscribe", ->
    it "should require headers", ->
      assert.throws (=> @client.unsubscribe()), /headers/
    
    it "should require id", ->
      assert.throws (=> @client.unsubscribe {}), /id/
    
    it "should map to unsubscribe command", ->
      @transport.sendFrame = (frame) ->
        assert.equal frame.command, "UNSUBSCRIBE"
        assert.equal frame.headers["id"], "sub-1"
      @client.unsubscribe(id: "sub-1")

  describe "disconnect", ->
    it "should map to disconnect command", ->
      @transport.sendFrame = (frame) ->
        assert.equal frame.command, "DISCONNECT"
      @client.disconnect()
    
    it "should prevent sending more messages", ->
      count = 0
      @transport.sendFrame = (frame) ->
        count += 1
      @client.disconnect()
      @client.send({ destination: "/hello" })
      assert.equal count, 1
  
  describe "auto heartbeat", ->
    it "should not send unwanted heartbeats", ->
      @transport.autoHeartbeat = ->
        throw new Error("this should not happen")
      @client.autoHeartbeat(10, 0)
    
    it "should send max frequency", ->
      @transport.autoHeartbeat = (ms) ->
        assert.equal ms, 10
      @client.autoHeartbeat(10, 5)
  
  describe "connected event", ->
    it "should emit event", (done) ->
      @client.once "connected", ->
        done()
      @client.onConnected({})
    
    it "should auto heartbeat", (done) ->
      @transport.sendFrame = noop
      @transport.autoHeartbeat = (ms) ->
        assert.equal ms, 30000
        done()      
      heartbeat = "1000,30000"
      frame =
        command: "CONNECTED"
        headers: { version: "1.2", "heart-beat": heartbeat }
      @transport.emit "frame", frame
  