{pull, isArray} = require "lodash"

class Signal
  constructor: ->
    @listeners = []

  emit: (event) ->
    unless isArray(@listeners)
      throw new Error("signal is in heaven now")
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

  close: ->
    delete @listeners
    undefined

module.exports = Signal
