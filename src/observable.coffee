Emitter = require './emitter'
Subscriber = require './subscriber'
Behavior = null

module.exports =
class Observable
  Emitter.includeInto(this)
  Subscriber.includeInto(this)

  onValue: (handler) -> @on 'value', handler

  toBehavior: (initialValue) ->
    behavior = new Behavior(this, initialValue)

  filter: (predicate) ->
    observable = @buildObservable()
    observable.subscribe this, 'value', (newValue) ->
      if predicate.call(newValue, newValue)
        observable.emit('value', newValue)
    observable

  map: (fn) ->
    observable = @buildObservable()
    observable.subscribe this, 'value', (newValue) ->
      observable.emit('value', fn(newValue))
    observable

Behavior = require './behavior'
