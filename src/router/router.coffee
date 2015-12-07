{EventEmitter} = require "events"
pathToRegexp = require "path-to-regexp"
async = require "async"
Server = require "../server"

COMMANDS = [
  "connect"
  "send"
  "subscribe"
  "unsubscribe"
  "disconnect"
]

class Router extends EventEmitter
  constructor: ->
    @routes = []
  
  dispatch: (context, next) ->
    iterator = (route, next) ->
      route.call(context, next)
    async.eachSeries @routes, iterator, next

  use: (path, func) ->
    unless path && func
      func ||= path
      path = null
    route = switch
      when func instanceof Router
        (next) ->
          func.dispatch(this, next)
      when path
        withPath(func, path)
      else
        func
    @routes.push route

COMMANDS.forEach (command) ->
  Router.prototype[command] = (path, func) ->
    unless path && func
      func ||= path
      path = null
    @use path, withCommand(func, command.toUpperCase())

withPath = (func, path) ->
  # Parse path regexp
  keys = []
  re = pathToRegexp path, keys
  emitter = this
  
  # Check path and populate params
  return (next) ->
    params = {}
    
    # Early exit if wrong type of command
    path = @headers["destination"]
    return next() unless path
    
    # Early exit if wrong path
    match = re.exec path
    return next() unless match
    
    # Get route params
    keys.forEach (key, i) ->
      params[key.name] = match[i + 1]
    @params = params
    
    # Proxy func finally
    func.apply(this, arguments)

withCommand = (func, command) ->
  return (next) ->
    if @command == command
      func.apply(this, arguments)
    else
      next()

module.exports = Router
