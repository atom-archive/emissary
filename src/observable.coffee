Emitter = require './emitter'
Subscriber = require './subscriber'
Behavior = null

module.exports =
class Observable
  Emitter.includeInto(this)
  Subscriber.includeInto(this)

  onValue: (handler) -> @on 'value', handler

  toBehavior: (initialValue) ->
    source = this
    new Behavior initialValue, ->
      @subscribe source, 'value', (value) =>
        @emit 'value', value

  filter: (predicate) ->
    source = this
    new @constructor ->
      @subscribe source, 'value', (value) =>
        @emit 'value', value if predicate.call(value, value)

  map: (fn) ->
    source = this
    new @constructor ->
      @subscribe source, 'value', (value) =>
        @emit 'value', fn(value)

Behavior = require './behavior'
