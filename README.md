# `webstomp`

Read about [STOMP protocol here](https://stomp.github.io/index.html). 

It seems STOMP is under-appreciated for realtime apps. It's text-based so it can work over WebSocket connections. My hope is to provide enough structure to make STOMP servers as simple as express HTTP servers. 

The motivation for using STOMP instead of `socket.io` or `SocketCluster` or `Sails` or `ActionCable` is that STOMP is an open protocol which can run on any client or server the supports TCP connections. Things change, perhaps in the future you'll want to use `golang` on the server and native `iOS` sockets. 

Each package module is explained below, from lowest to highest abstraction. 

### Frame

Each message between client and server is a "frame", which looks like:

```js
var frame = {
  command: "string",
  headers: { "string": "string" },
  body: "string",
}

var text = Frame.toString(frame)
frame = Frame.fromString(text)
```

The STOMP protocol defines available commands and headers. `webstomp` checks if the command is valid. 

### Socket

The `webstomp` Socket encodes and decodes frames. Otherwise, you'd have to call `toString` and `fromString` on each send and receive. 

```js
var WebSocket = require("ws")
var {Socket} = require("webstomp")

var ws = new WebSocket("https://example.com")
var socket = new Socket(ws)

socket.on("message", function (frame) {
  // Frame objects emitted here
})

socket.send({ command, headers, body }, function (err) {
  // Sends encoded text frame
  
  if (err) {
    // Failed to send :(
  }
})
```

### Server

The `webstomp` Server emits Socket connections. Otherwise, you'd have to wrap each new WebSocket connection yourself. 

```js
var {Server} = require("webstomp")

var server = new Server({ port: 8000 })
server.on("connection", function (socket) {
  // Socket is a webstomp Socket
})
```

You're bored. Here's the useful bits coming up. 

### Session

The `webstomp` Session adds a number of helpers. Otherwise you'd have to send full frames and stringify javascript objects. 

```js
var {Session} = require("webstomp")

// `socket` is a webstomp Socket
var session = new Session(socket)

// Send connected frame
session.connected({ session: "session-id-123", server: "OurCompany/3.4" })

// Send json message to a channel
var data = { key: "value" }
var headers = { "channel": "/notifications" }
session.message(data, headers)

// Send errors to client
session.error(new Error("sharp edges"))
```

For realtime apps, it's practical to model channels as lazy observables. Sessions can pipe observable events to the client as message frames. Examples include `es-observable`, `kefir` or `baconjs` stream, readable `event-stream`, etc.

```js
// When client subscribes
var unhook = session.observe(stream, { "channel": "/notifications" })

// When client unsubscribes
unhook()
```

### Router

The `webstomp` Router is designed to look like express. Instead of HTTP actions, you have STOMP actions. Instead of `(req, res, next)` you have `this (next)`.

```js
var {Router} = require("webstomp")

var router = new Router()

router.use(function (next) {
  // proceed to next
  next()
  
  // halt on error
  next(new Error("colors not coordinated"))
})

router.connect(function () {
  // Context is `this`
  this.command
  this.headers
  this.body
  
  // Keep track of stuff between frames on the `state` object. 
  var {email, passcode} = this.headers
  this.state.user = authenticate(email, passcode)
  
  // The current client session is available on `this` as well
  this.connected()
})

router.send("/users/:id/messages", function () {
  var {id} = this.params
  this.error(new Error("Invalid id: " + id))
})

router.subscribe("/stats/:metric", function () {
  var stream = service.getChanges()
  this.observe(stream)
})

router.use(anotherRouter)
```

### App

The `webstomp` App ties it all together. It creates a WebSocket server, wraps it with a `webstomp` Server, acts like a `webstomp` Router, and dispatches request Frames to the current Session. 

```js
var {App} = require("webstomp")
var app = new App()

// Or you can be fancy
// var app = require("stomp")()

app.use(router)

app.use(function () {
  this.error(new Error("Not found"))
})

app.listen(8080)
```

### Mount Server

You can mount a `webstomp` App onto an HTTP server, which allows you to use the HTTP server too. For example, with express:

```js
var http = require("http")
var stomp = require("webstomp")()
var api = require("express")()

var server = stomp.mount({
  server: http.createServer(api)
})

server.listen(port, function () {
  console.log("open for business")
})
```

So that's it. For realtime apps, on-demand PUB/SUB channels provide structure. The pattern maps well to server-side services that return an observable, and also client-side components that subscribe when added into view, and unsubscribe when removed. 

### Open Source

Please contribute ideas, bugs, etc. 

**MIT License**
