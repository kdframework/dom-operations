module.exports = class KDDomPatch

  @NONE = 0

  ###*
   * `KDDomPatch.TEXT_NODE` operation requires the following:
   *
   * - `node` {KDViewNode|KDTextNode} node of which will be replaced by patch.
   * - `patch` {KDTextNode}
   *
   * @type {Number}
  ###
  @TEXT_NODE = 1

  ###*
   * `KDDomPatch.VIEW_NODE` operation requires the following:
   *
   * - `node` {KDViewNode|KDTextNode} node of which will be replaced by patch.
   * - `patch` {KDViewNode}
   *
   * @type {Number}
  ###
  @VIEW_NODE = 2

  ###*
   * `KDDomPatch.ATTRIBUTES` operation requires the following:
   *
   * - `node` {KDViewNode} node of which attributes will be patched.
   * - `patch` {Object} diff of attributes.
   *
   * @type {Number}
  ###
  @ATTRIBUTES = 4

  ###*
   * `KDDomPatch.ORDER` operation requires the following:
   *
   * - `node` {KDViewNode}
   * - `patch` {Object} an object containing subview moves.
   *
   * @type {Number}
  ###
  @ORDER = 5

  ###*
   * `KDDomPatch.INSERT` operation requires the following:
   *
   * - `node` {null}
   * - `patch` {KDViewNode} view to be inserted.
   *
   * @type {Number}
  ###
  @INSERT = 6

  ###*
   * `KDDomPatch.DESTROY` operation requires the following:
   *
   * - `node` {KDViewNode} view to be destroyed.
   * - `patch` {null}
   *
   * @type {Number}
  ###
  @DESTROY = 7

  ###*
   * Represents a single dom patch operation.
   *
   * The options object contains the following:
   *
   * - `patch` Identifies the applied patch. This option changes with
   *           the operation type.
   *
   * @param {Object} options
   * @param {integer} type - Type of operation (e.g. KDDomPatch.DESTROY)
   * @param {KDViewNode|KDTextNode} node - source node for dom patch.
   * @param {Object} patch
  ###
  constructor: (options = {}) ->

    @type  = options.type
    @node  = options.node
    @patch = options.patch


