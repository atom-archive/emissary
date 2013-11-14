isEqual = require 'tantamount'
Signal = require './signal'

module.exports =
class Behavior extends Signal
  constructor: (args...) ->
    initialValue = args.shift() if typeof args[0]?.call isnt 'function'
    subscribe = args.shift()

    @on 'first-value-subscription-will-be-added', =>
      latestValue = initialValue
      @subscribe this, 'value-internal', (value) => latestValue = value
      @subscribe this, 'value-subscription-added', (handler) => handler(latestValue)
      subscribe?.call(this)

    @on 'last-value-subscription-removed', => @unsubscribe()

  emit: (name, args...) ->
    @emit('value-internal', args...) if name is 'value'
    super

  toBehavior: ->
    this

  # TODO: Write in terms of ::skip when it's added
  changes: ->
    source = this
    new Signal ->
      gotFirst = false
      @subscribe source, 'value', (value, metadata...) =>
        if gotFirst
          @emit 'value', value, metadata...
        gotFirst = true

  becomes: (predicateOrTargetValue) ->
    unless typeof predicateOrTargetValue is 'function'
      targetValue = predicateOrTargetValue
      return @becomes (value) -> isEqual(value, targetValue)

    predicate = predicateOrTargetValue
    @map((value) -> !!predicate(value))
    .distinctUntilChanged()
    .changes()

  becomesLessThan: (targetValue) ->
    @becomes (value) -> value < targetValue

  becomesGreaterThan: (targetValue) ->
    @becomes (value) -> value > targetValue
