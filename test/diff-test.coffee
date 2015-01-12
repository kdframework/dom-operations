jest.autoMockOff()

KDViewNode = require 'kdf-dom/lib/viewnode'

KDDomDiff  = require '../src/diff'
KDDomPatch = require '../src/patch'

{ createNode, createTextNode, NoUpdateNode } = require '../src/helpers'

describe 'KDDomDiff', ->

  it 'has defaults', ->

    left  = createNode 1
    right = createNode 2

    diff = new KDDomDiff left, right

    expect(diff.left).toBe left
    expect(diff.right).toBe right
    expect(diff.patch).toBeNull()


  describe '#generatePatch', ->

    it "generates a patch using object's left and right nodes.", ->

      left  = createNode 1
      right = createNode 2

      diff  = new KDDomDiff left, right
      patch = diff.generatePatch()

      # expect(patch).toBe {}


  describe '.diffAttributes', ->

    { diffAttributes } = KDDomDiff

    it 'adds new attributes to diff', ->

      a = {}
      b = { width: 300 }

      diff = diffAttributes a, b

      expect(diff.width).toBe 300


    it 'sets undefined for removed attributes', ->

      a = { width: 500 }
      b = {}

      diff = diffAttributes a, b

      # to test that key exists and undefined
      expect(Object.keys diff).toEqual ['width']
      expect(diff).toEqual { width: null }


    it 'adds the new values to diff if changed', ->

      a = { width: 300 }
      b = { width: 300 }
      c = { width: 500 }

      diff = diffAttributes a, b
      expect(diff).toBeNull()

      diff = diffAttributes a, c

      expect(diff.width).toBe 500


    it 'gets a diff for object properties as well', ->

      a = { width: 300 }
      b = { height: 500, style: { background: 'black' } }
      c = { height: 200, style: { background: 'black', padding: '10px' } }
      d = { height: 550, style: { background: 'black' } }

      diff = diffAttributes a, b
      expect(diff).toEqual { width: null, height: 500, style: {background: 'black'} }

      diff = diffAttributes b, c
      expect(diff).toEqual { height: 200, style: { padding: '10px' } }

      diff = diffAttributes b, d
      expect(diff).toEqual { height: 550 }

      diff = diffAttributes c, d
      expect(Object.keys diff.style).toEqual ['padding']
      expect(diff).toEqual { height: 550, style: { padding: null } }

      diff = diffAttributes b, a
      expect(Object.keys diff).toEqual ['height', 'style', 'width']
      expect(diff).toEqual { width: 300, height: null, style: null }


  describe '.reorderSubviews', ->

    { reorderSubviews } = KDDomDiff

    it 'returns next when there are no ids in next', ->

      current = [{ id: 1 }]
      next    = []

      ordered = reorderSubviews current, next
      expect(ordered).toEqual next

      next = [{tagName: 'span'}] # no id again

      ordered = reorderSubviews current, next
      expect(ordered).toEqual next


    # to check this the requirement is that next has an
    # at least one item with an `id` property.
    it 'returns next when there are no ids in current', ->

      current = []
      next    = [ createNode 1 ]

      ordered = reorderSubviews current, next
      expect(ordered).toEqual next

      current = [{tagName: 'span'}]
      ordered = reorderSubviews current, next
      expect(ordered).toEqual next


    it 'reorders the subviews', ->

      current = [ createNode(1), createNode(2) ]
      next    = [ createNode(2) ]

      expected =
        0 : undefined # empty first node, it will get a remove diff
        1 : createNode(2) # get a representation of id:2 view
        moves:
          0: 1 # move 1 to 0
          removes: { 0 : 0 }
          reverse: { 1 : 0 }

      reordered = reorderSubviews current, next
      expect(reordered).toEqual expected


  describe '.diffSubviews', ->

    { diffSubviews } = KDDomDiff

    it "adds an insert patch for every children that doesn't exist", ->

      current = createNode 10, []
      next    = createNode 10, [ createNode(1), createNode(2), createNode(3) ]

      patchArray = []
      patchArray = diffSubviews current, next, {a: current}, patchArray

      expect(patchArray.length).toBe 3
      expect(patchArray[0].type).toBe KDDomPatch.INSERT
      expect(patchArray[1].type).toBe KDDomPatch.INSERT
      expect(patchArray[2].type).toBe KDDomPatch.INSERT


    it 'adds an order patch if subviews needs to be ordered', ->

      current = createNode 10, [createNode(1)]
      next    = createNode 10, [createNode(2), createNode(1)]

      patchArray = []
      patchArray = diffSubviews current, next, {a: current}, patchArray

      expect(patchArray.length).toBe 2
      expect(patchArray[1].type).toBe KDDomPatch.ORDER
      expect(patchArray[1].node).toBe current

    describe 'current and next have subviews', ->

      origTraverse = KDDomDiff.traverse
      beforeEach -> KDDomDiff.traverse = jest.genMockFn()
      afterEach  -> KDDomDiff.traverse = origTraverse

      it 'starts traversing the children', ->

        current = createNode 10, [createNode(1)]
        next    = createNode 10, [createNode(1), createNode(2)]

        orig = KDDomDiff.traverse
        KDDomDiff.traverse = jest.genMockFn()

        patchArray = diffSubviews current, next, {}, [], 0

        expect(KDDomDiff.traverse.mock.calls[0][0]).toBe current.subviews[0]
        expect(KDDomDiff.traverse.mock.calls[0][1]).toBe next.subviews[0]


  describe 'getMatches', ->

    { getMatches } = KDDomDiff

    it 'gets matches', ->

      left = { a: 1, b: 0, c: 2}
      right = { a: 0, b: 1}

      rightMatches = getMatches left, right
      leftMatches = getMatches right, left

      expect(rightMatches).toEqual { 0: 1, 1: 0 }
      expect(leftMatches).toEqual { 0: 1, 1: 0, 2: undefined }


  describe '.destroyView', ->

    { destroyView } = KDDomDiff

    it 'adds a remove patch for itself', ->

      node = createNode 1

      patch = {}
      destroyView node, patch, 0

      expect(patch[0].type).toBe KDDomPatch.DESTROY
      expect(patch[0].node).toBe node
      expect(patch[0].patch).toBeNull()


    it 'adds remove patch for every subview', ->

      node = createNode 1, [createNode(2), createNode(3)]

      patch = {}
      destroyView node, patch, 0

      expect(patch[0].type).toBe KDDomPatch.DESTROY
      expect(patch[0].node).toBe node
      expect(patch[0].patch).toBe null

      expect(patch[1].type).toBe KDDomPatch.DESTROY
      expect(patch[1].node).toBe node.subviews[0]
      expect(patch[1].patch).toBe null

      expect(patch[2].type).toBe KDDomPatch.DESTROY
      expect(patch[2].node).toBe node.subviews[1]
      expect(patch[2].patch).toBe null


    it "doesn't add remove patch if subview is a text node", ->

      node = createNode 1, [createTextNode('foo')]

      patch = {}
      destroyView node, patch, 0

      expect(patch[0]).toBeDefined()
      expect(patch[1]).toBeUndefined()


  describe '.traverse', ->

    # traverse function that's being used in tests
    # is a wrapper around the KDDomDiff.traverse
    # function. It's added to dry up the test code.

    it 'returns undefined when nodes are same', ->

      current = createNode 1
      next    = createNode 1

      patchArray = traverse current, current, {}, 0

      expect(patchArray).toBeUndefined()


    it "returns if shouldUpdate returns false", ->

      current = new NoUpdateNode {id: 1, tagName: 'span'}
      next    = createNode 2

      patch = traverse current, next
      expect(patch).toBeUndefined()


    it "adds a remove patch to operations if next node is falsy", ->

      current = createNode 1
      next    = null

      patch = {}
      traverse current, next, patch

      expect(patch[0].type).toEqual KDDomPatch.DESTROY
      expect(patch[0].node).toEqual current
      expect(patch[0].patch).toEqual null


    describe 'when next element is VirtualNode', ->

      describe 'current element is VirtualNode', ->

        describe 'nodes are different states of same view', ->

          it 'creates an attributes patch', ->

            current = new KDViewNode {id: 1, tagName: 'a', attributes: { href: '' } }
            next    = new KDViewNode {id: 1, tagName: 'a', attributes: { href: 'kd.io' } }

            patch = traverse current, next

            expect(patch[0].type).toEqual KDDomPatch.ATTRIBUTES
            expect(patch[0].node).toEqual { current, next }
            expect(patch[0].patch).toEqual { href: 'kd.io' }


          it 'adds css class to attributes patch as className', ->

            current = new KDViewNode { id: 1, cssClass: 'foo' }
            next    = new KDViewNode { id: 1, cssClass: 'bar' }
            other   = new KDViewNode { id: 1 }

            patch = traverse current, next

            expect(patch[0].type).toEqual KDDomPatch.ATTRIBUTES
            expect(patch[0].patch).toEqual { className: 'bar' }


          it 'takes the diff of the subviews', ->

            current = createNode 1, [createNode(2)]
            next    = createNode 1, [createNode(2), createNode(3)]

            KDDomDiff.diffSubviews = jest.genMockFn()

            traverse current, next

            expect(KDDomDiff.diffSubviews).toBeCalled()


        describe 'when nodes are different nodes (else of above)', ->

          it 'adds a remove patch for current view node', ->

            current = createNode 1
            next    = createNode 2

            patch = traverse current, next

            expect(patch[0][0].type).toBe KDDomPatch.DESTROY
            expect(patch[0][0].node).toBe current
            expect(patch[0][0].patch).toBeNull()


          it 'adds an insert patch for next view node', ->

            current = createNode 1
            next    = createNode 2

            patch = traverse current, next

            expect(patch[0][1]).toEqual {
              type  : KDDomPatch.VIEW_NODE
              node  : current
              patch : next
            }


      describe 'when current element is not a virtual node', ->

        it 'adds an insert patch for next view node', ->

          current = createTextNode 'foo'
          next    = createNode 2

          patch = traverse current, next

          expect(patch[0]).toEqual {
            type  : KDDomPatch.VIEW_NODE
            node  : current
            patch : next
          }


    describe 'when next element is a text node', ->

      # view -> text
      describe 'when current element is not a text node', ->

        it 'adds a diff remove diff for current element', ->

          current = createNode 1
          next    = createTextNode 'foo'

          patch = traverse current, next

          expect(patch[0][0].type).toBe KDDomPatch.DESTROY
          expect(patch[0][0].node).toBe current
          expect(patch[0][0].patch).toBeNull()


        it 'adds a text node diff for next element', ->

          current = createNode 1
          next    = createTextNode 'foo'

          patch = traverse current, next

          expect(patch[0][1]).toEqual {
            type  : KDDomPatch.TEXT_NODE
            node  : current
            patch : next
          }


      # Happy path for text -> text
      describe "when current and next element doesn't have the same value", ->

        it 'creates a new text node patch', ->

          current = createTextNode 'foo'
          next    = createTextNode 'bar'

          patch = traverse current, next

          expect(patch[0]).toEqual {
            type  : KDDomPatch.TEXT_NODE
            node  : current
            patch : next
          }


traverse = (current, next, patch = {}, index = 0) ->

  KDDomDiff.traverse current, next, patch, index

