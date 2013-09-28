Emitter = require './emitter'
Subscriber = require './subscriber'
Behavior = null

module.exports =
class Observable
  Emitter.includeInto(this)
  Subscriber.includeInto(this)

  onValue: (handler) -> @on 'value', handler

  buildBehavior: (args...) ->
    Behavior ?= require './behavior'
    new Behavior(args...)

  toBehavior: (initialValue) ->
    source = this
    @buildBehavior initialValue, ->
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
