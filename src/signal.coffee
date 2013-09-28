Observable = require './observable'

module.exports =
class Signal extends Observable
  constructor: (subscribe) ->
    @on 'first-value-subscription-will-be-added', => subscribe.call(this)
    @on 'last-value-subscription-removed', => @unsubscribe()

  @fromEmitter: (emitter, eventName) ->
    new Signal ->
      @subscribe emitter, eventName, (event) =>
        @emit 'value', event
