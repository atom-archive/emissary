Subscriber = require '../src/subscriber'
Emitter = require '../src/emitter'

describe "Subscriber", ->
  [emitter1, emitter2, event1Handler, event2Handler, subscriber] = []

  beforeEach ->
    emitter1 = new Emitter
    emitter2 = new Emitter
    subscriber = new Subscriber
    event1Handler = jasmine.createSpy("event1Handler")
    event2Handler = jasmine.createSpy("event2Handler")
    subscriber.subscribe emitter1, 'event1', event1Handler
    subscriber.subscribe emitter2, 'event2', event2Handler

  it "subscribes to events on the specified object", ->
    emitter1.emit 'event1', 'foo'
    expect(event1Handler).toHaveBeenCalledWith('foo')

    emitter2.emit 'event2', 'bar'
    expect(event2Handler).toHaveBeenCalledWith('bar')

  it "allows an object to unsubscribe en-masse", ->
    subscriber.unsubscribe()
    emitter1.emit 'event1', 'foo'
    emitter2.emit 'event2', 'bar'
    expect(event1Handler).not.toHaveBeenCalled()
    expect(event2Handler).not.toHaveBeenCalled()

  it "allows an object to unsubscribe from a specific object", ->
    subscriber.unsubscribe(emitter1)
    emitter1.emit 'event1', 'foo'
    emitter2.emit 'event2', 'bar'
    expect(event1Handler).not.toHaveBeenCalled()
    expect(event2Handler).toHaveBeenCalledWith('bar')
