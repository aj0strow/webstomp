{isString} = require "lodash"

class Client
  constructor: (socket) ->
    @socket = socket
    @counter = 0
  
  send: (headers, body) ->
    unless headers
      throw new Error("headers required")
    unless headers["destination"]
      throw new Error("destination header required")
    unless isString(body)
      headers["content-type"] = "application/json"
      body = JSON.stringify(body)
    @socket.send
      command: "SEND"
      headers: headers
      body: body
  
  subscribe: (headers) ->
    unless headers
      throw new Error("headers required")
    unless headers["destination"]
      throw new Error("destination header required")
    unless headers["id"]
      headers["id"] = "sub-#{ @counter += 1 }"
    @socket.send
      command: "SUBSCRIBE"
      headers: headers

  unsubscribe: (headers) ->
    unless headers
      throw new Error("headers required")
    unless headers["id"]
      throw new Error("id header required")
    @socket.send
      command: "UNSUBSCRIBE"
      headers: headers

module.exports = Client
