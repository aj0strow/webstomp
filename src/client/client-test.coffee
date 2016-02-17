assert = require "assert"
EventEmitter = require "events"
Client = require "./client"

describe "Client", ->
  beforeEach ->
    @socket = new EventEmitter()
    @client = new Client(@socket)
  
  describe "send", ->
    it "should require headers", ->      
      assert.throws (=> @client.send()), /headers/
    
    it "should require destination", ->
      assert.throws (=> @client.send {}), /destination/
    
    it "should map to send command", ->
      @socket.send = (frame) ->
        assert.equal frame.command, "SEND"
        assert.equal frame.headers.destination, "/dest"
      @client.send(destination: "/dest")
    
    it "should encode json", ->
      @socket.send = (frame) ->
        assert.equal frame.headers["content-type"], "application/json"
        assert.equal frame.body, '{"ok":true}'
      @client.send({ destination: "/" }, { ok: true })
  
  describe "subscribe", ->
    it "should require headers", ->
      assert.throws (=> @client.subscribe()), /headers/
    
    it "should require destination", ->
      assert.throws (=> @client.subscribe({})), /destination/
    
    it "should map to subscribe command", ->
      @socket.send = (frame) ->
        assert.equal frame.command, "SUBSCRIBE"
        assert.equal frame.headers.id, "1"
        assert.equal frame.headers.destination, "/tea"
      @client.subscribe({ id: "1", destination: "/tea" })
    
    it "should generate unique id", ->
      ids = []
      @socket.send = (frame) ->
        ids.push frame.headers.id
      @client.subscribe({ destination: "/one" })
      @client.subscribe({ destination: "/two" })
      assert.notEqual ids[0], ids[1]
    
  describe "unsubscribe", ->
    it "should require headers", ->
      assert.throws (=> @client.subscribe()), /headers/
    
    it "should require id", ->
      assert.throws (=> @client.subscribe {}), /id/
    
    it "should map to unsubscribe command", ->
      @socket.send = (frame) ->
        assert.equal frame.command, "UNSUBSCRIBE"
        assert.equal frame.headers["id"], "sub-1"
      @client.unsubscribe(id: "sub-1")

