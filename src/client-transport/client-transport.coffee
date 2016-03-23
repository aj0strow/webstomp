Transport = require "../transport"

class ClientTransport extends Transport
  connect: (headers) ->
    assertHeaders headers, [ "accept-version", "host" ]
    @sendFrame
      command: "CONNECT"
      headers: headers

  stomp: (headers) ->
    @connect headers

  send: (headers, body) ->
    assertHeaders headers, [ "destination" ]
    @sendFrame
      command: "SEND"
      headers: headers
      body: body

  subscribe: (headers) ->
    assertHeaders headers, [ "destination", "id" ]
    @sendFrame
      command: "SUBSCRIBE"
      headers: headers

  unsubscribe: (headers) ->
    assertHeaders headers, [ "id" ]
    @sendFrame
      command: "UNSUBSCRIBE"
      headers: headers

  disconnect: (headers) ->
    @sendFrame
      command: "DISCONNECT"
      headers: headers


assertHeaders = (headers, names) ->
  unless headers
    throw new Error("headers required")
  for name in names
    unless headers[name]
      throw new Error("#{name} header required")


module.exports = ClientTransport
