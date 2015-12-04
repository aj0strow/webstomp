WebSocket = require "ws"
{Socket} = require("../../src")

ws = new WebSocket("ws://localhost:8080")
socket = new Socket(ws)

socket.on "message", (frame) ->
  console.log "message", frame

socket.on "error", (err) ->
  console.error err

socket.on "open", ->
  connect = ->
    socket.send
      command: "CONNECT"
      headers: {}

  setTimeout connect, 10

  subscribe = ->
    socket.send
      command: "SUBSCRIBE"
      headers:
        destination: "/messages"

  setTimeout subscribe, 15

  post = ->
    socket.send
      command: "SEND"
      headers:
        destination: "/messages"
      body: "hello"

  [ 120, 180 ].forEach (n) ->
    setTimeout post, n

  disconnect = ->
    socket.close()

  setTimeout disconnect, 3000
