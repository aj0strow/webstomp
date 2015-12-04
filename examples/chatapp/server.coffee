{EventEmitter} = require "events"
Kefir = require "kefir"

app = require("../../src")()

bus = new EventEmitter()
Kefir.fromEvents(bus, "message").log("database")

app.connect ->
  @context.user = true
  @context.unsubscribe = []
  @connected(session: "user-1")

app.use "/messages", (self, next) ->
  if @context.user
    return next()
  next(new Error "not authenticated")

app.send "/messages", ->
  bus.emit "message", @body

app.subscribe "/messages", ->
  unhook = @observe Kefir.fromEvents(bus, "message")
  @context.unsubscribe.push unhook

app.disconnect ->
  @context.unsubscribe.forEach (f) -> f()

app.listen(8080)
