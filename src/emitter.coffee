Mixin = require 'mixto'
Signal = null # required below to avoid circularity

subscriptionRemovedPattern = /^(last-)?.+-subscription-removed$/

module.exports =
class Emitter extends Mixin
  on: (eventNames, handler) ->
    for eventName in eventNames.split(/\s+/) when eventName isnt ''
      [eventName, namespace] = eventName.split('.')

      if @getSubscriptionCount(eventName) is 0
        @emit "first-#{eventName}-subscription-will-be-added", handler

      @eventHandlersByEventName ?= {}
      @eventHandlersByEventName[eventName] ?= []
      @eventHandlersByEventName[eventName].push(handler)

      if namespace
        @eventHandlersByNamespace ?= {}
        @eventHandlersByNamespace[namespace] ?= {}
        @eventHandlersByNamespace[namespace][eventName] ?= []
        @eventHandlersByNamespace[namespace][eventName].push(handler)

      @emit "#{eventName}-subscription-added", handler

  once: (eventName, handler) ->
    oneShotHandler = (args...) =>
      @off(eventName, oneShotHandler)
      handler(args...)

    @on eventName, oneShotHandler

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
        if queuedEvents = @queuedEventsByEventName?[eventName]
          queuedEvents.push(["#{eventName}.#{namespace}", args...])
        else if handlers = @eventHandlersByNamespace?[namespace]?[eventName]
          new Array(handlers...).forEach (handler) -> handler(args...)
      else
        if queuedEvents = @queuedEventsByEventName?[eventName]
          queuedEvents.push([eventName, args...])
        else if handlers = @eventHandlersByEventName?[eventName]
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
          eventHandlers = @eventHandlersByEventName?[eventName]
          return unless eventHandlers?

          unless handler?
            @off eventName, handler for handler in eventHandlers
            return

          if removeFromArray(eventHandlers, handler)
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

  getSubscriptionCount: (eventName) ->
    if eventName?
      @eventHandlersByEventName?[eventName]?.length ? 0
    else
      count = 0
      for name, handlers of @eventHandlersByEventName ? {}
        count += handlers.length
      count

removeFromArray = (array, element) ->
  index = array.indexOf(element)
  if index > -1
    array.splice(index, 1)
    true
  else
    false
