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

  scan: (initialValue, fn) ->
    source = this
    @buildBehavior initialValue, ->
      oldValue = initialValue
      @subscribe source, 'value', (newValue) =>
        @emit 'value', oldValue = fn(oldValue, newValue)

  diff: (initialValue, fn) ->
    source = this
    @buildBehavior ->
      oldValue = initialValue
      @subscribe source, 'value', (newValue) =>
        fnOldValue = oldValue
        oldValue = newValue
        @emit 'value', fn(fnOldValue, newValue)

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
