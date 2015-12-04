# STOMP

Read about [STOMP protocol here](https://stomp.github.io/index.html). 

It seems STOMP is an under-used protocol and perfectly suited to sit on top of persistent WebSocket connections. My hope is this package will provide structure so writing STOMP servers is as simple as writing HTTP servers. 

### Frame

Each message between client and server is a "frame", which looks like:

```js
{
  command: "string",
  headers: { "string": "string" },
  body: "string",
}
```

The protocol defines which commands and headers are valid. It checks if the command is correct, but certainly doesn't check headers (yet). 

### Socket

The STOMP socket is a light wrapper around each WebSocket to encode frame objects to text send over the wire and back. 

```js
var WebSocket = require("ws")
var {Socket} = require("stomp")

var ws = new WebSocket("https://example.com")
var socket = new Socket(ws)

socket.on("message", function (frame) {
  // frame objects emitted here
})

socket.send({ command, headers, body }, function (err) {
  // failed to send :(
})
```

### Server

Like the socket, the server is a light wrapper around WebSocketServer whish emits STOMP sockets instead of websockets. 

```js
var {Server} = require("stomp")

var server = new Server({ port: 8000 })
server.on("connection", function (socket) {
  // socket is a STOMP socket
})
```

Ok, you're bored. I get it. Bear with me.

### Session

Sockets are pretty basic though, we can do better. STOMP sessions make some assumptions to provide convenience. It encodes js objects and arrays as JSON and adds headers, and writes js errors as error packets. 

You can send frames by verb for a shorter method call. 

```js
var {Session} = require("stomp")

// socket is a stomp socket
var session = new Session(socket)

// Send connected frame
session.connected({ session: "session-id-123", server: "OurCompany/3.4" })

// Send message to a channel
var data = [ { data: "here" } ]
var headers = { "channel": "/notifications" }
session.message(data, headers)

// Send errors to client
session.error(new Error("Bad arguments"))
```

This allows for higher-level helpers, like piping an observable. So we're taking `es-observable`, `kefir`, `baconjs`, `event-stream`, that kind of thing. 

```js
// When client subscribes
var unhook = session.observe(stream, { "headers": "here" })

// When client unsubscribes
unhook()
```

This allows you to create services/modules that return a stream, and pipe that stream right to the client. 

### Router

So we want services and modules returning streams. The next step is to add structure to keep logic separate. Artists steal, right?

```js
var {Router} = require("stomp")

var router = new Router()

router.use(function (context, next) {
  // proceed to next
  next()
  
  // halt on error
  next(new Error("Colors not coordinated"))
})

router.connect(function () {
  // Context is `this`
  this.command
  this.headers
  this.body
  
  // Keep track of stuff on `context` of this, which is actually pretty confusing
  // will need to come up with a different name
  var {email, passcode} = this.headers  
  this.context.user = authenticate(email, passcode)
  
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

It's starting to look nice, eh.

### App

Finally, the app ties it all together. It opens a STOMP (websocket) server, acts like a router, and dispatches client request frames (to itself). 

```
var {App} = require("stomp")
var app = new App()

// Or you can be fancy
// var app = require("stomp")()

app.use(router)

app.use(function () {
  this.error(new Error("Not found"))
})

app.listen(8080)
```

So there's my concept. For real-time apps, on-demand PUB/SUB channels are very practical, and play nicely with React component lifecycles.

**MIT License**
