{ KDViewNode } = require 'kdf-dom'

###*
 * Helper method to create `KDViewNode` easily.
 *
 * @param {*} id - id for node
 * @param {Object|Array.<KDViewNode|KDTextNode>=} options - either options or subviews array
 * @param {Array=} subviews - subviews array
 * @return {KDViewNode}
###
createNode = (id, options, subviews) ->

  [options, subviews] = [subviews, options]  if Array.isArray options

  options or= {}
  options.subviews or= subviews
  options.id = id
  options.tagName or= 'span'

  new KDViewNode options


###*
 * Helper method to create `KDTextNode` like object easily.
 *
 * @param {String} value - value of KDTextNode
 * @param {Object} node - `KDTextNode` like object
###
createTextNode = (value = '') -> { value: value, nodeType: 'KDTextNode' }


###*
 * Helper class to test diff operations
 * when it shouldn't update.
###
class NoUpdateNode extends KDViewNode

  shouldUpdate: -> no


module.exports = {
  createNode
  createTextNode
  NoUpdateNode
}


