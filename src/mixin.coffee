module.exports =
class Mixin
  @includeInto: (constructor) ->
    @extend(constructor.prototype)
    for name, value of this when ExcludedClassProperties.indexOf(name) is -1
      constructor[name] ?= value

  @extend: (object) ->
    for key in Object.getOwnPropertyNames(@prototype) when key isnt 'constructor'
      object[key] = @prototype[key]

ExcludedClassProperties = ['__super__']
ExcludedClassProperties.push(name) for name of Mixin
