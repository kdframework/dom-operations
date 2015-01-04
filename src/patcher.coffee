{ isArray } = require 'lodash'
{ getAttributes, isTextNode } = require 'kdf-dom/lib/helpers'

domIndex = require 'vdom/dom-index'
patchOp  = require 'vdom/patch-op'

createElement = require './create-element'
KDDomPatch    = require './patch'

module.exports = class KDDomPatcher

  ###*
   * Patches the dom node with the given patches object.
   *
   * @param {DOMNode} rootNode - The DOM element that patches will be applied.
   * @param {Object} patches - Patch operations
   * @param {KDViewNode|KDTextNode} __node__ - source KD node.
   * @param {KDDomPatch|Array.<KDDomPatch>} numeric values - patch operations.
  ###
  @patch = (rootNode, patches, renderOptions) ->

    indices = KDDomPatcher.patchIndices patches

    return rootNode  unless indices.length

    domNodes      = KDDomPatcher.domIndex rootNode, patches.__node__, indices
    ownerDocument = rootNode.ownerDocument

    unless renderOptions

      renderOptions = { patch: KDDomPatcher.patch }
      renderOptions.document = ownerDocument  if ownerDocument isnt document

    for i in indices

      { applyPatch } = KDDomPatcher
      rootNode = applyPatch rootNode, domNodes[i], patches[i], renderOptions

    return rootNode


  ###*
   * It transforms either a view not or a text node
   * into a way that matches `vdom/dom-index`.
   *
   * @param {DOMNode} rootNode  start indexing dom from this DOM node.
   * @param {KDViewNode|KDTextNode} kdnode  use this view tree to map DOM node.
   * @param {Object} patches object.
   * @return {Object.<DOMNode>} an object contains individual DOM elements for each index.
   * @see {@link https://github.com/Matt-Esch/vdom} for more info about `vdom`.
  ###
  @domIndex = (rootNode, kdNode, indices) ->

    transformed = transformNode kdNode

    domIndex rootNode, transformed, indices


  ###*
   * Constructs an array of numeric values of patches object.
   *
   * @param {Object} patches
   * @return {Array.<KDDomPatch|Array.<KDDomPatch>>
  ###
  @patchIndices = (patches) ->

    return (Number key  for own key of patches when key isnt '__node__')


  ###*
   * Processes an entry from patchlist and delegates the
   * necessary object to `KDDomPatcher.applySinglePatch` method.
   * Processor of patch object.
   *
   * @param {DOMNode} rootNode - apply patch to this node.
   * @param {DOMNode|null} domNode - prospective DOM node for patch.
   * @param {KDDomPatch|Array.<KDDomPatch>} patchList
   * @param {Object} renderOptions
   * @return {DOMNode} rootNode - modified and patched `DOMNode`
   * @see KDDomPatcher.applySinglePatch
  ###
  @applyPatch = (rootNode, domNode, patchList, renderOptions) ->

    return rootNode  unless domNode

    patchList = [patchList]  unless Array.isArray patchList

    for singlePatch in patchList

      newNode  = KDDomPatcher.applySinglePatch singlePatch, domNode, renderOptions
      rootNode = newNode  if domNode is rootNode

    return rootNode


  ###*
   * Applies single patch operation to DOM node. This method
   * a custom wrapper arround `vdom/patch-op`. It uses it for some types
   * of patch, but for some others our own version is used.
   *
   * @param {KDDomPatch} domPatch
   * @param {DOMNode} domNode
   * @param {Object} renderOptions
   * @return {DOMNode} newNode
   * @see {@link https://github.com/Matt-Esch/vdom} for more info about `vdom`.
  ###
  @applySinglePatch: (domPatch, domNode, renderOptions) ->

    { type, node, patch } = domPatch

    return switch type
      when KDDomPatch.DESTROY    then patchOp domPatch, domNode, renderOptions
      when KDDomPatch.ORDER      then patchOp domPatch, domNode, renderOptions
      when KDDomPatch.INSERT     then insertNode domNode, patch, renderOptions
      when KDDomPatch.TEXT_NODE  then textNodePatch domNode, node, patch, renderOptions
      when KDDomPatch.VIEW_NODE  then viewNodePatch domNode, node, patch, renderOptions
      when KDDomPatch.ATTRIBUTES then attributesPatch domPatch, domNode, renderOptions
      else throw new Error 'Patch type is unknown'


###*
 * Creates a DOM element from {KDViewNode|KDTextNode}
 * instance. Inserts it into `parentNode`
 *
 * @param {DOMNode} parentNode
 * @param {KDViewNode|KDTextNode} kdNode
 * @param {Object} renderOptions
 * @return {DOMNode} parentNode - same node with `kdNode` inserted.
###
insertNode = (parentNode, kdNode, renderOptions) ->

  newNode = createElement kdNode, renderOptions

  parentNode.appendChild newNode  if parentNode

  return parentNode


###*
 * Removes given DOM node and inserts a new DOM Text node.
 *
 * @param {DOMNode} domNode
 * @param {KDViewNode|KDTextNode} current - node to be replaced.
 * @param {KDTextNode} next - node to be inserted.
 * @param {Object} renderOptions
 * @return {DOMNode} newNode
###
textNodePatch = (domNode, current, next, renderOptions) ->

  newNode = null

  if domNode.nodeType is 3

    domNode.replaceData 0, domNode.length, next.value
    newNode = domNode

  else

    parentNode = domNode.parentNode
    newNode = createElement next, renderOptions

    parentNode.replaceChild newNode, domNode  if parentNode

  return newNode


###*
 * Removes given DOM node and inserts a new DOM node.
 *
 * @param {DOMNode} domNode
 * @param {KDViewNode|KDTextNode} current - node to be replaced.
 * @param {KDTextNode} next - node to be inserted.
 * @param {Object} renderOptions
 * @return {DOMNode} newNode
###
viewNodePatch = (domNode, current, next, renderOptions) ->

 { parentNode } = domNode

 newNode = createElement next, renderOptions

 parentNode.replaceChild newNode, domNode  if parentNode

 return newNode


###*
 * Patches DOM node with the attributes by converting
 * `KDDomPatch` instance into `vdom/vpatch` like object
 * to be able to use `vdom/patch-op`.
 *
 * @param {KDDomPatch} domPatch
 * @param {DOMNode} domNode
 * @param {Object} renderOptions
 * @return {DOMNode}
 * @see {@link https://github.com/Matt-Esch/vdom} for more info about `vdom`.
###
attributesPatch = (domPatch, domNode, renderOptions) ->

  vPatch = {}

  { node, type, patch } = domPatch

  vNode = properties: node.attributes

  vPatch = { type, patch, vNode }

  patchOp vPatch, domNode, renderOptions


###*
 * Transforms `KDViewNode` instance into 'vtree/vnode' like object.
 *
 * @param {KDViewNode} node - to be converted.
 * @return {Object} vnode - `vtree/vnode` like object.
 * @see {@link https://github.com/Matt-Esch/vtree} for more info about `vnode`.
###
transformNode = (node) ->

  return { count: node.count, children: node.subviews }


