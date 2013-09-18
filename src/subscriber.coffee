Mixin = require './mixin'

module.exports =
class Subscriber extends Mixin
  subscribeWith: (eventEmitter, methodName, args) ->
    unless eventEmitter[methodName]?
      throw new Error("Object does not have method '#{methodName}' with which to subscribe")

    eventEmitter[methodName](args...)

    @subscriptions ?= []
    @subscriptionsByObject ?= new WeakMap
    @subscriptionsByObject.set(eventEmitter, []) unless @subscriptionsByObject.has(eventEmitter)

    eventName = args[0]
    callback = args[args.length - 1]
    subscription = cancel: ->
      # node's EventEmitter doesn't have 'off' method.
      removeListener = eventEmitter.off ? eventEmitter.removeListener
      removeListener.call eventEmitter, eventName, callback
    @subscriptions.push(subscription)
    @subscriptionsByObject.get(eventEmitter).push(subscription)

  subscribe: (eventEmitter, args...) ->
    @subscribeWith(eventEmitter, 'on', args)

  subscribeToCommand: (eventEmitter, args...) ->
    @subscribeWith(eventEmitter, 'command', args)

  unsubscribe: (object) ->
    if object?
      for subscription in @subscriptionsByObject?.get(object) ? []
        subscription.cancel()
        index = @subscriptions.indexOf(subscription)
        @subscriptions.splice(index, 1) if index >= 0
      @subscriptionsByObject?.delete(object)
    else
      subscription.cancel() for subscription in @subscriptions ? []
      @subscriptions = null
      @subscriptionsByObject = null
