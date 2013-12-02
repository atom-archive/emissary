Emitter = require '../src/emitter'
Signal = require '../src/signal'

describe "Signal", ->
  [emitter, signal] = []

  beforeEach ->
    emitter = new Emitter
    signal = emitter.signal('a')

  describe "::toBehavior(initialValue)", ->
    it "turns the signal into a behavior with the given inital value", ->
      behavior = signal.toBehavior(22)
      behavior.onValue(handler = jasmine.createSpy("handler"))
      expect(handler).toHaveBeenCalledWith(22)
      handler.reset()
      emitter.emit 'a', 44
      expect(handler).toHaveBeenCalledWith(44)

    it "can take undefined as the behavior's initial value", ->
      behavior = signal.toBehavior(undefined)
      behavior.onValue(handler = jasmine.createSpy("handler"))
      expect(handler).toHaveBeenCalledWith(undefined)

  describe "::changes()", ->
    it "returns itself, because a signal is already a stream of changes only (not a behavior)", ->
      expect(signal.changes()).toBe signal

  describe "::injectMetadata(fn)", ->
    it "allows a metadata value to be injected for the given event", ->
      values = []
      metadata = []
      signal.injectMetadata((value) -> {value}).onValue (v, m) ->
        values.push(v)
        metadata.push(m)

      emitter.emit('a', 4)
      expect(values).toEqual [4]
      expect(metadata).toEqual [{value: 4}]

  describe "::filter(predicate)", ->
    it "returns a new signal that only emits values matching the given predicate", ->
      values = []
      signal.filter((value) -> value > 5).onValue (v) -> values.push(v)

      expect(values).toEqual []
      emitter.emit('a', i) for i in [0..10]
      expect(values).toEqual [6..10]

  describe "::map(fn)", ->
    it "returns a new signal that emits events that are transformed by the given function", ->
      values = []
      signal.map((value) -> value + 2).onValue (v) -> values.push(v)

      expect(values).toEqual []
      emitter.emit('a', i) for i in [0..10]
      expect(values).toEqual [2..12]

  describe "::flatMapLatest(fn)", ->
    it "switches to the most recent signal returned by mapping over the stream with the fn", ->
      values = []
      metadata = []
      signal.flatMapLatest((signal) -> signal).onValue (v, m) ->
        values.push(v)
        metadata.push(m)

      subsignal1 = new Signal
      subsignal2 = new Signal
      subsignal3 = new Signal

      expect(subsignal1.getSubscriptionCount('value')).toBe 0
      signal.emitValue(subsignal1)
      expect(subsignal1.getSubscriptionCount('value')).toBe 1
      expect(values).toEqual []

      subsignal1.emitValue('a', 1)
      subsignal1.emitValue('b', 2)
      expect(values).toEqual ['a', 'b']
      expect(metadata).toEqual [1, 2]

      expect(subsignal2.getSubscriptionCount('value')).toBe 0
      signal.emitValue(subsignal2)
      expect(subsignal1.getSubscriptionCount('value')).toBe 0
      expect(subsignal2.getSubscriptionCount('value')).toBe 1
      expect(values).toEqual ['a', 'b']
      expect(metadata).toEqual [1, 2]

      subsignal1.emitValue('x', 0)
      subsignal2.emitValue('c', 3)
      subsignal2.emitValue('d', 4)
      expect(values).toEqual ['a', 'b', 'c', 'd']
      expect(metadata).toEqual [1, 2, 3, 4]

      expect(subsignal3.getSubscriptionCount('value')).toBe 0
      signal.emitValue(subsignal3)
      expect(subsignal2.getSubscriptionCount('value')).toBe 0
      expect(subsignal3.getSubscriptionCount('value')).toBe 1

      subsignal2.emitValue('x', 0)
      subsignal3.emitValue('e', 5)
      expect(values).toEqual ['a', 'b', 'c', 'd', 'e']
      expect(metadata).toEqual [1, 2, 3, 4, 5]

      signal.emitValue(null)
      expect(subsignal3.getSubscriptionCount('value')).toBe 0
      expect(values).toEqual ['a', 'b', 'c', 'd', 'e']
      expect(metadata).toEqual [1, 2, 3, 4, 5]

  describe "::skipUntil(valueOrPredicate)", ->
    describe "when passed a value", ->
      it "skips all values until encountering a value that matches the target value", ->
        values = []
        signal.skipUntil(5).onValue (v) -> values.push(v)
        expect(values).toEqual []
        emitter.emit 'a', 0
        emitter.emit 'a', 10
        emitter.emit 'a', 5
        emitter.emit 'a', 4
        emitter.emit 'a', 6
        expect(values).toEqual [5, 4, 6]

    describe "when passed a predicate", ->
      it "skips all values until the predicate obtains", ->
        values = []
        signal.skipUntil((v) -> v > 5).onValue (v) -> values.push(v)
        expect(values).toEqual []
        emitter.emit 'a', 0
        emitter.emit 'a', 10
        emitter.emit 'a', 5
        emitter.emit 'a', 4
        emitter.emit 'a', 6
        expect(values).toEqual [10, 5, 4, 6]

  describe "::scan(initialValue, fn)", ->
    it "returns a behavior yielding the given initial value, then a new value produced by calling the given function with the previous and new values for every change", ->
      values = []
      behavior = signal.scan 0, (oldValue, newValue) -> oldValue + newValue
      behavior.onValue (value) -> values.push(value)

      expect(values).toEqual [0]
      emitter.emit 'a', i for i in [1..5]
      expect(values).toEqual [0, 1, 3, 6, 10, 15]

  describe "::diff(initialValue, fn)", ->
    it "returns a behavior yielding the result of the function for previous and new value of the signal", ->
      values = []
      behavior = signal.diff 0, (oldValue, newValue) -> oldValue + newValue
      behavior.onValue (value) -> values.push(value)

      expect(values).toEqual [undefined]
      emitter.emit 'a', i for i in [1..5]
      expect(values).toEqual [undefined, 1, 3, 5, 7, 9]

  describe "::distinctUntilChanged()", ->
    it "returns a signal that yields a value only when the source signal emits a different value from the previous", ->
      values = []
      signal.distinctUntilChanged().onValue (v) -> values.push(v)

      expect(values).toEqual []
      emitter.emit('a', 1)
      emitter.emit('a', 1)
      expect(values).toEqual [1]
      emitter.emit('a', 2)
      emitter.emit('a', 2)
      expect(values).toEqual [1, 2]

  describe "::equals(value)", ->
    it "yields true when the signal's value is equal to the given value", ->
      values = []
      metadata = []
      signal.equals(1).onValue (v, m) -> values.push(v); metadata.push(m)

      signal.emitValue(0, 'a')
      signal.emitValue(2, 'b')
      signal.emitValue(1, 'c')
      signal.emitValue(1, 'd')
      signal.emitValue(5, 'e')
      signal.emitValue(1, 'f')
      expect(values).toEqual [false, true, false, true]
      expect(metadata).toEqual ['a', 'c', 'e', 'f']

  describe "::isDefined()", ->
    it "yields true when the signal's value is defined", ->
      values = []
      metadata = []
      signal.isDefined().onValue (v, m) -> values.push(v); metadata.push(m)

      signal.emitValue(null, 'a')
      signal.emitValue(undefined, 'b')
      signal.emitValue(1, 'c')
      signal.emitValue(0, 'd')
      signal.emitValue(null, 'e')
      signal.emitValue(1, 'f')
      expect(values).toEqual [false, true, false, true]
      expect(metadata).toEqual ['a', 'c', 'e', 'f']
