WebSocket = require "ws"
Signal = require "../signal"
ServerTransport = require "../server-transport"

# Create from port
#    server = new Server(port: 8080)
#
# Create from http server
#    server = new Server(server: httpServer)

class Server
  @events = ["listening", "connection", "error"]
  
  constructor: (params) ->
    @signals = {}
    @constructor.events.forEach (name) =>
      @signals[name] = new Signal()
    
    @server = WebSocket.createServer params, (ws) =>
      @receiveConnection(ws)
    
    @server.on "listening", =>
      @signals.listening.emit true
    
    @server.on "error", (err) =>
      @signals.error.emit err
  
  on: (name, fn) ->
    @addListener(name, fn)
  
  addListener: (name, fn) ->
    @signals[name].addListener(fn)
  
  removeListener: (name, fn) ->
    @signals[name].removeListener(fn)
  
  receiveConnection: (ws) ->
    transport = new ServerTransport(ws)
    @signals.connection.emit transport
  
  close: ->
    @server.close()

module.exports = Server
