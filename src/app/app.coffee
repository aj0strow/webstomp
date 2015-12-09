Router = require "../router"
Session = require "../session"
Server = require "../server"
{assign} = require "lodash"

class App extends Router
  accept: (socket) ->
    session = new Session(socket)
    
    session.on "error", (err) =>
      @emit "error", err
    
    dispatch = (frame) =>
      context = Object.create(session)
      assign(context, frame, context: session.context)
      @dispatch context, (err) =>
        if err
          @emit "error", err
    
    socket.on "message", (frame) ->
      dispatch frame
    
    socket.on "close", ->
      # Ensure disconnect is called at least once
      frame = 
        command: "DISCONNECT"
        headers: {}
      dispatch frame
  
  listen: (port) ->
    server = new Server(port: port)
    server.on "connection", (socket) =>
      @accept socket
    return server

module.exports = App
