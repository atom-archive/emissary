{isEqual} = require 'underscore-plus'
Emitter = require './emitter'
Subscriber = require './subscriber'
Behavior = null

module.exports =
class Signal extends Emitter
  Subscriber.includeInto(this)

  @fromEmitter: (emitter, eventName) ->
    new Signal ->
      @subscribe emitter, eventName, (value, metadata...) =>
        @emitValue value, metadata...

  constructor: (@subscribeCallback) ->
    @retainCount = 0
    @on 'value-subscription-will-be-added', => @retain()
    @on 'value-subscription-removed', => @release()

  isSignal: true

  retained: ->
    @subscribeCallback?()

  released: ->
    @unsubscribe()

  retain: ->
    if ++@retainCount is 1
      @retained?()
    this

  release: ->
    if --@retainCount is 0
      @released?()
    this

  onValue: (handler) -> @on 'value', handler

  emitValue: (value, metadata={}) ->
    metadata.source ?= this
    @emit 'value', value, metadata

  toBehavior: (initialValue) ->
    source = this
    @buildBehavior initialValue, ->
      @subscribe source, 'value', (value, metadata...) =>
        @emitValue value, metadata...

  changes: ->
    this

  injectMetadata: (fn) ->
    source = this
    new @constructor ->
      @subscribe source, 'value', (value, metadata) =>
        newMetadata = fn(value, metadata)
        metadata[k] = v for k, v of newMetadata
        @emitValue value, metadata

  filter: (predicate) ->
    source = this
    new @constructor ->
      @subscribe source, 'value', (value, metadata...) =>
        if predicate.call(value, value)
          @emitValue value, metadata...

  filterDefined: ->
    @filter (value) -> value?

  map: (fn) ->
    if typeof fn is 'string'
      property = fn
      fn = (value) -> value?[property]

    source = this
    new @constructor ->
      @subscribe source, 'value', (value, metadata...) =>
        @emitValue fn.call(value, value), metadata...

  switch: (fn) ->
    source = @map(fn)
    new @constructor ->
      currentSignal = null
      @subscribe source, 'value', (newSignal, outerMetadata) =>
        @unsubscribe(currentSignal) if currentSignal?
        currentSignal = newSignal
        if currentSignal?
          @subscribe currentSignal, 'value', (value, innerMetadata) =>
            @emitValue(value, innerMetadata)
        else
          @emitValue(undefined, outerMetadata)

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
        @emitValue (oldValue = fn(oldValue, newValue)), metadata...

  diff: (initialValue, fn) ->
    source = this
    @buildBehavior ->
      oldValue = initialValue
      @subscribe source, 'value', (newValue, metadata...) =>
        fnOldValue = oldValue
        oldValue = newValue
        @emitValue fn(fnOldValue, newValue), metadata...

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
            @emitValue newValue, metadata...
        else
          receivedValue = true
          oldValue = newValue
          @emitValue newValue, metadata...

  equals: (expected) ->
    @map((actual) -> isEqual(actual, expected)).distinctUntilChanged()

  isDefined: ->
    @map((value) -> value?).distinctUntilChanged()

  # Private: Builds a Behavior instance, lazily requiring the Behavior subclass
  # to avoid circular require.
  buildBehavior: (args...) ->
    Behavior ?= require './behavior'
    new Behavior(args...)
