jest.autoMockOff()

KDViewNode = require 'kdf-dom/lib/viewnode'

KDDomDiff     = require '../src/diff'
KDDomPatcher  = require '../src/patcher'
createElement = require '../src/create-element'

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


  describe '.applySinglePatch', ->

    it "throws if the patch's type is unknown", ->

      applySinglePatch = -> KDDomPatcher.applySinglePatch { type: 'UNKNOWN_TYPE' }

      expect(applySinglePatch).toThrow()


