Emitter = require './emitter'

module.exports =
class Subscription extends Emitter
  cancelled: false

  constructor: (@emitter, @eventNames, @handler) ->

  off: ->
    return if @cancelled

    @emitter.off(@eventNames, @handler)
    @emitter = null
    @handler = null
    @cancelled = true
    @emit 'cancelled'
