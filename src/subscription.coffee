Emitter = require './emitter'

module.exports =
class Subscription extends Emitter
  cancelled: false

  constructor: (@emitter, @eventNames, @handler) ->

  off: ->
    @emitter.off(@eventNames, @handler)
    @cancelled = true
    @emit 'cancelled'
