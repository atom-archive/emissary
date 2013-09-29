isEqual = require 'tantamount'
Signal = require './signal'

module.exports =
class Behavior extends Signal
  constructor: (args...) ->
    initialValue = args.shift() if args.length > 1
    subscribe = args.shift()

    latestValue = initialValue
    handlingFirstSubscription = false
    @on 'first-value-subscription-will-be-added', =>
      unless handlingFirstSubscription
        handlingFirstSubscription = true
        @subscribe this, 'value', (value) => latestValue = value
        subscribe.call(this)
        handlingFirstSubscription = false

    @on 'value-subscription-removed', =>
      @unsubscribe() if @getSubscriptionCount('value') is 1 # our self-subscription above doesn't count

    @on 'value-subscription-added', (handler) -> handler(latestValue)

  toBehavior: ->
    this

  # TODO: Write in terms of ::skip when it's added
  changes: ->
    source = this
    new Signal ->
      gotFirst = false
      source.onValue (value) =>
        if gotFirst
          @emit 'value', value
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
