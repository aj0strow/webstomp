### `Transport`

Webstomp transports wrap WebSockets to encode outgoing frames, parse incoming frames, and send heartbeats if required. 

```js
transport = new Transport(websocket)
```

Find out when the connection opens and closes. 

```js
transport.on("open", function () {
  // now connected
})

transport.on("close", function () {
  // connection dropped
})
```

Find out when a transport connection fails.

```
transport.on("error", function (err) {
  // connection to server refused
})
```

Send a stomp frame to the server.

```
transport.sendFrame({
  command: "CONNECT",
  headers: {
    passcode: "api-secret",
  },
})
```

Listen for incoming stomp frames.

```
transport.on("frame", function (frame) {
  // received a server frame
})
```

Send a hearbeat.

```js
transport.sendHeartbeat()
```

Listen for incoming heartbeats.

```js
transport.on("heartbeat", function () {
  // received a heartbeat
})
```

Auto send heartbeat every 30 seconds.

```
transport.autoHeartbeat(30 * 1000)
```
