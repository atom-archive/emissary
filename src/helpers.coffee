Behavior = require './behavior'

exports.combine = (args...) ->
  if args.length is 1 and Array.isArray(args[0])
    combineArray(args[0])
  else if typeof args[args.length - 1] is 'function'
    combineWithFunction(args)
  else
    throw new Error("Invalid object type")

combineArray = (array) ->
  behavior = new Behavior ->
    outputArray = array.slice()
    ready = false
    for element, i in array when element.constructor.name is 'Behavior'
      do (element, i) =>
        @subscribe element.onValue (value) =>
          outputArray = outputArray.slice() if ready
          outputArray[i] = value
          @emitValue(outputArray) if ready
    ready = true
    @emitValue(outputArray)

combineWithFunction = (args) ->
  fn = args.pop()
  combineArray(args).map (argsArray) -> fn(argsArray...)
