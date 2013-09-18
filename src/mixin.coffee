module.exports =
class Mixin
  @includeInto: (constructor) ->
    @extend(constructor.prototype)

  @extend: (object) ->
    for key in Object.getOwnPropertyNames(@prototype)
      object[key] = @prototype[key]
