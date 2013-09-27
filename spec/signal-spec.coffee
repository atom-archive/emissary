Emitter = require '../src/emitter'

describe "Signal", ->
  [emitter, signal] = []

  beforeEach ->
    emitter = new Emitter
    signal = emitter.signal('a')

  describe "::filter(predicate)", ->
    it "returns a new signal that only emits values matching the given predicate", ->
      values = []
      signal.filter((value) -> value > 5).onValue (v) -> values.push(v)

      emitter.emit('a', i) for i in [0..10]
      expect(values).toEqual [6..10]

  describe "::map(fn)", ->
    it "returns a new signal that emits events that are transformed by the given function", ->
      values = []
      signal.map((value) -> value + 2).onValue (v) -> values.push(v)

      emitter.emit('a', i) for i in [0..10]
      expect(values).toEqual [2..12]
