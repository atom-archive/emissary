isEqual = require 'tantamount'
Signal = require './signal'

module.exports =
class Behavior extends Signal
  constructor: (args...) ->
    @value = args.shift() if typeof args[0]?.call isnt 'function'
    super(subscribeCallback = args.shift())

  retained: ->
    @subscribe this, 'value-internal', (value) => @value = value
    @subscribe this, 'value-subscription-added', (handler) => handler(@value)
    @subscribeCallback?()

  emit: (name, args...) ->
    @emit('value-internal', args...) if name is 'value'
    super

  getValue: ->
    throw new Error("Subscribe to or retain this behavior before calling getValue") unless @retainCount > 0
    @value

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
