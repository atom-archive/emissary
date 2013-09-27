Mixin = require './mixin'
Signal = null # required below to avoid circularity

module.exports =
class Emitter extends Mixin
  on: (eventNames, handler) ->
    for eventName in eventNames.split(/\s+/) when eventName isnt ''
      [eventName, namespace] = eventName.split('.')

      @eventHandlersByEventName ?= {}
      @eventHandlersByEventName[eventName] ?= []
      @eventHandlersByEventName[eventName].push(handler)

      if namespace
        @eventHandlersByNamespace ?= {}
        @eventHandlersByNamespace[namespace] ?= {}
        @eventHandlersByNamespace[namespace][eventName] ?= []
        @eventHandlersByNamespace[namespace][eventName].push(handler)

      @emit "#{eventName}-subscription", handler

    @afterSubscribe?()

  once: (eventName, handler) ->
    oneShotHandler = (args...) =>
      @off(eventName, oneShotHandler)
      handler(args...)

    @on eventName, oneShotHandler

  signal: (eventName) ->
    @signalsByEventName ?= {}
    @signalsByEventName[eventName] ?= Signal.fromEmitter(this, eventName)

  emit: (eventName, args...) ->
    if @queuedEvents
      @queuedEvents.push [eventName, args...]
    else
      [eventName, namespace] = eventName.split('.')

      if namespace
        if handlers = @eventHandlersByNamespace?[namespace]?[eventName]
          new Array(handlers...).forEach (handler) -> handler(args...)
      else
        if handlers = @eventHandlersByEventName?[eventName]
          new Array(handlers...).forEach (handler) -> handler(args...)

  off: (eventNames, handler) ->
    if eventNames
      for eventName in eventNames.split(/\s+/) when eventName isnt ''
        [eventName, namespace] = eventName.split('.')
        eventName = undefined if eventName == ''

        if namespace
          if eventName
            handlers = @eventHandlersByNamespace?[namespace]?[eventName] ? []
            for handler in new Array(handlers...)
              removeFromArray(handlers, handler)
              @off eventName, handler
          else
            for eventName, handlers of @eventHandlersByNamespace?[namespace] ? {}
              for handler in new Array(handlers...)
                removeFromArray(handlers, handler)
                @off eventName, handler
        else
          subscriptionCountBefore = @getSubscriptionCount()
          if handler
            eventHandlers = @eventHandlersByEventName[eventName]
            removeFromArray(eventHandlers, handler) if eventHandlers
          else
            delete @eventHandlersByEventName?[eventName]
          @afterUnsubscribe?() if @getSubscriptionCount() < subscriptionCountBefore
    else
      subscriptionCountBefore = @getSubscriptionCount()
      @eventHandlersByEventName = {}
      @eventHandlersByNamespace = {}
      @afterUnsubscribe?() if @getSubscriptionCount() < subscriptionCountBefore

  pauseEvents: ->
    @pauseCount ?= 0
    if @pauseCount++ == 0
      @queuedEvents ?= []

  resumeEvents: ->
    if --@pauseCount == 0
      queuedEvents = @queuedEvents
      @queuedEvents = null
      @emit(event...) for event in queuedEvents

  getSubscriptionCount: (eventName) ->
    if eventName?
      @eventHandlersByEventName[eventName]?.length ? 0
    else
      count = 0
      for name, handlers of @eventHandlersByEventName
        count += handlers.length
      count

removeFromArray = (array, element) ->
  index = array.indexOf(element)
  array.splice(index, 1) if index >= 0

Signal = require './signal'
