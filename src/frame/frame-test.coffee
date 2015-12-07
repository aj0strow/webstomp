assert = require "assert"
Frame = require "./frame"

describe "Stomp Frame", ->
  describe "toString", ->
    it "should serialize connected", ->
      packet = Frame.toString
        command: "CONNECTED"
        headers:
          session: "abcde"
      lines = packet.split("\n")
      assert.equal lines[0], "CONNECTED"
      assert.equal lines[1], "session:abcde"
      assert.equal lines[2], ""
      assert.equal lines[3], "\0"

    it "should write body and content length", ->
      body = "one two three"
      packet = Frame.toString
        command: "MESSAGE"
        body: body
      matches = packet.match(/(\d+)/)
      length = matches && parseInt(matches[1], 10)
      assert.equal length, body.length
      
  describe "fromString", ->
    it "should parse connect packet", ->
      packet = [
        "CONNECT\n"
        "accept-version:1.2\n"
        "host:\n"
        "login:ajostrow\n"
        "passcode:secret\n"
        "\n"
        "\0"
      ].join("")
      frame = Frame.fromString(packet)
      assert.equal frame.command, "CONNECT"
      assert.equal frame.headers["accept-version"], "1.2"
      assert.equal frame.headers["host"], ""
      assert.equal frame.headers["login"], "ajostrow"
      assert.equal frame.headers["passcode"], "secret"
      assert.equal frame.body, null
    
    it "should parse packet with body", ->
      packet = [
        "SEND\n"
        "destination:/orders\n"
        "content-type:application/json; charset=utf-8\n"
        "\n"
        JSON.stringify(quantity: 10) + "\n"
        "\0"
      ].join("")
      frame = Frame.fromString(packet)      
      assert.equal frame.command, "SEND"
      assert.equal frame.headers["destination"], "/orders"
      assert.equal frame.headers["content-type"], "application/json; charset=utf-8"
      assert.equal frame.body, '{"quantity":10}'
    
    it "should should prefer earlier duplicate headers", ->
      packet = [
        "MESSAGE",
        "foo:OK",
        "foo:Not Ok",
        "\0",
      ].join("\n")
      frame = Frame.fromString(packet)
      assert.equal frame.headers["foo"], "OK"
      
      
      