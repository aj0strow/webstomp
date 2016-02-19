{fromCallback} = require "bluebird"
Frame = require "../frame"
Signal = require "../signal"

class Transport
  @events = ["open", "error", "close", "frame", "heartbeat"]
  
  constructor: (websocket) ->
    @ws = websocket
    @heartbeat = null
    
    @signals = {}
    @constructor.events.forEach (event) =>
      @signals[event] = new Signal()
    
    @ws.on "open", =>
      @signals.open.emit()
    
    @ws.on "message", (message) =>
      @onMessage message
    
    @ws.on "error", (err) =>
      @signals.error.emit(err)
    
    @ws.on "close", =>
      clearInterval @heartbeat
      @signals.close.emit()
  
  on: (name, fn) ->
    @signals[name].addListener(fn)
  
  onMessage: (message) ->
    if /^\s*$/.test message
      @signals.heartbeat.emit()
    else
      try
        frame = Frame.fromString(message)
        @signals.frame.emit(frame)
      catch err
        @signals.error.emit(err)
        @close()
  
  sendFrame: (frame) ->
    message = Frame.toString(frame)
    fromCallback (onError) =>
      @ws.send message, onError
  
  sendHeartbeat: ->
    fromCallback (onError) =>
      @ws.send "\n", onError
  
  autoHeartbeat: (ms) ->
    sendHeartbeat = @sendHeartbeat.bind(this)
    @heartbeat = setInterval sendHeartbeat, ms
  
  close: ->
    @ws.close()

module.exports = Transport
