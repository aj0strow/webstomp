pathToRegexp = require "path-to-regexp"
async = require "async"

commands = [
  "connect"
  "send"
  "subscribe"
  "unsubscribe"
  "disconnect"
]

class Router
  @commands = commands
  
  constructor: ->
    @routes = []
  
  dispatch: (context, next) ->
    iterator = (route, next) ->
      route.call(context, next)
    async.eachSeries @routes, iterator, next
  
  use: (path, fn) ->
    unless path && fn
      fn ||= path
      path = null
    route = switch
      when fn instanceof Router
        (next) ->
          fn.dispatch(this, next)
      when path
        withPath(path, fn)
      else
        fn
    @routes.push route

Router.commands.forEach (command) ->
  Router.prototype[command] = (path, fn) ->
    unless path && fn
      fn ||= path
      path = null
    @use path, withCommand(command.toUpperCase(), fn)

withPath = (path, fn) ->
  # parse path regexp
  keys = []
  re = pathToRegexp path, keys
  emitter = this
  
  # check path and populate params
  return (next) ->
    params = {}
    
    # exit if wrong type of command
    path = @headers["destination"]
    return next() unless path
    
    # Early exit if wrong path
    match = re.exec path
    return next() unless match
    
    # Get route params
    keys.forEach (key, i) ->
      params[key.name] = match[i + 1]
    @params = params
    
    # proxy func finally
    fn.call(this, next)

withCommand = (command, fn) ->
  return (next) ->
    if @command == command
      fn.call(this, next)
    else
      next()

module.exports = Router
