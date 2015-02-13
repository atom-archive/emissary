Mixin = require 'mixto'
Signal = null
WeakMap = global.WeakMap ? require 'es6-weak-map'
Subscription = require './subscription'

module.exports =
class Subscriber extends Mixin
  subscribeWith: (eventEmitter, methodName, args) ->
    unless eventEmitter[methodName]?
      throw new Error("Object does not have method '#{methodName}' with which to subscribe")

    eventEmitter[methodName](args...)

    eventNames = args[0]
    callback = args[args.length - 1]
    @addSubscription(new Subscription(eventEmitter, eventNames, callback))

  addSubscription: (subscription) ->
    @_subscriptions ?= []
    @_subscriptions.push(subscription)

    {emitter} = subscription
    if emitter?
      @_subscriptionsByObject ?= new WeakMap
      if @_subscriptionsByObject.has(emitter)
        @_subscriptionsByObject.get(emitter).push(subscription)
      else
        @_subscriptionsByObject.set(emitter, [subscription])

    subscription

  subscribe: (eventEmitterOrSubscription, args...) ->
    if args.length is 0
      @addSubscription(eventEmitterOrSubscription)
    else
      args.unshift('value') if args.length is 1 and eventEmitterOrSubscription.isSignal
      @subscribeWith(eventEmitterOrSubscription, 'on', args)

  subscribeToCommand: (eventEmitter, args...) ->
    @subscribeWith(eventEmitter, 'command', args)

  unsubscribe: (object) ->
    if object?
      for subscription in @_subscriptionsByObject?.get(object) ? []
        if typeof subscription.dispose is 'function'
          subscription.dispose()
        else
          subscription.off()
        index = @_subscriptions.indexOf(subscription)
        @_subscriptions.splice(index, 1) if index >= 0
      @_subscriptionsByObject?.delete(object)
    else
      for subscription in @_subscriptions ? []
        if typeof subscription.dispose is 'function'
          subscription.dispose()
        else
          subscription.off()
      @_subscriptions = null
      @_subscriptionsByObject = null
