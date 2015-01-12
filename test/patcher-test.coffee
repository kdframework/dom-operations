jest.autoMockOff()

KDViewNode     = require 'kdf-dom/lib/viewnode'
KDEventEmitter = require 'kdf-event-emitter'

KDDomDiff     = require '../src/diff'
KDDomPatcher  = require '../src/patcher'
createElement = require '../src/create-element'

fakeEvent = require 'synthetic-dom-events'

describe 'KDDomPatcher', ->

  describe '.patch', ->

    it 'updates text node', ->

      current  = new KDViewNode { id: 1, partial: 'foo' }
      rootNode = createElement current
      next     = new KDViewNode { id: 1, partial: 'bar' }
      diff     = new KDDomDiff current, next
      patch    = diff.generatePatch()

      newNode = KDDomPatcher.patch rootNode, patch

      expect(newNode.childNodes[0].textContent).toBe 'bar'


    it 'replaces text node', ->

      current = new KDViewNode { id: 1, partial: 'foo' }
      next    = new KDViewNode { id: 1 }
      next.addSubview new KDViewNode { tagName: 'span', id: 2, partial: 'bar' }

      rootNode = createElement current
      diff     = new KDDomDiff current, next
      patch    = diff.generatePatch()

      newNode = KDDomPatcher.patch rootNode, patch

      expect(newNode.childNodes[0].tagName).toBe 'SPAN'
      expect(newNode.childNodes[0].childNodes[0].textContent).toBe 'bar'


    it 'transforms attached events to new view node', ->

      current = new EventedView { id: 1, foo: 'a'}
      next    = new EventedView { id: 2, foo: 'b'}

      counts = {current: 0, next: 0}
      current.on 'click', -> counts.current++
      next.on    'click', -> counts.next++

      domElement = createElement current
      document.body.appendChild domElement

      clickEvent = fakeEvent 'click', { bubbles: yes }
      domElement.dispatchEvent clickEvent

      expect(counts.current).toBe 1

      patch = KDDomDiff.generatePatch current, next

      domElement = KDDomPatcher.patch domElement, patch

      domElement.dispatchEvent clickEvent

      expect(counts.next).toBe 1
      expect(counts.current).toBe 1


    it 'unregisters kd node from dom event delegator', ->

      clickEvent = fakeEvent 'click', { bubbles: yes }
      current    = new EventedView { id: 1 }
      next       = null
      count      = 0

      current.on 'click', -> count++

      document.body.appendChild domElement = createElement current
      domElement.dispatchEvent clickEvent

      expect(count).toBe 1

      patch = KDDomDiff.generatePatch current, next

      newNode = KDDomPatcher.patch domElement, patch

      expect(newNode).toBeNull()

      domElement.dispatchEvent clickEvent

      # It deleted from dom, so kdNode won't receive the message.
      # so count will still be `1`
      expect(count).toBe 1


  describe '.applySinglePatch', ->

    it "throws if the patch's type is unknown", ->

      applySinglePatch = -> KDDomPatcher.applySinglePatch { type: 'UNKNOWN_TYPE' }

      expect(applySinglePatch).toThrow()


class EventedView extends KDViewNode

  @include KDEventEmitter

  constructor: (options = {}, data) ->

    super options, data

    KDEventEmitter.call this

    @on 'click', => @clicked = yes


