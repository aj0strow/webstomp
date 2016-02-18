EventEmitter = require "events"
{fromCallback} = require "bluebird"
Frame = require "../frame"

class Transport extends EventEmitter
  constructor: (websocket) ->
    @ws = websocket
    @heartbeat = null
    
    @ws.on "open", =>
      @emit "open"
    
    @ws.on "message", (message) =>
      @onMessage message
    
    @ws.on "error", (err) =>
      @emit "error", err
    
    @ws.on "close", =>
      clearInterval @heartbeat
      @emit "close"
  
  onMessage: (message) ->
    if /^\s*$/.test message
      @emit "heartbeat"
    else
      try
        frame = Frame.fromString(message)
        @emit "frame", frame
      catch err
        @emit "error"
        @close()
  
  sendFrame: (frame) ->
    message = Frame.toString(frame)
    fromCallback (onError) =>
      @ws.send message, onError
  
  sendHeartbeat: ->
    fromCallback (onError) =>
      @ws.send "\n", onError
  
  autoHeartbeat: (x, y) ->
    if x == 0 || y == 0
      return
    frequency = Math.max(x, y)
    sendHeartbeat = @sendHeartbeat.bind(this)
    @heartbeat = setInterval sendHeartbeat, frequency
  
  close: ->
    @ws.close()

module.exports = Transport
