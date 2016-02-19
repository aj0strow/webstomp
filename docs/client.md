### `Client`

Webstomp clients wrap `webstomp.Transport` to ensure proper protocol usage and provide a high-level api for use in frontend apps. 

```js
client = new Client(transport)
```

Connect with api keys.

```
headers = {
  "api-key": "c9f35384cae9579046b",
  "heart-beat": "10000,0"
}
promise = client.connect(headers)
  
promise
  .then(function () {
    // received connected frame from server
    // if requested server heartbeats are auto-sent
  })
  .catch(fucntion (err) {
    // server rejected client
  })
```

Send a request and receive a receipt or error.

```
headers = {
  destination: "/messages"
}
body = "hey whats up"

promise = client.send(headers, body)

promise
  .then(function () {
    // sent successfully
    // and received receipt from server
  })
  .catch(function (err) {
    // network failure
    // or server rejected request
  })
```

Subscribe to a destination. 

```
observable = client.source({
  destination: "/messages"
})

subscription = observable.subscribe({
  next (data) {
    // client subscribe received
    // data is parsed message body
  },
  
  error (err) {
    // server rejected subscription
  },
})

subscription.unsubscribe()
```
