Emitter = require '../src/emitter'

describe "Behavior", ->
  [emitter, signal, behavior] = []

  beforeEach ->
    emitter = new Emitter
    signal = emitter.signal('a')
    behavior = signal.toBehavior(1)

  it "calls each subscribing callback with the behavior's current value", ->
    values = []
    behavior.onValue (v) -> values.push(v)
    expect(values).toEqual [1]
    emitter.emit 'a', 9
    expect(values).toEqual [1, 9]

    values2 = []
    behavior.onValue (v) -> values2.push(v)
    expect(values2).toEqual [9]

  it "unsubscribes from the underlying signal when there are no more subscribers", ->
    expect(behavior.getSubscriptionCount('value')).toBe 0
    expect(signal.getSubscriptionCount('value')).toBe 0

    subscription1 = behavior.onValue ->
    subscription2 = behavior.onValue ->

    expect(behavior.getSubscriptionCount('value')).toBe 2
    expect(signal.getSubscriptionCount('value')).toBe 1

    subscription1.off()
    expect(behavior.getSubscriptionCount('value')).toBe 1
    expect(signal.getSubscriptionCount('value')).toBe 1

    subscription2.off()
    expect(behavior.getSubscriptionCount('value')).toBe 0
    expect(signal.getSubscriptionCount('value')).toBe 0

  describe "::getValue()", ->
    it "returns the behavior's current value", ->
      behavior.retain()
      expect(behavior.getValue()).toBe 1
      signal.emitValue(22)
      expect(behavior.getValue()).toBe 22

  describe "::toBehavior()", ->
    it "returns itself because it's already a behavior", ->
      expect(behavior.toBehavior()).toBe behavior

  describe "::changes()", ->
    it "emits all changes to the behavior, but not its initial value", ->
      behavior.changes().onValue handler = jasmine.createSpy("handler")
      expect(handler).not.toHaveBeenCalled()
      emitter.emit 'a', 7
      expect(handler).toHaveBeenCalledWith(7)
      handler.reset()
      emitter.emit 'a', 8
      expect(handler).toHaveBeenCalledWith(8)

  describe "::filter(predicate)", ->
    it "returns a new behavior that only changes to values matching the given predicate", ->
      values = []
      behavior.filter((value) -> value > 5).onValue (v) -> values.push(v)

      expect(values).toEqual [undefined] # initial value did not match predicate
      emitter.emit('a', i) for i in [0..10]
      expect(values).toEqual [undefined].concat([6..10])

      # now the value of the source behavior is 10, so the initial value passes the predicate
      values = []
      behavior.filter((value) -> value > 5).onValue (v) ->
        debugger
        values.push(v)
      expect(values).toEqual [10]

  describe "::map(fn)", ->
    it "returns a new signal that emits events that are transformed by the given function", ->
      values = []
      behavior.map((value) -> value + 2).onValue (v) -> values.push(v)

      expect(values).toEqual [3]
      emitter.emit('a', i) for i in [0..10]
      expect(values).toEqual [3].concat([2..12])

  describe "::skipUntil(valueOrPredicate)", ->
    describe "when passed a value", ->
      it "skips all values until encountering a value that matches the target value", ->
        values = []
        behavior.skipUntil(5).onValue (v) -> values.push(v)
        expect(values).toEqual [undefined]
        emitter.emit 'a', 0
        emitter.emit 'a', 10
        emitter.emit 'a', 5
        emitter.emit 'a', 4
        emitter.emit 'a', 6
        expect(values).toEqual [undefined, 5, 4, 6]

    describe "when passed a predicate", ->
      it "skips all values until the predicate obtains", ->
        values = []
        behavior.skipUntil((v) -> v > 5).onValue (v) -> values.push(v)
        expect(values).toEqual [undefined]
        emitter.emit 'a', 0
        emitter.emit 'a', 10
        emitter.emit 'a', 5
        emitter.emit 'a', 4
        emitter.emit 'a', 6
        expect(values).toEqual [undefined, 10, 5, 4, 6]

  describe "::scan(initialValue, fn)", ->
    it "returns a behavior yielding the given initial value, then a new value produced by calling the given function with the previous and new values for every change", ->
      values = []
      behavior = behavior.scan 0, (oldValue, newValue) -> oldValue + newValue
      behavior.onValue (value) -> values.push(value)

      expect(values).toEqual [1]
      emitter.emit 'a', i for i in [1..5]
      expect(values).toEqual [1, 2, 4, 7, 11, 16]

  describe "::diff(initialValue, fn)", ->
    it "returns a behavior yielding the result of the function for previous and new value of the signal", ->
      values = []
      behavior = behavior.diff 0, (oldValue, newValue) -> oldValue + newValue
      behavior.onValue (value) -> values.push(value)

      expect(values).toEqual [1]
      emitter.emit 'a', i for i in [1..5]
      expect(values).toEqual [1, 2, 3, 5, 7, 9]

  describe "::distinctUntilChanged()", ->
    it "returns a signal that yields a value only when the source signal emits a different value from the previous", ->
      values = []
      behavior.distinctUntilChanged().onValue (v) -> values.push(v)

      expect(values).toEqual [1]
      emitter.emit('a', 1)
      emitter.emit('a', 1)
      expect(values).toEqual [1]
      emitter.emit('a', 2)
      emitter.emit('a', 2)
      expect(values).toEqual [1, 2]

  describe "::becomes(valueOrPredicate)", ->
    describe "when passed a value", ->
      it "emits true when the behavior changes from a non-target value to the target value and false when it changes from the target value to a non-target value", ->
        values = []
        behavior.becomes(1).onValue (v) -> values.push(v)
        expect(values).toEqual []
        emitter.emit 'a', 4
        emitter.emit 'a', 5
        expect(values).toEqual [false]
        emitter.emit 'a', 1
        emitter.emit 'a', 1
        expect(values).toEqual [false, true]
        emitter.emit 'a', 5
        emitter.emit 'a', 7
        expect(values).toEqual [false, true, false]
        emitter.emit 'a', 1
        expect(values).toEqual [false, true, false, true]

    describe "when passed a predicate", ->
      it "emits true when the behavior changes from a non-matching value to a matching value and false when it changes from a matching value to a non-matching value", ->
        values = []
        behavior.becomes((v) -> v < 5).onValue (v) -> values.push(v)
        expect(values).toEqual []
        emitter.emit 'a', 4
        expect(values).toEqual []
        emitter.emit 'a', 5
        expect(values).toEqual [false]
        emitter.emit 'a', 6
        emitter.emit 'a', 7
        expect(values).toEqual [false]
        emitter.emit 'a', 1
        expect(values).toEqual [false, true]
        emitter.emit 'a', 5
        expect(values).toEqual [false, true, false]
