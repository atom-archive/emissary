isEqual = require 'tantamount'
Signal = require './signal'

module.exports =
class Behavior extends Signal
  constructor: (args...) ->
    initialValue = args.shift() if typeof args[0]?.call isnt 'function'
    subscribe = args.shift()

    latestValue = initialValue

    @on 'value-subscription-removed', =>
      @unsubscribe() if @getSubscriptionCount('value') is 1 # our self-subscription below doesn't count

    super
      beforeFirstSubscription: ->
        @subscribe this, 'value', (value) => latestValue = value
        subscribe?.call(this)
      afterEachSubscription: (handler) ->
        handler(latestValue)

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
