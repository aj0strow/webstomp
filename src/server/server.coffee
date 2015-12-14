WebSocket = require("ws")
{EventEmitter} = require "events"
Socket = require "../socket"


# Create from port
#    server = new Server(port: 8080)
#
# Create from http server
#    server = new Server(server: httpServer)

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
