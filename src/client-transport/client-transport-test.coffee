EventEmitter = require "events"
assert = require "assert"
ClientTransport = require "./client-transport"

describe "ClientTransport", ->
  beforeEach ->
    @ws = new EventEmitter()
    @transport = new ClientTransport(@ws)

  assertCommand = (command) ->
    (message, fn) ->
      parsedCommand = message.split(/\n/).shift()
      assert.equal parsedCommand, command
      fn()

  describe "connect", ->
    it "should map to connect frame", ->
      @ws.send = assertCommand "CONNECT"
      @transport.connect
        "accept-version": "1.2"
        "host": "www.example.com"

    it "should fail without accept version header", ->
      assert.throws =>
        @transport.connected {}

  describe "send", ->
    it "should map to send frame", ->
      @ws.send = assertCommand "SEND"
      @transport.send
        "destination": "/"

    it "should have destination header", ->
      assert.throws =>
        @transport.send {}

  describe "subscribe", ->
    it "should map to subscribe frame", ->
      @ws.send = assertCommand "SUBSCRIBE"
      @transport.subscribe
        "destination": "/"
        "id": "sub-1"

    it "should fail without id", ->
      assert.throws =>
        @transport.subscripe { "destination": "/" }

  describe "unsubscribe", ->
    it "should map to unsubscribe frame", ->
      @ws.send = assertCommand "UNSUBSCRIBE"
      @transport.unsubscribe
        "id": "sub-1"

    it "should fail without id", ->
      assert.throws =>
        @transport.unsubscribe {}

  describe "disconnect", ->
    it "should map to disconnect frame", ->
      @ws.send = assertCommand "DISCONNECT"
      @transport.disconnect()
