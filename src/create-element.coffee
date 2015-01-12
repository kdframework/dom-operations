{ isObject } = require 'lodash'
{ isViewNode, isTextNode, getAttributes } = require 'kdf-dom/lib/helpers'

KDDomEventDelegator = require 'kdf-dom-event-delegator'
defaultEvents = require 'kdf-dom-event-delegator/lib/default-events'

###*
 * It takes a view node instance and converts it into real dom node.
 *
 * options object can have the following:
 *
 * - document {document}  a DOM document object. When provided it will
 *                        be used to create DOM Elements.
 *
 * @param {KDViewNode|KDTextNode} node - KD node which will be transformed into DOM element.
 * @param {Object=} options
 * @param {DOMDocument=} a DOM document object to be used for creating DOM elements when provided.
###
module.exports = createElement = (node, options = {}) ->

  doc = options.document or document

  return doc.createTextNode node.value  if isTextNode node

  element = doc.createElement node.options.tagName

  applyAttributes element, getAttributes node

  node.domElement = element

  if events = node._e

    applyEvents element, node

  { subviews } = node

  # create each subview's `DOMNode` and
  # append them to view's `DOMNode`.
  for subview in subviews

    child = createElement subview, options
    element.appendChild child  if child

  return element


applyEvents = (element, view) ->

  events = view._e
  bindedEvents = view.getOption('bind')?.split(' ') or []
  delegatedEvents = defaultEvents.slice()

  for e in bindedEvents
    continue  if e.trim()  is ''
    delegatedEvents.push e  unless e in bindedEvents

  shouldRegister = no
  for event of events

    if event in delegatedEvents
      shouldRegister = yes
      break

  delegator = KDDomEventDelegator.getInstance()
  delegator.registerNode element, view


###*
 * Apply given attributes to `DOMNode`
 *
 * @param {DOMNode} node - that attributes will be applied into.
 * @param {Object} attrs - attributes object to be aplied.
###
applyAttributes = (node, attrs) ->

  for attrKey, attrValue of attrs

    if attrValue is null
      node.removeAttribute attrKey

    # special cases for object type of attribute.
    # we need to take special action here.
    else if isObject attrValue
      # if we are dealing with style attributes
      # pass node with the attributes to `applyStyle` function.
      if attrKey is 'style'
        applyStyle node, attrValue  if Object.keys(attrValue).length
        continue

      for objKey, objValue of attrValue

        # go over other object type of attributes and
        # add them into dom element.
        # Example: attrs = {data: { id: 5 }} => <div data-id='5'></div>
        if objValue?
          node.setAttribute "#{attrKey}-#{objKey}", objValue

        else
          node.removeAttribute "#{attrKey}-#{objKey}"

    else
      attrKey = 'class'  if attrKey is 'className'

      node.setAttribute attrKey, attrValue


###*
 * Applies style to given `DOMNode`
 *
 * @param {DOMNode} node - DOM element
 * @param {Object} style - object to be applied as style attrs.
###
applyStyle = (node, style) ->

  for key, value of style

    value or= ''

    node.style[key] = value


