noflo = require 'noflo'
unless noflo.isBrowser()
  requestAnimFrame = process.nextTick
else
  requestAnimFrame = window.requestAnimationFrame or
    window.webkitRequestAnimationFrame or
    window.mozRequestAnimationFrame or
    (callback) -> setTimeout callback, 1

step = (ctx, output, callback) ->
  # We may have been stopped from the outside
  return unless ctx.moving

  distance = ctx.massPosition - ctx.anchorPosition

  # Forces applying to the spring
  dampingForce = -ctx.friction * ctx.speed
  springForce = -ctx.stiffness * distance
  totalForce = springForce + dampingForce
 
  # Count the new speed of movement
  acceleration = totalForce / ctx.mass
  ctx.speed += acceleration

  previousPosition = ctx.massPosition

  # Calculate where we've moved
  ctx.massPosition += ctx.speed / 100

  if Math.round(ctx.massPosition) isnt Math.round(previousPosition)
    # Send the new position out
    output.send Math.round ctx.massPosition

  if Math.round(ctx.massPosition) is ctx.anchorPosition and
  Math.abs(ctx.speed) < 0.2
    # The spring is back at rest
    do callback
  else
    # And yet it moves
    return if ctx.massPosition is 0
    requestAnimFrame ->
      step ctx, output, callback

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Animates a directional spring'
  c.inPorts.add 'in',
    description: 'Initial position for the moving mass'
    datatype: 'number'
  c.inPorts.add 'anchor',
    description: 'Position of the fixed point in the other end of the spring'
    datatype: 'number'
    default: 0
    control: true
  c.inPorts.add 'mass',
    datatype: 'int'
    default: 10
    control: true
  c.inPorts.add 'stiffness',
    datatype: 'int'
    default: 120
    control: true
  c.inPorts.add 'friction',
    datatype: 'int'
    default: 3
    control: true
  c.outPorts.add 'out',
    datatype: 'number'
  c.forwardBrackets = {}
  c.scopes = {}
  c.tearDown = (callback) ->
    for scope, val of c.scopes
      val.moving = false
      val.context.deactivate()
    c.scopes = {}
    do callback
  c.process (input, output, context) ->
    return unless input.has 'in'
    # Ensure we have the parameters expected
    return if input.attached('anchor').length and not input.hasData 'anchor'
    return if input.attached('mass').length and not input.hasData 'mass'
    return if input.attached('stiffness').length and not input.hasData 'stiffness'
    return if input.attached('friction').length and not input.hasData 'friction'
    if c.scopes[input.scope]
      # Kill previous spring movement
      c.scopes[input.scope].moving = false
      c.scopes[input.scope].context.deactivate()

    c.scopes[input.scope] =
      moving: true
      context: context
      massPosition: input.getData 'in'
      anchorPosition: 0
      mass: 10
      stiffness: 120
      friction: 3
      # We start with no motion
      speed: 0
    # Read params
    if input.hasData 'anchor'
      c.scopes[input.scope].anchorPosition = input.getData 'anchor'
    if input.hasData 'mass'
      c.scopes[input.scope].mass = input.getData 'mass'
    if input.hasData 'stiffness'
      c.scopes[input.scope].stiffness = input.getData 'stiffness'
    if input.hasData 'friction'
      c.scopes[input.scope].friction = input.getData 'friction'

    step c.scopes[input.scope], output, ->
      return unless c.scopes[input.scope]
      output.done()
      delete c.scopes[input.scope]
    return

