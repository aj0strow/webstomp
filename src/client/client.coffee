{isString, identity} = require "lodash"
EventEmitter = require "events"
Promise = require "bluebird"
Observable = require "zen-observable"

class Client extends EventEmitter
  constructor: (transport) ->
    @transport = transport
    
    # default to >= 10 seconds
    @connection = null
    @heartbeat = "10000,0"
    
    # promise handlers
    @receipts = {}
    
    # observable handlers
    @subscriptions = {}
    
    # unique id counters
    @receipt = 0
    @subscription = 0
    
    # flag when dead
    @disconnected = false
    
    @transport.on "frame", (frame) =>
      @onFrame frame
    
    @transport.on "close", =>
      @emit "disconnected"

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
    
    connected = new Promise (resolve, reject) =>
      @connection = {resolve, reject}
    .finally =>
      @connection = null
    
    @sendFrame
      command: "CONNECT"
      headers: headers
    .tap =>
      connected
    .tap =>
      @emit "connected"

  send: (headers, body) ->
    unless headers
      throw new Error("headers required")
    unless headers["destination"]
      throw new Error("destination header required")
    
    unless isString(body)
      headers["content-type"] = "application/json"
      body = JSON.stringify(body)
    
    unless headers["receipt"]
      headers["receipt"] = "req-#{ @receipt += 1 }"
    
    @sendFrameWithReceipt
      command: "SEND"
      headers: headers
      body: body

  source: (headers) ->
    new Observable (emitter) =>      
      @subscriptions[ headers["id"] ] = emitter
      @subscribe headers
      =>
        @unsubscribe headers

  subscribe: (headers) ->
    unless headers
      throw new Error("headers required")
    unless headers["destination"]
      throw new Error("destination header required")
    
    unless headers["id"]
      headers["id"] = "S#{ @subscription += 1 }"
    
    @sendFrameWithReceipt
      command: "SUBSCRIBE"
      headers: headers

  unsubscribe: (headers) ->
    unless headers
      throw new Error("headers required")
    unless headers["id"]
      throw new Error("id header required")

    @sendFrameWithReceipt
      command: "UNSUBSCRIBE"
      headers: headers
    .tap =>
      id = headers["id"]
      if @subscriptions[id]
        delete @subscriptions[id]

  disconnect: (headers) ->
    receipt = @sendFrameWithReceipt
      command: "DISCONNECT"
      headers: headers || {}
    @disconnected = true
    receipt.finally =>
      @transport.close()

  # ---

  onFrame: (frame) ->
    {command, headers, body} = frame
    switch command
      when "CONNECTED"
        @onConnected headers
      when "RECEIPT"
        @onReceipt headers
      when "ERROR"
        @onError headers
      when "MESSAGE"
        @onMessage headers, body

  onConnected: (headers) ->
    if heartbeat = headers["heart-beat"]
      @autoHeartbeat heartbeat
    if @connection
      @connection.resolve()

  onReceipt: (headers) ->
    if receipt = @receipts[headers["receipt-id"]]
      receipt.resolve()

  onError: (headers) ->
    err = new Error(headers["message"])
    if @connection
      @connection.reject err
    if receipt = @receipts[headers["receipt-id"]]
      receipt.reject err

  onMessage: (headers, body) ->
    if subscription = @subscriptions[headers["subscription"]]
      subscription.next body

  # ---

  sendFrameWithReceipt: (frame) ->
    receipt = "R#{ @receipt += 1 }"
    frame.headers["receipt"] = receipt
    
    received = new Promise (resolve, reject) =>
      @receipts[receipt] = {resolve, reject}
    .finally =>
      delete @receipts[receipt]
    
    @sendFrame frame
      .tap => received

  sendFrame: (frame) ->
    if @disconnected
      Promise.reject new Error("client disconnected")
    else
      @transport.sendFrame frame

  autoHeartbeat: (header) ->
    [ cx, cy ] = @heartbeat.split(",").map Number
    [ sx, sy ] = header.split(",").map Number
    if cx > 0 && sy > 0
      frequency = Math.max cx, sy
      @transport.autoHeartbeat frequency

module.exports = Client
