Emitter = require '../src/emitter'

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

  describe "::changes()", ->
    it "returns itself, because a signal is already a stream of changes only (not a behavior)", ->
      expect(signal.changes()).toBe signal

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
