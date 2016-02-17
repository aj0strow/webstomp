{isString} = require "lodash"

class Client
  constructor: (socket) ->  
    @socket = socket
    @subscription = 0
    @disconnected = false

  send: (headers, body) ->
    unless headers
      throw new Error("headers required")
    unless headers["destination"]
      throw new Error("destination header required")
    unless isString(body)
      headers["content-type"] = "application/json"
      body = JSON.stringify(body)
    @transmit
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
    @transmit
      command: "SUBSCRIBE"
      headers: headers

  unsubscribe: (headers) ->
    unless headers
      throw new Error("headers required")
    unless headers["id"]
      throw new Error("id header required")
    @transmit
      command: "UNSUBSCRIBE"
      headers: headers

  disconnect: (headers) ->
    @transmit
      command: "DISCONNECT"
      headers: headers
    @disconnected = true

  transmit: (frame) ->
    if @disconnected
      return
    @socket.send frame

module.exports = Client
