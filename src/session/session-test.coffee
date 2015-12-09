Session = require "./session"
{EventEmitter} = require "events"
Sinon = require "sinon-commonjs"
assert = require "assert"
Kefir = require "kefir"

describe "Stomp Session", ->
  beforeEach ->
    @socket = new EventEmitter()
    @socket.send = Sinon.spy()
    @session = new Session(@socket)
  
  it "should emit errors when socket send fails", (done) ->
    @socket.send = (message, func) ->
      func(new Error "Network problems")
    
    @session.on "error", (err) ->
      done()
    
    frame = 
      command: "MESSAGE"
      headers: {}
      body: "Hello friend"
    @session.send frame
  
  it "should not send after socket closes", ->
    @socket.emit "close"
    @session.send command: "invalid"
  
  it "should send connected frames", ->
    @session.connected session: "user-123"
    frame = @socket.send.getCall(0).args[0]
    assert.equal frame.command, "CONNECTED"
    assert.equal frame.headers["session"], "user-123"
  
  it "should send messages", ->
    @session.message "Oh Canada"
    frame = @socket.send.getCall(0).args[0]
    assert.equal frame.command, "MESSAGE"
  
  it "should encode json messages", ->
    @session.message [ { a: 1 } ]
    frame = @socket.send.getCall(0).args[0]
    assert.equal frame.command, "MESSAGE"
    assert /json/.test frame.headers["content-type"]
    assert.equal frame.body, '[{"a":1}]'
  
  it "should send errors", ->
    @session.error new Error "Snow"
    frame = @socket.send.getCall(0).args[0]
    assert.equal frame.command, "ERROR"
    assert.equal frame.headers["message"], "Snow"
  
  it "should send receipts", ->
    request = 
      command: "SEND"
      headers: { "receipt": "ok-123" }
    @session.receipt request
    frame = @socket.send.getCall(0).args[0]
    assert.equal frame.command, "RECEIPT"
    assert.equal frame.headers["receipt-id"], "ok-123"
  
  it "should close client", ->
    @socket.close = Sinon.spy()
    @session.close()
    assert @socket.close.called
  
  describe "observe", ->
    it "should write messages", ->
      stream = Kefir.constant("OK")
      @session.observe stream
      frame = @socket.send.getCall(0).args[0]
      assert.equal frame.command, "MESSAGE"
    
    it "should write errors", ->
      stream = Kefir.constantError(new Error "Its too cold")
      @session.observe stream
      frame = @socket.send.getCall(0).args[0]
      assert.equal frame.command, "ERROR"
    
    it "should return unsubscribe callback", (done) ->
      stream = Kefir.later(1, "OK")
      unsubscribe = @session.observe stream
      unsubscribe()
      check = =>
        assert !@socket.send.called
        done()
      setTimeout check, 2
            
      
      
  it "should observe kefir streams", ->
    
    
    
    