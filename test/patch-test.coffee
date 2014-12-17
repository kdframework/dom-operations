jest.autoMockOff()

KDDomPatch = require '../src/patch'

describe 'KDDomPatch', ->

  it 'has constants', ->

    expect(KDDomPatch.NONE).toBeDefined()
    expect(KDDomPatch.TEXT_NODE).toBeDefined()
    expect(KDDomPatch.VIEW_NODE).toBeDefined()
    expect(KDDomPatch.ATTRIBUTES).toBeDefined()
    expect(KDDomPatch.ORDER).toBeDefined()
    expect(KDDomPatch.INSERT).toBeDefined()
    expect(KDDomPatch.DESTROY).toBeDefined()


  it 'has properties', ->

    type  = KDDomPatch.INSERT
    node  = { type: 'KDVirtualNode' }
    patch = { a: node }

    domPatch = new KDDomPatch { type, node, patch }

    expect(domPatch.type).toBe type
    expect(domPatch.node).toBe node
    expect(domPatch.patch).toBe patch


