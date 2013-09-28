Signal = require './observable'

module.exports =
class Behavior extends Signal
  constructor: (args...) ->
    initialValue = args.shift() if args.length > 1
    subscribe = args.shift()

    latestValue = initialValue
    handlingFirstSubscription = false
    @on 'first-value-subscription-will-be-added', =>
      unless handlingFirstSubscription
        handlingFirstSubscription = true
        @subscribe this, 'value', (value) => latestValue = value
        subscribe.call(this)
        handlingFirstSubscription = false

    @on 'value-subscription-removed', =>
      @unsubscribe() if @getSubscriptionCount('value') is 1 # our self-subscription above doesn't count

    @on 'value-subscription-added', (handler) -> handler(latestValue)
