# Stomp frame
# See STOMP 1.2

{assign, each} = require "lodash"

exports.toString = ({command, headers, body}) ->  
  headers = assign({}, headers)
  if body
    headers['content-length'] = body.length
  s = command + "\n"
  each headers, (value, key) ->
    s += key + ":" + value + "\n"
  s += "\n"
  if body
    s += body
  s += "\0"
  return s

exports.fromString = (s) ->  
  unless s && s.length > 0
    return null
  
  # One-pass parse
  start = 0
  
  command = null
  loop
    # Parse line
    end = s.indexOf("\n", start)
    if end == -1
      throw new Error("Invalid packet")
    
    line = s.substr(start, end - start)
    start = end + 1
    
    # Break on bad input
    if start >= s.length
      return null
    
    if line != ""
      command = line
      break
    
  headers = {}
  loop
    # Parse line
    end = s.indexOf("\n", start)
    if end == -1
      break
    line = s.substr(start, end - start)
    start = end + 1
    
    # End of headers is empty line
    if line == ""
      break
    
    sep = line.indexOf(":", 0)
    if sep == -1
      throw new Error("Invalid header: " + line)
    
    key = line.substr(0, sep)
    unless headers[key]
      value = line.substr(sep + 1)
      headers[key] = value
  
  if headers['content-length']
    headers['content-length'] = parseInt(headers['content-length'], 10)
    
  body = if headers['content-length']
    end = start + headers['content-length']
    if end > s.length
      throw new Error("Content length incorrect")
    s.substr(start, end)
  else if s[start] != "\0"
    end = s.length - 1
    while s[end] == "\n" || s[end] == "\0"
      end -= 1      
      if end <= start
        throw new Error("No frame terminator")
    s.slice(start, end + 1)
  else
    null
    
  frame = 
    command: command
    headers: headers
    body: body
  return frame
