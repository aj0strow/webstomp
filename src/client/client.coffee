{isString} = require "lodash"
EventEmitter = require "events"

class Client extends EventEmitter
  constructor: (transport) ->
    @transport = transport
    @heartbeat = "10000,0"
    @subscription = 0
    @disconnected = false
    @transport.on "frame", (frame) =>
      @onFrame frame

  connect: (headers) ->
    unless headers
      throw new Error("headers required")
    unless headers["accept-version"]
      throw new Error("accept-version header required")
    unless headers["host"]
      throw new Error("host header required")
    
    if headers["heart-beat"]
      @heartbeat = headers["heart-beat"]
    else
      headers["heart-beat"] = @heartbeat
    
    @sendFrame
      command: "CONNECT"
      headers: headers

  send: (headers, body) ->
    unless headers
      throw new Error("headers required")
    unless headers["destination"]
      throw new Error("destination header required")
    unless isString(body)
      headers["content-type"] = "application/json"
      body = JSON.stringify(body)
    @sendFrame
      command: "SEND"
      headers: headers
      body: body

  subscribe: (headers) ->
    unless headers
      throw new Error("headers required")
    unless headers["destination"]
      throw new Error("destination header required")
    unless headers["id"]
      headers["id"] = "sub-#{ @subscription += 1 }"
    @sendFrame
      command: "SUBSCRIBE"
      headers: headers

  unsubscribe: (headers) ->
    unless headers
      throw new Error("headers required")
    unless headers["id"]
      throw new Error("id header required")
    @sendFrame
      command: "UNSUBSCRIBE"
      headers: headers

  disconnect: (headers) ->
    clearInterval @heartbeat
    @sendFrame
      command: "DISCONNECT"
      headers: headers
    @disconnected = true

  sendFrame: (frame) ->
    if @disconnected
      return
    @transport.sendFrame frame

  autoHeartbeat: (cx, sy) ->
    if cx == 0 || sy == 0
      return
    frequency = Math.max cx, sy
    @transport.autoHeartbeat frequency

  onFrame: (frame) ->
    {command, headers} = frame
    switch command
      when "CONNECTED"
        @onConnected headers
  
  onConnected: (headers) ->
    if headers["heart-beat"]
      [ cx, cy ] = @heartbeat.split(",")
      [ sx, sy ] = headers["heart-beat"].split(",")
      @autoHeartbeat parseInt(cx, 10), parseInt(sy, 10)
    @emit "connected"

module.exports = Client
