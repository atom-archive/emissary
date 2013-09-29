isEqual = require 'tantamount'
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

  changes: ->
    this

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
