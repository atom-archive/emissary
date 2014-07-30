Mixin = require 'mixto'
Grim = require 'grim'
Signal = null # required below to avoid circularity
Subscription = null # required below to avoid circularity

subscriptionRemovedPattern = /^(last-)?.+-subscription-removed$/

module.exports =
class Emitter extends Mixin
  eventHandlersByEventName: null
  eventHandlersByNamespace: null
  subscriptionCounts: null
  pauseCountsByEventName: null
  queuedEventsByEventName: null
  globalPauseCount: null
  globalQueuedEvents: null
  signalsByEventName: null

  on: (eventNames, handler) ->
    for eventName in eventNames.split(/\s+/) when eventName isnt ''
      [eventName, namespace] = eventName.split('.')

      @emit "#{eventName}-subscription-will-be-added", handler
      if @incrementSubscriptionCount(eventName) is 1
        @emit "first-#{eventName}-subscription-will-be-added", handler

      @eventHandlersByEventName ?= {}
      @eventHandlersByEventName[eventName] ?= []
      @eventHandlersByEventName[eventName].push(handler)

      if namespace
        Grim.deprecate("Emissary namespaces are deprecated. Call .off() on the returned subscription object instead.")
        @eventHandlersByNamespace ?= {}
        @eventHandlersByNamespace[namespace] ?= {}
        @eventHandlersByNamespace[namespace][eventName] ?= []
        @eventHandlersByNamespace[namespace][eventName].push(handler)

      @emit "#{eventName}-subscription-added", handler

    Subscription ?= require './subscription'
    new Subscription(this, eventNames, handler)

  once: (eventName, handler) ->
    subscription = @on eventName, (args...) ->
      subscription.off()
      handler(args...)

  signal: (eventName) ->
    Signal ?= require './signal'
    @signalsByEventName ?= {}
    @signalsByEventName[eventName] ?= Signal.fromEmitter(this, eventName)

  behavior: (eventName, initialValue) ->
    @signal(eventName).toBehavior(initialValue)

  emit: (eventName, args...) ->
    if @globalQueuedEvents
      @globalQueuedEvents.push [eventName, args...]
    else
      [eventName, namespace] = eventName.split('.')

      if namespace
        Grim.deprecate("Emissary namespaces are deprecated.")
        if queuedEvents = @queuedEventsByEventName?[eventName]
          queuedEvents.push(["#{eventName}.#{namespace}", args...])
        else if handlers = @eventHandlersByNamespace?[namespace]?[eventName]
          new Array(handlers...).forEach (handler) -> handler(args...)
          @emit "after-#{eventName}", args...
      else
        if queuedEvents = @queuedEventsByEventName?[eventName]
          queuedEvents.push([eventName, args...])
        else if handlers = @eventHandlersByEventName?[eventName]
          new Array(handlers...).forEach (handler) -> handler(args...)
          @emit "after-#{eventName}", args...

  off: (eventNames, handler) ->
    Grim.deprecate("Call .off() on the subscription object returned by ::on() instead.")

    if eventNames
      for eventName in eventNames.split(/\s+/) when eventName isnt ''
        [eventName, namespace] = eventName.split('.')
        eventName = undefined if eventName == ''

        if namespace
          if eventName
            handlers = @eventHandlersByNamespace?[namespace]?[eventName] ? []
            if handler?
              removeFromArray(handlers, handler)
              @off eventName, handler
            else
              for handler in new Array(handlers...)
                removeFromArray(handlers, handler)
                @off eventName, handler
          else
            namespaceHandlers = @eventHandlersByNamespace?[namespace] ? {}
            if handler?
              for eventName, handlers of namespaceHandlers
                removeFromArray(handlers, handler)
                @off eventName, handler
            else
              for eventName, handlers of namespaceHandlers
                for handler in new Array(handlers...)
                  removeFromArray(handlers, handler)
                  @off eventName, handler
        else
          eventHandlers = @eventHandlersByEventName?[eventName]
          return unless eventHandlers?

          unless handler?
            @off eventName, handler for handler in eventHandlers
            return

          if removeFromArray(eventHandlers, handler)
            @decrementSubscriptionCount(eventName)
            @emit "#{eventName}-subscription-removed", handler
            if @getSubscriptionCount(eventName) is 0
              @emit "last-#{eventName}-subscription-removed", handler
              delete @eventHandlersByEventName[eventName]
    else
      # First remove handlers that aren't for subscription removed events
      for eventName of @eventHandlersByEventName
        @off(eventName) unless subscriptionRemovedPattern.test(eventName)

      # Then remove all remaining handlers
      for eventName of @eventHandlersByEventName
        @off(eventName)

      @eventHandlersByNamespace = {}

  pauseEvents: (eventNames) ->
    if eventNames
      for eventName in eventNames.split(/\s+/) when eventName isnt ''
        @pauseCountsByEventName ?= {}
        @queuedEventsByEventName ?= {}
        @pauseCountsByEventName[eventName] ?= 0
        @pauseCountsByEventName[eventName]++
        @queuedEventsByEventName[eventName] ?= []
    else
      @globalPauseCount ?= 0
      @globalQueuedEvents ?= []
      @globalPauseCount++

  resumeEvents: (eventNames) ->
    if eventNames
      for eventName in eventNames.split(/\s+/) when eventName isnt ''
        if @pauseCountsByEventName?[eventName] > 0 and --@pauseCountsByEventName[eventName] is 0
          queuedEvents = @queuedEventsByEventName[eventName]
          @queuedEventsByEventName[eventName] = null
          @emit(event...) for event in queuedEvents
    else
      for eventName of @pauseCountsByEventName
        @resumeEvents(eventName)
      if @globalPauseCount > 0 and --@globalPauseCount == 0
        queuedEvents = @globalQueuedEvents
        @globalQueuedEvents = null
        @emit(event...) for event in queuedEvents

  incrementSubscriptionCount: (eventName) ->
    @subscriptionCounts ?= {}
    @subscriptionCounts[eventName] ?= 0
    ++@subscriptionCounts[eventName]

  decrementSubscriptionCount: (eventName) ->
    count = --@subscriptionCounts[eventName]
    if count is 0
      delete @subscriptionCounts[eventName]
    count

  getSubscriptionCount: (eventName) ->
    if eventName?
      @subscriptionCounts?[eventName] ? 0
    else
      total = 0
      for name, count of @subscriptionCounts
        total += count
      total

  hasSubscriptions: (eventName) ->
    @getSubscriptionCount(eventName) > 0

removeFromArray = (array, element) ->
  index = array.indexOf(element)
  if index > -1
    array.splice(index, 1)
    true
  else
    false
