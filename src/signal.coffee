Emitter = require './emitter'

module.exports =
class Signal extends Emitter
  @fromEmitter: (emitter, eventName) ->
    signal = new Signal
    emitter.on eventName, (event) -> signal.emit 'value', event
    signal

  onValue: (handler) -> @on 'value', handler
