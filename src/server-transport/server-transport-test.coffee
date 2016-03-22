EventEmitter = require "events"
ServerTransport = require "./server-transport"
assert = require "assert"

describe "ServerTransport", ->
  beforeEach ->
    @ws = new EventEmitter()
    @transport = new ServerTransport(@ws)

  assertCommand = (command) ->
    (message, fn) ->
      parsedCommand = message.split(/\n/).shift()
      assert.equal parsedCommand, command
      fn()

  describe "connected", ->
    it "should map to connected frame", ->
      @ws.send = assertCommand "CONNECTED"
      @transport.connected
        "version": "1.2"

    it "should fail without version header", ->
      assert.throws =>
        @transport.connected {}

  describe "message", ->
    it "should map to message frame", ->
      @ws.send = assertCommand "MESSAGE"
      @transport.message
        "destination": "/"
        "subscription": "abc"
        "message-id": "M1-1"

    it "should have message id header", ->
      assert.throws =>
        @transport.message
          "destination": "/"
          "subscription": "abc"

  describe "receipt", ->
    it "should map to receipt frame", ->
      @ws.send = assertCommand "RECEIPT"
      @transport.receipt
        "receipt-id": "123"

    it "should fail without receipt id", ->
      assert.throws =>
        @transport.receipt {}

  describe "error", ->
    it "should map to error frame", ->
      @ws.send = assertCommand "ERROR"
      @transport.error
        "message": "too much risk"

    it "should fail without message header", ->
      assert.throws ->
        @transport.error {}
