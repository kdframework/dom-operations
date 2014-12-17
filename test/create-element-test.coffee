jest.autoMockOff()

createElement = require '../src/create-element'

{ createNode, createTextNode } = require '../src/helpers'

describe 'createElement', ->

  it 'assigns dom element to node', ->

    view = createNode 1

    dom = createElement view

    expect(view.domElement).toBe dom


  it 'creates a text document if node is a text node', ->

    textNode = createTextNode 'foo'

    textElement = createElement textNode

    expect(textElement.textContent).toEqual 'foo'


  it 'renders a text node inside a view node', ->

    view = createNode 1, { tagName: 'div' }, [createTextNode 'foo']

    dom = createElement view

    expect(dom.tagName).toBe 'DIV'
    expect(dom.id).toBeNull()
    expect(dom.childNodes.length).toBe 1
    expect(dom.childNodes[0].textContent).toBe 'foo'


  it 'applies domId correctly', ->

    view = createNode 1, { domId: 'foo' }

    dom = createElement view

    expect(dom.id).toBe 'foo'
    expect(dom.className).toBe ''
    expect(dom.childNodes.length).toBe 0


  it 'applies cssClass correctly', ->

    view = createNode 1, { cssClass: 'foo bar' }

    dom = createElement view

    expect(dom.id).toBeNull()
    expect(dom.className).toBe 'foo bar'
    expect(dom.childNodes.length).toBe 0


  it 'applies style property correctly', ->

    view = createNode 1, {
      tagName          : 'div'
      domId            : 'foo'
      cssClass         : 'bar qux'
      attributes       :
        style          :
          padding      : '2px'
          'text-align' : 'center'
    }

    dom = createElement view

    expect(dom.id).toBe 'foo'
    expect(dom.className).toBe 'bar qux'
    expect(dom.tagName).toBe 'DIV'
    expect(dom.style.padding).toBe '2px'


  it 'adds children', ->

    view = createNode 1, [
      createNode 2, { tagName: 'span' }, [
        createTextNode 'bar'
        createTextNode 'testing'
        createNode 3, { partial: 'qux', cssClass: 'qux-style' }
      ]
      createTextNode 'hello'
      createNode 4, { tagName: 'section', partial: 'test' }
    ]

    dom = createElement view

    { childNodes } = dom

    expect(childNodes.length).toBe 3
    expect(childNodes[0].tagName).toBe 'SPAN'
    expect(childNodes[1].textContent).toBe 'hello'
    expect(childNodes[2].tagName).toBe 'SECTION'

    children = childNodes[0].childNodes

    expect(children.length).toBe 3
    expect(children[0].textContent).toBe 'bar'
    expect(children[1].textContent).toBe 'testing'
    expect(children[2].className).toBe 'qux-style'

    children = childNodes[2].childNodes

    expect(children.length).toBe 1
    expect(children[0].textContent).toBe 'test'

