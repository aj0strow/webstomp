### `Frame`

Stomp frames are plain-text messages.

```
SEND
destination:/queue/a
receipt:message-12345

hello queue a
```

Parse a text frame into a stomp frame.

```js
frame = fromString(text)

{
  command: "SEND",
  headers: {
    destination: "/queue/a",
    receipt: "message-12345"
  },
  body: "hello queue a"
}
```

Encode a stomp frame to a text frame. 

```js
text = toString({ command, headers, body })
```
