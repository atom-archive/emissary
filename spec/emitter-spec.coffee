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
      it "subscribes to each of the event names", ->
        emitter.on '    a.b  c.d\te ', fooHandler1

        emitter.emit 'a'
        expect(fooHandler1).toHaveBeenCalled()

        fooHandler1.reset()
        emitter.emit 'c'
        expect(fooHandler1).toHaveBeenCalled()

        fooHandler1.reset()
        emitter.emit 'e'
        expect(fooHandler1).toHaveBeenCalled()

        fooHandler1.reset()
        emitter.emit ''
        expect(fooHandler1).not.toHaveBeenCalled()

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

  describe "::off", ->
    describe "when called with no arguments", ->
      it "removes all subscriptions", ->
        emitter.off()
        emitter.emit 'foo'
        expect(fooHandler1).not.toHaveBeenCalled()
        expect(fooHandler2).not.toHaveBeenCalled()

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

      it "does not throw an exception if there was no subscriptino for the given handler", ->
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

  describe "::getSubscriptionCount()", ->
    it "returns the total number of subscriptions on the emitter", ->
      expect(emitter.getSubscriptionCount()).toBe 3

      emitter.on 'baz', ->
      expect(emitter.getSubscriptionCount()).toBe 4

      emitter.off 'foo'
      expect(emitter.getSubscriptionCount()).toBe 2
