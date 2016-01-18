{EventEmitter} = require "events"
Kefir = require "kefir"

app = require("../../src")()

bus = new EventEmitter()
Kefir.fromEvents(bus, "message").log("database")

app.connect ->
  @state.user = true
  @state.unsubscribe = []
  @connected(session: "user-1")

app.use "/messages", (next) ->
  if @state.user
    return next()
  next(new Error "not authenticated")

app.send "/messages", ->
  bus.emit "message", @body

app.subscribe "/messages", ->
  unhook = @observe Kefir.fromEvents(bus, "message")
  @state.unsubscribe.push unhook

app.disconnect ->
  @state.unsubscribe.forEach (f) -> f()

app.listen(8080)
console.log("app started wss://localhost:8080")
