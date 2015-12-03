WebSocket = require("ws")
{EventEmitter} = require "events"
Socket = require "../socket"

class Server extends EventEmitter
  constructor: (params) ->
    @server = WebSocket.createServer params, (ws) =>
      socket = new Socket(ws)
      @emit "connection", socket
    
    @server.on "error", (err) =>
      @emit "error", err
    
  close: ->
    @server.close()

module.exports = Server
