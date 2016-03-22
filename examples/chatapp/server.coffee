{EventEmitter} = require "events"
webstomp = require "../../src"
{each} = require "lodash"
Kefir = require "kefir"

app = webstomp()
bus = new EventEmitter()

app.connect ->
  @state.user = true
  @state.hooks = {}
  @state.message = 0
  
  console.log(">> client")
  
  @connected
    host: "test"
    session: "user-1"
    version: "1.2"

app.disconnect ->
  console.log("<< client")
  each @state.hooks, (fn) -> fn()

app.use (next) ->
  if @state.user
    next()
  else
    next(new Error("invalid auth"))

app.send "/messages", ->
  bus.emit "message", @body

app.subscribe "/messages", ->  
  stream = Kefir.fromEvents(bus, "message")
  
  sendMessage = (message) =>
    console.log("[message]", message)
    @message({
      subscription: @headers.id
      destination: "/messages"
      "message-id": "m-#{ @state.message += 1 }"
    }, message)
  stream.onValue(sendMessage)
  @state.hooks[@headers.id] = ->
    stream.offValue(sendMessage)

app.listen(8080)

app.on "error", (err) ->
  console.error(err)

console.log("app started ws://localhost:8080")
