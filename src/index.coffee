App = require "./app"

webstomp = ->
  return new App()

webstomp.App = App
webstomp.Router = require "./router"
webstomp.Socket = require "./socket"
webstomp.Frame = require "./frame"
webstomp.Client = require "./client"

module.exports = webstomp
