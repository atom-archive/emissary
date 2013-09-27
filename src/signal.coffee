Observable = require './observable'

module.exports =
class Signal extends Observable
  @fromEmitter: (emitter, eventName) ->
    signal = new Signal
    emitter.on eventName, (event) -> signal.emit 'value', event
    signal

  buildObservable: ->
    new Signal
