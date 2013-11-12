isEqual = require 'tantamount'
Emitter = require './emitter'
Subscriber = require './subscriber'
Behavior = null

module.exports =
class Signal
  Emitter.includeInto(this)
  Subscriber.includeInto(this)

  constructor: (subscribe) ->
    @on 'first-value-subscription-will-be-added', (handler) => subscribe?.call(this)
    @on 'last-value-subscription-removed', => @unsubscribe()

  @fromEmitter: (emitter, eventName) ->
    new Signal ->
      @subscribe emitter, eventName, (value, metadata...) =>
        @emit 'value', value, metadata...

  onValue: (handler) -> @on 'value', handler

  toBehavior: (initialValue) ->
    source = this
    @buildBehavior initialValue, ->
      @subscribe source, 'value', (value, metadata...) =>
        @emit 'value', value, metadata...

  changes: ->
    this

  injectMetadata: (fn) ->
    source = this
    new @constructor ->
      @subscribe source, 'value', (value, metadata...) =>
        metadata = fn(value, metadata...)
        @emit 'value', value, metadata

  filter: (predicate) ->
    source = this
    new @constructor ->
      @subscribe source, 'value', (value, metadata...) =>
        if predicate.call(value, value)
          @emit 'value', value, metadata...

  filterDefined: ->
    @filter (value) -> value?

  map: (fn) ->
    source = this
    new @constructor ->
      @subscribe source, 'value', (value, metadata...) =>
        @emit 'value', fn(value), metadata...

  skipUntil: (predicateOrTargetValue) ->
    unless typeof predicateOrTargetValue is 'function'
      targetValue = predicateOrTargetValue
      return @skipUntil (value) -> isEqual(value, targetValue)

    predicate = predicateOrTargetValue
    doneSkipping = false
    @filter (value) ->
      return true if doneSkipping
      if predicate(value)
        doneSkipping = true
      else
        false

  scan: (initialValue, fn) ->
    source = this
    @buildBehavior initialValue, ->
      oldValue = initialValue
      @subscribe source, 'value', (newValue, metadata...) =>
        @emit 'value', (oldValue = fn(oldValue, newValue)), metadata...

  diff: (initialValue, fn) ->
    source = this
    @buildBehavior ->
      oldValue = initialValue
      @subscribe source, 'value', (newValue, metadata...) =>
        fnOldValue = oldValue
        oldValue = newValue
        @emit 'value', fn(fnOldValue, newValue), metadata...

  distinctUntilChanged: ->
    source = this
    new @constructor ->
      receivedValue = false
      oldValue = undefined
      @subscribe source, 'value', (newValue, metadata...) =>
        if receivedValue
          if isEqual(oldValue, newValue)
            oldValue = newValue
          else
            oldValue = newValue
            @emit 'value', newValue, metadata...
        else
          receivedValue = true
          oldValue = newValue
          @emit 'value', newValue, metadata...

  # Private: Builds a Behavior instance, lazily requiring the Behavior subclass
  # to avoid circular require.
  buildBehavior: (args...) ->
    Behavior ?= require './behavior'
    new Behavior(args...)
