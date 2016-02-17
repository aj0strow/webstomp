{isString} = require "lodash"

class Client
  constructor: (socket) ->
    @socket = socket
  
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

module.exports = Client
