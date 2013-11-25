Behavior = require '../src/behavior'
{combine} = require '../src/helpers'

describe "helpers", ->
  describe "combine(object)", ->
    it "transforms an array of behaviors/constants into a behavior that yields an array constants", ->
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
