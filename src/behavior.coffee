Observable = require './observable'

module.exports =
class Behavior extends Observable
  constructor: (signal, initialValue) ->
    currentValue = initialValue

    @subscribe signal, 'value', (newValue) =>
      currentValue = newValue
      @emit 'value', newValue

    @on 'value-subscription', (handler) ->
      handler(currentValue)
