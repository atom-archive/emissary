Emitter = require './emitter'
Subscriber = require './subscriber'

module.exports =
class Signal
  Emitter.includeInto(this)
  Subscriber.includeInto(this)

  @fromEmitter: (emitter, eventName) ->
    signal = new Signal
    emitter.on eventName, (event) -> signal.emit 'value', event
    signal

  onValue: (handler) -> @on 'value', handler

  filter: (predicate) ->
    signal = new Signal
    signal.subscribe this, 'value', (newValue) ->
      if predicate.call(newValue, newValue)
        signal.emit('value', newValue)
    signal

  map: (fn) ->
    signal = new Signal
    signal.subscribe this, 'value', (newValue) ->
      signal.emit('value', fn(newValue))
    signal
