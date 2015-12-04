Router = require "../router"
Session = require "../session"
Server = require "../server"
{assign} = require "lodash"

class App extends Router
  accept: (socket) ->
    session = new Session(socket)
    
    dispatch = (context) =>
      @dispatch context, (err) =>
        if err
          @emit "error", err
    
    socket.on "message", (frame) ->
      context = Object.create(session)
      dispatch assign(context, frame)
    
    socket.on "close", ->
      # Ensure disconnect is called at least once
      context = Object.create(session)
      frame = 
        command: "DISCONNECT"
        headers: {}
      dispatch assign(context, frame)
  
  listen: (port) ->
    server = new Server(port: port)
    server.on "connection", (socket) =>
      @accept socket
    return server

module.exports = App
