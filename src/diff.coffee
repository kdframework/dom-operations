KDDomPatch = require './patch'

{ isFunction, isObject, isEmpty } = require 'lodash'
{ isViewNode, isTextNode, getAttributes } = require 'kdf-dom/lib/helpers'

module.exports = class KDDomDiff

  ###*
   * Generates diff patch array between 2 views.
   *
   * @param {KDViewNode|KDTextNode} left - current state of the view.
   * @param {KDViewNode|KDTextNode} right - next state of the view.
   * @return {Object.<Array>} patch operations
  ###
  @generatePatch = (left, right) ->

    patch = { __node__: left }
    KDDomDiff.traverse left, right, patch, 0
    return patch


  ###*
   * Traverses given states of the tree,
   * generates a patch operation to change `left`
   * into `right`.
   *
   * @param {KDViewNode|KDTextNode} left - current state of the view.
   * @param {KDViewNode|KDTextNode} right - next state of the view.
   * @param {Object.<Array>} patch - object that will have the final patch ops.
   * @param {integer} index
   * @return {Object.<Array>} patch object that was passed to the function, but with ops.
  ###
  @traverse = (left, right, patch, index) ->

    return  if left is right

    # return only if the left node doesn't want to
    # be rerendered.
    if left and isFunction left.shouldUpdate

      return  unless left.shouldUpdate right

    patchArray = patch[index]

    # which means that node is deleted.
    # add destroy patch.
    unless right
      KDDomDiff.destroyView left, patch, index

    # we got a view node.
    else if isViewNode right

      if isViewNode left

        # this is for identifying if we are still
        # dealing with the same node. So just make an attributes patch
        # and continue with subviews if they exist.
        if left.tagName is right.tagName and left.id is right.id

          leftAttributes  = getAttributes left
          rightAttributes = getAttributes right

          attrDiff = KDDomDiff.diffAttributes leftAttributes, rightAttributes
          attrPatch = new KDDomPatch
            type  : KDDomPatch.ATTRIBUTES
            patch : attrDiff
            node  : { current: left, next: right }

          patchArray = appendPatch patchArray, attrPatch  if attrDiff

          # view's itself is done, need to diff subviews,
          # reorder them if necessary first, then start individual node
          # traversing again.
          patchArray = KDDomDiff.diffSubviews left, right, patch, patchArray, index

        # if we are not dealing with same node
        # we are simply deleting and recreating new view node
        else patchArray = addViewNodePatch left, right, patch, index

      # if current node is not a view node
      # we are destroying it and adding a view node.
      else patchArray = addViewNodePatch left, right, patch, index

    else if isTextNode right

      # if we are diffing something not a text node
      # with a text node, we are destroying current element
      # first, and adding a new text node patch.
      if not isTextNode left

        patchArray = addTextNodePatch left, right, patch, index

      # instead of explicitly checking if nodes
      # are text nodes, we are comparing their value
      # because text node has data in its `value` property.
      # And because it's only
      else if left.value isnt right.value

        forceDestroy = no
        patchArray = addTextNodePatch left, right, patch, index, forceDestroy


    patch[index] = patchArray  if patchArray

    return patch


  ###*
   * Generates a diff of given attributes.
   *
   * @param {Object} left - current state of the attributes.
   * @param {Object} right - next state of the attributes.
   * @return {Object} final diff of attributes.
  ###
  @diffAttributes = (left, right) ->

    diff = {}

    for lKey of left

      leftValue  = left[lKey]
      rightValue = right[lKey] ? null

      # don't do anything if left value hasn't changed.
      continue  if leftValue is rightValue

      # for example style attribute.
      # attributes: { style: { width: 10, height: 20 } }
      if isObject(leftValue) and isObject(rightValue)

        objectDiff = KDDomDiff.diffAttributes leftValue, rightValue
        diff[lKey] = objectDiff  if objectDiff

      else

        diff[lKey] = rightValue

    # copy the keys from b that is not present in a.
    diff[rKey] = right[rKey]  for own rKey of right when rKey not of left

    diff = null  if isEmpty diff

    return diff


  ###*
   * Crates a diff of 2 different subviews array.
   *
   * @param {KDViewNode|KDTextNode} current - current state of node.
   * @param {KDViewNode|KDTextNode} next - next state of node.
   * @param {Object} patch - object that operations will be added.
   * @param {Array} patchArray - patch operations array for current node.
   * @param {integer} index - holds the current state index.
   * @return {Array} final patch for particular node.
  ###
  @diffSubviews = (current, next, patch, patchArray, index) ->

    currentSubviews = current.subviews
    nextSubviews    = KDDomDiff.reorderSubviews currentSubviews, next.subviews

    len = Math.max currentSubviews.length, nextSubviews.length

    for i in [0...len]

      left  = currentSubviews[i]
      right = nextSubviews[i]

      index += 1

      unless left
        if right

          domPatch = new KDDomPatch
            type  : KDDomPatch.INSERT
            node  : null
            patch : right

          patchArray = appendPatch patchArray, domPatch

      else
        # go start traversing the subview.
        KDDomDiff.traverse left, right, patch, index

      index += left.subviews.length  if left?.subviews?.length

    if nextSubviews.moves
      orderPatch = new KDDomPatch
        type  : KDDomPatch.ORDER
        node  : current
        patch : nextSubviews.moves

      patchArray = appendPatch patchArray, orderPatch

    return patchArray


  ###*
   * Reorders the subviews array depending on
   * the id property of the KDViewNode instance.
   *
   * h3 Constraint
   *  - There at least needs to be one `id` property in each subview array.
   *  - Otherwise, subview array of next state will be used.
   *
   * @param {Array.<KDViewNode>} current - subviews of current state of view.
   * @param {Array.<KDViewNode>} next - subviews of next state of view.
   *
  ###
  @reorderSubviews = (current, next) ->

    return next  unless nextIdsMap = getIdIndexes next
    return next  unless currentIdsMap = getIdIndexes current

    currentMatchMap = KDDomDiff.getMatches nextIdsMap, currentIdsMap
    nextMatchMap    = KDDomDiff.getMatches currentIdsMap, nextIdsMap

    len = Math.max current.length, next.length

    reordered = []
    moves     = {}
    removes   = moves.removes = {}
    reverse   = moves.reverse = {}
    hasMoves  = no

    freeIndex = 0
    moveIndex = 0
    index = 0

    while freeIndex < len

      move = currentMatchMap[index]

      # if there is a match on current map
      # there may be a move between 2 maps.
      if move?

        reordered[index] = next[move]

        # extract: 0
        # when the value and moveIndex
        # are not the same that means we
        # have a move and we need to add that
        # to moves object to identify the change
        # from `move` to `moveIndex`.
        if move isnt moveIndex

          moves[move]        = moveIndex
          reverse[moveIndex] = move
          hasMoves           = yes

        moveIndex += 1

        # hasMoves = addMoves moves, move, moveIndex

      # this means that we have a key defined
      # but the value of that key is `undefined`.
      # so add an `undefined` value to the same key
      # for reordered to say that, it's deleted.
      # also add that to the removes array,
      # so that we will now it's deleted.
      else if index of currentMatchMap

        reordered[index] = undefined
        removes[index]   = moveIndex
        hasMoves         = yes

        moveIndex += 1

      # this means that there is no move.
      # which means there is no object with this
      # key in our current map.
      else

        # find the first undefined index.
        freeIndex += 1  while nextMatchMap[freeIndex] isnt undefined

        if freeIndex < len

          freeSubview = next[freeIndex]

          if freeSubview

            reordered[index] = freeSubview

            if freeIndex isnt moveIndex

              moves[freeIndex]   = moveIndex
              reverse[moveIndex] = freeIndex
              hasMoves           = yes

            moveIndex += 1

          freeIndex += 1

      index += 1

    reordered.moves = moves  if hasMoves

    return reordered


  ###*
   * Generates patches for the destroyal of subviews.
   *
   * @param {KDViewNode|KDTextNode} view - view that its subviews will be deleted.
   * @param {Object} patch - object which patches will be added.
   * @param {integer} index - current state index.
  ###
  @destroyView = (view, patch, index) ->

    return  unless isViewNode view

    destroyPatch = new KDDomPatch
      type  : KDDomPatch.DESTROY
      node  : view
      patch : null

    patchArray = appendPatch patchArray, destroyPatch
    patch[index] = patchArray

    for subview in view.subviews

      index += 1

      KDDomDiff.destroyView subview, patch, index

      index += subview.subviews.length  if isViewNode subview


  ###*
   * Returns a new object with the index
   * difference between left and right.
   * (Subview order diff)
   *
   * ## Example:
   *
   *     left  = { a: 1, b: 0, c: 2}
   *     right = { a: 0, b: 1, c: 2, d: 3}
   *
   *     rightMatches = getMatches left, right
   *     # => {0: 1, 1: 0, 2: 2, 3: undefined}
   *
   *     leftMatches = getMatches right, left
   *     # => {0: 1, 1: 0, 2: 2}
   *
   * @param {Object} left - current state of object.
   * @param {Object} right - next state of obect.
   * @return {Object}
  ###
  @getMatches = (left, right) ->

    match = {}

    match[value] = left[key]  for own key, value of right

    return match


  ###*
   * Object representation of a diff operation
   * between 2 different nodes. Holds a `null` patch
   * for initial state, once patch is generated `diff` instance
   * will hold the patch object as it's property.
   *
   * @param {KDViewNode|KDTextNode} left - current state of node.
   * @param {KDViewNode|KDTextNode} right - next state of node.
  ###
  constructor: (left, right) ->

    @left  = left
    @right = right
    @patch = null


  ###*
   * Instance Method of KDDomDiff.generate patch.
   * it generates a patch using the static method
   * by passing the instance's left and right properties.
   * Which are either KDViewNode
   *
   * @return {Object} patch operations.
  ###
  generatePatch: -> @patch = KDDomDiff.generatePatch @left, @right


