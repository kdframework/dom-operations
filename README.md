This package is a part of the `KDFramework` that handles the conversion from `KDDom` tree and regular `DOM Element`.

## KDDomOperations
This is a collection of `diff-patch` operations that work efficiently on `KDDom` view trees.

This package exports the following:
- `KDDomPatch` is a object type to represent a patch operation that can be applied to a `DOM Element`.
- `KDDomDiff` is a utility class that holds functions for creating a queue of  `KDDomPatch` operations.
- `KDDomPatcher` acts as a bridge to automatically convert `KDDom` tree to a regular `DOM` element. It utilizes [`vdom/patch-op`](https://github.com/Matt-Esch/vdom). It automatically manages the state for you.
- `createElement` is a function that you can manually use to create the initial representation of the `KDDom` tree as a normal `DOM` element.

## Motivation
We needed a performant way to do diff calculations between the various possible states of a `KDDom` tree. After some research we saw that
[`virtual-dom`](https://github.com/Matt-Esch/virtual-dom) does exactly what we want but, it uses its own DOM node interface `VNode` to achieve this. So we applied the `virtual-dom` diff algorithm to our own `KDViewNode` dom node interface and created `KDDomDiff`, which utilizes the same algorithm for diffing but in a more `KDFramework` fashion. Additionally, it directly utilizes `virtual-dom` patch operations when possible, with the fallback to our own wrappers. Thanks to all of the contributors for their awesome work on [virtual-dom](https://github.com/Matt-Esch/virtual-dom).


## Example
```coffee
{ KDDomPatcher, createElement } = require 'kdf-dom-operations'
{ KDViewNode } = require 'kdf-dom'

count = 0

# create a view that represents <div>#{count}</div>
view = new KDViewNode { partial: count }

# create dom element and append it to body.
domNode = createElement view
document.body.appendChild domNode

# setup a patcher to handle diff/patch
# operations for you.
patcher = new KDDomPatcher { node: view }

# setup the update logic.
setInterval ->

  count += 1

  next = new KDViewNode { partial: count }

  # tell patcher to
  # render next state.
  patcher.render next

, 500
```

More API references will be added here for individual classes. Documentation is *WIP*.

## Installation

```
npm install kdf-dom-operations
```

