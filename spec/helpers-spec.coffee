Behavior = require '../src/behavior'
{combine} = require '../src/helpers'

describe "helpers", ->
  describe "combine(object)", ->
    describe "when passed a multiple behaviors and constants, plus a function", ->
      it "returns a behavior based calling the function on constant values based on the input behaviors and constants", ->
        input1 = new Behavior(1)
        input2 = new Behavior(2)

        values = []
        combine(1, input1, 2, input2, (a, b, c, d) -> a + b + c + d).onValue (v) -> values.push v
        expect(values).toEqual [6]

        input1.emitValue(4)
        input2.emitValue(1)
        expect(values).toEqual [6, 9, 8]

    describe "when passed an array of behaviors and constant values", ->
      it "returns a behavior that yields an array of constant values based on the input behaviors and constants", ->
        input1 = new Behavior(1)
        input2 = new Behavior('a')

        values = []
        combine([1, input1, 2, input2, 'b']).onValue (v) -> values.push v
        expect(values).toEqual [[1, 1, 2, 'a', 'b']]

        input1.emit('value', 4)
        input2.emit('value', 'x')
        expect(values).toEqual [
          [1, 1, 2, 'a', 'b']
          [1, 4, 2, 'a', 'b']
          [1, 4, 2, 'x', 'b']
        ]
