Emitter = require './emitter'

module.exports =
class Subscription extends Emitter
  cancelled: false

  constructor: (@emitter, @eventNames, @handler) ->

  off: ->
    @dispose()

  dispose: ->
    return if @cancelled

    unsubscribe = @emitter.off ? @emitter.removeListener
    unsubscribe.call(@emitter, @eventNames, @handler)

    @emitter = null
    @handler = null
    @cancelled = true
    @emit 'cancelled'
