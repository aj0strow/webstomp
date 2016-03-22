Signal = require "../signal"
Frame = require "../frame"
{fromCallback} = require "bluebird"

class Transport
  @events = ["open", "message", "frame", "heartbeat", "error", "close"]
  
  constructor: (ws) ->
    @ws = ws
    @heartbeat = null
    @signals = {}
    
    # init signals
    
    @constructor.events.forEach (name) =>
      @signals[name] = new Signal()
    
    # proxy websocket events
    
    @ws.on "open", =>
      @signals.open.emit true
    
    @ws.on "message", (message) =>
      @receiveMessage message
    
    @ws.on "error", (err) =>
      @signals.error.emit err
    
    @ws.on "close", =>
      clearInterval @heartbeat
      @signals.close.emit true
  
  on: (name, fn) ->
    @addListener(name, fn)
  
  addListener: (name, fn) ->
    @signals[name].addListener(fn)
  
  removeListener: (name, fn) ->
    @signals[name].removeListener(fn)
  
  receiveMessage: (message) ->
    if /^\s*$/.test message
      @signals.heartbeat.emit true
    else
      try
        frame = Frame.fromString(message)
        @signals.frame.emit frame
      catch err
        @signals.error.emit err
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
