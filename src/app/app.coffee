Signal = require "../signal"
Router = require "../router"
Server = require "../server"
{assign} = require "lodash"

class App
  @events = ["error"]
  
  constructor: ->
    @router = new Router()
    
    @signals = {}
    @constructor.events.forEach (name) =>
      @signals[name] = new Signal()
  
  on: (name, fn) ->
    @addListener(name, fn)
  
  addListener: (name, fn) ->
    @signals[name].addListener(fn)
  
  removeListener: (name, fn) ->
    @signals[name].removeListener(fn)
  
  accept: (transport) ->
    transport.on "error", (err) =>
      @signals.error.emit err
    
    state = {}
    
    dispatch = (frame) =>
      context = Object.create(transport)
      assign(context, frame, { state: state })
      
      @router.dispatch context, (err) =>
        if err
          @signals.error.emit err
    
    transport.on "frame", (frame) ->
      dispatch frame
    
    transport.on "close", ->
      dispatch
        command: "DISCONNECT"
        headers: {}
    
    return null
  
  mount: (params) ->
    server = new Server(params)
    server.on "connection", @accept.bind(this)
    return server
  
  listen: (port) ->
    return @mount(port: port)

Router.commands.concat([ "use" ]).forEach (name) ->
  App.prototype[name] = ->
    @router[name].apply(@router, arguments)

module.exports = App
