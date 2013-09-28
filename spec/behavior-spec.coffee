Emitter = require '../src/emitter'

describe "Behavior", ->
  [emitter, behavior] = []

  beforeEach ->
    emitter = new Emitter
    behavior = emitter.signal('a').toBehavior(1)

  describe "::toBehavior(initialValue)", ->
    it "returns a new behavior with the same initial value", ->
      newBehavior = behavior.toBehavior()
      newBehavior.onValue(handler = jasmine.createSpy("handler"))
      expect(handler).toHaveBeenCalledWith(1)
      handler.reset()
      emitter.emit 'a', 44
      expect(handler).toHaveBeenCalledWith(44)

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
