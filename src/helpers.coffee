Behavior = require './behavior'

exports.combine = (source) ->
  if Array.isArray(source)
    outputArray = source.slice()
    behavior = new Behavior ->
      for element, i in source when element.constructor.name is 'Behavior'
        do (element, i) =>
          @subscribe element.onValue (value) =>
            outputArray = outputArray.slice()
            outputArray[i] = value
            @emit 'value', outputArray
  else
    throw new Error("Invalid object type")
