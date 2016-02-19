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
    undefined

  removeListener: (fn) ->
    pull @listeners, fn
    undefined

module.exports = Signal
