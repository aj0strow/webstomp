assert = require "assert"
Signal = require "./Signal"

describe "Signal", ->
  it "should add listener", ->
    @signal = new Signal()
    
    called = false
    @signal.addListener (event) ->
      assert event.ok
      called = true
    
    @signal.emit {ok: true}
    assert called
  
  it "should remove listener", ->
    @signal = new Signal()
    
    fn = (event) ->
      throw new Error("invalid code path")
    
    @signal.addListener fn
    @signal.removeListener fn
    @signal.emit {}
