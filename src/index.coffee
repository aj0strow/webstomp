App = require "./app"

create = ->
  return new App()

create.App = App
create.Router = require "./router"
create.Socket = require "./socket"
create.Frame = require "./frame"

module.exports = create
