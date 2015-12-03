# Stomp Socket wraps a websockets for frames

Frame = require "../frame"
{EventEmitter} = require "events"

COMMANDS = new Set([
  "CONNECT"
  "STOMP"
  "SEND"
  "SUBSCRIBE"
  "UNSUBSCRIBE"
  "DISCONNECT"
  "CONNECTED"
  "MESSAGE"
  "RECEIPT"
  "ERROR"
])

class Socket extends EventEmitter
  constructor: (ws) ->
    @ws = ws
    
    ws.on "open", =>
      @emit "open"
    
    ws.on "message", (buffer) =>
      @emit "message", Frame.fromString(buffer)
    
    ws.on "error", (err) =>
      @emit "error", err
    
    ws.on "close", =>
      @emit "close"
  
  send: (frame) ->
    {command} = frame
    unless COMMANDS.has(command)
      throw new Error("Bad command: #{ command }")
    @ws.send Frame.toString(frame), (err) =>
      @emit "error", err
  
  close: ->
    @ws.close()

module.exports = Socket
