# `webstomp`

Read about [STOMP protocol here](https://stomp.github.io/index.html). 

It seems STOMP is under-appreciated for realtime apps. It's text-based so it can work over WebSocket connections. My hope is to provide enough structure to make STOMP servers as simple as express HTTP servers. 

The motivation for using STOMP instead of `socket.io` or `SocketCluster` or `Sails` or `ActionCable` is that STOMP is an open protocol which can run on any client or server the supports TCP connections. Things change, perhaps in the future you'll want to use `golang` on the server and native `iOS` sockets. 

Each package module is explained below, from lowest to highest abstraction. 

### Frame

Each message between client and server is a "frame", which looks like:

```js
{
  command: "string",
  headers: { "string": "string" },
  body: "string",
}
```

The STOMP protocol defines available commands and headers. `webstomp` checks if the command is valid. 

### Socket

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

```js
var {Server} = require("webstomp")

var server = new Server({ port: 8000 })
server.on("connection", function (socket) {
  // Socket is a webstomp Socket
})
```

You're bored. Here's the useful bits coming up. 

### Session

Send frames by command name, encode javascript objects. 

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

For real-time apps, it's practical to create lazy observables, and pipe them to the client on-demand. For example notifications could be an `es-observable`, `kefir` or `baconjs` stream, readable `event-stream`, etc. 

```js
// When client subscribes
var unhook = session.observe(stream, { "channel": "/notifications" })

// When client unsubscribes
unhook()
```

### Router

It's designed to look like the express router. 

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

The `webstomp` app ties it all together. It opens a WebSocket server, wraps it with a `webstomp` server, acts like a `webstomp` router, and dispatches server request frames to itself. 

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

### Mount Http Server

You can mount a `webstomp` server on an HTTP server, which allows you to use `express` too.

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

So that's the concept. For realtime apps on-demand PUB/SUB channels are very practical, and play nicely with React components. Please contribute ideas, bugs, etc. 

**MIT License**
