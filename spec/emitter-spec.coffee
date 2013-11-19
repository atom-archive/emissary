Emitter = require '../src/emitter'

describe "Emitter", ->
  [emitter, fooHandler1, fooHandler2, barHandler] = []

  beforeEach ->
    emitter = new Emitter

    fooHandler1 = jasmine.createSpy('fooHandler1')
    fooHandler2 = jasmine.createSpy('fooHandler2')
    barHandler = jasmine.createSpy('barHandler')

    emitter.on 'foo', fooHandler1
    emitter.on 'foo', fooHandler2
    emitter.on 'bar', barHandler

  describe "::on", ->
    describe "when called with multiple space-separated event names", ->
      it "subscribes to each of the specified event names", ->
        emitter.on '    a.b  c.d\te ', handler = jasmine.createSpy("handler")

        emitter.emit 'a'
        expect(handler).toHaveBeenCalled()

        handler.reset()
        emitter.emit 'c'
        expect(handler).toHaveBeenCalled()

        handler.reset()
        emitter.emit 'e'
        expect(handler).toHaveBeenCalled()

        handler.reset()
        emitter.emit ''
        expect(handler).not.toHaveBeenCalled()

      it "emits a '{event-name}-subscription-added' event with the given handler for each named event", ->
        emitter.on 'a-subscription-added', aSubscriptionHandler = jasmine.createSpy("aSubscriptionHandler")
        emitter.on 'b-subscription-added', bSubscriptionHandler = jasmine.createSpy("bSubscriptionHandler")
        emitter.on 'c-subscription-added', cSubscriptionHandler = jasmine.createSpy("cSubscriptionHandler")
        emitter.on 'e-subscription-added', eSubscriptionHandler = jasmine.createSpy("eSubscriptionHandler")

        emitter.on 'a.b c.d e', handler = ->

        expect(aSubscriptionHandler).toHaveBeenCalledWith(handler)
        expect(cSubscriptionHandler).toHaveBeenCalledWith(handler)
        expect(eSubscriptionHandler).toHaveBeenCalledWith(handler)
        expect(bSubscriptionHandler).not.toHaveBeenCalled()

      it "emits a 'first-{event-name}-subscription-will-be-added' if there are no other handlers for the named event", ->
        events = []
        emitter.on 'first-b-subscription-will-be-added', (handler) -> events.push (['first-b-subscription-will-be-added', handler])
        emitter.on 'b-subscription-added', (handler) -> events.push (['b-subscription-added', handler])

        emitter.on 'b', handler1 = ->
        emitter.on 'b', handler2 = ->

        expect(events).toEqual [
          ['first-b-subscription-will-be-added', handler1]
          ['b-subscription-added', handler1]
          ['b-subscription-added', handler2]
        ]

      it "does not blow the stack when subscribing from a 'first-{event-name}-subscription-will-be-added event'", ->
        events = []
        emitter.on 'first-b-subscription-will-be-added', (handler) ->
          emitter.on 'b', -> events.push(2)

        emitter.on 'b', -> events.push(1)

        emitter.emit 'b'
        expect(events).toEqual [2, 1]

    it "returns an object with an off() method that removes the handler when called", ->
      events = []
      subscription = emitter.on 'b', (event) -> events.push(event)

      emitter.emit 'b', 'b1'
      expect(events).toEqual ['b1']

      subscription.off()
      emitter.emit 'b', 'b2'
      expect(events).toEqual ['b1']

  describe "::emit", ->
    describe "when called with a non-namespaced event name", ->
      it "calls all handlers that are subscribed to the given event name with the given data", ->
        emitter.emit 'foo', 'data'
        expect(fooHandler1).toHaveBeenCalledWith('data')
        expect(fooHandler2).toHaveBeenCalledWith('data')
        expect(barHandler).not.toHaveBeenCalled()

        fooHandler1.reset()
        fooHandler2.reset()

        emitter.emit 'bar', 'stuff'
        expect(barHandler).toHaveBeenCalledWith('stuff')

    describe "when there are namespaced handlers", ->
      it "emits only handlers registered with the given namespace / event combination", ->
        barHandler2 = jasmine.createSpy('barHandler2')
        emitter.on('bar.ns1', barHandler2)

        emitter.emit('bar')

        expect(barHandler).toHaveBeenCalled()
        expect(barHandler2).toHaveBeenCalled()
        barHandler.reset()
        barHandler2.reset()

        emitter.emit('bar.ns1')

        expect(barHandler).not.toHaveBeenCalled()
        expect(barHandler2).toHaveBeenCalled()

    it "does not raise exceptions when called with non-existent events / namespaces", ->
      emitter.emit('junk')
      emitter.emit('junk.garbage')

    it "emits '{event-name}-subscription-removed' and 'last-{event-name}-subscription-removed' events", ->
      events = []
      emitter.on 'foo-subscription-removed', (handler) -> events.push(['foo-subscription-removed', handler])
      emitter.on 'last-foo-subscription-removed', (handler) -> events.push(['last-foo-subscription-removed', handler])

      emitter.off 'foo', fooHandler1
      emitter.off 'foo', fooHandler2

      expect(events).toEqual [
        ['foo-subscription-removed', fooHandler1]
        ['foo-subscription-removed', fooHandler2]
        ['last-foo-subscription-removed', fooHandler2]
      ]

      events = []
      emitter.on 'foo', fooHandler1
      emitter.off()

      expect(events).toEqual [
        ['foo-subscription-removed', fooHandler1]
        ['last-foo-subscription-removed', fooHandler1]
      ]

  describe "::off", ->
    describe "when called with no arguments", ->
      it "removes all subscriptions", ->
        namespaceHandler = jasmine.createSpy('namespaceHandler')
        emitter.on 'foo.me', namespaceHandler
        emitter.off()
        emitter.emit 'foo'
        expect(fooHandler1).not.toHaveBeenCalled()
        expect(fooHandler2).not.toHaveBeenCalled()
        expect(namespaceHandler).not.toHaveBeenCalled()
        expect(emitter.eventHandlersByEventName).toEqual {}
        expect(emitter.eventHandlersByNamespace).toEqual {}

    describe "when called with multiple space-separated event names", ->
      it "unsubscribes from each event name", ->
        emitter.on 'a.b c.d e', fooHandler1
        emitter.off ' a.b\te   '

        emitter.emit 'a'
        expect(fooHandler1).not.toHaveBeenCalled()

        fooHandler1.reset()
        emitter.emit 'e'
        expect(fooHandler1).not.toHaveBeenCalled()

        fooHandler1.reset()
        emitter.emit 'c.d'
        expect(fooHandler1).toHaveBeenCalled()

    describe "when called with a non-namespaced event name", ->
      it "removes all subscriptions for that event name", ->
        emitter.off 'foo'
        emitter.emit 'foo'
        expect(fooHandler1).not.toHaveBeenCalled()
        expect(fooHandler2).not.toHaveBeenCalled()

    describe "when called with a non-namespaced event name and a handler function", ->
      it "removes the subscription for that specific handler", ->
        emitter.off 'foo', fooHandler1
        emitter.emit 'foo'
        expect(fooHandler1).not.toHaveBeenCalled()
        expect(fooHandler2).toHaveBeenCalled()

      it "does not throw an exception if there was no subscription for the given handler", ->
        expect(-> emitter.off 'marco', -> "nothing").not.toThrow()

    describe "when there are namespaced event handlers", ->
      [barHandler2, bazHandler1, bazHandler2, bazHandler3] = []

      beforeEach ->
        barHandler2 = jasmine.createSpy('barHandler2')
        bazHandler1 = jasmine.createSpy('bazHandler1')
        bazHandler2 = jasmine.createSpy('bazHandler2')
        bazHandler3 = jasmine.createSpy('bazHandler3')

        emitter.on 'bar.ns1', barHandler2
        emitter.on 'baz.ns1', bazHandler1
        emitter.on 'baz.ns1', bazHandler2
        emitter.on 'baz.ns2', bazHandler3

      describe "when called with a namespaced event name and handler", ->
        it "removes the subscription for that specific handler", ->
          emitter.off 'baz.ns1', bazHandler1
          emitter.emit 'baz'

          expect(bazHandler1).not.toHaveBeenCalled()
          expect(bazHandler2).toHaveBeenCalled()
          expect(bazHandler3).toHaveBeenCalled()

      describe "when called with a namespace and handler", ->
        it "removes the subscription for that specific handler", ->
          emitter.on 'bat.ns1', bazHandler1
          emitter.off '.ns1', bazHandler1
          emitter.emit 'baz'
          emitter.emit 'bat'

          expect(bazHandler1).not.toHaveBeenCalled()
          expect(bazHandler2).toHaveBeenCalled()
          expect(bazHandler3).toHaveBeenCalled()

      describe "when called with a namespaced event name", ->
        it "removes all subscriptions in that namespace", ->
          emitter.emit 'baz'

          expect(bazHandler1).toHaveBeenCalled()
          expect(bazHandler2).toHaveBeenCalled()
          expect(bazHandler3).toHaveBeenCalled()

          bazHandler1.reset()
          bazHandler2.reset()
          bazHandler3.reset()

          emitter.off 'baz.ns1'
          emitter.emit 'baz'
          emitter.emit 'baz.ns1'

          expect(bazHandler1).not.toHaveBeenCalled()
          expect(bazHandler2).not.toHaveBeenCalled()
          expect(bazHandler3).toHaveBeenCalled()

      describe "when called with just a namespace", ->
        it "removes all subscriptions for all events in that namespace", ->
          emitter.emit 'bar'
          expect(barHandler).toHaveBeenCalled()
          expect(barHandler2).toHaveBeenCalled()

          barHandler.reset()
          barHandler2.reset()

          emitter.emit 'baz'
          expect(bazHandler1).toHaveBeenCalled()
          expect(bazHandler2).toHaveBeenCalled()
          expect(bazHandler3).toHaveBeenCalled()

          bazHandler1.reset()
          bazHandler2.reset()
          bazHandler3.reset()

          emitter.off '.ns1'

          emitter.emit 'bar'
          emitter.emit 'bar.ns1'
          expect(barHandler).toHaveBeenCalled()
          expect(barHandler2).not.toHaveBeenCalled()

          emitter.emit 'baz'
          emitter.emit 'baz.ns1'

          expect(bazHandler1).not.toHaveBeenCalled()
          expect(bazHandler2).not.toHaveBeenCalled()
          expect(bazHandler3).toHaveBeenCalled()

        describe "when called with event names and namespaces that don't exist", ->
          it "does not raise an exception", ->
            emitter.off 'junk'
            emitter.off '.garbage'
            emitter.off 'junk.garbage'

  describe "::once(event, callback)", ->
    it "emits the given callback once, then removes the subscription", ->
      onceHandler = jasmine.createSpy('onceHandler')
      emitter.once 'event', onceHandler

      emitter.emit('event')
      expect(onceHandler).toHaveBeenCalled()
      onceHandler.reset()

      emitter.emit('event')
      expect(onceHandler).not.toHaveBeenCalled()

  describe "::pauseEvents", ->
    describe "when not passed an event name", ->
      it "pauses all events until ::resumeEvents is called", ->
        emitter.pauseEvents()
        emitter.on 'baz', bazHandler = jasmine.createSpy("bazHandler")

        emitter.emit('foo', 1)
        emitter.emit('bar', 2)
        emitter.emit('baz', 3)

        expect(fooHandler1).not.toHaveBeenCalled()
        expect(fooHandler2).not.toHaveBeenCalled()
        expect(barHandler).not.toHaveBeenCalled()
        expect(bazHandler).not.toHaveBeenCalled()

        emitter.resumeEvents()
        expect(fooHandler1).toHaveBeenCalledWith(1)
        expect(fooHandler2).toHaveBeenCalledWith(1)
        expect(barHandler).toHaveBeenCalledWith(2)
        expect(bazHandler).toHaveBeenCalledWith(3)

        emitter.emit('foo', 4)
        expect(fooHandler1).toHaveBeenCalledWith(4)
        expect(fooHandler2).toHaveBeenCalledWith(4)

    describe "when passed an event name", ->
      it "pauses events by the given name until ::resumeEvents is called", ->
        emitter.pauseEvents('foo')
        emitter.pauseEvents('bar')
        emitter.on 'baz', bazHandler = jasmine.createSpy("bazHandler")

        emitter.emit('foo', 1)
        emitter.emit('bar', 2)
        emitter.emit('baz', 3)

        expect(fooHandler1).not.toHaveBeenCalled()
        expect(fooHandler2).not.toHaveBeenCalled()
        expect(barHandler).not.toHaveBeenCalled()
        expect(bazHandler).toHaveBeenCalledWith(3)

        emitter.resumeEvents('foo')
        expect(fooHandler1).toHaveBeenCalledWith(1)
        expect(fooHandler2).toHaveBeenCalledWith(1)

        emitter.emit('foo', 4)
        expect(fooHandler1).toHaveBeenCalledWith(4)
        expect(fooHandler2).toHaveBeenCalledWith(4)

        emitter.resumeEvents()
        expect(barHandler).toHaveBeenCalledWith(2)

  describe "::getSubscriptionCount()", ->
    describe "when not passed an event name", ->
      it "returns the total number of subscriptions on the emitter", ->
        expect(emitter.getSubscriptionCount()).toBe 3

        emitter.on 'baz', ->
        expect(emitter.getSubscriptionCount()).toBe 4

        emitter.off 'foo'
        expect(emitter.getSubscriptionCount()).toBe 2

    describe "when passed an event name", ->
      it "returns the total number of subscriptions for the given event name", ->
        expect(emitter.getSubscriptionCount('baz')).toBe 0

        emitter.on 'baz', handler1 = ->
        expect(emitter.getSubscriptionCount('baz')).toBe 1

        emitter.on 'baz', handler2 = ->
        expect(emitter.getSubscriptionCount('baz')).toBe 2

        emitter.off 'baz', handler2
        expect(emitter.getSubscriptionCount('baz')).toBe 1

        emitter.off 'baz', handler1
        expect(emitter.getSubscriptionCount('baz')).toBe 0

  describe "::hasSubscriptions()", ->
    describe "when not passed an event name", ->
      it "returns true if the subscription count is greater than zero", ->
        expect(emitter.hasSubscriptions()).toBe true
        emitter.off()
        expect(emitter.hasSubscriptions()).toBe false

    describe "when passed an event name", ->
      it "returns true if the subscription count is greater than zero", ->
        expect(emitter.hasSubscriptions('baz')).toBe false

        emitter.on 'baz', handler1 = ->
        expect(emitter.hasSubscriptions('baz')).toBe true

  describe "::signal(eventName)", ->
    it "returns a signal that yields a value whenever an event by the given name is emitted", ->
      values = []
      emitter.signal('a').on 'value', (v) -> values.push(v)
      expect(values).toEqual []
      emitter.emit('a', 'hello')
      emitter.emit('a', 'goodbye')
      expect(values).toEqual ['hello', 'goodbye']

  describe "::behavior(eventName, initialValue)", ->
    it "returns a behavior based on events of the given name, assigning the given initial value if a behavior for that event does not already exist", ->
      values = []
      emitter.behavior('a', 'hello').on 'value', (v) -> values.push(v)
      expect(values).toEqual ['hello']
      emitter.emit('a', 'goodbye')

      # new behaviors can use a different initial value
      values2 = []
      emitter.behavior('a', 'no, stay!').on 'value', (v) -> values2.push(v)
      expect(values2).toEqual ['no, stay!']

      emitter.emit('a', 'good riddance!')
      expect(values).toEqual ['hello', 'goodbye', 'good riddance!']
      expect(values2).toEqual ['no, stay!', 'good riddance!']
