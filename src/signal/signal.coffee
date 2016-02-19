{pull} = require "lodash"

class Signal
  constructor: ->
    @listeners = []

  emit: (event) ->
    @listeners.forEach (fn) ->
      fn(event)
    undefined

  addListener: (fn) ->
    @listeners.push fn
    @listeners.length
    undefined

  removeListener: (fn) ->
    pull @listeners, fn
    @listeners.length
    undefined

module.exports = Signal
