isEqual = require 'tantamount'
Emitter = require './emitter'
Subscriber = require './subscriber'
Behavior = null

module.exports =
class Signal
  Emitter.includeInto(this)
  Subscriber.includeInto(this)

  constructor: (subscribe) ->
    @on 'first-value-subscription-will-be-added', => subscribe.call(this)
    @on 'last-value-subscription-removed', => @unsubscribe()

  @fromEmitter: (emitter, eventName) ->
    new Signal ->
      @subscribe emitter, eventName, (event) =>
        @emit 'value', event

  onValue: (handler) -> @on 'value', handler

  toBehavior: (initialValue) ->
    source = this
    @buildBehavior initialValue, ->
      @subscribe source, 'value', (value) =>
        @emit 'value', value

  changes: ->
    this

  filter: (predicate) ->
    source = this
    new @constructor ->
      @subscribe source, 'value', (value) =>
        @emit 'value', value if predicate.call(value, value)

  filterDefined: ->
    @filter (value) -> value?

  map: (fn) ->
    source = this
    new @constructor ->
      @subscribe source, 'value', (value) =>
        @emit 'value', fn(value)

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

  distinctUntilChanged: ->
    source = this
    new @constructor ->
      receivedValue = false
      oldValue = undefined
      @subscribe source, 'value', (newValue) =>
        if receivedValue
          if isEqual(oldValue, newValue)
            oldValue = newValue
          else
            oldValue = newValue
            @emit 'value', newValue
        else
          receivedValue = true
          oldValue = newValue
          @emit 'value', newValue

  becomes: (targetValue) ->
    @distinctUntilChanged()
    .diff undefined, (oldValue, newValue) ->
      if isEqual(newValue, targetValue)
        true
      else if isEqual(oldValue, targetValue)
        false
    .filterDefined()
    .changes()

  # Private: Builds a Behavior instance, lazily requiring the Behavior subclass
  # to avoid circular require.
  buildBehavior: (args...) ->
    Behavior ?= require './behavior'
    new Behavior(args...)
