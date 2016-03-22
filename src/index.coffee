App = require "./app"

webstomp = ->
  return new App()

webstomp.Frame = require "./frame"
webstomp.Transport = require "./transport"
webstomp.ClientTransport = require "./client-transport"
webstomp.ServerTransport = require "./server-transport"

webstomp.Client = require "./client"
webstomp.Server = require "./server"
webstomp.Router = require "./router"
webstomp.App = App

module.exports = webstomp
