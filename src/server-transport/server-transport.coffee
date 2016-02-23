Transport = require "../transport"

class ServerTransport extends Transport
  connected: (headers) ->
    assertHeaders headers, [ "version" ]
    @sendFrame
      command: "CONNECTED"
      headers: headers
  
  message: (headers, body) ->
    assertHeaders headers, [ "destination", "subscription", "message-id" ]
    @sendFrame
      command: "MESSAGE"
      headers: headers
      body: body
  
  receipt: (headers) ->
    assertHeaders headers, [ "receipt-id" ]
    @sendFrame
      command: "RECEIPT"
      headers: headers
  
  error: (headers, body) ->
    assertHeaders headers, [ "message" ]
    @sendFrame
      command: "ERROR"
      headers: headers
      body: body


assertHeaders = (headers, names) ->
  unless headers
    throw new Error("headers required")
  for name in names
    unless headers[name]
      throw new Error("#{name} header required")


module.exports = ServerTransport
