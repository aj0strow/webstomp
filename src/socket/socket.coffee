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

COMMANDS_WITH_BODY = new Set([
  "SEND"
  "MESSAGE"
  "ERROR"
])

class Socket extends EventEmitter
  constructor: (ws) ->
    @ws = ws
    
    ws.on "open", =>
      @emit "open"
    
    ws.on "message", (buffer) =>
      try
        frame = Frame.fromString(buffer)
        if frame
          @emit "message", frame
      catch err
        @emit "error", err
    
    ws.on "error", (err) =>
      @emit "error", err
    
    ws.on "close", =>
      @emit "close"
  
  send: (frame, onError) ->
    {command, body} = frame
    unless COMMANDS.has(command)
      throw new Error("invalid command: #{command}")
    if body and !COMMANDS_WITH_BODY.has(command)
      throw new Error("invalid frame: #{command} must not have body")
    message = Frame.toString(frame)
    @ws.send message, onError
  
  close: ->
    @ws.close()

module.exports = Socket
