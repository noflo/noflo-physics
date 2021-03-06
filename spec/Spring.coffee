noflo = require 'noflo'
socket = noflo.internalSocket
unless noflo.isBrowser()
  chai = require 'chai'
  path = require 'path'
  baseDir = path.resolve __dirname, '../'
else
  baseDir = 'noflo-physics'

describe 'Spring component', ->
  c = null
  ins = null
  out = null
  before (done) ->
    @timeout 4000
    loader = new noflo.ComponentLoader baseDir
    loader.load 'physics/Spring', (err, instance) ->
      return done err if err
      c = instance
      ins = socket.createSocket()
      c.inPorts.in.attach ins
      c.start done
  beforeEach ->
    out = socket.createSocket()
    c.outPorts.out.attach out
  afterEach (done) ->
    c.outPorts.out.detach out
    c.shutdown done

  describe 'with default anchor position', ->
    describe 'with rest state', ->
      it 'should not move', (done) ->
        changes = 0
        out.on 'data', (position) ->
          changes++
        ins.send 0
        setTimeout ->
          chai.expect(changes).to.equal 0
          done()
        , 4

    describe 'pulled to 100', ->
      it 'should move 24 times', (done) ->
        changes = 0
        lastPosition = null
        out.on 'data', (position) ->
          changes++
          lastPosition = position
          return if changes < 24
          chai.expect(lastPosition).to.equal 0
          chai.expect(changes).to.equal 24
          done()
        ins.send 100

    describe 'pulled to -100', ->
      it 'should move 24 times', (done) ->
        changes = 0
        lastPosition = null
        out.on 'data', (position) ->
          changes++
          lastPosition = position
          return if changes < 24
          chai.expect(lastPosition).to.equal 0
          chai.expect(changes).to.equal 24
          done()
        ins.send -100

  describe 'with custom anchor position of 200', ->
    anchor = null
    before ->
      anchor = socket.createSocket()
      c.inPorts.anchor.attach anchor
    after ->
      c.inPorts.anchor.detach anchor
    describe 'with rest state', ->
      it 'should not move', (done) ->
        anchor.send 200
        setTimeout ->
          changes = 0
          out.on 'data', (position) ->
            changes++
          ins.send 200
          setTimeout ->
            chai.expect(changes).to.equal 0
            done()
          , 4
        , 1
    describe 'pulled to 300', ->
      it 'should move 24 times', (done) ->
        anchor.send 200
        changes = 0
        lastPosition = null
        out.on 'data', (position) ->
          changes++
          lastPosition = position
          return if changes < 24
          chai.expect(lastPosition).to.equal 200
          chai.expect(changes).to.equal 24
          done()
        ins.send 300

    describe 'pulled to 700', ->
      it 'should move 31 times', (done) ->
        anchor.send 200
        changes = 0
        lastPosition = null
        out.on 'data', (position) ->
          changes++
          lastPosition = position
          return if changes < 31
          chai.expect(lastPosition).to.equal 200
          chai.expect(changes).to.equal 31
          done()
        ins.send 700
