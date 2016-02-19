### `STOMP`

Webstomp is a variation on [STOMP 1.2](https://stomp.github.io/stomp-specification-1.2.html). The goal is to adapt the protocol to serve real-time apps instead of backend message brokers. 

The main changes are:

1. No client acks or nacks of server subscription messages. We assume the client receives messages because it's over WebSocket. 

2. Errors associated with a SEND command do not close the connection. This allows the client to perform SEND commands and receive either an ERROR or RECEIPT. 

3. No client transactions (for now). 

#### List of Commands

Client commands.

```
CONNECT or STOMP
 REQUIRED: accept-version, host
 OPTIONAL: login, passcode, heart-beat

SEND
 REQUIRED: destination
 OPTIONAL: transaction

SUBSCRIBE
 REQUIRED: destination, id
 OPTIONAL: ack

UNSUBSCRIBE
 REQUIRED: id
 OPTIONAL: none

DISCONNECT
 REQUIRED: none
 OPTIONAL: receipt
```

Omitted client commands.

```
ACK or NACK
 REQUIRED: id
 OPTIONAL: transaction

BEGIN or COMMIT or ABORT
 REQUIRED: transaction
 OPTIONAL: none
```

Server commands.

```
CONNECTED
 REQUIRED: version
 OPTIONAL: session, server, heart-beat

MESSAGE
 REQUIRED: destination, message-id, subscription
 OPTIONAL: ack

RECEIPT
 REQUIRED: receipt-id
 OPTIONAL: none

ERROR
 REQUIRED: none
 OPTIONAL: message, receipt-id
```

#### Examples

Bad auth.

```
-- client --

STOMP
login: api-token
passcode: api-secret

-- server --

ERROR
message: invalid api keys

-- // --
```

Component sub and unsub.

```
-- client --

SUBSCRIBE
id: sub-1
destination: /attendance/room123

-- server --

MESSAGE
message-id: 456893cc-9225-4ea4-bada-f03f6755f903
subscription: sub-1
destination: /attendance/room123

{"date":"2016-01-02","time":"9:33","teachers":1,"students":3}

-- server --

MESSAGE
message-id: 456893cc-9225-4ea4-bada-f03f6755f903
subscription: sub-1
destination: /attendance/room123

{"date":"2016-01-02","time":"9:35","teachers":1,"students":7}

-- client --

UNSUBSCRIBE
id: sub-1
```

Send update failure.

```
-- client --

SEND
receipt: req-1
destination: /room123/choices/q428

{"option":"C"}

-- server --

ERROR
receipt-id: req-1
message: answer period closed

{"code":"Q202"}
```

Send update success.

```
-- client --

SEND
receipt: req-1
destination: /room123/attendance

{"password":"w0t7OBcp"}

-- server --

RECEIPT
receipt-id: req-1
```