###*
 * Gets subviews, and returns their indexes
 * associated with their id.
 *
 * h3 Example
 *
 *   firstView = new KDView # no id
 *   secondView = new KDView # no id
 *
 *   # returns `null` because there are no ids.
 *   getIdIndexes [firstView, secondView]
 *   # => null
 *
 *   firstView.id = 'f3ffd79'
 *   secondView.id = 'c33219b'
 *
 *   getIdIndexes [firstView, secondView]
 *   # => {'f3ffd79': 0, 'c33219b': 1}
 *
 * @param {Array.<KDViewNode|KDTextNode>} subviews
 * @return {Object} an object that contains the <id, index> pairs.
###
getIdIndexes = (subviews) ->

  map = null

  for view, index in subviews when view.id?
    map or= {}
    map[view.id] = index

  return map


###*
 * Patch operations for individual nodes can either
 * be an object, or an Array of this objects.
 * This helper method deals with that problem.
 * If the first parameters is an array it pushes
 * the patch into it, or if it's an object, constructs
 * a new array and returns it.
 *
 * @param {KDDomPatch|Array.<KDDomPatch} patchArray - initial collection of patches
 * @param {KDDomPatch} patch - single patch operation to be added
###
appendPatch = (patchArray, patch) ->

  return patch  unless patchArray

  if Array.isArray patchArray
  then patchArray.push patch
  else patchArray = [patchArray, patch]

  return patchArray


addViewNodePatch = (left, right, patch, index, forceDestroy = yes) ->

  KDDomDiff.destroyView left, patch, index  if forceDestroy

  viewPatch = new KDDomPatch
    type  : KDDomPatch.VIEW_NODE
    node  : left
    patch : right

  patchArray = patch[index]
  patchArray = appendPatch patchArray, viewPatch


addTextNodePatch = (left, right, patch, index) ->

  KDDomDiff.destroyView left, patch, index

  viewPatch = new KDDomPatch
    type  : KDDomPatch.TEXT_NODE
    node  : left
    patch : right

  patchArray = patch[index]
  patchArray = appendPatch patchArray, viewPatch



