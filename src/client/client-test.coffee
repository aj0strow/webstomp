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
    
    it "should map to send command", (done) ->
      @socket.send = (frame) ->
        assert.equal frame.command, "SEND"
        assert.equal frame.headers.destination, "/dest"
        done()
      @client.send(destination: "/dest")
    
    it "should encode json", (done) ->
      @socket.send = (frame) ->
        assert.equal frame.headers["content-type"], "application/json"
        assert.equal frame.body, '{"ok":true}'
        done()
      @client.send({ destination: "/" }, { ok: true })
  