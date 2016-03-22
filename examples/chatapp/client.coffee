WebSocket = require "ws"
{ClientTransport} = require "../../src"

ws = new WebSocket("ws://localhost:8080")
transport = new ClientTransport(ws)



transport.on "frame", (frame) ->
  console.log "frame", frame

transport.on "error", (err) ->
  console.log "error", err

transport.on "close", ->
  console.log "closed"

transport.on "open", ->
  console.log("open")
  connect = ->
    transport.connect
      "host": "chatapp"
      "accept-version": "1.2"
      "heart-beat": "0,0"
  setTimeout connect, 10

  subscribe = ->
    transport.subscribe
      id: "sub-1"
      destination: "/messages"
  setTimeout subscribe, 15

  post = (message) ->
    transport.send({ destination: "/messages" }, message)
  
  setTimeout((-> post("help")), 120)
  setTimeout((-> post("thanks")), 180)

  disconnect = ->
    transport.close()
  
  setTimeout(disconnect, 2000)