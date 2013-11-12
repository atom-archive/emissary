isEqual = require 'tantamount'
Signal = require './signal'

module.exports =
class Behavior extends Signal
  constructor: (args...) ->
    initialValue = args.shift() if typeof args[0]?.call isnt 'function'
    subscribe = args.shift()

    @on 'first-value-subscription-will-be-added', =>
      latestValue = initialValue
      @subscribe this, 'value', (value) => latestValue = value
      @subscribe this, 'value-subscription-added', (handler) => handler(latestValue)
      subscribe?.call(this)

    @on 'value-subscription-removed', =>
      @unsubscribe() if @getSubscriptionCount('value') is 1 # our self-subscription to 'value' events above doesn't count

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
