Behavior = require '../src/behavior'
{combine} = require '../src/helpers'

describe "helpers", ->
  describe "combine(object)", ->
    describe "when passed a multiple behaviors and constants, plus a function", ->
      it "returns a behavior based calling the function on constant values based on the input behaviors and constants", ->
        input1 = new Behavior(1)
        input2 = new Behavior(2)

        values = []
        metadata = []
        combine(1, input1, 2, input2, (a, b, c, d) -> a + b + c + d).onValue (v, m) ->
          values.push v
          metadata.push m

        expect(values).toEqual [6]
        expect(metadata).toEqual [undefined]

        input1.emitValue(4, {a: 1})
        input2.emitValue(1, {b: 2})
        expect(values).toEqual [6, 9, 8]
        expect(metadata).toEqual [undefined, {source: input1, a: 1}, {source: input2, b: 2}]

    describe "when passed an array of behaviors and constant values", ->
      it "returns a behavior that yields an array of constant values based on the input behaviors and constants", ->
        input1 = new Behavior(1)
        input2 = new Behavior('a')

        values = []
        metadata = []
        combine([1, input1, 2, input2, 'b']).onValue (v, m) ->
          values.push v
          metadata.push m
        expect(values).toEqual [[1, 1, 2, 'a', 'b']]
        expect(metadata).toEqual [undefined]

        input1.emitValue(4, {a: 1})
        input2.emitValue('x', {b: 2})
        expect(values).toEqual [
          [1, 1, 2, 'a', 'b']
          [1, 4, 2, 'a', 'b']
          [1, 4, 2, 'x', 'b']
        ]
        expect(metadata).toEqual [undefined, {source: input1, a: 1}, {source: input2, b: 2}]
